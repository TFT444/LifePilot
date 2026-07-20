import Foundation
import LifePilotCore

/// Turns unstructured text — typically OCR read off a photo/screenshot, or a
/// typed/spoken line — into a structured `CapturedEvent` (title, date/time,
/// location, confidence). This is the "Understand" step of the Core Philosophy
/// (README.md): deterministic, on-device heuristics that a heavier model can
/// later augment without changing this seam.
///
/// The parser is intentionally pure and calendar-injectable so its behaviour is
/// fully testable and time-zone independent.
public struct EventTextParser: Sendable {
    let calendar: Calendar

    public init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    public func parse(_ rawText: String, now: Date = Date()) -> CapturedEvent {
        let text = rawText
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            return CapturedEvent(title: "New reminder", confidence: 0)
        }

        let time = Self.findTime(in: text)
        let day = findDay(in: text, now: now)
        let location = Self.findLocation(in: text)
        let recurrence = Self.findRecurrence(in: text)

        var resolvedDate = resolveDate(day: day?.date, time: time, now: now)
        let ambiguities = Self.captureAmbiguities(
            in: text,
            context: AmbiguityContext(
                day: day?.date,
                time: time,
                resolvedDate: resolvedDate,
                recurrence: recurrence,
                calendar: calendar,
                now: now
            )
        )
        if !ambiguities.isDisjoint(with: [.ambiguousNumericDate, .invalidDate]) {
            resolvedDate = nil
        }

        // Build a title by stripping the tokens we already understood. Location
        // is removed first because its match can contain the time substring.
        let title = Self.captureTitle(
            from: text,
            removing: [location?.matched, time?.matched, recurrence?.matched, day?.matched]
        )

        let confidence = Self.captureConfidence(
            foundTime: time != nil,
            foundDay: day != nil,
            foundLocation: location != nil
        )

        return CapturedEvent(
            title: title,
            date: resolvedDate,
            location: location?.value,
            details: nil,
            recurrence: recurrence?.rule,
            ambiguities: ambiguities,
            confidence: confidence
        )
    }

    /// A time-of-day parsed out of free text, plus the exact substring matched.
    struct ParsedTime {
        let hour: Int
        let minute: Int
        let matched: String
    }

    private func resolveDate(day: Date?, time: ParsedTime?, now: Date) -> Date? {
        // Need at least a time or a day to produce a concrete date.
        guard day != nil || time != nil else { return nil }
        let base = day ?? now
        var comps = calendar.dateComponents([.year, .month, .day], from: base)
        comps.hour = time?.hour ?? 9
        comps.minute = time?.minute ?? 0
        comps.second = 0
        return calendar.date(from: comps)
    }
}

// MARK: - Day parsing

private extension EventTextParser {
    func findDay(in text: String, now: Date) -> (date: Date, matched: String)? {
        let lower = text.lowercased()
        if lower.contains("tomorrow") {
            return (startOfDay(now, offsetDays: 1), matchedSlice("tomorrow", in: text))
        }
        if lower.contains("today") || lower.contains("tonight") {
            let token = lower.contains("today") ? "today" : "tonight"
            return (startOfDay(now, offsetDays: 0), matchedSlice(token, in: text))
        }
        if let numeric = findNumericDate(in: text, now: now) {
            return numeric
        }
        if let weekday = findWeekday(in: text, lower: lower, now: now) {
            return weekday
        }
        return findExplicitDate(in: text, now: now)
    }

    func findWeekday(in text: String, lower: String, now: Date) -> (date: Date, matched: String)? {
        let weekdays: [(name: String, weekday: Int)] = [
            ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7),
            ("sun", 1), ("mon", 2), ("tue", 3), ("wed", 4), ("thu", 5), ("fri", 6), ("sat", 7),
        ]
        for entry in weekdays where rangeOfWord(entry.name, in: lower) != nil {
            return (nextDate(weekday: entry.weekday, from: now), matchedSlice(entry.name, in: text))
        }
        return nil
    }

    func findExplicitDate(in text: String, now: Date) -> (date: Date, matched: String)? {
        // "14 July" / "14 Jul"
        let dayMonth = explicitDateMatch(
            #"\b(\d{1,2})\s+([A-Za-z]{3,9})\b"#,
            dayGroup: 1,
            monthGroup: 2,
            in: text,
            now: now
        )
        if let dayMonth {
            return dayMonth
        }

        // "July 14" / "Jul 14"
        let monthDay = explicitDateMatch(
            #"\b([A-Za-z]{3,9})\s+(\d{1,2})\b"#,
            dayGroup: 2,
            monthGroup: 1,
            in: text,
            now: now
        )
        if let monthDay {
            return monthDay
        }
        return nil
    }

    func explicitDateMatch(
        _ pattern: String,
        dayGroup: Int,
        monthGroup: Int,
        in text: String,
        now: Date
    ) -> (date: Date, matched: String)? {
        guard let match = Self.firstMatch(pattern, in: text, caseInsensitive: true) else {
            return nil
        }
        guard let month = Self.monthNumber(match.group(monthGroup)) else {
            return nil
        }
        guard let rawDay = match.group(dayGroup), let day = Int(rawDay) else {
            return nil
        }
        guard let date = makeDate(day: day, month: month, now: now) else {
            return nil
        }
        return (date, match.matched)
    }

    func startOfDay(_ now: Date, offsetDays: Int) -> Date {
        let start = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: offsetDays, to: start) ?? start
    }

    func nextDate(weekday: Int, from now: Date) -> Date {
        let today = calendar.startOfDay(for: now)
        let current = calendar.component(.weekday, from: today)
        var delta = weekday - current
        if delta < 0 {
            delta += 7
        }
        return calendar.date(byAdding: .day, value: delta, to: today) ?? today
    }
}

// MARK: - Time parsing

extension EventTextParser {
    static func findTime(in text: String) -> ParsedTime? {
        // 12-hour with am/pm, e.g. "2:30 PM", "6 am", "8p.m."
        if let match = firstMatch(#"\b(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m\.?\b"#, in: text, caseInsensitive: true) {
            var hour = Int(match.group(1) ?? "0") ?? 0
            let minute = Int(match.group(2) ?? "0") ?? 0
            let isPM = (match.group(3) ?? "").lowercased() == "p"
            if hour == 12 {
                hour = 0
            }
            if isPM {
                hour += 12
            }
            if hour <= 23, minute <= 59 {
                return ParsedTime(hour: hour, minute: minute, matched: match.matched)
            }
        }
        // 24-hour, e.g. "14:30", "09:00"
        if let match = firstMatch(#"\b([01]?\d|2[0-3]):([0-5]\d)\b"#, in: text, caseInsensitive: false) {
            let hour = Int(match.group(1) ?? "0") ?? 0
            let minute = Int(match.group(2) ?? "0") ?? 0
            return ParsedTime(hour: hour, minute: minute, matched: match.matched)
        }
        return nil
    }
}

// MARK: - Location & title

extension EventTextParser {
    static func findLocation(in text: String) -> (value: String, matched: String)? {
        // "@ Somewhere" or "at Somewhere" where the following text is not a time.
        // We scan every " at " and take the first whose tail isn't a time value.
        let patterns = [#"\bat\s+(.+)$"#, #"@\s*(.+)$"#]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let nsText = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: nsText.length))
            for match in matches where match.numberOfRanges > 1 {
                let tail = nsText.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                if tail.isEmpty {
                    continue
                }
                // Skip a pure "at 2:30 PM" style time reference.
                if let time = findTime(in: tail), time.matched.trimmingCharacters(in: .whitespaces) == tail {
                    continue
                }
                let cleaned = stripLeadingTime(from: tail)
                if cleaned.isEmpty {
                    continue
                }
                return (cleaned, nsText.substring(with: match.range(at: 0)))
            }
        }
        return nil
    }

    private static func stripLeadingTime(from text: String) -> String {
        var result = text
        if let time = findTime(in: text), text.hasPrefix(time.matched) {
            result = String(text.dropFirst(time.matched.count))
            result = result.trimmingCharacters(in: CharacterSet(charactersIn: " ,-"))
                .trimmingCharacters(in: .whitespaces)
            // "2:30 PM at Baker St" → after dropping time we may have "at Baker St".
            if result.lowercased().hasPrefix("at ") {
                result = String(result.dropFirst(3))
            }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    static func cleanTitle(_ source: String, fallback: String) -> String {
        var title = source
        // Remove common leftover connective words and separators.
        for filler in [" on ", " at ", " @ "] {
            title = title.replacingOccurrences(of: filler, with: " ", options: [.caseInsensitive])
        }
        title = title.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: [.regularExpression])
        title = title.trimmingCharacters(in: CharacterSet(charactersIn: " ,-–—:"))
        title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return title.isEmpty ? fallback.trimmingCharacters(in: .whitespacesAndNewlines) : title
    }
}

// MARK: - Regex & string helpers

extension EventTextParser {
    static func monthNumber(_ raw: String?) -> Int? {
        guard let raw = raw?.lowercased() else { return nil }
        let months = [
            "january",
            "february",
            "march",
            "april",
            "may",
            "june",
            "july",
            "august",
            "september",
            "october",
            "november",
            "december",
        ]
        for (idx, full) in months.enumerated() where raw == full || raw == String(full.prefix(3)) {
            return idx + 1
        }
        return nil
    }

    struct RegexMatch {
        let matched: String
        private let groups: [String?]
        init(matched: String, groups: [String?]) {
            self.matched = matched
            self.groups = groups
        }

        func group(_ index: Int) -> String? {
            index < groups.count ? groups[index] : nil
        }
    }

    static func firstMatch(_ pattern: String, in text: String, caseInsensitive: Bool) -> RegexMatch? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let nsText = text as NSString
        guard let match = regex.firstMatch(in: text, range: NSRange(location: 0, length: nsText.length)) else {
            return nil
        }
        var groups: [String?] = []
        for index in 0 ..< match.numberOfRanges {
            let range = match.range(at: index)
            groups.append(range.location == NSNotFound ? nil : nsText.substring(with: range))
        }
        return RegexMatch(matched: nsText.substring(with: match.range(at: 0)), groups: groups)
    }

    func rangeOfWord(_ word: String, in lower: String) -> Range<String.Index>? {
        guard let range = lower.range(of: word) else { return nil }
        let beforeOK = range.lowerBound == lower.startIndex || !lower[lower.index(before: range.lowerBound)].isLetter
        let afterOK = range.upperBound == lower.endIndex || !lower[range.upperBound].isLetter
        return (beforeOK && afterOK) ? range : nil
    }

    func matchedSlice(_ token: String, in text: String) -> String {
        if let range = text.range(of: token, options: [.caseInsensitive]) {
            return String(text[range])
        }
        return token
    }
}
