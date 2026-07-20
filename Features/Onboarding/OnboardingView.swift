import LifePilotDesignSystem
import SwiftUI

/// The onboarding flow shown on first launch. See `OnboardingViewModel`
/// for step progression and `OnboardingStep` for step content.
public struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    private let onFinish: () -> Void

    public init(
        permissions: PermissionDependencies = PermissionDependencies(),
        skipHandler: @escaping (PermissionKind) async -> Void = { _ in },
        onFinish: @escaping () -> Void
    ) {
        _viewModel = State(
            initialValue: OnboardingViewModel(
                permissions: permissions,
                skipHandler: skipHandler
            )
        )
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

                    if let message = viewModel.permissionMessage {
                        StatusBanner(
                            message: message,
                            style: viewModel.permissionState == .denied
                                ? .warning
                                : .info
                        )
                        .padding(.horizontal, Spacing.lg)
                    }
                }
                .id(viewModel.currentStep.id)
                .transition(reduceMotion
                    ? .opacity
                    : .opacity.combined(with: .move(edge: .trailing)))

                Spacer()

                actionButtons
                    .padding(.horizontal, Spacing.lg)
                .padding(.bottom, Spacing.lg)
            }
        }
        .lifePilotAnimation(
            Motion.deliberate,
            reduceMotion: reduceMotion,
            value: viewModel.currentStepIndex
        )
        .task(id: viewModel.currentStep.id) {
            await viewModel.refreshCurrentPermission()
        }
    }

    @ViewBuilder
    private var actionButtons: some View {
        if !viewModel.permissionHandled, let permission = viewModel.currentStep.permission {
            VStack(spacing: Spacing.sm) {
                Button(
                    viewModel.isRequestingPermission
                        ? "Requesting..."
                        : "Connect \(permission.displayName)"
                ) {
                    Task { await viewModel.requestCurrentPermission() }
                }
                .buttonStyle(.lifePilotPrimary)
                .disabled(viewModel.isRequestingPermission)

                Button("Not Now") {
                    Task { await viewModel.skipCurrentPermission() }
                }
                .buttonStyle(.lifePilotSecondary)
                .disabled(viewModel.isRequestingPermission)
            }
        } else {
            VStack(spacing: Spacing.sm) {
                if viewModel.permissionState == .denied {
                    Button("Open System Settings") {
                        if let url = PermissionSystemSettings.url {
                            openURL(url)
                        }
                    }
                    .buttonStyle(.lifePilotSecondary)
                }

                Button(viewModel.isLastStep ? "Get Started" : "Continue") {
                    continueFlow()
                }
                .buttonStyle(.lifePilotPrimary)
            }
        }
    }

    private func continueFlow() {
        if viewModel.isLastStep {
            onFinish()
        } else {
            withAnimation(reduceMotion ? nil : Motion.deliberate) {
                viewModel.advance()
            }
        }
    }
}

#Preview {
    OnboardingView(onFinish: {})
}
