import XCTest
@testable import FinTrack

final class DayTests: XCTestCase {
    func testParsingAndArithmetic() throws {
        let day = try XCTUnwrap(Day("2026-10-30"))
        XCTAssertEqual(day.description, "2026-10-30")
        XCTAssertEqual(Day("2026/3/5")?.description, "2026-03-05")
        XCTAssertNil(Day("not a date"))
        XCTAssertEqual(day.adding(days: 3).description, "2026-11-02")
        XCTAssertEqual(day.days(until: Day(year: 2026, month: 11, day: 4)), 5)
        XCTAssertEqual(Day(year: 2026, month: 3, day: 31).adding(months: -1).description, "2026-02-28")
    }

    func testJSONRoundTripKeepsDecimalsExact() throws {
        let item = Item(name: "Magic Keyboard", category: "键盘鼠标", source: "VV", purchaseDay: Day(year: 2026, month: 1, day: 2), cost: Decimal(string: "12.34")!)
        let data = AppData(items: [item], sales: [Sale(day: item.purchaseDay, amount: Decimal(string: "0.1")!, channel: "Marketplace", itemIDs: [item.id])])
        let decoded = try JSONDecoder().decode(AppData.self, from: JSONEncoder().encode(data))
        XCTAssertEqual(decoded.items.first?.cost, Decimal(string: "12.34"))
        XCTAssertEqual(decoded.sales.first?.amount, Decimal(string: "0.1"))
        XCTAssertEqual(decoded.items.first?.purchaseDay, item.purchaseDay)
    }
}

final class CategoryGuesserTests: XCTestCase {
    func testCommonItems() {
        let cases: [(String, String)] = [
            ("Dyson V10", "小家电"),
            ("戴森头", "小家电"),
            ("Apple Magic keyboard", "键盘鼠标"),
            ("罗技G502鼠标", "键盘鼠标"),
            ("MagSafe 2 电源", "电源充电"),
            ("Apple Watch 充电线", "电源充电"),
            ("HP laptop", "笔记本电脑"),
            ("MacBook Air 2015", "笔记本电脑"),
            ("TI-84 plus SE", "计算器"),
            ("2 hp 10bii plus", "计算器"),
            ("Bose QC25", "耳机音箱"),
            ("Sony 降噪耳机", "耳机音箱"),
            ("Amazon echo dot 音箱", "智能家居"),
            ("Apple TV 4K", "智能家居"),
            ("LG 24 寸显示器", "显示器电视"),
            ("Sumsang 40 inch TV", "显示器电视"),
            ("Canon AE-1", "相机摄影"),
            ("PS4 光盘 FIFA 20", "游戏"),
            ("ddr3 8G", "电脑配件"),
            ("3.5寸软盘 12张", "电脑配件"),
            ("Dell 7020 PC", "台式机"),
            ("iPad 1代", "手机平板"),
            ("Fender guitar", "乐器"),
            ("魔方", "其他"),
        ]
        for (name, expected) in cases {
            XCTAssertEqual(CategoryGuesser.guess(name), expected, name)
        }
    }
}

final class LedgerCSVTests: XCTestCase {
    func testParsesExportedBackupFormat() throws {
        let text = "\u{FEFF}日期,类型,金额,成本,类别,描述\n2026-11-04,expense,6,,\"Transportation\",\"daypass\"\n2026-11-04,income,200,100,\"Marketplace\",\"罗技G25\"\n2026-11-03,income,50,15,\"marketplace\",\"Magic \"\"Keyboard\"\", 2\"\n"
        let rows = try LedgerCSV.parse(text)
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows[2].description, "Magic \"Keyboard\", 2")
        XCTAssertEqual(rows[1].cost, 100)

        let records = LedgerCSV.records(from: rows)
        XCTAssertEqual(records.expenses.first?.category, "交通")
        XCTAssertEqual(records.sales.map(\.channel), ["Marketplace", "Marketplace"])
        XCTAssertEqual(records.sales.map(\.category), ["游戏", "键盘鼠标"])
        XCTAssertEqual(records.sales.first?.extraCost, 100)
        XCTAssertFalse(records.sales.first!.isLinked)
    }

    func testReportsInvalidRow() {
        XCTAssertThrowsError(try LedgerCSV.parse("日期,类型,金额,成本,类别,描述\n2026-11-04,gift,6,,a,b")) { error in
            XCTAssertEqual(error as? CSVError, .invalidRow(2))
        }
    }

    func testExportRoundTrip() throws {
        let item = Item(name: "Dyson V8", category: "小家电", source: "VV", purchaseDay: Day(year: 2026, month: 10, day: 1), cost: 30)
        let sale = Sale(day: Day(year: 2026, month: 10, day: 9), amount: 100, extraCost: 5, channel: "Marketplace", itemIDs: [item.id])
        let data = AppData(items: [item], sales: [sale], expenses: [Expense(day: sale.day, amount: 6, category: "交通")])
        let csv = LedgerCSV.encode(Analytics(data: data, today: sale.day))
        let rows = try LedgerCSV.parse(csv)
        XCTAssertEqual(rows.count, 2)
        let income = try XCTUnwrap(rows.first { $0.isIncome })
        XCTAssertEqual(income.amount, 100)
        XCTAssertEqual(income.cost, 35)
        XCTAssertEqual(income.description, "Dyson V8")
    }
}

final class AnalyticsTests: XCTestCase {
    private let today = Day(year: 2026, month: 11, day: 4)

    private func item(_ name: String, _ category: String, cost: Decimal, daysAgo: Int, source: String = "VV") -> Item {
        Item(name: name, category: category, source: source, purchaseDay: today.adding(days: -daysAgo), cost: cost)
    }

    func testBundleSaleAllocatesPriceByCost() {
        let keyboard = item("Magic Keyboard", "键盘鼠标", cost: 15, daysAgo: 10)
        let mouse = item("Magic Mouse", "键盘鼠标", cost: 5, daysAgo: 4)
        let sale = Sale(day: today, amount: 80, extraCost: 4, channel: "Marketplace", itemIDs: [keyboard.id, mouse.id])
        let analytics = Analytics(data: AppData(items: [keyboard, mouse], sales: [sale]), today: today)

        let lines = analytics.lines
        XCTAssertEqual(lines.count, 2)
        XCTAssertEqual(lines.sum(\.revenue), 80)
        XCTAssertEqual(lines.sum(\.extraCost), 4)
        let keyboardLine = analytics.lineByItemID[keyboard.id]!
        XCTAssertEqual(keyboardLine.revenue, 60)
        XCTAssertEqual(keyboardLine.extraCost, 3)
        XCTAssertEqual(keyboardLine.profit, 42)
        XCTAssertEqual(keyboardLine.daysToSell, 10)
        XCTAssertEqual(analytics.lineByItemID[mouse.id]?.daysToSell, 4)
    }

    func testCategoryStatsAndDaysToSell() {
        var items: [Item] = []
        var sales: [Sale] = []
        for (index, days) in [3, 5, 10].enumerated() {
            let sold = item("Dyson V\(index + 6)", "小家电", cost: 30, daysAgo: 20)
            items.append(sold)
            sales.append(Sale(day: sold.purchaseDay.adding(days: days), amount: 90, channel: "Marketplace", itemIDs: [sold.id]))
        }
        items.append(item("Dyson V10", "小家电", cost: 40, daysAgo: 2))
        // A legacy sale counts toward money but not days.
        sales.append(Sale(day: today, amount: 50, extraCost: 20, channel: "Marketplace", title: "戴森头", category: "小家电"))

        let analytics = Analytics(data: AppData(items: items, sales: sales), today: today)
        let stats = analytics.categoryStat("小家电")
        XCTAssertEqual(stats.soldCount, 4)
        XCTAssertEqual(stats.revenue, 320)
        XCTAssertEqual(stats.cost, 110)
        XCTAssertEqual(stats.avgDays ?? 0, 6, accuracy: 0.001)
        XCTAssertEqual(stats.medianDays, 5)
        XCTAssertEqual(stats.boughtCount, 4)
        XCTAssertEqual(stats.soldFromBought, 3)
        XCTAssertEqual(stats.inStockCount, 1)
        XCTAssertEqual(stats.sellThrough ?? 0, 0.75, accuracy: 0.001)
        XCTAssertEqual(stats.verdict(targetROI: 100), .buyMore)
        // Average price 80, target 100% → buy at most 40.
        XCTAssertEqual(stats.maxBuyPrice(targetROI: 100), 40)
    }

    func testProfitAndLossIncludesExpensesAndWriteOffs() {
        let sold = item("ThinkPad", "笔记本电脑", cost: 60, daysAgo: 20)
        var broken = item("HP laptop", "笔记本电脑", cost: 25, daysAgo: 15)
        broken.writtenOffDay = today.adding(days: -1)
        let stock = item("LG 显示器", "显示器电视", cost: 20, daysAgo: 40)
        let sale = Sale(day: today.adding(days: -2), amount: 180, channel: "Marketplace", itemIDs: [sold.id])
        let expenses = [
            Expense(day: today.adding(days: -20), amount: 6, category: "交通"),
            Expense(day: today.adding(days: -3), amount: 12, category: "交通"),
        ]
        let analytics = Analytics(data: AppData(items: [sold, broken, stock], sales: [sale], expenses: expenses), today: today)

        let month = analytics.pnl(.days30)
        XCTAssertEqual(month.revenue, 180)
        XCTAssertEqual(month.cogs, 60)
        XCTAssertEqual(month.grossProfit, 120)
        XCTAssertEqual(month.expenses, 18)
        XCTAssertEqual(month.transport, 18)
        XCTAssertEqual(month.writeOffs, 25)
        XCTAssertEqual(month.netProfit, 77)
        XCTAssertEqual(month.purchaseSpend, 85)
        XCTAssertEqual(month.cashFlow, 180 - 85 - 18)

        let week = analytics.pnl(.week)
        XCTAssertEqual(week.netProfit, 120 - 12 - 25)

        let inventory = analytics.inventory()
        XCTAssertEqual(inventory.count, 1)
        XCTAssertEqual(inventory.staleCount, 1)
        XCTAssertEqual(inventory.totalCost, 20)
    }

    func testHaulPayback() {
        let a = item("Magic Keyboard", "键盘鼠标", cost: 15, daysAgo: 10)
        let b = item("Apple 电源", "电源充电", cost: 5, daysAgo: 10)
        let sale = Sale(day: today, amount: 45, channel: "Marketplace", itemIDs: [a.id])
        let fare = Expense(day: a.purchaseDay, amount: 6, category: "交通")
        let analytics = Analytics(data: AppData(items: [a, b], sales: [sale], expenses: [fare]), today: today)

        let haul = try! XCTUnwrap(analytics.hauls().first)
        XCTAssertEqual(haul.items.count, 2)
        XCTAssertEqual(haul.outlay, 26)
        XCTAssertEqual(haul.proceeds, 45)
        XCTAssertEqual(haul.balance, 19)
        XCTAssertEqual(haul.inStockCount, 1)
        XCTAssertGreaterThan(haul.payback, 1)
    }

    func testPriceCheckMatchesAllTokens() {
        let sales = [
            Sale(day: today, amount: 50, extraCost: 15, channel: "M", title: "Apple Magic keyboard", category: "键盘鼠标"),
            Sale(day: today, amount: 40, extraCost: 15, channel: "M", title: "Magic Keyboard键盘", category: "键盘鼠标"),
            Sale(day: today, amount: 30, extraCost: 10, channel: "M", title: "Magic Mouse", category: "键盘鼠标"),
        ]
        let analytics = Analytics(data: AppData(sales: sales), today: today)
        let check = try! XCTUnwrap(analytics.priceCheck("magic keyboard"))
        XCTAssertEqual(check.count, 2)
        XCTAssertEqual(check.avgPrice, 45)
        XCTAssertNil(analytics.priceCheck("dyson"))
    }
}

@MainActor
final class AppStoreTests: XCTestCase {
    func testSellingAndDeletingSaleMovesItemsInAndOutOfStock() throws {
        let store = AppStore(fileURL: nil, initial: AppData())
        let item = Item(name: "TI-84", category: "计算器", source: "VV", purchaseDay: .today, cost: 10)
        store.addItems([item])
        let sale = Sale(day: .today, amount: 60, channel: "Marketplace", itemIDs: [item.id])
        store.saveSale(sale)
        XCTAssertEqual(store.item(item.id)?.status, .sold)

        // Re-linking the item to another sale detaches it from the first.
        let second = Sale(day: .today, amount: 55, channel: "Marketplace", itemIDs: [item.id])
        store.saveSale(second)
        XCTAssertEqual(store.item(item.id)?.saleID, second.id)
        XCTAssertEqual(store.sale(sale.id)?.itemIDs, [])

        store.deleteSale(second.id)
        XCTAssertEqual(store.item(item.id)?.status, .inStock)
    }

    func testDeletingSoldItemKeepsSaleTotals() {
        let store = AppStore(fileURL: nil, initial: AppData())
        let item = Item(name: "Dyson V8", category: "小家电", source: "VV", purchaseDay: .today, cost: 35)
        store.addItems([item])
        let sale = Sale(day: .today, amount: 110, channel: "Marketplace", itemIDs: [item.id])
        store.saveSale(sale)
        store.deleteItems([item.id])

        let kept = try! XCTUnwrap(store.sale(sale.id))
        XCTAssertFalse(kept.isLinked)
        XCTAssertEqual(kept.extraCost, 35)
        XCTAssertEqual(kept.title, "Dyson V8")
        XCTAssertEqual(store.analytics().pnl(.all).grossProfit, 75)
    }

    func testAppendLedgerSkipsDuplicates() {
        let store = AppStore(fileURL: nil, initial: AppData())
        let rows = [LedgerCSV.Row(day: .today, isIncome: true, amount: 50, cost: 15, category: "Marketplace", description: "Magic Keyboard")]
        let records = LedgerCSV.records(from: rows)
        XCTAssertEqual(store.appendLedger(sales: records.sales, expenses: records.expenses), 1)
        let again = LedgerCSV.records(from: rows)
        XCTAssertEqual(store.appendLedger(sales: again.sales, expenses: again.expenses), 0)
    }

    func testPersistsToDisk() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("fintrack-test-\(UUID()).json")
        defer { try? FileManager.default.removeItem(at: url) }
        let store = AppStore(fileURL: url)
        store.addItems([Item(name: "iPod", category: "手机平板", source: "", purchaseDay: .today, cost: 3)])
        let reloaded = AppStore(fileURL: url)
        XCTAssertEqual(reloaded.data.items.map(\.name), ["iPod"])
    }
}
