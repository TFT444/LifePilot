/// A single step in the onboarding flow. Each step names the concrete
/// feature it unlocks, per docs/MASTER_ROADMAP.md Phase 4's UX
/// requirement that permission requests are contextual, not a blanket
/// upfront dump.
public struct OnboardingStep: Identifiable {
    public let id: String
    public let symbolName: String
    public let title: String
    public let message: String

    public init(id: String, symbolName: String, title: String, message: String) {
        self.id = id
        self.symbolName = symbolName
        self.title = title
        self.message = message
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
                + "and catch conflicts before they happen."
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
