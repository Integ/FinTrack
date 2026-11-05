import Foundation

enum ItemStatus: String, Codable, Sendable {
    case inStock
    case sold
    case writtenOff
}

/// One physical piece of stock bought from a thrift store (收货).
struct Item: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var name: String
    var category: String
    /// Where it was bought, e.g. a thrift store name.
    var source: String
    var purchaseDay: Day
    var cost: Decimal
    /// Asking price on the marketplace, if set.
    var listPrice: Decimal?
    /// Day it was listed for sale; `nil` means not listed yet.
    var listedDay: Day?
    var note: String = ""
    /// The sale this item was sold in.
    var saleID: UUID?
    /// Day it was scrapped / kept for personal use; cost becomes a loss.
    var writtenOffDay: Day?
    /// Items entered together in one restock form share a batch id.
    var batchID: UUID?

    var status: ItemStatus {
        if saleID != nil { return .sold }
        if writtenOffDay != nil { return .writtenOff }
        return .inStock
    }

    func age(on today: Day) -> Int { max(0, purchaseDay.days(until: today)) }
}

/// One sale (卖出). Usually linked to one or more inventory items;
/// imported legacy sales have no items and carry their own name, category and cost.
struct Sale: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var day: Day
    /// Total price received.
    var amount: Decimal
    /// For linked sales: extra costs (parts, shipping, fees).
    /// For unlinked sales: the full cost of goods.
    var extraCost: Decimal = 0
    var channel: String
    /// Item name when the sale is not linked to inventory.
    var title: String = ""
    /// Item category when the sale is not linked to inventory.
    var category: String = ""
    var itemIDs: [UUID] = []
    var note: String = ""

    var isLinked: Bool { !itemIDs.isEmpty }
}

/// Operating expenses: transit passes, platform fees, cleaning supplies…
struct Expense: Identifiable, Codable, Hashable, Sendable {
    var id = UUID()
    var day: Day
    var amount: Decimal
    var category: String
    var note: String = ""
}

struct AppSettings: Codable, Equatable, Sendable {
    /// ISO currency code; empty means follow the system region.
    var currencyCode: String = ""
    /// Items older than this are flagged as slow-moving stock.
    var staleDays: Int = 30
    /// Target return on cost in percent, used for the suggested max buying price.
    var targetROI: Int = 100
}

struct AppData: Codable, Sendable {
    var version: Int = 1
    var items: [Item] = []
    var sales: [Sale] = []
    var expenses: [Expense] = []
    var settings = AppSettings()
}

enum Defaults {
    static let itemCategories = [
        "笔记本电脑", "台式机", "电脑配件", "显示器电视", "键盘鼠标", "电源充电",
        "耳机音箱", "智能家居", "手机平板", "相机摄影", "游戏", "计算器", "小家电", "乐器", "其他",
    ]
    static let expenseCategories = ["交通", "平台费", "维修配件", "清洁耗材", "包装运费", "其他"]
    static let channels = ["Marketplace", "eBay", "线下"]
    static let transportCategory = "交通"
    static let otherCategory = "其他"
}

enum Period: String, CaseIterable, Identifiable, Sendable {
    case week
    case days30
    case thisMonth
    case thisYear
    case all

    var id: String { rawValue }

    var title: String {
        switch self {
        case .week: "7天"
        case .days30: "30天"
        case .thisMonth: "本月"
        case .thisYear: "今年"
        case .all: "全部"
        }
    }

    var longTitle: String {
        switch self {
        case .week: "最近 7 天"
        case .days30: "最近 30 天"
        case .thisMonth: "本月"
        case .thisYear: "今年"
        case .all: "全部时间"
        }
    }

    func start(today: Day) -> Day? {
        switch self {
        case .week: today.adding(days: -6)
        case .days30: today.adding(days: -29)
        case .thisMonth: today.startOfMonth
        case .thisYear: today.startOfYear
        case .all: nil
        }
    }

    func contains(_ day: Day, today: Day) -> Bool {
        guard day <= today else { return self == .all }
        guard let start = start(today: today) else { return true }
        return day >= start
    }
}
