import Foundation
import LifePilotCore

extension EventTextParser {
    static func captureAmbiguities(
        in text: String,
        day: Date?,
        time: ParsedTime?,
        resolvedDate: Date?,
        recurrence: ParsedRecurrence?,
        calendar: Calendar,
        now: Date
    ) -> Set<CaptureAmbiguity> {
        var result: Set<CaptureAmbiguity> = []
        let ambiguousNumericDate = hasAmbiguousNumericDate(in: text)
        let containsDateToken = hasDateToken(in: text)

        if ambiguousNumericDate {
            result.insert(.ambiguousNumericDate)
        } else if containsDateToken, day == nil {
            result.insert(.invalidDate)
        }
        if time != nil, day == nil, recurrence == nil, !containsDateToken {
            result.insert(.missingDate)
        }
        if day != nil, time == nil {
            result.insert(.missingTime)
        }
        if let resolvedDate, resolvedDate < now, recurrence == nil {
            result.insert(.pastDate)
        }
        if isDaylightSavingAdjustment(
            requestedTime: time,
            resolvedDate: resolvedDate,
            calendar: calendar
        ) {
            result.insert(.daylightSavingAdjustment)
        }
        return result
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
        let named = #"\b(?:\d{1,2}\s+[A-Za-z]{3,9}|[A-Za-z]{3,9}\s+\d{1,2})\b"#
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
