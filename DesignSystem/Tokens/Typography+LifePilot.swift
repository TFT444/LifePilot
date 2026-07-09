import SwiftUI

/// Typography tokens matching docs/DESIGN_SYSTEM.md's Typography table.
/// Built on `Font.system(_:)`'s `TextStyle` factory rather than a fixed
/// point size, so every token is Dynamic-Type-native by construction —
/// see docs/ENGINEERING_GUIDE.md's Accessibility standard.
/// Point sizes at the default content size match Apple's standard sizes
/// for the corresponding text style (e.g. `.largeTitle` is 34pt), which
/// is why each token maps to the closest system text style rather than
/// specifying an arbitrary custom size.
extension Font {
    public enum LifePilot {
        /// Screen titles. Bold, `.largeTitle` scale (34pt at the default
        /// content size).
        public static let titleLarge = Font.system(.largeTitle, design: .default, weight: .bold)

        /// Section headers. Semibold, `.title2` scale (22pt at the
        /// default content size).
        public static let titleMedium = Font.system(.title2, design: .default, weight: .semibold)

        /// Primary content. Regular, `.body` scale (17pt at the default
        /// content size).
        public static let body = Font.system(.body, design: .default, weight: .regular)

        /// Metadata, timestamps. Medium, `.footnote` scale (13pt at the
        /// default content size).
        public static let caption = Font.system(.footnote, design: .default, weight: .medium)
    }
}
