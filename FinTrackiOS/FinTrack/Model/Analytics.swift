import Foundation

/// One sold item. A sale of several items is split into lines, with the price
/// and extra costs allocated by each item's purchase cost.
struct SaleLine: Identifiable, Hashable, Sendable {
    let id: String
    let saleID: UUID
    let itemID: UUID?
    let day: Day
    let name: String
    let category: String
    let source: String?
    let channel: String
    /// Allocated share of the sale price.
    let revenue: Decimal
    /// Purchase cost (or the manually entered cost for unlinked sales).
    let itemCost: Decimal
    /// Allocated extra cost (parts, shipping, fees) for linked sales.
    let extraCost: Decimal
    let purchaseDay: Day?

    var cost: Decimal { itemCost + extraCost }
    var profit: Decimal { revenue - cost }
    /// Money that came back for this item after extras.
    var netProceeds: Decimal { revenue - extraCost }
    var daysToSell: Int? { purchaseDay.map { max(0, $0.days(until: day)) } }
    var roi: Double? { cost > 0 ? profit.double / cost.double : nil }
    /// Cash paid at sale time: extras, or the whole cost for legacy sales whose purchase was never recorded.
    var cashCostAtSale: Decimal { itemID == nil ? itemCost : extraCost }
}

struct PnL: Sendable {
    var revenue: Decimal = 0
    var cogs: Decimal = 0
    var expenses: Decimal = 0
    var transport: Decimal = 0
    var writeOffs: Decimal = 0
    var purchaseSpend: Decimal = 0
    var cashCostAtSale: Decimal = 0
    var soldCount = 0
    var purchasedCount = 0
    var daysSamples: [Int] = []

    var grossProfit: Decimal { revenue - cogs }
    var netProfit: Decimal { grossProfit - expenses - writeOffs }
    var grossMargin: Double? { revenue > 0 ? grossProfit.double / revenue.double : nil }
    var netMargin: Double? { revenue > 0 ? netProfit.double / revenue.double : nil }
    var roi: Double? { cogs > 0 ? grossProfit.double / cogs.double : nil }
    /// Money in minus money out in the period, counting stock purchases when they happen.
    var cashFlow: Decimal { revenue - purchaseSpend - cashCostAtSale - expenses }
    var avgProfitPerItem: Decimal? { soldCount > 0 ? grossProfit / Decimal(soldCount) : nil }
    var avgDays: Double? { Stats.mean(daysSamples) }
}

enum Verdict: String, Sendable {
    case buyMore = "多收"
    case slow = "卖得慢"
    case thin = "利润薄"
    case stuck = "压货"

    var explanation: String {
        switch self {
        case .buyMore: "回报率达到目标、卖得也快，遇到可以多收。"
        case .slow: "平均超过 45 天才卖掉，资金周转慢。"
        case .thin: "回报率不到 50%，收货时要压低进价。"
        case .stuck: "收的货有六成以上还没卖出去，先清库存再收。"
        }
    }
}

/// Aggregated numbers for one category / store / price band / channel.
struct GroupStats: Identifiable, Sendable {
    let key: String
    var id: String { key }
    var soldCount = 0
    var revenue: Decimal = 0
    var cost: Decimal = 0
    var daysSamples: [Int] = []
    var boughtCount = 0
    var boughtSpend: Decimal = 0
    var soldFromBought = 0
    var writtenOffFromBought = 0
    var inStockCount = 0
    var inStockCost: Decimal = 0

    var profit: Decimal { revenue - cost }
    var avgPrice: Decimal? { soldCount > 0 ? revenue / Decimal(soldCount) : nil }
    var avgCost: Decimal? { soldCount > 0 ? cost / Decimal(soldCount) : nil }
    var avgProfit: Decimal? { soldCount > 0 ? profit / Decimal(soldCount) : nil }
    var roi: Double? { cost > 0 ? profit.double / cost.double : nil }
    var avgDays: Double? { Stats.mean(daysSamples) }
    var medianDays: Double? { Stats.median(daysSamples) }
    /// Of the items bought in the period, the share already sold.
    var sellThrough: Double? { boughtCount > 0 ? Double(soldFromBought) / Double(boughtCount) : nil }

    /// Highest buying price that still reaches the target return, based on the average selling price.
    func maxBuyPrice(targetROI: Int) -> Decimal? {
        guard soldCount >= 2, let avgPrice else { return nil }
        let value = avgPrice / (1 + Decimal(targetROI) / 100)
        var source = value
        var floored = Decimal()
        NSDecimalRound(&floored, &source, 0, .down)
        return floored
    }

    func verdict(targetROI: Int) -> Verdict? {
        if boughtCount >= 5, let sellThrough, sellThrough < 0.4, inStockCount >= 3 { return .stuck }
        if daysSamples.count >= 3, let avgDays, avgDays > 45 { return .slow }
        guard soldCount >= 3, let roi else { return nil }
        if roi < 0.5 { return .thin }
        let fastEnough = avgDays.map { $0 <= 21 } ?? true
        if roi >= Double(targetROI) / 100, fastEnough { return .buyMore }
        return nil
    }
}

struct SpeedBucket: Identifiable, Sendable {
    let label: String
    let count: Int
    var id: String { label }
}

struct MonthStat: Identifiable, Sendable {
    let month: Month
    var revenue: Decimal = 0
    var netProfit: Decimal = 0
    var soldCount = 0
    var purchasedCount = 0
    var purchaseSpend: Decimal = 0
    var id: Month { month }
}

struct AgeBucket: Identifiable, Sendable {
    let label: String
    let count: Int
    let cost: Decimal
    var id: String { label }
}

struct InventorySummary: Sendable {
    var items: [Item] = []
    var totalCost: Decimal = 0
    var expectedRevenue: Decimal = 0
    var pricedCount = 0
    var unlistedCount = 0
    var staleCount = 0
    var staleCost: Decimal = 0
    var buckets: [AgeBucket] = []
    var avgAge: Double?

    var count: Int { items.count }
}

/// Everything bought on one day (收货), and how much of it has come back.
struct Haul: Identifiable, Sendable {
    let day: Day
    var items: [Item]
    var transport: Decimal
    var soldCount: Int
    var writtenOffCount: Int
    var proceeds: Decimal
    var soldProfit: Decimal

    var id: Day { day }
    var spend: Decimal { items.sum(\.cost) }
    var outlay: Decimal { spend + transport }
    var inStockCount: Int { items.count - soldCount - writtenOffCount }
    var payback: Double { outlay > 0 ? proceeds.double / outlay.double : 0 }
    var balance: Decimal { proceeds - outlay }
    var sources: [String] {
        var seen = Set<String>()
        return items.map(\.source).filter { !$0.isEmpty && seen.insert($0).inserted }
    }
}

struct PriceCheck: Sendable {
    let query: String
    let lines: [SaleLine]
    let inStock: [Item]

    var count: Int { lines.count }
    var avgPrice: Decimal? { count > 0 ? lines.sum(\.revenue) / Decimal(count) : nil }
    var minPrice: Decimal? { lines.map(\.revenue).min() }
    var maxPrice: Decimal? { lines.map(\.revenue).max() }
    var avgCost: Decimal? { count > 0 ? lines.sum(\.cost) / Decimal(count) : nil }
    var avgProfit: Decimal? { count > 0 ? lines.sum(\.profit) / Decimal(count) : nil }
    var avgDays: Double? { Stats.mean(lines.compactMap(\.daysToSell)) }
    var roi: Double? {
        let cost = lines.sum(\.cost)
        return cost > 0 ? lines.sum(\.profit).double / cost.double : nil
    }
}

enum InventoryFilter: String, CaseIterable, Identifiable, Sendable {
    case all
    case unlisted
    case listed
    case stale

    var id: String { rawValue }

    var title: String {
        switch self {
        case .all: "全部"
        case .unlisted: "待上架"
        case .listed: "在售"
        case .stale: "压货"
        }
    }
}

struct Insight: Identifiable, Sendable {
    enum Kind: Sendable { case warning, positive, info }

    enum Action: Hashable, Sendable {
        case inventory(InventoryFilter)
        case category(String)
        case hauls
    }

    let id: String
    let kind: Kind
    let icon: String
    let title: String
    let detail: String
    let action: Action?
}

enum Stats {
    static func mean(_ values: [Int]) -> Double? {
        values.isEmpty ? nil : Double(values.reduce(0, +)) / Double(values.count)
    }

    static func median(_ values: [Int]) -> Double? {
        guard !values.isEmpty else { return nil }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        return sorted.count.isMultiple(of: 2)
            ? Double(sorted[middle - 1] + sorted[middle]) / 2
            : Double(sorted[middle])
    }
}

/// Read-only analysis of the whole data set. Cheap enough to rebuild on every render
/// for a one-person business (thousands of records).
struct Analytics {
    let data: AppData
    let today: Day
    /// All sold lines, newest first.
    let lines: [SaleLine]
    let itemsByID: [UUID: Item]
    let lineByItemID: [UUID: SaleLine]
    let categoryAvgDays: [String: (avg: Double, samples: Int)]

    var settings: AppSettings { data.settings }

    init(data: AppData, today: Day = .today) {
        self.data = data
        self.today = today
        let itemsByID = Dictionary(data.items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        self.itemsByID = itemsByID

        var lines: [SaleLine] = []
        lines.reserveCapacity(data.sales.count)
        for sale in data.sales {
            lines.append(contentsOf: Analytics.lines(for: sale, itemsByID: itemsByID))
        }
        lines.sort { $0.day != $1.day ? $0.day > $1.day : $0.id < $1.id }
        self.lines = lines

        var lineByItemID: [UUID: SaleLine] = [:]
        var daysByCategory: [String: [Int]] = [:]
        for line in lines {
            if let itemID = line.itemID { lineByItemID[itemID] = line }
            if let days = line.daysToSell { daysByCategory[line.category, default: []].append(days) }
        }
        self.lineByItemID = lineByItemID
        self.categoryAvgDays = daysByCategory.compactMapValues { samples in
            Stats.mean(samples).map { (avg: $0, samples: samples.count) }
        }
    }

    static func lines(for sale: Sale, itemsByID: [UUID: Item]) -> [SaleLine] {
        let items = sale.itemIDs.compactMap { itemsByID[$0] }
        guard !items.isEmpty else {
            return [SaleLine(
                id: sale.id.uuidString,
                saleID: sale.id,
                itemID: nil,
                day: sale.day,
                name: sale.title.isEmpty ? "未命名" : sale.title,
                category: sale.category.isEmpty ? Defaults.otherCategory : sale.category,
                source: nil,
                channel: sale.channel,
                revenue: sale.amount,
                itemCost: sale.extraCost,
                extraCost: 0,
                purchaseDay: nil
            )]
        }

        let totalCost = items.sum(\.cost)
        var remainingRevenue = sale.amount
        var remainingExtra = sale.extraCost
        return items.enumerated().map { index, item in
            let weight = totalCost > 0 ? item.cost / totalCost : 1 / Decimal(items.count)
            let isLast = index == items.count - 1
            let revenue = isLast ? remainingRevenue : (sale.amount * weight).rounded(scale: 2)
            let extra = isLast ? remainingExtra : (sale.extraCost * weight).rounded(scale: 2)
            remainingRevenue -= revenue
            remainingExtra -= extra
            return SaleLine(
                id: "\(sale.id.uuidString)-\(item.id.uuidString)",
                saleID: sale.id,
                itemID: item.id,
                day: sale.day,
                name: item.name,
                category: item.category,
                source: item.source.isEmpty ? nil : item.source,
                channel: sale.channel,
                revenue: revenue,
                itemCost: item.cost,
                extraCost: extra,
                purchaseDay: item.purchaseDay
            )
        }
    }

    // MARK: - Profit & loss

    func lines(in period: Period) -> [SaleLine] {
        lines.filter { period.contains($0.day, today: today) }
    }

    func pnl(_ period: Period) -> PnL {
        var result = PnL()
        for line in lines where period.contains(line.day, today: today) {
            result.revenue += line.revenue
            result.cogs += line.cost
            result.cashCostAtSale += line.cashCostAtSale
            result.soldCount += 1
            if let days = line.daysToSell { result.daysSamples.append(days) }
        }
        for expense in data.expenses where period.contains(expense.day, today: today) {
            result.expenses += expense.amount
            if expense.category == Defaults.transportCategory { result.transport += expense.amount }
        }
        for item in data.items {
            if period.contains(item.purchaseDay, today: today) {
                result.purchaseSpend += item.cost
                result.purchasedCount += 1
            }
            if let day = item.writtenOffDay, lineByItemID[item.id] == nil, period.contains(day, today: today) {
                result.writeOffs += item.cost
            }
        }
        return result
    }

    func monthly(count: Int = 12) -> [MonthStat] {
        let first = Month(today.startOfMonth.adding(months: -(count - 1)))
        var months: [Month: MonthStat] = [:]
        var cursor = first.firstDay
        for _ in 0..<count {
            months[Month(cursor)] = MonthStat(month: Month(cursor))
            cursor = cursor.adding(months: 1)
        }
        for line in lines {
            let month = Month(line.day)
            guard months[month] != nil else { continue }
            months[month]?.revenue += line.revenue
            months[month]?.netProfit += line.profit
            months[month]?.soldCount += 1
        }
        for expense in data.expenses {
            months[Month(expense.day)]?.netProfit -= expense.amount
        }
        for item in data.items {
            let month = Month(item.purchaseDay)
            if months[month] != nil {
                months[month]?.purchasedCount += 1
                months[month]?.purchaseSpend += item.cost
            }
            if let day = item.writtenOffDay, lineByItemID[item.id] == nil {
                months[Month(day)]?.netProfit -= item.cost
            }
        }
        return months.values.sorted { $0.month < $1.month }
    }

    // MARK: - Groups

    func groupStats(
        _ period: Period,
        lineKey: (SaleLine) -> String?,
        itemKey: (Item) -> String?
    ) -> [GroupStats] {
        var groups: [String: GroupStats] = [:]
        for line in lines where period.contains(line.day, today: today) {
            guard let key = lineKey(line) else { continue }
            groups[key, default: GroupStats(key: key)].soldCount += 1
            groups[key]?.revenue += line.revenue
            groups[key]?.cost += line.cost
            if let days = line.daysToSell { groups[key]?.daysSamples.append(days) }
        }
        for item in data.items {
            guard let key = itemKey(item) else { continue }
            if period.contains(item.purchaseDay, today: today) {
                groups[key, default: GroupStats(key: key)].boughtCount += 1
                groups[key]?.boughtSpend += item.cost
                switch status(of: item) {
                case .sold: groups[key]?.soldFromBought += 1
                case .writtenOff: groups[key]?.writtenOffFromBought += 1
                case .inStock: break
                }
            }
            if status(of: item) == .inStock {
                groups[key, default: GroupStats(key: key)].inStockCount += 1
                groups[key]?.inStockCost += item.cost
            }
        }
        return groups.values.sorted {
            $0.profit != $1.profit ? $0.profit > $1.profit : $0.soldCount > $1.soldCount
        }
    }

    func categoryStats(_ period: Period) -> [GroupStats] {
        groupStats(period, lineKey: { $0.category }, itemKey: { $0.category })
    }

    func categoryStat(_ category: String, period: Period = .all) -> GroupStats {
        groupStats(
            period,
            lineKey: { $0.category == category ? category : nil },
            itemKey: { $0.category == category ? category : nil }
        ).first ?? GroupStats(key: category)
    }

    func sourceStats(_ period: Period) -> [GroupStats] {
        groupStats(period, lineKey: { $0.itemID == nil ? nil : ($0.source ?? "未填写店铺") }, itemKey: { $0.source.isEmpty ? "未填写店铺" : $0.source })
            .filter { $0.boughtCount > 0 || $0.soldCount > 0 }
    }

    func channelStats(_ period: Period) -> [GroupStats] {
        groupStats(period, lineKey: { $0.channel.isEmpty ? "未填写" : $0.channel }, itemKey: { _ in nil })
    }

    static let costBands: [(label: String, upper: Decimal?)] = [
        ("进价 ≤5", 5), ("进价 5–15", 15), ("进价 15–40", 40), ("进价 40 以上", nil),
    ]

    static func costBand(_ cost: Decimal) -> String {
        for band in costBands {
            guard let upper = band.upper else { return band.label }
            if cost <= upper { return band.label }
        }
        return costBands.last!.label
    }

    func costBandStats(_ period: Period) -> [GroupStats] {
        let stats = groupStats(period, lineKey: { Analytics.costBand($0.itemCost) }, itemKey: { Analytics.costBand($0.cost) })
        let order = Analytics.costBands.map(\.label)
        return stats.sorted { (order.firstIndex(of: $0.key) ?? 0) < (order.firstIndex(of: $1.key) ?? 0) }
    }

    func speedDistribution(_ period: Period) -> [SpeedBucket] {
        let days = lines(in: period).compactMap(\.daysToSell)
        return [
            SpeedBucket(label: "7天内", count: days.filter { $0 <= 7 }.count),
            SpeedBucket(label: "8–30天", count: days.filter { (8...30).contains($0) }.count),
            SpeedBucket(label: "31–60天", count: days.filter { (31...60).contains($0) }.count),
            SpeedBucket(label: "60天以上", count: days.filter { $0 > 60 }.count),
        ]
    }

    // MARK: - Inventory

    /// Sold-ness comes from the sales themselves, so analysis stays right even if an item's own link is stale.
    func status(of item: Item) -> ItemStatus {
        if lineByItemID[item.id] != nil { return .sold }
        if item.writtenOffDay != nil { return .writtenOff }
        return .inStock
    }

    var inStockItems: [Item] {
        data.items.filter { status(of: $0) == .inStock }
    }

    var usesListing: Bool { data.items.contains { $0.listedDay != nil } }

    func isStale(_ item: Item) -> Bool {
        status(of: item) == .inStock && item.age(on: today) >= settings.staleDays
    }

    /// Typical days to sell for the item's category, when the item is already well past it.
    func slowerThanUsual(_ item: Item) -> Double? {
        guard status(of: item) == .inStock,
              let stats = categoryAvgDays[item.category], stats.samples >= 3 else { return nil }
        let threshold = max(stats.avg * 1.5, 7)
        return Double(item.age(on: today)) > threshold ? stats.avg : nil
    }

    func inventory() -> InventorySummary {
        let items = inStockItems.sorted { $0.purchaseDay < $1.purchaseDay }
        var summary = InventorySummary(items: items)
        summary.totalCost = items.sum(\.cost)
        let priced = items.compactMap(\.listPrice)
        summary.pricedCount = priced.count
        summary.expectedRevenue = priced.reduce(0, +)
        summary.unlistedCount = items.filter { $0.listedDay == nil }.count
        let stale = items.filter(isStale)
        summary.staleCount = stale.count
        summary.staleCost = stale.sum(\.cost)
        let ages = items.map { $0.age(on: today) }
        summary.avgAge = Stats.mean(ages)
        let ranges: [(String, ClosedRange<Int>)] = [
            ("7天内", 0...7), ("8–30天", 8...30), ("31–60天", 31...60), ("60天以上", 61...Int.max),
        ]
        summary.buckets = ranges.map { label, range in
            let matching = items.filter { range.contains($0.age(on: today)) }
            return AgeBucket(label: label, count: matching.count, cost: matching.sum(\.cost))
        }
        return summary
    }

    func matches(_ item: Item, filter: InventoryFilter) -> Bool {
        switch filter {
        case .all: true
        case .unlisted: item.listedDay == nil
        case .listed: item.listedDay != nil
        case .stale: isStale(item)
        }
    }

    // MARK: - Hauls

    func hauls() -> [Haul] {
        let byDay = Dictionary(grouping: data.items, by: \.purchaseDay)
        var transportByDay: [Day: Decimal] = [:]
        for expense in data.expenses where expense.category == Defaults.transportCategory {
            transportByDay[expense.day, default: 0] += expense.amount
        }
        return byDay.map { day, items in
            var soldCount = 0
            var writtenOff = 0
            var proceeds: Decimal = 0
            var profit: Decimal = 0
            for item in items {
                if let line = lineByItemID[item.id] {
                    soldCount += 1
                    proceeds += line.netProceeds
                    profit += line.profit
                } else if status(of: item) == .writtenOff {
                    writtenOff += 1
                }
            }
            return Haul(
                day: day,
                items: items.sorted { $0.name < $1.name },
                transport: transportByDay[day] ?? 0,
                soldCount: soldCount,
                writtenOffCount: writtenOff,
                proceeds: proceeds,
                soldProfit: profit
            )
        }
        .sorted { $0.day > $1.day }
    }

    // MARK: - Price check

    static func searchTokens(_ query: String) -> [String] {
        query.lowercased()
            .split(whereSeparator: { $0.isWhitespace || ",，/、+".contains($0) })
            .map(String.init)
    }

    static func matches(_ name: String, tokens: [String]) -> Bool {
        guard !tokens.isEmpty else { return false }
        let haystack = name.lowercased()
        return tokens.allSatisfy(haystack.contains)
    }

    func priceCheck(_ query: String) -> PriceCheck? {
        let tokens = Analytics.searchTokens(query)
        guard !tokens.isEmpty else { return nil }
        let matched = lines.filter { Analytics.matches($0.name, tokens: tokens) }
        let stock = inStockItems.filter { Analytics.matches($0.name, tokens: tokens) }
        guard !matched.isEmpty || !stock.isEmpty else { return nil }
        return PriceCheck(query: query, lines: matched, inStock: stock)
    }

    // MARK: - Insights

    func insights() -> [Insight] {
        var result: [Insight] = []
        let inventory = inventory()

        if data.items.isEmpty {
            result.append(Insight(
                id: "start",
                kind: .info,
                icon: "lightbulb",
                title: "从收货开始记录",
                detail: "收货时记下进价，卖出时选中这件货，就能算出每类货多久卖掉、哪家店最值得去、哪些货在压钱。",
                action: nil
            ))
        }

        if inventory.staleCount > 0 {
            result.append(Insight(
                id: "stale",
                kind: .warning,
                icon: "hourglass",
                title: "\(inventory.staleCount) 件货压了 \(settings.staleDays) 天以上",
                detail: "占用 \(money(inventory.staleCost))。降价 10–20% 或打包出售，把钱换回来再去收货。",
                action: .inventory(.stale)
            ))
        }

        if usesListing {
            let waiting = inventory.items.filter { $0.listedDay == nil && $0.age(on: today) >= 2 }
            if !waiting.isEmpty {
                result.append(Insight(
                    id: "unlisted",
                    kind: .info,
                    icon: "camera",
                    title: "\(waiting.count) 件货还没上架",
                    detail: "收回来两天以上还没挂出去，占用 \(money(waiting.sum(\.cost)))。早上架早回款。",
                    action: .inventory(.unlisted)
                ))
            }
        }

        if let haul = hauls().first {
            let soldText = "\(haul.items.count) 件花了 \(money(haul.outlay))\(haul.transport > 0 ? "（含交通 \(money(haul.transport))）" : "")，已卖 \(haul.soldCount) 件，回款 \(money(haul.proceeds))。"
            if haul.payback >= 1 {
                result.append(Insight(
                    id: "haul",
                    kind: .positive,
                    icon: "checkmark.seal",
                    title: "\(Fmt.day(haul.day)) 的收货已回本，多赚 \(money(haul.balance))",
                    detail: soldText,
                    action: .hauls
                ))
            } else {
                result.append(Insight(
                    id: "haul",
                    kind: .info,
                    icon: "shippingbox",
                    title: "\(Fmt.day(haul.day)) 的收货已回本 \(Fmt.percent(haul.payback))",
                    detail: soldText,
                    action: .hauls
                ))
            }
        }

        // Prefer the last half year so the advice follows current conditions.
        let cutoff = today.adding(days: -180)
        let useRecent = lines.filter { $0.day >= cutoff }.count >= 10
        let categories = groupStats(
            .all,
            lineKey: { useRecent && $0.day < cutoff ? nil : $0.category },
            itemKey: { $0.category }
        ).filter { $0.soldCount >= 3 }
        let scope = useRecent ? "近半年" : "目前"

        if let best = categories.max(by: { $0.profit < $1.profit }), best.profit > 0 {
            result.append(Insight(
                id: "best",
                kind: .positive,
                icon: "star",
                title: "\(best.key) 是你\(scope)最赚钱的品类",
                detail: "卖出 \(best.soldCount) 件，共赚 \(money(best.profit))，平均每件 \(money(best.avgProfit ?? 0))，回报率 \(Fmt.percent(best.roi))\(best.avgDays.map { "，平均 \(Fmt.days($0)) 卖出" } ?? "")。",
                action: .category(best.key)
            ))
        }

        if let fastest = categories.filter({ $0.daysSamples.count >= 3 }).min(by: { ($0.avgDays ?? .infinity) < ($1.avgDays ?? .infinity) }),
           let days = fastest.avgDays {
            result.append(Insight(
                id: "fastest",
                kind: .positive,
                icon: "hare",
                title: "\(fastest.key) 卖得最快，平均 \(Fmt.days(days))",
                detail: "周转快的货回款快，资金能多转几圈。\(fastest.maxBuyPrice(targetROI: settings.targetROI).map { "进价控制在 \(money($0)) 以内，回报率能保持在 \(settings.targetROI)%。" } ?? "")",
                action: .category(fastest.key)
            ))
        }

        let problem = categories
            .filter { [.slow, .thin, .stuck].contains($0.verdict(targetROI: settings.targetROI)) }
            .max(by: { $0.soldCount + $0.inStockCount < $1.soldCount + $1.inStockCount })
        if let problem, let verdict = problem.verdict(targetROI: settings.targetROI) {
            let price = problem.maxBuyPrice(targetROI: settings.targetROI).map { "收货时进价最好不超过 \(money($0))。" } ?? ""
            result.append(Insight(
                id: "problem",
                kind: .warning,
                icon: "exclamationmark.triangle",
                title: "\(problem.key)：\(verdict.rawValue)",
                detail: "\(verdict.explanation)\(price)",
                action: .category(problem.key)
            ))
        }

        let month = pnl(.days30)
        if month.transport > 0, month.grossProfit > 0 {
            let ratio = month.transport.double / month.grossProfit.double
            if ratio >= 0.15 {
                result.append(Insight(
                    id: "transport",
                    kind: .warning,
                    icon: "tram",
                    title: "交通费吃掉了 \(Fmt.percent(ratio)) 的毛利",
                    detail: "最近 30 天交通 \(money(month.transport))，毛利 \(money(month.grossProfit))。一趟多跑几家店、多收几件更划算。",
                    action: nil
                ))
            }
        }

        return result
    }

    func money(_ value: Decimal) -> String {
        Fmt.money(value, code: settings.currencyCode)
    }
}
