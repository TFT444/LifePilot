import Foundation
import LifePilotCore

extension EventTextParser {
    struct ParsedRecurrence {
        let rule: RecurrenceRule
        let matched: String
    }

    static func findRecurrence(in text: String) -> ParsedRecurrence? {
        if let weekday = recurringWeekday(in: text) {
            return weekday
        }
        if let interval = recurringInterval(in: text) {
            return interval
        }

        let aliases: [(pattern: String, frequency: RecurrenceRule.Frequency)] = [
            (#"\bdaily\b"#, .daily),
            (#"\bweekly\b"#, .weekly),
            (#"\bmonthly\b"#, .monthly),
            (#"\byearly\b"#, .yearly),
        ]
        for alias in aliases {
            if let match = firstMatch(alias.pattern, in: text, caseInsensitive: true) {
                return ParsedRecurrence(
                    rule: RecurrenceRule(frequency: alias.frequency),
                    matched: match.matched
                )
            }
        }
        return nil
    }

    static func captureTitle(from text: String, removing tokens: [String?]) -> String {
        var title = text
        for token in tokens.compactMap({ $0 }) {
            title = title.replacingOccurrences(of: token, with: " ")
        }
        return cleanTitle(title, fallback: text)
    }

    private static func recurringWeekday(in text: String) -> ParsedRecurrence? {
        let weekdays: [(name: String, value: Int)] = [
            ("sunday", 1),
            ("monday", 2),
            ("tuesday", 3),
            ("wednesday", 4),
            ("thursday", 5),
            ("friday", 6),
            ("saturday", 7),
        ]
        for weekday in weekdays {
            let pattern = "\\bevery\\s+\(weekday.name)\\b"
            if let match = firstMatch(pattern, in: text, caseInsensitive: true) {
                return ParsedRecurrence(
                    rule: RecurrenceRule(frequency: .weekly, daysOfWeek: [weekday.value]),
                    matched: match.matched
                )
            }
        }
        return nil
    }

    private static func recurringInterval(in text: String) -> ParsedRecurrence? {
        let pattern = #"\bevery\s+(?:(\d+)\s+)?(day|week|month|year)s?\b"#
        guard let match = firstMatch(pattern, in: text, caseInsensitive: true),
              let unit = match.group(2)?.lowercased()
        else {
            return nil
        }
        let frequency: RecurrenceRule.Frequency = switch unit {
        case "day": .daily
        case "week": .weekly
        case "month": .monthly
        default: .yearly
        }
        return ParsedRecurrence(
            rule: RecurrenceRule(
                frequency: frequency,
                interval: Int(match.group(1) ?? "1") ?? 1
            ),
            matched: match.matched
        )
    }
}
