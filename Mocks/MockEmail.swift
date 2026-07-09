import Foundation
import LifePilotCore

/// Realistic sample inbox data for previews, tests, and Phase 3's
/// mock-driven screens.
public enum MockEmail {
    public static func messages(relativeTo now: Date = Date()) -> [EmailMessage] {
        [
            EmailMessage(
                sender: "Priya Nair",
                subject: "Q3 roadmap — need your input by Friday",
                preview: "Hey — before we lock the roadmap I wanted to get your take on the prioritization...",
                receivedAt: now.addingTimeInterval(-3 * 24 * 3600),
                isUnread: true,
                requiresReply: true
            ),
            EmailMessage(
                sender: "United Airlines",
                subject: "Your flight UA 1472 has been updated",
                preview: "There has been a change to your upcoming reservation...",
                receivedAt: now.addingTimeInterval(-2 * 3600),
                isUnread: true,
                requiresReply: false
            ),
            EmailMessage(
                sender: "GitHub",
                subject: "[LifePilot] New pull request opened",
                preview: "feature/app-foundation was opened against develop by...",
                receivedAt: now.addingTimeInterval(-45 * 60),
                isUnread: false,
                requiresReply: false
            ),
            EmailMessage(
                sender: "Sam Rivera",
                subject: "Lunch tomorrow?",
                preview: "Are we still on for Tatte at 12:30? Let me know if...",
                receivedAt: now.addingTimeInterval(-18 * 3600),
                isUnread: false,
                requiresReply: true
            ),
        ]
    }
}
