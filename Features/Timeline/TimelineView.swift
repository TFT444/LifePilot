import LifePilotCore
import LifePilotDesignSystem
import SwiftUI

/// Unified chronological view — Phase 2 spine + filter chips.
public struct TimelineView: View {
    @State private var viewModel: TimelineViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(timelineProvider: TimelineProviding) {
        _viewModel = State(initialValue: TimelineViewModel(timelineProvider: timelineProvider))
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Date().formatted(.dateTime.weekday(.wide).month(.wide).day()))
                        .font(.LifePilot.titleMedium)
                        .foregroundStyle(Color.LifePilot.textPrimary)
                    Text("\(viewModel.entries.count) items in this view")
                        .font(.LifePilot.caption)
                        .foregroundStyle(Color.LifePilot.textSecondary)
                }
                Spacer()
                Label("Today", systemImage: "location.fill")
                    .font(.LifePilot.caption)
                    .foregroundStyle(Color.LifePilot.accentTeal)
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.top, Spacing.sm)
            filterBar
            ScrollView {
                if viewModel.isEmpty {
                    EmptyStateView(
                        symbolName: "calendar",
                        message: "Nothing on your timeline for this filter."
                    )
                    .padding(Spacing.lg)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.entries) { entry in
                            TimelineRow(content: .init(
                                time: entry.date.formatted(date: .omitted, time: .shortened),
                                title: entry.title,
                                subtitle: entry.subtitle,
                                accentColor: color(for: entry.kind)
                            ))
                            .lifePilotAnimation(Motion.quick, reduceMotion: reduceMotion, value: entry.id)
                        }
                    }
                    .padding(.horizontal, Spacing.lg)
                    .padding(.top, Spacing.md)
                    .padding(.bottom, Spacing.xl)
                }
            }
        }
        .background(AmbientBackground())
        .navigationTitle("Timeline")
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var filterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(TimelineViewModel.Filter.allCases, id: \.self) { filter in
                    FilterChip(
                        title: filter.title,
                        isSelected: viewModel.filter == filter,
                        action: { viewModel.setFilter(filter) }
                    )
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.sm)
        }
    }

    private func color(for kind: TimelineEntry.Kind) -> Color {
        switch kind {
        case .event: return Color.LifePilot.accentStart
        case .task: return Color.LifePilot.signalSuccess
        case .reminder: return Color.LifePilot.accentEnd
        case .recommendation: return Color.LifePilot.signalRisk
        case .signal: return Color.LifePilot.textSecondary
        }
    }
}

#Preview {
    NavigationStack {
        TimelineView(timelineProvider: PreviewTimelineProvider())
    }
}

private struct PreviewTimelineProvider: TimelineProviding {
    func loadEntries(relativeTo now: Date) async -> [TimelineEntry] {
        [TimelineEntry(date: now, title: "Design Review", subtitle: "Studio", kind: .event)]
    }
}
