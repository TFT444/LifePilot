import LifePilotDesignSystem
import SwiftUI

/// The onboarding flow shown on first launch. See `OnboardingViewModel`
/// for step progression and `OnboardingStep` for step content.
public struct OnboardingView: View {
    @State private var viewModel = OnboardingViewModel()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let onFinish: () -> Void

    public init(onFinish: @escaping () -> Void) {
        self.onFinish = onFinish
    }

    public var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: Spacing.xl) {
                ProgressView(value: viewModel.progress)
                    .tint(Color.LifePilot.accentEnd)
                    .padding(.horizontal, Spacing.lg)

                Spacer()

                VStack(spacing: Spacing.lg) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient.LifePilot.hero.opacity(0.18))
                            .frame(width: 112, height: 112)
                        Image(systemName: viewModel.currentStep.symbolName)
                            .font(.system(size: IconSize.xl, weight: .medium))
                            .foregroundStyle(LinearGradient.LifePilot.hero)
                    }
                    .accessibilityHidden(true)

                    Text(viewModel.currentStep.title)
                        .font(.LifePilot.titleLarge)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                        .multilineTextAlignment(.center)

                    Text(viewModel.currentStep.message)
                        .font(.LifePilot.body)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Spacing.lg)

                    if viewModel.currentStepIndex == 0 {
                        GlassSurface(cornerRadius: CornerRadius.md) {
                            HStack(spacing: Spacing.sm) {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundStyle(Color.LifePilot.accentTeal)
                                Text("Useful without an account. Permissions stay optional.")
                                    .font(.LifePilot.caption)
                                    .foregroundStyle(Color.LifePilot.textSecondary)
                            }
                            .padding(Spacing.md)
                        }
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .id(viewModel.currentStep.id)
                .transition(reduceMotion
                    ? .opacity
                    : .opacity.combined(with: .move(edge: .trailing)))

                Spacer()

                Button(viewModel.isLastStep ? "Get Started" : "Continue") {
                    if viewModel.isLastStep {
                        onFinish()
                    } else {
                        withAnimation(reduceMotion ? nil : Motion.deliberate) {
                            viewModel.advance()
                        }
                    }
                }
                .buttonStyle(.lifePilotPrimary)
                .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .lifePilotAnimation(
            Motion.deliberate,
            reduceMotion: reduceMotion,
            value: viewModel.currentStepIndex
        )
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
