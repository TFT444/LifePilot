/// A single step in the onboarding flow. Each step names the concrete
/// feature it unlocks, per docs/MASTER_ROADMAP.md Phase 4's UX
/// requirement that permission requests are contextual, not a blanket
/// upfront dump.
public struct OnboardingStep: Identifiable {
    public let id: String
    public let symbolName: String
    public let title: String
    public let message: String
    public let permission: PermissionKind?

    public init(
        id: String,
        symbolName: String,
        title: String,
        message: String,
        permission: PermissionKind? = nil
    ) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
        self.message = message
        self.permission = permission
    }

    public static let allSteps: [OnboardingStep] = [
        OnboardingStep(
            id: "welcome",
            symbolName: "sparkle",
            title: "Meet LifePilot",
            message: "An AI operating system that prepares your day before you ask — not another app to check."
        ),
        OnboardingStep(
            id: "calendar",
            symbolName: "calendar",
            title: "Connect your calendar",
            message: "LifePilot reads your schedule to build your Morning Briefing "
                + "and catch conflicts before they happen.",
            permission: .calendar
        ),
        OnboardingStep(
            id: "reminders",
            symbolName: "checklist",
            title: "Bring in your reminders",
            message: "Connect Apple Reminders to see open commitments beside "
                + "LifePilot tasks. You can keep them separate and connect later.",
            permission: .reminders
        ),
        OnboardingStep(
            id: "notifications",
            symbolName: "bell.badge.fill",
            title: "Choose helpful alerts",
            message: "Notifications are used only for briefings, reminders, and "
                + "approved leave-by alerts. Sensitive previews stay off by default.",
            permission: .notifications
        ),
        OnboardingStep(
            id: "location",
            symbolName: "location.fill",
            title: "Add local context",
            message: "Location When In Use improves weather and leave-by guidance. "
                + "LifePilot still works when you skip it.",
            permission: .location
        ),
        OnboardingStep(
            id: "approvals",
            symbolName: "checkmark.shield.fill",
            title: "You're always in control",
            message: "LifePilot prepares recommendations — nothing changes your "
                + "calendar, reminders, or external apps without your explicit approval."
        ),
        OnboardingStep(
            id: "ready",
            symbolName: "arrow.right.circle.fill",
            title: "You're ready",
            message: "Your Morning Briefing is waiting."
        ),
    ]
}
