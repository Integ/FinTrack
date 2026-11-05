import Foundation

enum CSVError: LocalizedError, Equatable {
    case empty
    case invalidRow(Int)

    var errorDescription: String? {
        switch self {
        case .empty: "文件中没有可导入的记录。"
        case .invalidRow(let row): "CSV 第 \(row) 行格式不正确。"
        }
    }
}

/// The 6-column ledger format shared with the Web and Android versions:
/// `日期,类型,金额,成本,类别,描述`.
enum LedgerCSV {
    static let header = "日期,类型,金额,成本,类别,描述"

    struct Row: Equatable {
        var day: Day
        var isIncome: Bool
        var amount: Decimal
        var cost: Decimal
        var category: String
        var description: String
    }

    static func parse(_ text: String) throws -> [Row] {
        let records = CSV.records(text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text)
            .filter { !$0.allSatisfy { $0.trimmingCharacters(in: .whitespaces).isEmpty } }
        guard let headers = records.first?.map({ $0.trimmingCharacters(in: .whitespaces).lowercased() }) else {
            throw CSVError.empty
        }
        let hasCost = headers.contains("成本") || headers.contains("cost") || headers.count > 5
        let categoryIndex = hasCost ? 4 : 3
        let descriptionIndex = hasCost ? 5 : 4

        let rows = try records.dropFirst().enumerated().map { offset, columns -> Row in
            let line = offset + 2
            guard columns.count > categoryIndex,
                  let day = Day(columns[0]),
                  let amount = Decimal(userInput: columns[2]) else {
                throw CSVError.invalidRow(line)
            }
            let type = columns[1].trimmingCharacters(in: .whitespaces).lowercased()
            let isIncome: Bool
            switch type {
            case "income", "收入": isIncome = true
            case "expense", "支出": isIncome = false
            default: throw CSVError.invalidRow(line)
            }
            let cost = hasCost ? (Decimal(userInput: columns[3]) ?? 0) : 0
            return Row(
                day: day,
                isIncome: isIncome,
                amount: amount,
                cost: isIncome ? cost : 0,
                category: columns[categoryIndex].trimmingCharacters(in: .whitespacesAndNewlines),
                description: columns.count > descriptionIndex
                    ? columns[descriptionIndex].trimmingCharacters(in: .whitespacesAndNewlines)
                    : ""
            )
        }
        guard !rows.isEmpty else { throw CSVError.empty }
        return rows
    }

    /// Turns ledger rows into sales and expenses. Income rows become unlinked sales whose
    /// item category is guessed from the description; the ledger category becomes the sales channel.
    static func records(from rows: [Row]) -> (sales: [Sale], expenses: [Expense]) {
        var channelNames = CanonicalNames()
        var expenseNames = CanonicalNames()
        var sales: [Sale] = []
        var expenses: [Expense] = []
        for row in rows {
            if row.isIncome {
                sales.append(Sale(
                    day: row.day,
                    amount: row.amount,
                    extraCost: row.cost,
                    channel: channelNames.canonical(row.category),
                    title: row.description,
                    category: CategoryGuesser.guess(row.description)
                ))
            } else {
                expenses.append(Expense(
                    day: row.day,
                    amount: row.amount,
                    category: expenseCategory(row.category, names: &expenseNames),
                    note: row.description
                ))
            }
        }
        return (sales, expenses)
    }

    private static func expenseCategory(_ raw: String, names: inout CanonicalNames) -> String {
        switch raw.lowercased() {
        case "transportation", "transport", "交通", "交通费", "transit": Defaults.transportCategory
        case "platform fees", "平台费用", "平台费": "平台费"
        default: names.canonical(raw.isEmpty ? Defaults.otherCategory : raw)
        }
    }

    static func encode(_ analytics: Analytics) -> String {
        var rows: [(Day, String)] = []
        for sale in analytics.data.sales {
            let lines = Analytics.lines(for: sale, itemsByID: analytics.itemsByID)
            let cost = lines.sum(\.cost)
            let names = lines.map(\.name).joined(separator: "、")
            let description = sale.note.isEmpty ? names : "\(names)（\(sale.note)）"
            rows.append((sale.day, [
                sale.day.description, "income", sale.amount.plainString, cost.plainString,
                CSV.escape(sale.channel), CSV.escape(description),
            ].joined(separator: ",")))
        }
        for expense in analytics.data.expenses {
            rows.append((expense.day, [
                expense.day.description, "expense", expense.amount.plainString, "",
                CSV.escape(expense.category), CSV.escape(expense.note),
            ].joined(separator: ",")))
        }
        for item in analytics.data.items where analytics.status(of: item) == .writtenOff {
            guard let day = item.writtenOffDay else { continue }
            rows.append((day, [
                day.description, "expense", item.cost.plainString, "",
                CSV.escape("报废"), CSV.escape(item.name),
            ].joined(separator: ",")))
        }
        let body = rows.sorted { $0.0 > $1.0 }.map(\.1)
        return ([header] + body).joined(separator: "\n")
    }
}

/// Item-level export for spreadsheets.
enum InventoryCSV {
    static let header = "名称,类别,收货店铺,收货日期,进价,挂牌价,上架日期,状态,售出日期,售价,利润,售出天数,备注"

    static func encode(_ analytics: Analytics) -> String {
        let rows = analytics.data.items.sorted { $0.purchaseDay > $1.purchaseDay }.map { item -> String in
            let line = analytics.lineByItemID[item.id]
            let status: String = switch analytics.status(of: item) {
            case .inStock: "在库"
            case .sold: "已售"
            case .writtenOff: "报废"
            }
            return [
                CSV.escape(item.name),
                CSV.escape(item.category),
                CSV.escape(item.source),
                item.purchaseDay.description,
                item.cost.plainString,
                item.listPrice?.plainString ?? "",
                item.listedDay?.description ?? "",
                status,
                line?.day.description ?? item.writtenOffDay?.description ?? "",
                line?.revenue.plainString ?? "",
                line?.profit.plainString ?? (analytics.status(of: item) == .writtenOff ? (-item.cost).plainString : ""),
                line?.daysToSell.map(String.init) ?? "",
                CSV.escape(item.note),
            ].joined(separator: ",")
        }
        return ([header] + rows).joined(separator: "\n")
    }
}

/// Keeps the first spelling seen for case-insensitive duplicates ("marketplace" → "Marketplace").
struct CanonicalNames {
    private var names: [String: String] = [:]

    mutating func canonical(_ raw: String) -> String {
        let key = raw.lowercased()
        if let existing = names[key] {
            if existing.first?.isLowercase == true, raw.first?.isUppercase == true {
                names[key] = raw
                return raw
            }
            return existing
        }
        let value = raw.first?.isLowercase == true && raw.allSatisfy({ $0.isASCII })
            ? raw.prefix(1).uppercased() + raw.dropFirst()
            : raw
        names[key] = value
        return value
    }
}

enum CSV {
    static func escape(_ value: String) -> String {
        "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    /// RFC 4180-style parser: quoted fields, escaped quotes, CRLF and newlines inside quotes.
    static func records(_ text: String) -> [[String]] {
        var records: [[String]] = []
        var fields: [String] = []
        var current = ""
        var quoted = false
        var iterator = text.makeIterator()
        var pending: Character?

        func next() -> Character? {
            if let value = pending {
                pending = nil
                return value
            }
            return iterator.next()
        }

        while let character = next() {
            if quoted {
                if character == "\"" {
                    if let following = next() {
                        if following == "\"" {
                            current.append("\"")
                        } else {
                            quoted = false
                            pending = following
                        }
                    } else {
                        quoted = false
                    }
                } else {
                    current.append(character)
                }
                continue
            }
            switch character {
            case "\"":
                quoted = true
            case ",":
                fields.append(current)
                current = ""
            case "\n", "\r", "\r\n":
                fields.append(current)
                current = ""
                records.append(fields)
                fields = []
            default:
                current.append(character)
            }
        }
        if !current.isEmpty || !fields.isEmpty {
            fields.append(current)
            records.append(fields)
        }
        return records
    }
}
