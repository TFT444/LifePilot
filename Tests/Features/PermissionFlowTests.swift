import Foundation
import LifePilotCore
import XCTest
@testable import LifePilotFeatures
@testable import LifePilotServices

@MainActor
final class PermissionFlowTests: XCTestCase {
    func testOnboardingDoesNotRequestBeforeEducationAction() async {
        let calendar = PermissionCalendar(nextState: .authorized)
        let viewModel = OnboardingViewModel(
            permissions: PermissionDependencies(calendar: calendar)
        )
        viewModel.advance()

        await viewModel.refreshCurrentPermission()
        let initialRequests = await calendar.requestCount()
        XCTAssertEqual(initialRequests, 0)
        XCTAssertFalse(viewModel.permissionHandled)

        await viewModel.requestCurrentPermission()
        let finalRequests = await calendar.requestCount()
        XCTAssertEqual(finalRequests, 1)
        XCTAssertEqual(viewModel.permissionState, .authorized)
        XCTAssertTrue(viewModel.permissionHandled)
    }

    func testOnboardingSkipPersistsChoiceAndContinues() async {
        let recorder = PermissionSkipRecorder()
        let viewModel = OnboardingViewModel(skipHandler: { permission in
            await recorder.record(permission)
        })
        viewModel.advance()
        XCTAssertEqual(viewModel.currentStep.permission, .calendar)

        await viewModel.skipCurrentPermission()

        let skipped = await recorder.values()
        XCTAssertEqual(skipped, [.calendar])
        XCTAssertEqual(viewModel.currentStep.permission, .reminders)
    }

    func testDeniedOnboardingPermissionKeepsLocalOnlyRecoveryMessage() async {
        let calendar = PermissionCalendar(nextState: .denied)
        let viewModel = OnboardingViewModel(
            permissions: PermissionDependencies(calendar: calendar)
        )
        viewModel.advance()

        await viewModel.requestCurrentPermission()

        XCTAssertEqual(viewModel.permissionState, .denied)
        XCTAssertEqual(
            viewModel.permissionMessage,
            "Calendar access is off. LifePilot will continue in local-only mode. "
                + "To connect later, open System Settings and allow access for LifePilot."
        )
    }

    func testCapabilityStatesRemainDistinctInPermissionPresentation() async {
        let expected: [CapabilityState: PermissionState] = [
            .unavailable: .unavailable,
            .notDetermined: .notRequested,
            .denied: .denied,
            .restricted: .restricted,
            .limited: .limited,
            .authorized: .authorized,
        ]

        for state in CapabilityState.allCases {
            let permissions = PermissionDependencies(
                calendar: PermissionCalendar(initialState: state)
            )
            let result = await permissions.state(for: .calendar)
            XCTAssertEqual(result, expected[state], "Incorrect mapping for \(state)")
        }
    }

    func testNotificationPermissionStatesPassThroughUnchanged() async {
        for state in PermissionState.allCases {
            let permissions = PermissionDependencies(
                notifications: PermissionNotifications(initialState: state)
            )
            let result = await permissions.state(for: .notifications)
            XCTAssertEqual(result, state)
        }
    }

    func testAllPermissionsCanBeSkippedForLocalOnlyOnboarding() async {
        let recorder = PermissionSkipRecorder()
        let calendar = PermissionCalendar()
        let viewModel = OnboardingViewModel(
            permissions: PermissionDependencies(calendar: calendar),
            skipHandler: { permission in
                await recorder.record(permission)
            }
        )
        viewModel.advance()

        for permission in PermissionKind.allCases {
            XCTAssertEqual(viewModel.currentStep.permission, permission)
            await viewModel.skipCurrentPermission()
        }

        let skipped = await recorder.values()
        let requests = await calendar.requestCount()
        XCTAssertEqual(skipped, PermissionKind.allCases)
        XCTAssertEqual(requests, 0)
        XCTAssertNil(viewModel.currentStep.permission)
    }

    func testSettingsLoadsAllOperatingSystemPermissionStates() async {
        let calendar = PermissionCalendar(initialState: .authorized)
        let reminders = PermissionReminders(initialState: .limited)
        let notifications = PermissionNotifications(initialState: .denied)
        let location = PermissionLocation(initialState: .notDetermined)
        let viewModel = SettingsViewModel(
            preferenceStore: InMemoryPreferenceStore(),
            permissions: PermissionDependencies(
                calendar: calendar,
                reminders: reminders,
                notifications: notifications,
                location: location
            )
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state(for: .calendar), .authorized)
        XCTAssertEqual(viewModel.state(for: .reminders), .limited)
        XCTAssertEqual(viewModel.state(for: .notifications), .denied)
        XCTAssertEqual(viewModel.state(for: .location), .notRequested)
        XCTAssertTrue(viewModel.connections.allSatisfy { $0.lastCheckedAt != nil })
    }

    func testSettingsRequestsNotificationAndRefreshesState() async {
        let notifications = PermissionNotifications(
            initialState: .notRequested,
            nextState: .authorized
        )
        let viewModel = SettingsViewModel(
            preferenceStore: InMemoryPreferenceStore(),
            permissions: PermissionDependencies(notifications: notifications)
        )

        await viewModel.requestConnection(.notifications)

        let requests = await notifications.requestCount()
        XCTAssertEqual(requests, 1)
        XCTAssertEqual(viewModel.state(for: .notifications), .authorized)
        XCTAssertEqual(viewModel.connectionMessage, "Notifications connected.")
    }

    func testSettingsRefreshReflectsPermissionChangedOutsideApp() async {
        let calendar = PermissionCalendar(initialState: .denied)
        let viewModel = SettingsViewModel(
            preferenceStore: InMemoryPreferenceStore(),
            permissions: PermissionDependencies(calendar: calendar)
        )
        await viewModel.load()
        XCTAssertEqual(viewModel.state(for: .calendar), .denied)

        await calendar.setState(.authorized)
        await viewModel.refreshConnections()

        XCTAssertEqual(viewModel.state(for: .calendar), .authorized)
    }

    func testHomeLoadsRemindersAfterAuthorizationWithoutRelaunch() async {
        let reminder = TaskItem(
            title: "Call Mum",
            source: .eventKitReminders,
            syncState: .synced
        )
        let reminders = PermissionReminders(
            initialState: .denied,
            reminders: [reminder]
        )
        let viewModel = HomeViewModel(
            taskStore: InMemoryTaskStore(),
            eventStore: InMemoryEventStore(),
            preferenceStore: InMemoryPreferenceStore(),
            integrations: HomeBriefingIntegrations(reminders: reminders)
        )

        await viewModel.load()
        XCTAssertFalse(viewModel.topTasks.contains(where: { $0.title == reminder.title }))

        await reminders.setState(.authorized)
        await viewModel.refresh()

        XCTAssertTrue(viewModel.topTasks.contains(where: { $0.title == reminder.title }))
        XCTAssertTrue(viewModel.freshnessSummary.contains("Reminders connected"))
    }

    func testHomeReconcilesReminderByExternalIdentifierWithoutDuplicates() async {
        let reminder = TaskItem(
            title: "Call Mum",
            source: .eventKitReminders,
            externalIdentifier: "stable-reminder-id",
            syncState: .synced
        )
        let store = InMemoryTaskStore()
        let viewModel = HomeViewModel(
            taskStore: store,
            eventStore: InMemoryEventStore(),
            preferenceStore: InMemoryPreferenceStore(),
            integrations: HomeBriefingIntegrations(
                reminders: PermissionReminders(initialState: .authorized, reminders: [reminder])
            )
        )

        await viewModel.load()
        await viewModel.refresh()

        let tasks = await store.allTasks()
        let imported = tasks.filter {
            $0.externalIdentifier == "stable-reminder-id"
        }
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported.first?.source, .eventKitReminders)
    }

    func testLegacyPreferencesDecodeWithNoFalsePermissionAuthorization() throws {
        let legacy = """
        {
          "onboardingCompleted": true,
          "briefingHour": 8,
          "briefingMinute": 0,
          "quietHoursStart": 22,
          "quietHoursEnd": 7,
          "defaultTravelBufferMinutes": 15,
          "defaultPreparationMinutes": 10,
          "workDayStartHour": 9,
          "workDayEndHour": 17,
          "workDays": [2, 3, 4, 5, 6],
          "sensitiveNotificationPreviews": false,
          "appearance": "system"
        }
        """

        let data = try XCTUnwrap(legacy.data(using: .utf8))
        let decoded = try JSONDecoder().decode(UserPreferences.self, from: data)

        XCTAssertEqual(decoded.briefingHour, 8)
        XCTAssertTrue(decoded.skippedPermissionIDs.isEmpty)
    }
}

private actor PermissionSkipRecorder {
    private var permissions: [PermissionKind] = []

    func record(_ permission: PermissionKind) {
        permissions.append(permission)
    }

    func values() -> [PermissionKind] {
        permissions
    }
}

private actor PermissionCalendar: CalendarIntegrating {
    private var state: CapabilityState
    private let nextState: CapabilityState
    private var requests = 0

    init(
        initialState: CapabilityState = .notDetermined,
        nextState: CapabilityState = .authorized
    ) {
        state = initialState
        self.nextState = nextState
    }

    func authorizationState() async -> CapabilityState {
        state
    }

    func requestAccess() async throws -> Bool {
        requests += 1
        state = nextState
        return state == .authorized || state == .limited
    }

    func fetchEvents(from _: Date, to _: Date) async throws -> [CalendarEvent] {
        []
    }

    func requestCount() -> Int {
        requests
    }

    func setState(_ state: CapabilityState) {
        self.state = state
    }
}

private actor PermissionReminders: RemindersIntegrating {
    private var state: CapabilityState
    private let reminders: [TaskItem]

    init(initialState: CapabilityState, reminders: [TaskItem] = []) {
        state = initialState
        self.reminders = reminders
    }

    func authorizationState() async -> CapabilityState {
        state
    }

    func requestAccess() async throws -> Bool {
        state = .authorized
        return true
    }

    func fetchOpenReminders() async throws -> [TaskItem] {
        reminders
    }

    func createReminder(
        title _: String,
        notes _: String?,
        dueDate _: Date?,
        recurrence _: RecurrenceRule?
    ) async throws -> String {
        "permission-reminder-id"
    }

    func setState(_ state: CapabilityState) {
        self.state = state
    }
}

private actor PermissionNotifications: NotificationScheduling {
    private var state: PermissionState
    private let nextState: PermissionState
    private var requests = 0

    init(
        initialState: PermissionState,
        nextState: PermissionState = .authorized
    ) {
        state = initialState
        self.nextState = nextState
    }

    func authorizationState() async -> PermissionState {
        state
    }

    func requestAuthorization() async throws -> Bool {
        requests += 1
        state = nextState
        return state == .authorized
    }

    func schedule(
        id _: String,
        title _: String,
        body _: String,
        fireDate _: Date
    ) async throws {}

    func cancel(id _: String) async throws {}

    func cancelAll() async throws {}

    func requestCount() -> Int {
        requests
    }
}

private actor PermissionLocation: LocationProviding {
    private var state: CapabilityState

    init(initialState: CapabilityState) {
        state = initialState
    }

    func authorizationState() async -> CapabilityState {
        state
    }

    func requestAuthorization() async -> CapabilityState {
        state = .authorized
        return state
    }

    func currentCoordinate() async throws -> GeoCoordinate {
        GeoCoordinate(latitude: 51.5074, longitude: -0.1278)
    }
}
