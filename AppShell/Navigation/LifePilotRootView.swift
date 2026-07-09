import LifePilotFeatures
import SwiftUI

/// The top-level view controlling the Splash → Onboarding → Main app
/// transition. This is the single entry point the thin Xcode app target
/// (`App/`) is expected to instantiate — see `docs/ARCHITECTURE.md`'s note
/// that `Package.swift` builds the first buildable units ahead of the full
/// iOS app wrapper.
public struct LifePilotRootView: View {
    @State private var phase: LaunchPhase = .splash
    private let dependencies: AppDependencies

    public init(dependencies: AppDependencies = .live) {
        self.dependencies = dependencies
    }

    public var body: some View {
        Group {
            switch phase {
            case .splash:
                SplashView()
            case .onboarding:
                OnboardingView(onFinish: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        phase = .main
                    }
                })
            case .main:
                RootTabView(dependencies: dependencies)
            }
        }
        .task {
            // A brief, deliberate splash duration — long enough to read as
            // intentional, short enough not to feel like a delay. See
            // docs/DESIGN_SYSTEM.md's Motion principle.
            try? await Task.sleep(for: .seconds(1.2))
            withAnimation(.easeInOut(duration: 0.35)) {
                phase = .onboarding
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
