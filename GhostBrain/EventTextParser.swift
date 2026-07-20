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
    private let calendar: Calendar

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

        let resolvedDate = resolveDate(day: day?.date, time: time, now: now)

        // Build a title by stripping the tokens we already understood. Location
        // is removed first because its match can contain the time substring.
        var titleSource = text
        for token in [location?.matched, time?.matched, day?.matched].compactMap({ $0 }) {
            titleSource = titleSource.replacingOccurrences(of: token, with: " ")
        }
        let title = Self.cleanTitle(titleSource, fallback: text)

        var confidence = 0.5
        if time != nil { confidence += 0.25 }
        if day != nil { confidence += 0.2 }
        if location != nil { confidence += 0.05 }

        return CapturedEvent(
            title: title,
            date: resolvedDate,
            location: location?.value,
            details: nil,
            confidence: confidence
        )
    }

    // MARK: - Date resolution

    private func resolveDate(day: Date?, time: (hour: Int, minute: Int, matched: String)?, now: Date) -> Date? {
        // Need at least a time or a day to produce a concrete date.
        guard day != nil || time != nil else { return nil }
        let base = day ?? now
        var comps = calendar.dateComponents([.year, .month, .day], from: base)
        comps.hour = time?.hour ?? 9
        comps.minute = time?.minute ?? 0
        comps.second = 0
        return calendar.date(from: comps)
    }

    // MARK: - Time

    static func findTime(in text: String) -> (hour: Int, minute: Int, matched: String)? {
        // 12-hour with am/pm, e.g. "2:30 PM", "6 am", "8p.m."
        if let m = firstMatch(#"\b(\d{1,2})(?::(\d{2}))?\s*([ap])\.?m\.?\b"#, in: text, caseInsensitive: true) {
            var hour = Int(m.group(1) ?? "0") ?? 0
            let minute = Int(m.group(2) ?? "0") ?? 0
            let isPM = (m.group(3) ?? "").lowercased() == "p"
            if hour == 12 { hour = 0 }
            if isPM { hour += 12 }
            if hour <= 23, minute <= 59 { return (hour, minute, m.matched) }
        }
        // 24-hour, e.g. "14:30", "09:00"
        if let m = firstMatch(#"\b([01]?\d|2[0-3]):([0-5]\d)\b"#, in: text, caseInsensitive: false) {
            let hour = Int(m.group(1) ?? "0") ?? 0
            let minute = Int(m.group(2) ?? "0") ?? 0
            return (hour, minute, m.matched)
        }
        return nil
    }

    // MARK: - Day

    private func findDay(in text: String, now: Date) -> (date: Date, matched: String)? {
        let lower = text.lowercased()

        if lower.contains("tomorrow") {
            return (startOfDay(now, offsetDays: 1), matchedSlice("tomorrow", in: text))
        }
        if lower.contains("today") || lower.contains("tonight") {
            let token = lower.contains("today") ? "today" : "tonight"
            return (startOfDay(now, offsetDays: 0), matchedSlice(token, in: text))
        }

        // Weekday names (full and 3-letter), resolved to the next occurrence.
        let weekdays: [(name: String, weekday: Int)] = [
            ("sunday", 1), ("monday", 2), ("tuesday", 3), ("wednesday", 4),
            ("thursday", 5), ("friday", 6), ("saturday", 7),
            ("sun", 1), ("mon", 2), ("tue", 3), ("wed", 4), ("thu", 5), ("fri", 6), ("sat", 7),
        ]
        for entry in weekdays where rangeOfWord(entry.name, in: lower) != nil {
            return (nextDate(weekday: entry.weekday, from: now), matchedSlice(entry.name, in: text))
        }

        // "14 July" / "July 14" / "14 Jul"
        if let m = Self.firstMatch(#"\b(\d{1,2})\s+([A-Za-z]{3,9})\b"#, in: text, caseInsensitive: true),
           let month = Self.monthNumber(m.group(2)) {
            if let d = makeDate(day: Int(m.group(1) ?? "") ?? 0, month: month, now: now) {
                return (d, m.matched)
            }
        }
        if let m = Self.firstMatch(#"\b([A-Za-z]{3,9})\s+(\d{1,2})\b"#, in: text, caseInsensitive: true),
           let month = Self.monthNumber(m.group(1)) {
            if let d = makeDate(day: Int(m.group(2) ?? "") ?? 0, month: month, now: now) {
                return (d, m.matched)
            }
        }
        return nil
    }

    private func startOfDay(_ now: Date, offsetDays: Int) -> Date {
        let start = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: offsetDays, to: start) ?? start
    }

    private func nextDate(weekday: Int, from now: Date) -> Date {
        let today = calendar.startOfDay(for: now)
        let current = calendar.component(.weekday, from: today)
        var delta = weekday - current
        if delta < 0 { delta += 7 }
        return calendar.date(byAdding: .day, value: delta, to: today) ?? today
    }

    private func makeDate(day: Int, month: Int, now: Date) -> Date? {
        guard day >= 1, day <= 31 else { return nil }
        let year = calendar.component(.year, from: now)
        var comps = DateComponents()
        comps.year = year
        comps.month = month
        comps.day = day
        return calendar.date(from: comps)
    }

    // MARK: - Location

    static func findLocation(in text: String) -> (value: String, matched: String)? {
        // "@ Somewhere" or "at Somewhere" where the following text is not a time.
        // We scan every " at " and take the first whose tail isn't a time value.
        let patterns = [#"\bat\s+(.+)$"#, #"@\s*(.+)$"#]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            let ns = text as NSString
            let matches = regex.matches(in: text, range: NSRange(location: 0, length: ns.length))
            for match in matches where match.numberOfRanges > 1 {
                let tail = ns.substring(with: match.range(at: 1)).trimmingCharacters(in: .whitespaces)
                if tail.isEmpty { continue }
                // Skip "at 2:30 PM" style time references.
                if findTime(in: tail) != nil, findTime(in: tail)?.matched.trimmingCharacters(in: .whitespaces) == tail {
                    continue
                }
                // Strip a leading time if the tail is "2:30 PM at Baker St".
                let cleaned = stripLeadingTime(from: tail)
                if cleaned.isEmpty { continue }
                return (cleaned, ns.substring(with: match.range(at: 0)))
            }
        }
        return nil
    }

    private static func stripLeadingTime(from text: String) -> String {
        var result = text
        if let t = findTime(in: text), text.hasPrefix(t.matched) {
            result = String(text.dropFirst(t.matched.count))
            result = result.trimmingCharacters(in: CharacterSet(charactersIn: " ,-")).trimmingCharacters(in: .whitespaces)
            // "2:30 PM at Baker St" → after dropping time we may have "at Baker St"
            if result.lowercased().hasPrefix("at ") { result = String(result.dropFirst(3)) }
        }
        return result.trimmingCharacters(in: .whitespaces)
    }

    // MARK: - Title

    static func cleanTitle(_ source: String, fallback: String) -> String {
        var t = source
        // Remove common leftover connective words and separators.
        for filler in [" on ", " at ", " @ "] {
            t = t.replacingOccurrences(of: filler, with: " ", options: [.caseInsensitive])
        }
        t = t.replacingOccurrences(of: #"\s{2,}"#, with: " ", options: [.regularExpression])
        t = t.trimmingCharacters(in: CharacterSet(charactersIn: " ,-–—:"))
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? fallback.trimmingCharacters(in: .whitespacesAndNewlines) : t
    }

    // MARK: - Month names

    static func monthNumber(_ raw: String?) -> Int? {
        guard let raw = raw?.lowercased() else { return nil }
        let months = ["january", "february", "march", "april", "may", "june",
                      "july", "august", "september", "october", "november", "december"]
        for (i, full) in months.enumerated() {
            if raw == full || raw == String(full.prefix(3)) { return i + 1 }
        }
        return nil
    }

    // MARK: - Regex helper

    struct RegexMatch {
        let matched: String
        private let groups: [String?]
        init(matched: String, groups: [String?]) { self.matched = matched; self.groups = groups }
        func group(_ i: Int) -> String? { i < groups.count ? groups[i] : nil }
    }

    static func firstMatch(_ pattern: String, in text: String, caseInsensitive: Bool) -> RegexMatch? {
        let options: NSRegularExpression.Options = caseInsensitive ? [.caseInsensitive] : []
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else { return nil }
        let ns = text as NSString
        guard let m = regex.firstMatch(in: text, range: NSRange(location: 0, length: ns.length)) else { return nil }
        var groups: [String?] = []
        for i in 0..<m.numberOfRanges {
            let r = m.range(at: i)
            groups.append(r.location == NSNotFound ? nil : ns.substring(with: r))
        }
        return RegexMatch(matched: ns.substring(with: m.range(at: 0)), groups: groups)
    }

    // MARK: - Small string helpers

    private func rangeOfWord(_ word: String, in lower: String) -> Range<String.Index>? {
        guard let r = lower.range(of: word) else { return nil }
        let beforeOK = r.lowerBound == lower.startIndex || !lower[lower.index(before: r.lowerBound)].isLetter
        let afterOK = r.upperBound == lower.endIndex || !lower[r.upperBound].isLetter
        return (beforeOK && afterOK) ? r : nil
    }

    private func matchedSlice(_ token: String, in text: String) -> String {
        if let r = text.range(of: token, options: [.caseInsensitive]) {
            return String(text[r])
        }
        return token
    }
}
