import LifePilotDesignSystem
import SwiftUI

/// Placeholder for the Insights tab, per README.md's Insights feature
/// description. Full implementation arrives in
/// docs/MASTER_ROADMAP.md Phase 4.
public struct InsightsView: View {
    public init() {}

    public var body: some View {
        ComingSoonPlaceholder(
            symbolName: "chart.line.uptrend.xyaxis",
            title: "Insights",
            message: "Patterns in how you spend time and attention will appear here."
        )
        .navigationTitle("Insights")
    }
}

#Preview {
    NavigationStack {
        InsightsView()
    }
}
