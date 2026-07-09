import LifePilotDesignSystem
import SwiftUI

/// The onboarding flow shown on first launch. See `OnboardingViewModel`
/// for step progression and `OnboardingStep` for step content.
public struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    private let onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            Color.LifePilot.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: Spacing.xl) {
                ProgressView(value: viewModel.progress)
                    .tint(Color.LifePilot.accentEnd)
                    .padding(.horizontal, Spacing.lg)

                Spacer()

                VStack(spacing: Spacing.lg) {
                    Image(systemName: viewModel.currentStep.symbolName)
                        .font(.system(size: IconSize.xl, weight: .medium))
                        .foregroundStyle(LinearGradient.LifePilot.accent)

                    Text(viewModel.currentStep.title)
                        .font(.LifePilot.titleLarge)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(viewModel.currentStep.message)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)
                }
                .id(viewModel.currentStep.id)
                .transition(.opacity.combined(with: .move(edge: .trailing)))

                Spacer()

                Button(viewModel.isLastStep ? "Get Started" : "Continue") {
                    if viewModel.isLastStep {
                        onFinish()
                    } else {
                        withAnimation(Motion.deliberate) {
                            viewModel.advance()
                        }
                    }
                }
                .buttonStyle(.lifePilotPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .animation(Motion.deliberate, value: viewModel.currentStepIndex)
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
