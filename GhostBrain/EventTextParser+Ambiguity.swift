import Foundation
import LifePilotCore

extension EventTextParser {
    struct AmbiguityContext {
        let day: Date?
        let time: ParsedTime?
        let resolvedDate: Date?
        let recurrence: ParsedRecurrence?
        let calendar: Calendar
        let now: Date
    }

    static func captureAmbiguities(
        in text: String,
        context: AmbiguityContext
    ) -> Set<CaptureAmbiguity> {
        var result: Set<CaptureAmbiguity> = []
        let ambiguousNumericDate = hasAmbiguousNumericDate(in: text)
        let containsDateToken = hasDateToken(in: text)

        if ambiguousNumericDate {
            result.insert(.ambiguousNumericDate)
        } else if containsDateToken, context.day == nil {
            result.insert(.invalidDate)
        }
        let needsDate = context.time != nil && context.day == nil
            && context.recurrence == nil && !containsDateToken
        if needsDate {
            result.insert(.missingDate)
        }
        if context.day != nil, context.time == nil {
            result.insert(.missingTime)
        }
        let isPast = context.resolvedDate.map { $0 < context.now } ?? false
        if isPast, context.recurrence == nil {
            result.insert(.pastDate)
        }
        if isDaylightSavingAdjustment(
            requestedTime: context.time,
            resolvedDate: context.resolvedDate,
            calendar: context.calendar
        ) {
            result.insert(.daylightSavingAdjustment)
        }
        return result
    }

    static func captureConfidence(
        foundTime: Bool,
        foundDay: Bool,
        foundLocation: Bool
    ) -> Double {
        0.5
            + (foundTime ? 0.25 : 0)
            + (foundDay ? 0.2 : 0)
            + (foundLocation ? 0.05 : 0)
    }

    private static func hasAmbiguousNumericDate(in text: String) -> Bool {
        let pattern = #"\b(\d{1,2})[/-](\d{1,2})(?:[/-]\d{4})?\b"#
        guard let match = firstMatch(pattern, in: text, caseInsensitive: false),
              let first = match.group(1).flatMap(Int.init),
              let second = match.group(2).flatMap(Int.init)
        else {
            return false
        }
        return (1 ... 12).contains(first) && (1 ... 12).contains(second)
    }

    private static func hasDateToken(in text: String) -> Bool {
        let month = "(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|"
            + "Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|Oct(?:ober)?|"
            + "Nov(?:ember)?|Dec(?:ember)?)"
        let named = "\\b(?:\\d{1,2}\\s+\(month)|\(month)\\s+\\d{1,2})\\b"
        let numeric = #"\b\d{1,4}[/-]\d{1,2}(?:[/-]\d{4})?\b"#
        return firstMatch(named, in: text, caseInsensitive: true) != nil
            || firstMatch(numeric, in: text, caseInsensitive: false) != nil
    }

    private static func isDaylightSavingAdjustment(
        requestedTime: ParsedTime?,
        resolvedDate: Date?,
        calendar: Calendar
    ) -> Bool {
        guard let requestedTime else { return false }
        guard let resolvedDate else { return true }
        let resolved = calendar.dateComponents([.hour, .minute], from: resolvedDate)
        return resolved.hour != requestedTime.hour || resolved.minute != requestedTime.minute
    }
}
