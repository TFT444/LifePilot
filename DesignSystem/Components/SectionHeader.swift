import SwiftUI

/// A titled section label with a leading SF Symbol, used to introduce a
/// group of content on a screen (Morning Briefing sections, Settings
/// groups, the component gallery). Extracted from a private type that had
/// been duplicated inside `HomeView` — per this PR's mandate to reuse
/// existing patterns rather than let each screen reimplement its own.
public struct SectionHeader: View {
    private let title: String
    private let symbolName: String

    public init(title: String, symbolName: String) {
        self.title = title
        self.symbolName = symbolName
    }

    public var body: some View {
        Label(title, systemImage: symbolName)
            .font(.LifePilot.titleMedium)
            .foregroundStyle(Color.LifePilot.textPrimary)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    SectionHeader(title: "Prepared for you", symbolName: "sparkle")
}
