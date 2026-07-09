import SwiftUI

/// Typography tokens matching docs/DESIGN_SYSTEM.md's Typography table
/// exactly. Uses the system font (SF Pro) and scales with Dynamic Type by
/// default via `.font(...)`'s relative text styles, per
/// docs/ENGINEERING_GUIDE.md's Accessibility standard.
extension Font {
    public enum LifePilot {
        /// Screen titles. 34pt Bold.
        public static let titleLarge = Font.system(size: 34, weight: .bold, design: .default)

        /// Section headers. 22pt Semibold.
        public static let titleMedium = Font.system(size: 22, weight: .semibold, design: .default)

        /// Primary content. 17pt Regular.
        public static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// Metadata, timestamps. 13pt Medium.
        public static let caption = Font.system(size: 13, weight: .medium, design: .default)
    }
}
