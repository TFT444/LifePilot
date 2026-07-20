import LifePilotCore
import LifePilotServices
import XCTest
@testable import LifePilotFeatures

@MainActor
final class ApprovalsViewModelTests: XCTestCase {
    func testUnsupportedActionShowsActionableFailure() async throws {
        let approvalStore = InMemoryApprovalStore()
        let executor = LocalActionExecutor(
            taskStore: InMemoryTaskStore(),
            eventStore: InMemoryEventStore(),
            approvalStore: approvalStore
        )
        let viewModel = ApprovalsViewModel(
            executor: executor,
            approvalStore: approvalStore
        )
        let proposal = ActionProposal(
            actionType: .createEventKitReminder,
            title: "Create reminder",
            detail: "Call Mum tomorrow",
            parameters: ["title": "Call Mum"]
        )

        try await viewModel.enqueue(proposal)
        await viewModel.approve(proposal)

        XCTAssertEqual(
            viewModel.lastError,
            "Apple Reminder creation is not connected yet."
        )
        XCTAssertTrue(viewModel.pending.isEmpty)
        XCTAssertEqual(viewModel.history.first?.state, .failed)
        XCTAssertEqual(
            viewModel.history.first?.executionResult,
            "Apple Reminder creation is not connected yet."
        )
    }
}
