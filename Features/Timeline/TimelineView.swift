import LifePilotDesignSystem
import SwiftUI

/// The Timeline screen — a unified, chronological view of everything
/// happening across connected apps, per README.md's Timeline feature.
public struct TimelineView: View {
    @State private var viewModel = TimelineViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(viewModel.entries) { entry in
                    TimelineRow(content: .init(
                        time: entry.date.formatted(date: .omitted, time: .shortened),
                        title: entry.title,
                        subtitle: entry.subtitle,
                        accentColor: color(for: entry.kind)
                    ))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.md)
        }
        .background(Color.LifePilot.backgroundPrimary)
        .navigationTitle("Timeline")
        .task { await viewModel.load() }
    }

    private func color(for kind: TimelineEntry.Kind) -> Color {
        switch kind {
        case .event: return Color.LifePilot.accentStart
        case .email: return Color.LifePilot.accentEnd
        case .task: return Color.LifePilot.signalSuccess
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView()
    }
}
