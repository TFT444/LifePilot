import Foundation
import LifePilotCore

/// Realistic sample calendar data for previews, tests, and Phase 3's
/// mock-driven screens. Not used by production code — see
/// docs/MASTER_ROADMAP.md Phase 7 for the real EventKit-backed source.
public enum MockCalendar {
    /// A full day's worth of varied events, anchored relative to `now` so
    /// previews always show a plausible "today."
    public static func events(relativeTo now: Date = Date()) -> [CalendarEvent] {
        let calendar = Calendar.current
        return [
            CalendarEvent(
                title: "Morning Standup",
                location: "Zoom",
                startDate: calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 9, minute: 15, second: 0, of: now) ?? now,
                attendeeCount: 6
            ),
            CalendarEvent(
                title: "Design Review",
                location: "Studio — Room 2B",
                startDate: calendar.date(bySettingHour: 10, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 10, minute: 45, second: 0, of: now) ?? now,
                attendeeCount: 5
            ),
            CalendarEvent(
                title: "Lunch with Sam",
                location: "Tatte Bakery",
                startDate: calendar.date(bySettingHour: 12, minute: 30, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: now) ?? now,
                attendeeCount: 2
            ),
            CalendarEvent(
                title: "1:1 with Priya",
                startDate: calendar.date(bySettingHour: 13, minute: 30, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 2
            ),
            CalendarEvent(
                title: "School Pickup",
                location: "Lincoln Elementary",
                startDate: calendar.date(bySettingHour: 14, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 14, minute: 30, second: 0, of: now) ?? now
            ),
            CalendarEvent(
                title: "Board Deck Review",
                location: nil,
                startDate: calendar.date(bySettingHour: 16, minute: 0, second: 0, of: now) ?? now,
                endDate: calendar.date(bySettingHour: 17, minute: 0, second: 0, of: now) ?? now,
                attendeeCount: 4
            ),
        ]
    }
}
