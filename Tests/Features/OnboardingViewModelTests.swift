import XCTest
@testable import LifePilotFeatures

@MainActor
final class OnboardingViewModelTests: XCTestCase {
    func testAdvanceMovesToNextStep() {
        let viewModel = OnboardingViewModel()
        let firstStepID = viewModel.currentStep.id

        viewModel.advance()

        XCTAssertNotEqual(viewModel.currentStep.id, firstStepID)
    }

    func testAdvanceDoesNotOverrunLastStep() {
        let viewModel = OnboardingViewModel()

        for _ in 0 ..< (viewModel.steps.count + 5) {
            viewModel.advance()
        }

        XCTAssertTrue(viewModel.isLastStep)
        XCTAssertEqual(viewModel.currentStepIndex, viewModel.steps.count - 1)
    }

    func testGoBackDoesNotUnderrunFirstStep() {
        let viewModel = OnboardingViewModel()

        viewModel.goBack()

        XCTAssertEqual(viewModel.currentStepIndex, 0)
    }

    func testProgressReachesOneOnLastStep() {
        let viewModel = OnboardingViewModel()

        for _ in 0 ..< viewModel.steps.count {
            viewModel.advance()
        }

        XCTAssertEqual(viewModel.progress, 1.0, accuracy: 0.0001)
    }
}
