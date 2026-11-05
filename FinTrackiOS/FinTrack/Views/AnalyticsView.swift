import Charts
import SwiftUI

struct AnalyticsView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var period: Period = .all

    var body: some View {
        @Bindable var router = router
        let analytics = store.analytics()
        let pnl = analytics.pnl(period)
        let categories = analytics.categoryStats(period).filter { $0.soldCount > 0 || $0.inStockCount > 0 }
        let target = analytics.settings.targetROI

        NavigationStack(path: $router.analyticsPath) {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("时间范围", selection: $period) {
                        ForEach(Period.allCases) { Text($0.title).tag($0) }
                    }
                    .pickerStyle(.segmented)

                    ProfitStatement(pnl: pnl, period: period)
                    MonthlyCharts(months: analytics.monthly())

                    VStack(spacing: 10) {
                        SectionTitle(title: "品类表现", subtitle: "哪类货最赚钱、卖得最快。点进去看详情和收货参考价。")
                        if categories.isEmpty {
                            EmptyStateView(icon: "square.grid.2x2", title: "还没有数据", message: "卖出几件货后这里会显示每类货的表现。")
                                .card()
                        } else {
                            VStack(spacing: 0) {
                                ForEach(Array(categories.enumerated()), id: \.element.id) { index, stats in
                                    NavigationLink(value: stats.key) {
                                        CategoryRow(stats: stats, targetROI: target)
                                    }
                                    .buttonStyle(.plain)
                                    if index < categories.count - 1 { Divider() }
                                }
                            }
                            .card(padding: 14)
                        }
                    }

                    SpeedSection(buckets: analytics.speedDistribution(period), pnl: pnl)

                    GroupTable(
                        title: "进价区间",
                        subtitle: "便宜的小件和贵的大件，哪种更划算",
                        rows: analytics.costBandStats(period).filter { $0.soldCount > 0 }
                    )

                    GroupTable(
                        title: "收货店铺",
                        subtitle: "哪家店收的货最赚钱、卖得最快",
                        rows: analytics.sourceStats(period),
                        showBought: true
                    )

                    let channels = analytics.channelStats(period)
                    if channels.count > 1 {
                        GroupTable(title: "销售渠道", subtitle: nil, rows: channels)
                    }

                    Text("售出天数只统计从库存选中卖出的货（有收货日期）；导入的旧记录只参与金额统计。回报率 = 利润 ÷ 成本。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("分析")
            .navigationDestination(for: String.self) { CategoryDetailView(category: $0) }
            .navigationDestination(for: UUID.self) { ItemDetailView(itemID: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AddMenu() }
            }
        }
    }
}

private struct ProfitStatement: View {
    @Environment(AppStore.self) private var store
    let pnl: PnL
    let period: Period

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(period.longTitle)利润表").font(.headline)
            row("销售额", pnl.revenue)
            row("售出货品成本", -pnl.cogs)
            Divider()
            row("毛利", pnl.grossProfit, bold: true, caption: "毛利率 \(Fmt.percent(pnl.grossMargin)) · 回报率 \(Fmt.percent(pnl.roi))")
            row("经营支出", -pnl.expenses, caption: pnl.transport > 0 ? "其中交通 \(store.money(pnl.transport))" : nil)
            if pnl.writeOffs > 0 {
                row("报废损失", -pnl.writeOffs)
            }
            Divider()
            row("净利润", pnl.netProfit, bold: true, tint: Palette.profit(pnl.netProfit), caption: "净利率 \(Fmt.percent(pnl.netMargin))")
            if pnl.purchasedCount > 0 {
                Divider()
                HStack(alignment: .top) {
                    Image(systemName: "banknote").foregroundStyle(.secondary)
                    Text("这段时间收货 \(pnl.purchasedCount) 件花了 \(store.money(pnl.purchaseSpend))，现金净流入 \(store.money(pnl.cashFlow, signed: true))。"
                         + (pnl.netProfit > 0 && pnl.cashFlow < pnl.netProfit * Decimal(0.7) ? "现金明显少于利润，说明钱压在库存里了。" : ""))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .card()
    }

    private func row(_ title: String, _ value: Decimal, bold: Bool = false, tint: Color = .primary, caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).fontWeight(bold ? .semibold : .regular)
                Spacer()
                Text(store.money(value))
                    .monospacedDigit()
                    .fontWeight(bold ? .bold : .regular)
                    .foregroundStyle(tint)
            }
            if let caption {
                Text(caption).font(.caption).foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
    }
}

private struct MonthlyCharts: View {
    @Environment(AppStore.self) private var store
    let months: [MonthStat]

    var body: some View {
        let hasPurchases = months.contains { $0.purchasedCount > 0 }
        VStack(alignment: .leading, spacing: 12) {
            Text("近 12 个月净利润").font(.headline)
            Chart(months) { month in
                BarMark(
                    x: .value("月份", month.month.firstDay.date, unit: .month),
                    y: .value("净利润", month.netProfit.double)
                )
                .foregroundStyle(month.netProfit >= 0 ? Color.green.gradient : Color.red.gradient)
                .cornerRadius(3)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .month, count: 2)) {
                    AxisValueLabel(format: .dateTime.month(.defaultDigits))
                }
            }
            .frame(height: 160)

            if hasPurchases {
                Text("收货 vs 卖出（件）").font(.headline).padding(.top, 6)
                Chart {
                    ForEach(months) { month in
                        BarMark(
                            x: .value("月份", month.month.firstDay.date, unit: .month),
                            y: .value("件数", month.purchasedCount)
                        )
                        .foregroundStyle(by: .value("类型", "收货"))
                        .position(by: .value("类型", "收货"))
                        BarMark(
                            x: .value("月份", month.month.firstDay.date, unit: .month),
                            y: .value("件数", month.soldCount)
                        )
                        .foregroundStyle(by: .value("类型", "卖出"))
                        .position(by: .value("类型", "卖出"))
                    }
                }
                .chartForegroundStyleScale(["收货": Color.orange, "卖出": Color.green])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) {
                        AxisValueLabel(format: .dateTime.month(.defaultDigits))
                    }
                }
                .frame(height: 140)
                let recent = months.suffix(3)
                let bought = recent.reduce(0) { $0 + $1.purchasedCount }
                let sold = recent.reduce(0) { $0 + $1.soldCount }
                Text(bought > sold + sold / 5
                     ? "近 3 个月收了 \(bought) 件、卖了 \(sold) 件，收得比卖得快，库存和压的钱在变多。"
                     : "近 3 个月收了 \(bought) 件、卖了 \(sold) 件，库存周转正常。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .environment(\.locale, Fmt.chinese)
        .card()
    }
}

private struct CategoryRow: View {
    @Environment(AppStore.self) private var store
    let stats: GroupStats
    let targetROI: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(stats.key).font(.subheadline.weight(.semibold))
                if let verdict = stats.verdict(targetROI: targetROI) {
                    Tag(text: verdict.rawValue, color: verdict.color)
                }
                Spacer()
                Text(store.money(stats.profit))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.profit(stats.profit))
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            HStack(spacing: 8) {
                metric("卖出", "\(stats.soldCount)件")
                metric("每件赚", stats.avgProfit.map { store.money($0) } ?? "—")
                metric("回报率", Fmt.percent(stats.roi))
                metric("平均卖出", Fmt.days(stats.avgDays))
            }
            if stats.inStockCount > 0 || stats.maxBuyPrice(targetROI: targetROI) != nil {
                HStack(spacing: 10) {
                    if stats.inStockCount > 0 {
                        Text("在库 \(stats.inStockCount) 件")
                    }
                    if let price = stats.maxBuyPrice(targetROI: targetROI) {
                        Text("建议进价 ≤ \(store.money(price))")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.medium)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SpeedSection: View {
    let buckets: [SpeedBucket]
    let pnl: PnL

    var body: some View {
        let total = buckets.reduce(0) { $0 + $1.count }
        if total > 0 {
            VStack(alignment: .leading, spacing: 10) {
                Text("多久卖掉").font(.headline)
                Text("\(total) 件有收货日期，平均 \(Fmt.days(pnl.avgDays))，中位 \(Fmt.days(Stats.median(pnl.daysSamples)))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Chart(buckets) { bucket in
                    BarMark(x: .value("件数", bucket.count), y: .value("用时", bucket.label))
                        .foregroundStyle(Color.accentColor.gradient)
                        .annotation(position: .trailing) {
                            Text("\(bucket.count)").font(.caption2).foregroundStyle(.secondary)
                        }
                }
                .chartXAxis(.hidden)
                .frame(height: 130)
            }
            .card()
        }
    }
}

/// Compact table for stores, price bands and channels.
private struct GroupTable: View {
    @Environment(AppStore.self) private var store
    let title: String
    let subtitle: String?
    let rows: [GroupStats]
    var showBought = false

    var body: some View {
        if !rows.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                SectionTitle(title: title, subtitle: subtitle)
                VStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, stats in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(stats.key).font(.subheadline.weight(.semibold)).lineLimit(1)
                                Spacer()
                                Text(store.money(stats.profit))
                                    .font(.subheadline.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.profit(stats.profit))
                            }
                            HStack(spacing: 8) {
                                if showBought {
                                    cell("收货", "\(stats.boughtCount)件")
                                    cell("已卖", stats.sellThrough.map { Fmt.percent($0) } ?? "\(stats.soldCount)件")
                                } else {
                                    cell("卖出", "\(stats.soldCount)件")
                                }
                                cell("每件赚", stats.avgProfit.map { store.money($0) } ?? "—")
                                cell("回报率", Fmt.percent(stats.roi))
                                cell("平均卖出", Fmt.days(stats.avgDays))
                            }
                        }
                        .padding(.vertical, 10)
                        if index < rows.count - 1 { Divider() }
                    }
                }
                .card(padding: 14)
            }
        }
    }

    private func cell(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(title).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.caption.weight(.medium)).monospacedDigit().lineLimit(1).minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct CategoryDetailView: View {
    @Environment(AppStore.self) private var store
    let category: String
    @State private var period: Period = .all

    var body: some View {
        let analytics = store.analytics()
        let stats = analytics.categoryStat(category, period: period)
        let target = analytics.settings.targetROI
        let lines = analytics.lines(in: period).filter { $0.category == category }
        let stock = analytics.inStockItems.filter { $0.category == category }.sorted { $0.purchaseDay < $1.purchaseDay }
        let days = lines.compactMap(\.daysToSell)

        List {
            Section {
                Picker("时间范围", selection: $period) {
                    ForEach(Period.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section {
                Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 14) {
                    GridRow {
                        StatView(title: "卖出", value: "\(stats.soldCount) 件")
                        StatView(title: "总利润", value: store.money(stats.profit), tint: Palette.profit(stats.profit))
                        StatView(title: "回报率", value: Fmt.percent(stats.roi))
                    }
                    GridRow {
                        StatView(title: "平均售价", value: stats.avgPrice.map { store.money($0) } ?? "—")
                        StatView(title: "平均成本", value: stats.avgCost.map { store.money($0) } ?? "—")
                        StatView(title: "每件赚", value: stats.avgProfit.map { store.money($0) } ?? "—")
                    }
                    GridRow {
                        StatView(title: "平均卖出", value: Fmt.days(stats.avgDays), caption: days.isEmpty ? nil : "\(days.count) 件有日期")
                        StatView(title: "中位用时", value: Fmt.days(stats.medianDays))
                        StatView(
                            title: "售罄率",
                            value: Fmt.percent(stats.sellThrough),
                            caption: stats.boughtCount > 0 ? "收 \(stats.boughtCount) 卖 \(stats.soldFromBought)" : nil
                        )
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                if let verdict = stats.verdict(targetROI: target) {
                    HStack(alignment: .top) {
                        Tag(text: verdict.rawValue, color: verdict.color)
                        Text(verdict.explanation).font(.subheadline)
                    }
                }
                if let price = stats.maxBuyPrice(targetROI: target), let avg = stats.avgPrice {
                    Text("这类货平均卖 \(store.money(avg))。想要 \(target)% 的回报率，进价不要超过 **\(store.money(price))**。")
                        .font(.subheadline)
                } else {
                    Text("卖出 2 件以上后会给出建议进价。").font(.subheadline).foregroundStyle(.secondary)
                }
            } header: {
                Text("收货参考")
            } footer: {
                Text("目标回报率可以在设置里调整。")
            }

            if !stock.isEmpty {
                Section("在库 \(stock.count) 件 · \(store.money(stock.sum(\.cost)))") {
                    ForEach(stock) { item in
                        NavigationLink(value: item.id) {
                            ItemRow(item: item, analytics: analytics)
                        }
                    }
                }
            }

            if !lines.isEmpty {
                Section("卖出记录") {
                    ForEach(lines.prefix(100)) { line in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.name).lineLimit(1)
                                Text([Fmt.dayWithWeekday(line.day), line.source, line.daysToSell.map { "\($0) 天卖出" }]
                                    .compactMap { $0 }
                                    .joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("\(store.money(line.cost)) → \(store.money(line.revenue))")
                                    .font(.subheadline)
                                    .monospacedDigit()
                                Text(store.money(line.profit, signed: true))
                                    .font(.caption.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.profit(line.profit))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(category)
    }
}
