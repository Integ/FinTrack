import Foundation

/// A calendar day without time or time zone, stored as `yyyy-MM-dd`.
/// Keeps purchase/sale dates stable when the phone changes time zone and matches the CSV format.
struct Day: Hashable, Comparable, Codable, Sendable, CustomStringConvertible {
    let year: Int
    let month: Int
    let day: Int

    private static let utc: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }()

    init(year: Int, month: Int, day: Int) {
        self.year = year
        self.month = month
        self.day = day
    }

    init(_ date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        self.init(year: parts.year ?? 1970, month: parts.month ?? 1, day: parts.day ?? 1)
    }

    /// Accepts `2026-11-04`, `2026/11/4` and `2026.11.04`.
    init?(_ string: String) {
        let parts = string
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(whereSeparator: { $0 == "-" || $0 == "/" || $0 == "." })
            .compactMap { Int($0) }
        guard parts.count == 3, (1...12).contains(parts[1]), (1...31).contains(parts[2]), parts[0] > 1900 else {
            return nil
        }
        self.init(year: parts[0], month: parts[1], day: parts[2])
    }

    static var today: Day { Day(Date()) }

    var description: String { String(format: "%04d-%02d-%02d", year, month, day) }

    /// Local midnight, for use with `DatePicker` and formatters.
    var date: Date {
        Calendar.current.date(from: DateComponents(year: year, month: month, day: day)) ?? Date()
    }

    private var utcDate: Date {
        Day.utc.date(from: DateComponents(year: year, month: month, day: day)) ?? Date(timeIntervalSince1970: 0)
    }

    /// Whole days from `self` to `other` (positive when `other` is later).
    func days(until other: Day) -> Int {
        Day.utc.dateComponents([.day], from: utcDate, to: other.utcDate).day ?? 0
    }

    func adding(days count: Int) -> Day {
        Day(Day.utc.date(byAdding: .day, value: count, to: utcDate) ?? utcDate, calendar: Day.utc)
    }

    func adding(months count: Int) -> Day {
        Day(Day.utc.date(byAdding: .month, value: count, to: utcDate) ?? utcDate, calendar: Day.utc)
    }

    var startOfMonth: Day { Day(year: year, month: month, day: 1) }
    var startOfYear: Day { Day(year: year, month: 1, day: 1) }

    static func < (lhs: Day, rhs: Day) -> Bool {
        (lhs.year, lhs.month, lhs.day) < (rhs.year, rhs.month, rhs.day)
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = Day(raw) else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid day \(raw)")
        }
        self = value
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(description)
    }
}

/// A month bucket used by trend charts.
struct Month: Hashable, Comparable, Sendable {
    let year: Int
    let month: Int

    init(_ day: Day) {
        year = day.year
        month = day.month
    }

    var firstDay: Day { Day(year: year, month: month, day: 1) }

    static func < (lhs: Month, rhs: Month) -> Bool {
        (lhs.year, lhs.month) < (rhs.year, rhs.month)
    }
}
