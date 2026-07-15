import LifePilotCore
import LifePilotFeatures
import LifePilotServices
import SwiftUI

/// Top-level Splash → Onboarding → Main with persisted launch state (#35).
public struct LifePilotRootView: View {
    @State private var phase: LaunchPhase = .splash
    @State private var launchError: String?
    private let dependencies: AppDependencies
    private let launchStore: any LaunchStateStoring

    public init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
        launchStore = PreferenceBackedLaunchStore(
            preferenceStore: dependencies.preferenceStore
        )
    }

    public init(
        dependencies: AppDependencies,
        launchStore: any LaunchStateStoring
    ) {
        self.dependencies = dependencies
        self.launchStore = launchStore
    }

    public var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView()
            case .onboarding:
                OnboardingView(onFinish: {
                    Task { await completeOnboarding() }
                })
            case .main:
                RootTabView(dependencies: dependencies)
            }
        }
        .overlay(alignment: .bottom) {
            if let launchError {
                Text(launchError)
                    .font(.caption)
                    .padding()
                    .background(.ultraThinMaterial)
            }
        }
        .task {
            await boot()
        }
    }

    private func boot() async {
        try? await Task.sleep(for: .seconds(1.2))
        let state = await launchStore.load()
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = state.shouldShowOnboarding ? .onboarding : .main
        }
    }

    private func completeOnboarding() async {
        do {
            try await launchStore.save(
                LaunchState(
                    hasCompletedOnboarding: true,
                    onboardingVersion: LaunchState.currentOnboardingVersion,
                    isLocalOnlyMode: true
                )
            )
            withAnimation(.easeInOut(duration: 0.35)) {
                phase = .main
            }
        } catch {
            launchError = "Could not save onboarding progress. Continuing locally."
            withAnimation(.easeInOut(duration: 0.35)) {
                phase = .main
            }
        }
    }

    private enum LaunchPhase {
        case splash
        case onboarding
        case main
    }
}

#Preview {
    LifePilotRootView()
}
