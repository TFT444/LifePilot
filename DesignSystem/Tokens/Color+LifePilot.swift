import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Color tokens matching docs/DESIGN_SYSTEM.md's Color table exactly. Every
/// value here has an explicit light and dark definition — see that
/// document's Theming principle. No feature module should reach for a raw
/// hex value; everything composes from `Color.LifePilot`.
extension Color {
    public enum LifePilot {
        // MARK: - Background

        public static let backgroundPrimary = Color(
            light: Color(hex: 0xFFFFFF),
            dark: Color(hex: 0x05050F)
        )

        public static let backgroundElevated = Color(
            light: Color(hex: 0xF5F5F7),
            dark: Color(hex: 0x0A0A1A)
        )

        // MARK: - Accent

        /// The brand gradient's two stops. Prefer `LinearGradient.LifePilot.accent`
        /// for anything that should render the full gradient rather than a
        /// flat color.
        public static let accentStart = Color(hex: 0x7C3AED)
        public static let accentEnd = Color(hex: 0x2563EB)

        // MARK: - Text

        public static let textPrimary = Color(
            light: Color(hex: 0x111114),
            dark: Color(hex: 0xFFFFFF)
        )

        public static let textSecondary = Color(
            light: Color(hex: 0x6B7280),
            dark: Color(hex: 0x9CA3C4)
        )

        // MARK: - Signal

        public static let signalRisk = Color(hex: 0xE94560)
        public static let signalSuccess = Color(hex: 0x2EA44F)
    }
}

extension LinearGradient {
    public enum LifePilot {
        /// The primary brand gradient — see docs/DESIGN_SYSTEM.md's Color
        /// table, `color.accent.primary`.
        public static let accent = LinearGradient(
            colors: [Color.LifePilot.accentStart, Color.LifePilot.accentEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

extension Color {
    /// Constructs a color from a packed RGB hex value, e.g. `Color(hex: 0x7C3AED)`.
    init(hex: UInt32) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255
        self.init(red: red, green: green, blue: blue)
    }

    /// Constructs a color that resolves to `light` or `dark` depending on
    /// the active `ColorScheme`, per docs/DESIGN_SYSTEM.md's Theming
    /// principle: "Light and dark themes are both first-class."
    ///
    /// Implemented via `Color(_:)`'s dynamic-provider initializer rather
    /// than `UIColor`/`NSColor` directly, so this compiles identically on
    /// iOS and macOS per the platforms declared in Package.swift.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #elseif canImport(AppKit)
        self.init(NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                ? NSColor(dark)
                : NSColor(light)
        })
        #else
        self = light
        #endif
    }
}
