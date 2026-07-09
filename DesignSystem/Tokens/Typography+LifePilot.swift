import SwiftUI

/// Typography tokens matching docs/DESIGN_SYSTEM.md's Typography table
/// exactly. Uses the system font (SF Pro) and scales with Dynamic Type by
/// default via `.font(...)`'s relative text styles, per
/// docs/ENGINEERING_GUIDE.md's Accessibility standard.
extension Font {
    public enum LifePilot {
        /// Screen titles. 34pt Bold at the default content size, scaling
        /// with Dynamic Type relative to `.largeTitle`.
        public static let titleLarge = Font.system(
            size: 34, weight: .bold, design: .default, relativeTo: .largeTitle
        )

        /// Section headers. 22pt Semibold, scaling relative to `.title2`.
        public static let titleMedium = Font.system(
            size: 22, weight: .semibold, design: .default, relativeTo: .title2
        )

        /// Primary content. 17pt Regular, scaling relative to `.body`.
        public static let body = Font.system(
            size: 17, weight: .regular, design: .default, relativeTo: .body
        )

        /// Metadata, timestamps. 13pt Medium, scaling relative to
        /// `.footnote`.
        public static let caption = Font.system(
            size: 13, weight: .medium, design: .default, relativeTo: .footnote
        )
    }
}
