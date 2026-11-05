#if DEBUG
import Foundation

/// Launch arguments for simulator testing and screenshots. Debug builds only.
///
///     -resetData YES               start from an empty data set
///     -importLedger /path/x.csv    append a ledger CSV
///     -demoInventory YES           add ~2 months of sample hauls and linked sales
///     -tab analytics               open a tab (home, inventory, records, analytics, settings)
///     -records hauls               records segment (sales, hauls, expenses)
///     -category 键盘鼠标           push a category detail in Analytics
///     -sheet restock               open a sheet (restock, sale, expense, priceCheck)
@MainActor
enum DebugLaunch {
    static func apply(to store: AppStore) {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: "resetData") {
            store.replaceAll(with: AppData())
        }
        if let path = defaults.string(forKey: "importLedger"),
           let text = try? String(contentsOfFile: path, encoding: .utf8),
           let rows = try? LedgerCSV.parse(text) {
            let records = LedgerCSV.records(from: rows)
            store.appendLedger(sales: records.sales, expenses: records.expenses)
        }
        if defaults.bool(forKey: "demoInventory") {
            addDemoInventory(to: store)
        }
    }

    static func route(_ router: Router) {
        let defaults = UserDefaults.standard
        switch defaults.string(forKey: "tab") {
        case "inventory": router.tab = .inventory
        case "records": router.tab = .records
        case "analytics": router.tab = .analytics
        case "settings": router.tab = .settings
        default: break
        }
        if let segment = defaults.string(forKey: "records").flatMap(RecordsSegment.init(rawValue:)) {
            router.recordsSegment = segment
        }
        if let category = defaults.string(forKey: "category") {
            router.open(.category(category))
        }
        switch defaults.string(forKey: "sheet") {
        case "restock": router.sheet = .restock
        case "sale": router.sheet = .newSale([])
        case "expense": router.sheet = .expense(nil)
        case "priceCheck": router.sheet = .priceCheck
        default: break
        }
    }

    private struct Generator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state >> 33
        }
        mutating func int(_ range: ClosedRange<Int>) -> Int {
            range.lowerBound + Int(next() % UInt64(range.count))
        }
    }

    private static func addDemoInventory(to store: AppStore) {
        let catalog: [(String, String, Decimal, Decimal, ClosedRange<Int>)] = [
            ("Magic Keyboard", "键盘鼠标", 15, 45, 2...12),
            ("罗技 MX Master 鼠标", "键盘鼠标", 10, 40, 3...15),
            ("Dyson V8", "小家电", 35, 110, 3...20),
            ("Dyson V7", "小家电", 30, 90, 5...25),
            ("ThinkPad T480", "笔记本电脑", 60, 180, 10...45),
            ("HP laptop", "笔记本电脑", 30, 80, 15...60),
            ("Apple 61W 电源", "电源充电", 5, 30, 2...10),
            ("MagSafe 2 电源", "电源充电", 5, 25, 3...14),
            ("TI-84 Plus", "计算器", 10, 60, 2...9),
            ("Bose QC35 II", "耳机音箱", 25, 90, 4...20),
            ("LG 24 寸显示器", "显示器电视", 20, 60, 10...40),
            ("Amazon Echo Dot", "智能家居", 5, 20, 15...70),
            ("Canon 18-55 镜头", "相机摄影", 15, 50, 5...30),
            ("PS4 游戏盘", "游戏", 3, 10, 20...80),
        ]
        let stores = ["Value Village", "Salvation Army", "Goodwill"]
        var random = Generator(state: 42)
        let today = Day.today
        var day = today.adding(days: -75)
        var items: [Item] = []
        var sales: [(Day, Item, Decimal)] = []
        var expenses: [Expense] = []

        while day < today {
            let source = stores[random.int(0...stores.count - 1)]
            expenses.append(Expense(day: day, amount: 6, category: Defaults.transportCategory, note: "收货 · \(source)"))
            for _ in 0..<random.int(2...5) {
                let entry = catalog[random.int(0...catalog.count - 1)]
                let cost = entry.2 + Decimal(random.int(-2...4))
                let item = Item(
                    name: entry.0,
                    category: entry.1,
                    source: source,
                    purchaseDay: day,
                    cost: max(2, cost),
                    listPrice: entry.3,
                    listedDay: day.adding(days: random.int(0...3))
                )
                let days = random.int(entry.4)
                if day.adding(days: days) <= today {
                    sales.append((day.adding(days: days), item, entry.3 + Decimal(random.int(-10...5))))
                }
                items.append(item)
            }
            day = day.adding(days: random.int(2...5))
        }
        store.addItems(items)
        for expense in expenses { store.saveExpense(expense) }
        for (saleDay, item, price) in sales {
            store.saveSale(Sale(day: saleDay, amount: max(5, price), channel: "Marketplace", itemIDs: [item.id]))
        }
        if let unlisted = items.last {
            store.setListed(unlisted.id, on: nil)
        }
    }
}
#endif
