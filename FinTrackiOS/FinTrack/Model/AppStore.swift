import Foundation
import Observation

/// Single source of truth. Saves the whole data set as JSON in Application Support after every change.
@MainActor
@Observable
final class AppStore {
    private(set) var data: AppData
    private(set) var saveError: String?
    @ObservationIgnored private let fileURL: URL?

    init(fileURL: URL? = AppStore.defaultFileURL, initial: AppData? = nil) {
        self.fileURL = fileURL
        if let initial {
            data = initial
        } else if let fileURL, let stored = try? Data(contentsOf: fileURL) {
            do {
                data = try AppStore.decoder.decode(AppData.self, from: stored)
            } catch {
                // Never overwrite a file we could not read: keep a copy next to it.
                let copy = fileURL.deletingPathExtension()
                    .appendingPathExtension("unreadable-\(Int(Date().timeIntervalSince1970)).json")
                try? stored.write(to: copy)
                data = AppData()
                saveError = "无法读取已保存的数据，已备份到 \(copy.lastPathComponent)"
            }
        } else {
            data = AppData()
        }
    }

    nonisolated static var defaultFileURL: URL? {
        guard let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return folder.appendingPathComponent("fintrack.json")
    }

    static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    static let decoder = JSONDecoder()

    var settings: AppSettings { data.settings }
    var currencyCode: String { data.settings.currencyCode }

    func analytics(today: Day = .today) -> Analytics {
        Analytics(data: data, today: today)
    }

    func money(_ value: Decimal, signed: Bool = false) -> String {
        Fmt.money(value, code: currencyCode, signed: signed)
    }

    // MARK: - Lookup

    func item(_ id: UUID) -> Item? { data.items.first { $0.id == id } }
    func sale(_ id: UUID) -> Sale? { data.sales.first { $0.id == id } }
    func expense(_ id: UUID) -> Expense? { data.expenses.first { $0.id == id } }

    func items(in sale: Sale) -> [Item] {
        sale.itemIDs.compactMap(item)
    }

    func displayName(of sale: Sale) -> String {
        let names = items(in: sale).map(\.name)
        if names.isEmpty { return sale.title.isEmpty ? "未命名" : sale.title }
        return names.count <= 2 ? names.joined(separator: "、") : "\(names[0]) 等 \(names.count) 件"
    }

    // MARK: - Suggestions

    /// Recently used store names first.
    var recentSources: [String] {
        uniqueRecent(data.items.sorted { $0.purchaseDay > $1.purchaseDay }.map(\.source))
    }

    var recentChannels: [String] {
        let used = uniqueRecent(data.sales.sorted { $0.day > $1.day }.map(\.channel))
        return used + Defaults.channels.filter { !used.contains($0) }
    }

    /// Default categories, most used first, then any custom ones.
    var itemCategories: [String] {
        var counts: [String: Int] = [:]
        for item in data.items { counts[item.category, default: 0] += 1 }
        for sale in data.sales where !sale.isLinked { counts[sale.category, default: 0] += 1 }
        let all = Set(Defaults.itemCategories).union(counts.keys.filter { !$0.isEmpty })
        return all.sorted {
            let left = counts[$0] ?? 0
            let right = counts[$1] ?? 0
            if left != right { return left > right }
            return (Defaults.itemCategories.firstIndex(of: $0) ?? 99) < (Defaults.itemCategories.firstIndex(of: $1) ?? 99)
        }
    }

    var expenseCategories: [String] {
        let used = uniqueRecent(data.expenses.sorted { $0.day > $1.day }.map(\.category))
        return used + Defaults.expenseCategories.filter { !used.contains($0) }
    }

    /// Fares used for transit, most recent first (e.g. a $6 or $12 day pass).
    var recentTransportAmounts: [Decimal] {
        var seen = Set<Decimal>()
        return data.expenses
            .filter { $0.category == Defaults.transportCategory }
            .sorted { $0.day > $1.day }
            .map(\.amount)
            .filter { seen.insert($0).inserted }
            .prefix(3)
            .map { $0 }
    }

    func transport(on day: Day) -> Decimal {
        data.expenses.filter { $0.day == day && $0.category == Defaults.transportCategory }.sum(\.amount)
    }

    private func uniqueRecent(_ values: [String]) -> [String] {
        var seen = Set<String>()
        return values.filter { !$0.isEmpty && seen.insert($0).inserted }
    }

    // MARK: - Items

    func addItems(_ items: [Item], transport: Expense? = nil) {
        data.items.append(contentsOf: items)
        if let transport { data.expenses.append(transport) }
        persist()
    }

    func updateItem(_ item: Item) {
        guard let index = data.items.firstIndex(where: { $0.id == item.id }) else { return }
        data.items[index] = item
        persist()
    }

    /// Deletes items; a sale that loses all its items keeps the price and cost so totals stay right.
    func deleteItems(_ ids: Set<UUID>) {
        let removed = data.items.filter { ids.contains($0.id) }
        for item in removed {
            guard let saleID = item.saleID, let index = data.sales.firstIndex(where: { $0.id == saleID }) else { continue }
            data.sales[index].itemIDs.removeAll { $0 == item.id }
            data.sales[index].extraCost += item.cost
            if data.sales[index].itemIDs.isEmpty {
                data.sales[index].title = item.name
                data.sales[index].category = item.category
            }
        }
        data.items.removeAll { ids.contains($0.id) }
        persist()
    }

    func setListed(_ itemID: UUID, on day: Day?) {
        guard let index = data.items.firstIndex(where: { $0.id == itemID }) else { return }
        data.items[index].listedDay = day
        persist()
    }

    func writeOff(_ itemID: UUID, on day: Day) {
        guard let index = data.items.firstIndex(where: { $0.id == itemID }), data.items[index].saleID == nil else { return }
        data.items[index].writtenOffDay = day
        persist()
    }

    func restore(_ itemID: UUID) {
        guard let index = data.items.firstIndex(where: { $0.id == itemID }) else { return }
        data.items[index].writtenOffDay = nil
        persist()
    }

    // MARK: - Sales

    /// Adds or updates a sale and keeps item links in both directions.
    func saveSale(_ sale: Sale) {
        var sale = sale
        sale.itemIDs = sale.itemIDs.filter { id in data.items.contains { $0.id == id } }
        let linked = Set(sale.itemIDs)
        for index in data.items.indices {
            if data.items[index].saleID == sale.id, !linked.contains(data.items[index].id) {
                data.items[index].saleID = nil
            }
            if linked.contains(data.items[index].id) {
                if let previous = data.items[index].saleID, previous != sale.id {
                    detach(data.items[index].id, from: previous)
                }
                data.items[index].saleID = sale.id
                data.items[index].writtenOffDay = nil
            }
        }
        if let index = data.sales.firstIndex(where: { $0.id == sale.id }) {
            data.sales[index] = sale
        } else {
            data.sales.append(sale)
        }
        persist()
    }

    /// Deletes a sale; its items go back into stock.
    func deleteSale(_ saleID: UUID) {
        for index in data.items.indices where data.items[index].saleID == saleID {
            data.items[index].saleID = nil
        }
        data.sales.removeAll { $0.id == saleID }
        persist()
    }

    private func detach(_ itemID: UUID, from saleID: UUID) {
        guard let index = data.sales.firstIndex(where: { $0.id == saleID }) else { return }
        data.sales[index].itemIDs.removeAll { $0 == itemID }
    }

    // MARK: - Expenses

    func saveExpense(_ expense: Expense) {
        if let index = data.expenses.firstIndex(where: { $0.id == expense.id }) {
            data.expenses[index] = expense
        } else {
            data.expenses.append(expense)
        }
        persist()
    }

    func deleteExpense(_ id: UUID) {
        data.expenses.removeAll { $0.id == id }
        persist()
    }

    // MARK: - Settings & import

    func updateSettings(_ change: (inout AppSettings) -> Void) {
        change(&data.settings)
        persist()
    }

    func replaceAll(with newData: AppData) {
        data = newData
        persist()
    }

    /// Merges a JSON backup by id; existing records win.
    @discardableResult
    func merge(_ other: AppData) -> Int {
        let itemIDs = Set(data.items.map(\.id))
        let saleIDs = Set(data.sales.map(\.id))
        let expenseIDs = Set(data.expenses.map(\.id))
        let items = other.items.filter { !itemIDs.contains($0.id) }
        let sales = other.sales.filter { !saleIDs.contains($0.id) }
        let expenses = other.expenses.filter { !expenseIDs.contains($0.id) }
        data.items += items
        data.sales += sales
        data.expenses += expenses
        persist()
        return items.count + sales.count + expenses.count
    }

    /// Appends ledger rows, skipping rows that already exist (same day, amount, cost and name).
    @discardableResult
    func appendLedger(sales: [Sale], expenses: [Expense]) -> Int {
        let analytics = analytics()
        var existingSales = Set(data.sales.map { sale in
            let lines = Analytics.lines(for: sale, itemsByID: analytics.itemsByID)
            return "\(sale.day)|\(sale.amount)|\(lines.sum(\.cost))|\(displayName(of: sale).lowercased())"
        })
        var existingExpenses = Set(data.expenses.map { "\($0.day)|\($0.amount)|\($0.category)|\($0.note.lowercased())" })
        var added = 0
        for sale in sales where existingSales.insert("\(sale.day)|\(sale.amount)|\(sale.extraCost)|\(sale.title.lowercased())").inserted {
            data.sales.append(sale)
            added += 1
        }
        for expense in expenses where existingExpenses.insert("\(expense.day)|\(expense.amount)|\(expense.category)|\(expense.note.lowercased())").inserted {
            data.expenses.append(expense)
            added += 1
        }
        persist()
        return added
    }

    func eraseAll() {
        data = AppData(settings: data.settings)
        persist()
    }

    func encodedBackup() throws -> Data {
        try AppStore.encoder.encode(data)
    }

    private func persist() {
        guard let fileURL else { return }
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try AppStore.encoder.encode(data).write(to: fileURL, options: [.atomic])
            saveError = nil
        } catch {
            saveError = error.localizedDescription
        }
    }
}
