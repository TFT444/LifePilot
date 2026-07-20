import Foundation

extension EventTextParser {
    func makeDate(day: Int, month: Int, now: Date) -> Date? {
        guard day >= 1, day <= 31 else { return nil }
        let year = calendar.component(.year, from: now)
        return makeDate(day: day, month: month, year: year)
    }

    func findNumericDate(in text: String, now: Date) -> (date: Date, matched: String)? {
        let pattern = #"\b(\d{1,4})[/-](\d{1,2})(?:[/-](\d{1,4}))?\b"#
        guard let match = Self.firstMatch(pattern, in: text, caseInsensitive: false),
              let firstRaw = match.group(1),
              let secondRaw = match.group(2),
              let first = Int(firstRaw),
              let second = Int(secondRaw)
        else {
            return nil
        }

        let day: Int
        let month: Int
        let year: Int
        let yearToken = match.group(3)
        guard firstRaw.count == 4 || yearToken == nil || yearToken?.count == 4 else {
            return nil
        }
        if firstRaw.count == 4, let third = yearToken.flatMap(Int.init) {
            year = first
            month = second
            day = third
        } else if first > 12 {
            day = first
            month = second
            year = yearToken.flatMap(Int.init) ?? calendar.component(.year, from: now)
        } else if second > 12 {
            month = first
            day = second
            year = yearToken.flatMap(Int.init) ?? calendar.component(.year, from: now)
        } else {
            return nil
        }

        guard let date = makeDate(day: day, month: month, year: year) else { return nil }
        return (date, match.matched)
    }

    private func makeDate(day: Int, month: Int, year: Int) -> Date? {
        guard day >= 1, day <= 31, month >= 1, month <= 12 else { return nil }
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        guard let date = calendar.date(from: components) else { return nil }
        let resolved = calendar.dateComponents([.year, .month, .day], from: date)
        guard resolved.year == year, resolved.month == month, resolved.day == day else { return nil }
        return date
    }
}
