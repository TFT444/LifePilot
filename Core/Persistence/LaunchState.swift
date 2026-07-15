import Foundation

/// Shared content phase for feature ViewModels (#38).
public enum LoadableState<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case empty
    case offline(cached: Value?)
    case failed(message: String)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var value: Value? {
        switch self {
        case let .loaded(value), let .offline(cached: .some(value)):
            return value
        default:
            return nil
        }
    }
}

/// Launch + onboarding persistence (#35).
public struct LaunchState: Sendable, Codable, Equatable {
    public var hasCompletedOnboarding: Bool
    public var onboardingVersion: Int
    public var isLocalOnlyMode: Bool

    public static let currentOnboardingVersion = 1

    public init(
        hasCompletedOnboarding: Bool = false,
        onboardingVersion: Int = 0,
        isLocalOnlyMode: Bool = true
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.onboardingVersion = onboardingVersion
        self.isLocalOnlyMode = isLocalOnlyMode
    }

    public var shouldShowOnboarding: Bool {
        !hasCompletedOnboarding || onboardingVersion < LaunchState.currentOnboardingVersion
    }
}

public protocol LaunchStateStoring: Sendable {
    func load() async -> LaunchState
    func save(_ state: LaunchState) async throws
    func resetOnboarding() async throws
}

/// Preference-backed launch state for app shell.
public actor PreferenceBackedLaunchStore: LaunchStateStoring {
    private let preferenceStore: any PreferenceStore
    private var cached: LaunchState?

    public init(preferenceStore: any PreferenceStore) {
        self.preferenceStore = preferenceStore
    }

    public func load() async -> LaunchState {
        if let cached {
            return cached
        }
        let preferences = await preferenceStore.loadPreferences()
        let state = LaunchState(
            hasCompletedOnboarding: preferences.onboardingCompleted,
            onboardingVersion: preferences.onboardingCompleted
                ? LaunchState.currentOnboardingVersion
                : 0,
            isLocalOnlyMode: true
        )
        cached = state
        return state
    }

    public func save(_ state: LaunchState) async throws {
        var preferences = await preferenceStore.loadPreferences()
        preferences.onboardingCompleted = state.hasCompletedOnboarding
        try await preferenceStore.savePreferences(preferences)
        cached = state
    }

    public func resetOnboarding() async throws {
        let reset = LaunchState()
        try await save(reset)
    }
}
