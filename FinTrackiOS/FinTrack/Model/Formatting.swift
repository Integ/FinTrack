import Foundation

extension Decimal {
    var double: Double { NSDecimalNumber(decimal: self).doubleValue }

    /// Plain string without grouping, e.g. `12.5`.
    var plainString: String { NSDecimalNumber(decimal: self).stringValue }

    var isWhole: Bool {
        var source = self
        var rounded = Decimal()
        NSDecimalRound(&rounded, &source, 0, .plain)
        return rounded == self
    }

    func rounded(scale: Int = 2) -> Decimal {
        var source = self
        var result = Decimal()
        NSDecimalRound(&result, &source, scale, .bankers)
        return result
    }

    /// Parses user input such as `12`, `12.5`, `12,5`, `$12`.
    init?(userInput: String) {
        let cleaned = userInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
            .filter { $0.isNumber || $0 == "." || $0 == "-" }
        guard !cleaned.isEmpty, let value = Decimal(string: cleaned, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        self = value
    }
}

extension Sequence {
    func sum(_ value: (Element) -> Decimal) -> Decimal {
        reduce(Decimal.zero) { $0 + value($1) }
    }
}

enum Fmt {
    static let chinese = Locale(identifier: "zh_Hans")

    static func resolvedCurrency(_ code: String) -> String {
        code.isEmpty ? (Locale.current.currency?.identifier ?? "USD") : code
    }

    static func money(_ value: Decimal, code: String, signed: Bool = false) -> String {
        let style = Decimal.FormatStyle.Currency(code: resolvedCurrency(code), locale: .current)
            .precision(.fractionLength(value.isWhole ? 0 : 2))
            .sign(strategy: signed ? .always(showZero: false) : .automatic)
        return value.formatted(style)
    }

    static func percent(_ value: Double?, signed: Bool = false) -> String {
        guard let value, value.isFinite else { return "—" }
        let style = FloatingPointFormatStyle<Double>.Percent(locale: chinese)
            .precision(.fractionLength(0))
            .sign(strategy: signed ? .always(includingZero: false) : .automatic)
        return value.formatted(style)
    }

    static func days(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "—" }
        if value < 10, value.rounded() != value {
            return String(format: "%.1f 天", value)
        }
        return "\(Int(value.rounded())) 天"
    }

    static func day(_ day: Day, includeYear: Bool = false) -> String {
        let style = includeYear
            ? Date.FormatStyle(locale: chinese).year().month(.defaultDigits).day()
            : Date.FormatStyle(locale: chinese).month(.defaultDigits).day()
        return day.date.formatted(style)
    }

    static func dayWithWeekday(_ day: Day) -> String {
        let today = Day.today
        if day == today { return "今天" }
        if day == today.adding(days: -1) { return "昨天" }
        let style = Date.FormatStyle(locale: chinese).month(.defaultDigits).day().weekday(.abbreviated)
        let text = day.date.formatted(style)
        return day.year == today.year ? text : "\(day.year)年\(text)"
    }

    static func month(_ month: Month) -> String {
        month.year == Day.today.year ? "\(month.month)月" : "\(month.year)年\(month.month)月"
    }
}
