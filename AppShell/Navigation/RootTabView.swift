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
        .overlay(alignment: .bottomTrailing) {
            Button {
                captureKind = .task
                isCapturing = true
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 44))
                    .symbolRenderingMode(.hierarchical)
                    .padding(.trailing, Spacing.lg)
                    .padding(.bottom, Spacing.xl)
            }
            .accessibilityLabel("Quick capture")
        }
        .sheet(isPresented: $isCapturing) {
            QuickCaptureView(
                title: $captureTitle,
                kind: captureKind,
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
    }

    @ViewBuilder
    private func destination(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView(
                taskStore: dependencies.taskStore,
                eventStore: dependencies.eventStore,
                preferenceStore: dependencies.preferenceStore,
                planningEngine: dependencies.planningEngine,
                calendarIntegration: dependencies.calendarIntegration
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
                actionExecutor: dependencies.actionExecutor
            )
        }
    }

    private func submitCapture() async {
        let title = captureTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        do {
            switch captureKind {
            case .task, .reminder:
                // Inbox capture — no arbitrary deadline unless the user sets one later.
                try await dependencies.taskStore.save(
                    TaskItem(title: title, listID: TaskList.inbox.id)
                )
            case .event:
                // Default: starts in 30 minutes for 30 minutes — editable later.
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
            // Keep sheet open so the user can retry; toast lands in a later polish pass.
        }
    }
}

#Preview {
    RootTabView(dependencies: .preview)
}
