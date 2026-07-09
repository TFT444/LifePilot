import LifePilotDesignSystem
import LifePilotFeatures
import SwiftUI

/// The root `TabView`, hosting the five tabs defined in `AppTab`. Each tab
/// wraps its screen in its own `NavigationStack`, per SwiftUI's recommended
/// pattern for independent per-tab navigation history.
public struct RootTabView: View {
    private let dependencies: AppDependencies
    @State private var selectedTab: AppTab = .home

    public init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    destination(for: tab)
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.symbolName)
                }
                .tag(tab)
            }
        }
        .tint(Color.LifePilot.accentEnd)
    }

    @ViewBuilder
    private func destination(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView(ghostBrain: dependencies.ghostBrain)
                .navigationTitle("")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                #endif
        case .timeline:
            TimelineView(timelineProvider: dependencies.timelineProvider)
        case .memory:
            MemoryView()
        case .insights:
            InsightsView()
        case .settings:
            SettingsView()
        }
    }
}

#Preview {
    RootTabView(dependencies: .live)
}
