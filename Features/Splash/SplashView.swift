import LifePilotDesignSystem
import SwiftUI

/// The launch screen, shown briefly while the app performs its initial
/// setup. Purely presentational — no ViewModel, since it holds no state
/// beyond a timed transition the parent view controls.
public struct SplashView: View {
    @State private var isPulsing = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        ZStack {
            AmbientBackground()

            VStack(spacing: Spacing.md) {
                BrandMark(size: 82)
                    .scaleEffect(isPulsing ? 1.03 : 1)
                    .lifePilotAnimation(
                        .easeInOut(duration: 1).repeatCount(2, autoreverses: true),
                        reduceMotion: reduceMotion,
                        value: isPulsing
                    )

                Text("LifePilot")
                    .font(.LifePilot.titleLarge)
                    .foregroundStyle(Color.LifePilot.textPrimary)
                Text("A clearer view of your day")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.textSecondary)
            }
        }
        .onAppear {
            if !reduceMotion {
                isPulsing = true
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("LifePilot is preparing your day")
    }
}

#Preview {
    SplashView()
}
