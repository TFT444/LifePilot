import Foundation

/// Owns the onboarding flow's step progression. Per
/// docs/MASTER_ROADMAP.md Phase 4's UX requirement, onboarding explains
/// *why* each step matters rather than dumping permissions upfront —
/// `OnboardingStep` carries that explanation alongside its content.
@Observable
@MainActor
public final class OnboardingViewModel {
    public private(set) var currentStepIndex = 0

    public let steps: [OnboardingStep] = OnboardingStep.allSteps

    public init() {}

    public var currentStep: OnboardingStep {
        steps[currentStepIndex]
    }

    public var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    public var progress: Double {
        Double(currentStepIndex + 1) / Double(steps.count)
    }

    public func advance() {
        guard !isLastStep else { return }
        currentStepIndex += 1
    }

    public func goBack() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
    }
}
