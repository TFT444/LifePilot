import Foundation
import XCTest
@testable import LifePilotCore

final class SecurityPolicyAndApprovalTests: XCTestCase {
    func testFinanceAndEmailActionsAreDenied() {
        let policy = SecurityPolicy()
        XCTAssertFalse(policy.isAllowed(.forbiddenExternalFinancial))
        XCTAssertFalse(policy.isAllowed(.forbiddenSendEmail))
        XCTAssertTrue(policy.isAllowed(.createLocalTask))
        XCTAssertTrue(policy.isAllowed(.createLocalEvent))
    }

    func testExecutorRejectsDeniedActions() async {
        let executor = LocalActionExecutor(
            taskStore: FakeTaskStore(),
            eventStore: FakeEventStore()
        )
        let proposal = ActionProposal(
            actionType: .forbiddenExternalFinancial,
            title: "Pay bill",
            detail: "Must never execute",
            parameters: ["amount": "100"]
        )
        let approval = ApprovalRecord(
            proposalID: proposal.id,
            boundFingerprint: proposal.parameterFingerprint,
            state: .approved
        )

        do {
            _ = try await executor.execute(proposal: proposal, approval: approval)
            XCTFail("Expected denial")
        } catch is DomainError {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testFingerprintMismatchFails() async {
        let executor = LocalActionExecutor(
            taskStore: FakeTaskStore(),
            eventStore: FakeEventStore()
        )
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

        do {
            _ = try await executor.execute(proposal: proposal, approval: approval)
            XCTFail("Expected conflict")
        } catch is DomainError {
            // expected
        } catch {
            XCTFail("Unexpected error \(error)")
        }
    }

    func testIdempotentExecution() async throws {
        let taskStore = FakeTaskStore()
        let executor = LocalActionExecutor(
            taskStore: taskStore,
            eventStore: FakeEventStore()
        )
        let proposal = ActionProposal(
            actionType: .createLocalTask,
            title: "Walk the dog",
            detail: "Evening",
            parameters: ["title": "Walk the dog"]
        )
        let approval = ApprovalRecord(
            proposalID: proposal.id,
            boundFingerprint: proposal.parameterFingerprint,
            state: .approved
        )

        let first = try await executor.execute(proposal: proposal, approval: approval)
        let second = try await executor.execute(proposal: proposal, approval: approval)
        XCTAssertEqual(first.state, .completed)
        XCTAssertEqual(second.state, .completed)
        XCTAssertEqual(second.executionResult, "Already executed")
        let saved = await taskStore.allTasks()
        XCTAssertEqual(saved.count, 1)
    }

    func testAgentKindExcludesFinanceShoppingHealth() {
        let raw = Set(AgentKind.allCases.map(\.rawValue))
        XCTAssertFalse(raw.contains("finance"))
        XCTAssertFalse(raw.contains("shopping"))
        XCTAssertFalse(raw.contains("health"))
        XCTAssertFalse(raw.contains("email"))
    }
}

private actor FakeTaskStore: TaskStore {
    private var items: [TaskItem] = []

    func allTasks() async -> [TaskItem] {
        items
    }

    func save(_ task: TaskItem) async throws {
        items.append(task)
    }

    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }

    func tasks(matching predicate: @Sendable (TaskItem) -> Bool) async -> [TaskItem] {
        items.filter(predicate)
    }
}

private actor FakeEventStore: EventStore {
    private var items: [CalendarEvent] = []

    func allEvents() async -> [CalendarEvent] {
        items
    }

    func save(_ event: CalendarEvent) async throws {
        items.append(event)
    }

    func delete(id: UUID) async throws {
        items.removeAll { $0.id == id }
    }
}
