import LifePilotDesignSystem
import SwiftUI

/// The launch screen, shown briefly while the app performs its initial
/// setup. Purely presentational — no ViewModel, since it holds no state
/// beyond a timed transition the parent view controls.
public struct SplashView: View {
    @State private var isPulsing = false

    public init() {}

    public var body: some View {
        ZStack {
            Color.LifePilot.backgroundPrimary
                .ignoresSafeArea()

            VStack(spacing: Spacing.md) {
                sparkMark
                    .scaleEffect(isPulsing ? 1.04 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.1).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                Text("LifePilot")
                    .font(.LifePilot.titleLarge)
                    .foregroundStyle(Color.LifePilot.textPrimary)
            }
        }
        .onAppear { isPulsing = true }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LifePilot is preparing your day")
    }

    private var sparkMark: some View {
        Image(systemName: "sparkle")
            .font(.system(size: IconSize.lg, weight: .medium))
            .foregroundStyle(LinearGradient.LifePilot.accent)
    }
}

#Preview {
    SplashView()
}
