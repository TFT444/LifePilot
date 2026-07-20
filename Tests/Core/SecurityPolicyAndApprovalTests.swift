import Foundation
import XCTest
@testable import LifePilotCore

final class SecurityPolicyAndApprovalTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testFinanceEmailAndUnwiredExternalActionsAreNotAllowed() {
        let policy = SecurityPolicy()
        XCTAssertFalse(policy.isAllowed(.forbiddenExternalFinancial))
        XCTAssertFalse(policy.isAllowed(.forbiddenSendEmail))
        XCTAssertFalse(policy.isAllowed(.rescheduleEventKitEvent))
        XCTAssertFalse(policy.isAllowed(.createEventKitReminder))
        XCTAssertTrue(policy.isAllowed(.createLocalTask))
        XCTAssertTrue(policy.isAllowed(.scheduleNotification))
    }

    func testExecutorRejectsDeniedActionAndPersistsFailureAudit() async throws {
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(approvalStore: approvalStore)
        let proposal = ActionProposal(
            actionType: .forbiddenExternalFinancial,
            title: "Pay bill",
            detail: "Must never execute",
            parameters: ["amount": "100"]
        )

        await assertDomainError(
            .unauthorizedNamed("Financial actions are outside LifePilot's scope.")
        ) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: approved(proposal)
            )
        }

        let audit = await approvalStore.auditTrail()
        XCTAssertEqual(audit.count, 1)
        XCTAssertFalse(try XCTUnwrap(audit.first).success)
    }

    func testUnsupportedExternalActionCannotReportSuccess() async {
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(approvalStore: approvalStore)
        let proposal = ActionProposal(
            actionType: .createEventKitReminder,
            title: "Create reminder",
            detail: "External write is not connected",
            parameters: ["title": "Call Mum"]
        )

        await assertDomainError(
            .invalidState("Apple Reminder creation is not connected yet.")
        ) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: approved(proposal)
            )
        }

        let stored = await approvalStore.all()
        XCTAssertEqual(stored.first?.1.state, .failed)
        XCTAssertEqual(
            stored.first?.1.executionResult,
            "Apple Reminder creation is not connected yet."
        )
    }

    func testApprovedReminderWriteReturnsStableIdentifierAndIsIdempotent() async throws {
        let reminders = FakeRemindersIntegration()
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(
            remindersIntegration: reminders,
            approvalStore: approvalStore
        )
        let proposal = ActionProposal(
            actionType: .createEventKitReminder,
            title: "Create reminder",
            detail: "Review first",
            parameters: [
                "title": "Call Mum",
                "notes": "Weekend plan",
                "dueDate": "2026-07-21T09:30:00Z",
                "recurrenceFrequency": "weekly",
                "recurrenceInterval": "1",
                "recurrenceDays": "3",
            ]
        )

        let first = try await executor.execute(proposal: proposal, approval: approved(proposal))
        let restarted = makeExecutor(
            remindersIntegration: reminders,
            approvalStore: approvalStore
        )
        let second = try await restarted.execute(proposal: proposal, approval: approved(proposal))

        XCTAssertEqual(first.executionResult, "Created Apple Reminder (external-reminder-id)")
        XCTAssertEqual(second.executionResult, first.executionResult)
        let firstCreationCount = await reminders.creationCount()
        XCTAssertEqual(firstCreationCount, 1)
        let creation = await reminders.lastCreation()
        XCTAssertEqual(creation?.title, "Call Mum")
        XCTAssertEqual(creation?.recurrence?.frequency, .weekly)
        XCTAssertEqual(creation?.recurrence?.daysOfWeek, [3])
    }

    func testReminderWriteRecoversAfterPermissionIsRestored() async throws {
        let reminders = FakeRemindersIntegration(state: .denied)
        let executor = makeExecutor(remindersIntegration: reminders)
        let proposal = ActionProposal(
            actionType: .createEventKitReminder,
            title: "Create reminder",
            detail: "Review first",
            parameters: ["title": "Call Mum"]
        )
        await assertDomainError(.unavailableNamed("Reminders access denied")) {
            _ = try await executor.execute(proposal: proposal, approval: approved(proposal))
        }

        await reminders.setState(.authorized)
        let result = try await executor.execute(proposal: proposal, approval: approved(proposal))
        XCTAssertEqual(result.state, .completed)
        let recoveredCreationCount = await reminders.creationCount()
        XCTAssertEqual(recoveredCreationCount, 1)
    }

    func testFingerprintMismatchFails() async {
        let executor = makeExecutor()
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Buy milk",
            detail: "Grocery",
            parameters: ["title": "Buy milk"]
        )
        let approval = ApprovalRecord(
            proposalID: proposal.id,
            boundFingerprint: "stale-fingerprint",
            state: .approved
        )

        await assertDomainError(.conflict) {
            _ = try await executor.execute(proposal: proposal, approval: approval)
        }
    }

    func testProposalIDMismatchFails() async {
        let executor = makeExecutor()
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Buy milk",
            detail: "Grocery",
            parameters: ["title": "Buy milk"]
        )
        let approval = ApprovalRecord(
            proposalID: UUID(),
            boundFingerprint: proposal.parameterFingerprint,
            state: .approved
        )

        await assertDomainError(.validationFailed(field: "proposalID")) {
            _ = try await executor.execute(proposal: proposal, approval: approval)
        }
    }

    func testExpiredProposalPersistsExpiredState() async {
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(approvalStore: approvalStore)
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Expired",
            detail: "Too late",
            parameters: ["title": "Expired"],
            expiresAt: now.addingTimeInterval(-1)
        )

        await assertDomainError(.unavailableNamed("Proposal expired.")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: approved(proposal)
            )
        }

        let stored = await approvalStore.all()
        XCTAssertEqual(stored.first?.1.state, .expired)
    }

    func testCreateTaskIsIdempotentAcrossExecutorRestart() async throws {
        let taskStore = FakeTaskStore()
        let approvalStore = InMemoryApprovalStore()
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Walk the dog",
            detail: "Evening",
            parameters: ["title": "Walk the dog"]
        )
        let approval = approved(proposal)

        let firstExecutor = makeExecutor(
            taskStore: taskStore,
            approvalStore: approvalStore
        )
        let first = try await firstExecutor.execute(proposal: proposal, approval: approval)

        let restartedExecutor = makeExecutor(
            taskStore: taskStore,
            approvalStore: approvalStore
        )
        let second = try await restartedExecutor.execute(proposal: proposal, approval: approval)

        let tasks = await taskStore.allTasks()
        XCTAssertEqual(first.state, .completed)
        XCTAssertEqual(second.state, .completed)
        XCTAssertEqual(tasks.count, 1)
        XCTAssertEqual(tasks.first?.id, proposal.id)
    }

    func testSideEffectFailurePersistsFailedOutcomeAndAudit() async throws {
        let taskStore = FakeTaskStore(saveError: .unavailableNamed("Disk unavailable."))
        let approvalStore = InMemoryApprovalStore()
        let executor = makeExecutor(
            taskStore: taskStore,
            approvalStore: approvalStore
        )
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Write safely",
            detail: "Persistence must succeed",
            parameters: ["title": "Write safely"]
        )

        await assertDomainError(.unavailableNamed("Disk unavailable.")) {
            _ = try await executor.execute(
                proposal: proposal,
                approval: approved(proposal)
            )
        }

        let stored = await approvalStore.all()
        let audit = await approvalStore.auditTrail()
        XCTAssertEqual(stored.first?.1.state, .failed)
        XCTAssertEqual(stored.first?.1.executionResult, "Disk unavailable.")
        XCTAssertFalse(try XCTUnwrap(audit.first).success)
    }

    func testAgentKindExcludesFinanceShoppingHealth() {
        let raw = Set(AgentKind.allCases.map(\.rawValue))
        XCTAssertFalse(raw.contains("finance"))
        XCTAssertFalse(raw.contains("shopping"))
        XCTAssertFalse(raw.contains("health"))
        XCTAssertFalse(raw.contains("email"))
    }
}
