import LifePilotCore
import LifePilotDesignSystem
import LifePilotFeatures
import LifePilotServices
import SwiftUI

/// Root tabs with universal quick capture (#36).
public struct RootTabView: View {
    private let dependencies: AppDependencies
    @State private var selectedTab: AppTab = .home
    @State private var isCapturing = false
    @State private var captureKind: AppRoute.QuickCaptureKind = .task
    @State private var captureTitle = ""
    @State private var isSearching = false

    public init(dependencies: AppDependencies) {
        self.dependencies = dependencies
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    destination(for: tab)
                        .toolbar {
                            ToolbarItem(placement: .primaryAction) {
                                Button {
                                    isSearching = true
                                } label: {
                                    Image(systemName: "magnifyingglass")
                                }
                                .accessibilityLabel("Search")
                            }
                        }
                }
                .tabItem {
                    Label(tab.title, systemImage: tab.symbolName)
                }
                .tag(tab)
            }
        }
        .tint(Color.LifePilot.accentEnd)
        #if os(iOS)
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        #endif
        .overlay(alignment: .bottomTrailing) {
            Button {
                captureKind = .task
                isCapturing = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(LinearGradient.LifePilot.accent)
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
            }
            .accessibilityLabel("Quick capture")
        }
        .sheet(isPresented: $isCapturing) {
            QuickCaptureView(
                title: $captureTitle,
                kind: $captureKind,
                onSubmit: {
                    Task { await submitCapture() }
                },
                onCancel: {
                    isCapturing = false
                    captureTitle = ""
                }
            )
            .presentationDetents([.medium])
        }
        .sheet(isPresented: $isSearching) {
            NavigationStack {
                SearchView(
                    taskStore: dependencies.taskStore,
                    eventStore: dependencies.eventStore
                )
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") { isSearching = false }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func destination(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView(
                viewModel: HomeViewModel(
                    taskStore: dependencies.taskStore,
                    eventStore: dependencies.eventStore,
                    preferenceStore: dependencies.preferenceStore,
                    planningEngine: dependencies.planningEngine,
                    integrations: HomeBriefingIntegrations(
                        calendar: dependencies.calendarIntegration,
                        weather: dependencies.weatherIntegration,
                        travel: dependencies.travelIntegration,
                        location: dependencies.locationProvider
                    )
                )
            )
            .navigationTitle("")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        case .timeline:
            TimelineView(timelineProvider: dependencies.timelineProvider)
        case .tasks:
            TasksView(taskStore: dependencies.taskStore)
        case .insights:
            InsightsView(
                taskStore: dependencies.taskStore,
                eventStore: dependencies.eventStore,
                preferenceStore: dependencies.preferenceStore
            )
        case .settings:
            SettingsView(
                preferenceStore: dependencies.preferenceStore,
                actionExecutor: dependencies.actionExecutor,
                approvalStore: dependencies.approvalStore,
                connections: SettingsConnections(
                    cloudSync: dependencies.cloudSync,
                    locationProvider: dependencies.locationProvider,
                    calendarIntegration: dependencies.calendarIntegration,
                    remindersIntegration: dependencies.remindersIntegration
                )
            )
        }
    }

    private func submitCapture() async {
        let title = captureTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            switch captureKind {
            case .task, .reminder:
                try await dependencies.taskStore.save(
                    TaskItem(title: title, listID: TaskList.inbox.id)
                )
            case .event:
                let start = Date().addingTimeInterval(30 * 60)
                try await dependencies.eventStore.save(
                    CalendarEvent(
                        title: title,
                        startDate: start,
                        endDate: start.addingTimeInterval(30 * 60)
                    )
                )
            }
            isCapturing = false
            captureTitle = ""
        } catch {
            // Keep sheet open so the user can retry.
        }
    }
}

#Preview {
    RootTabView(dependencies: .preview)
}
