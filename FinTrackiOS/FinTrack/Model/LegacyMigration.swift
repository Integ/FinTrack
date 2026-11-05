import Foundation

/// Reads the data of the previous FinTrack iOS app (`com.vicecity.fintrack` up to 2026.07),
/// which kept a flat transaction list in `Application Support/FinTrack/transactions.json`
/// and the currency in `UserDefaults["currencyCode"]`. The old file is never modified.
enum LegacyMigration {
    struct Transaction: Decodable {
        var id: UUID?
        var day: Day
        var type: String
        var amount: Decimal
        var cost: Decimal?
        var category: String
        var note: String?

        private enum CodingKeys: String, CodingKey {
            case id, date, type, amount, cost, category, note
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? container.decodeIfPresent(String.self, forKey: .id)).flatMap(UUID.init(uuidString:))
            type = try container.decode(String.self, forKey: .type)
            amount = try container.decode(Decimal.self, forKey: .amount)
            cost = try container.decodeIfPresent(Decimal.self, forKey: .cost)
            category = try container.decodeIfPresent(String.self, forKey: .category) ?? ""
            note = try container.decodeIfPresent(String.self, forKey: .note)
            if let text = try? container.decode(String.self, forKey: .date) {
                guard let value = LegacyMigration.day(from: text) else {
                    throw DecodingError.dataCorruptedError(forKey: .date, in: container, debugDescription: "Bad date \(text)")
                }
                day = value
            } else {
                // Foundation's default Date encoding: seconds since 2001-01-01.
                day = Day(Date(timeIntervalSinceReferenceDate: try container.decode(Double.self, forKey: .date)))
            }
        }
    }

    nonisolated static var defaultURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("FinTrack/transactions.json")
    }

    static func load(from url: URL, defaults: UserDefaults?) throws -> AppData? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        let transactions = try JSONDecoder().decode([Transaction].self, from: Data(contentsOf: url))
        return convert(transactions, currencyCode: defaults?.string(forKey: "currencyCode") ?? "")
    }

    /// Same mapping as importing the old CSV, but keeps the original record ids.
    static func convert(_ transactions: [Transaction], currencyCode: String) -> AppData {
        let rows = transactions.map { transaction in
            let isIncome = transaction.type.lowercased() != "expense"
            return LedgerCSV.Row(
                day: transaction.day,
                isIncome: isIncome,
                amount: transaction.amount,
                cost: isIncome ? (transaction.cost ?? 0) : 0,
                category: transaction.category,
                description: transaction.note ?? ""
            )
        }
        var (sales, expenses) = LedgerCSV.records(from: rows)
        let incomeIDs = zip(transactions, rows).filter { $0.1.isIncome }.map { $0.0.id }
        let expenseIDs = zip(transactions, rows).filter { !$0.1.isIncome }.map { $0.0.id }
        for index in sales.indices { if let id = incomeIDs[index] { sales[index].id = id } }
        for index in expenses.indices { if let id = expenseIDs[index] { expenses[index].id = id } }

        var settings = AppSettings()
        settings.currencyCode = currencyCode
        return AppData(sales: sales, expenses: expenses, settings: settings)
    }

    static func day(from text: String) -> Day? {
        let formatter = ISO8601DateFormatter()
        if let date = formatter.date(from: text) { return Day(date) }
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: text) { return Day(date) }
        return Day(String(text.prefix(10)))
    }
}
