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
    @State private var captureConfirmation: String?
    @State private var isSearching = false
    @State private var permissionRevision = 0

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
                dependencies: quickCaptureDependencies,
                initialDestination: captureKind,
                onSaved: { message in
                    isCapturing = false
                    captureConfirmation = message
                },
                onCancel: {
                    isCapturing = false
                }
            )
            .presentationDetents([.medium, .large])
        }
        .alert(
            "Capture Saved",
            isPresented: Binding(
                get: { captureConfirmation != nil },
                set: {
                    if !$0 {
                        captureConfirmation = nil
                    }
                }
            )
        ) {
            Button("OK", role: .cancel) { captureConfirmation = nil }
        } message: {
            Text(captureConfirmation ?? "")
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
                        reminders: dependencies.remindersIntegration,
                        weather: dependencies.weatherIntegration,
                        travel: dependencies.travelIntegration,
                        location: dependencies.locationProvider
                    )
                )
            )
            .id(permissionRevision)
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
                    permissions: permissionDependencies
                ),
                onPermissionsChanged: {
                    permissionRevision += 1
                }
            )
        }
    }

    private var permissionDependencies: PermissionDependencies {
        PermissionDependencies(
            calendar: dependencies.calendarIntegration,
            reminders: dependencies.remindersIntegration,
            notifications: dependencies.notificationScheduler,
            location: dependencies.locationProvider
        )
    }

    private var quickCaptureDependencies: QuickCaptureDependencies {
        QuickCaptureDependencies(
            taskStore: dependencies.taskStore,
            eventStore: dependencies.eventStore,
            approvalStore: dependencies.approvalStore,
            reminders: dependencies.remindersIntegration
        )
    }
}

#Preview {
    RootTabView(dependencies: .preview)
}
