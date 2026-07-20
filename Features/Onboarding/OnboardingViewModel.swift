import Foundation
import LifePilotCore

/// Owns onboarding progression and contextual permission requests. A request
/// can only be triggered while its education step is visible.
@Observable
@MainActor
public final class OnboardingViewModel {
    public private(set) var currentStepIndex = 0
    public private(set) var permissionState: PermissionState = .notRequested
    public private(set) var permissionMessage: String?
    public private(set) var isRequestingPermission = false
    public private(set) var permissionHandled = false

    public let steps: [OnboardingStep]

    private let permissions: PermissionDependencies
    private let skipHandler: (PermissionKind) async -> Void

    public init(
        permissions: PermissionDependencies = PermissionDependencies(),
        steps: [OnboardingStep] = OnboardingStep.allSteps,
        skipHandler: @escaping (PermissionKind) async -> Void = { _ in }
    ) {
        self.permissions = permissions
        self.steps = steps
        self.skipHandler = skipHandler
    }

    public var currentStep: OnboardingStep {
        steps[currentStepIndex]
    }

    public var isLastStep: Bool {
        currentStepIndex == steps.count - 1
    }

    public var progress: Double {
        Double(currentStepIndex + 1) / Double(steps.count)
    }

    public func refreshCurrentPermission() async {
        guard let permission = currentStep.permission else {
            resetPermissionPresentation()
            return
        }
        permissionState = await permissions.state(for: permission)
        permissionHandled = permissionState != .notRequested
        permissionMessage = Self.message(
            for: permission,
            state: permissionState
        )
    }

    public func requestCurrentPermission() async {
        guard let permission = currentStep.permission else { return }
        isRequestingPermission = true
        permissionMessage = nil
        defer { isRequestingPermission = false }

        do {
            permissionState = try await permissions.request(permission)
        } catch {
            permissionState = await permissions.state(for: permission)
            permissionMessage = error.localizedDescription
        }
        permissionHandled = true
        if permissionMessage == nil {
            permissionMessage = Self.message(
                for: permission,
                state: permissionState
            )
        }
    }

    public func skipCurrentPermission() async {
        if let permission = currentStep.permission {
            await skipHandler(permission)
        }
        advance()
    }

    public func advance() {
        guard !isLastStep else { return }
        currentStepIndex += 1
        resetPermissionPresentation()
    }

    public func goBack() {
        guard currentStepIndex > 0 else { return }
        currentStepIndex -= 1
        resetPermissionPresentation()
    }

    private func resetPermissionPresentation() {
        permissionState = .notRequested
        permissionMessage = nil
        permissionHandled = false
        isRequestingPermission = false
    }

    private static func message(
        for permission: PermissionKind,
        state: PermissionState
    ) -> String? {
        switch state {
        case .authorized:
            "\(permission.displayName) connected."
        case .limited:
            "\(permission.displayName) has limited access. You can review it in Settings."
        case .denied:
            "\(permission.displayName) access is off. LifePilot will continue in local-only mode. "
                + "To connect later, open System Settings and allow access for LifePilot."
        case .restricted:
            "\(permission.displayName) is restricted by this device or account. "
                + "LifePilot will continue in local-only mode."
        case .unavailable:
            "\(permission.displayName) is unavailable on this device."
        case .notRequested:
            nil
        }
    }
}
