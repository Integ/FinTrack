import SwiftUI

struct DashboardView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var period: Period = .thisMonth

    var body: some View {
        let analytics = store.analytics()
        let pnl = analytics.pnl(period)
        let inventory = analytics.inventory()
        let insights = analytics.insights()

        NavigationStack {
            ScrollView {
                VStack(spacing: 18) {
                    Picker("时间范围", selection: $period) {
                        ForEach([Period.week, .days30, .thisMonth, .all]) { period in
                            Text(period.title).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)

                    ProfitCard(period: period, pnl: pnl)
                    quickActions
                    priceCheckButton
                    InventoryCard(summary: inventory, staleDays: analytics.settings.staleDays)

                    if !insights.isEmpty {
                        VStack(spacing: 10) {
                            SectionTitle(title: "经营建议")
                            ForEach(insights) { insight in
                                InsightCard(insight: insight)
                            }
                        }
                    }

                    RecentActivity(analytics: analytics)
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("FinTrack")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AddMenu() }
            }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            QuickActionButton(title: "收货", icon: "cart.badge.plus", tint: .orange) { router.sheet = .restock }
            QuickActionButton(title: "卖出", icon: "tag.fill", tint: .green) { router.sheet = .newSale([]) }
            QuickActionButton(title: "支出", icon: "minus.circle.fill", tint: .pink) { router.sheet = .expense(nil) }
        }
    }

    private var priceCheckButton: some View {
        Button {
            router.sheet = .priceCheck
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                VStack(alignment: .leading, spacing: 2) {
                    Text("查历史售价").font(.subheadline.weight(.semibold))
                    Text("在店里拿不准？看看以前卖了多少、多久卖掉")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .foregroundStyle(.primary)
            .card(padding: 14)
        }
        .buttonStyle(.plain)
    }
}

private struct ProfitCard: View {
    @Environment(AppStore.self) private var store
    let period: Period
    let pnl: PnL

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(period.longTitle)净利润")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Text(store.money(pnl.netProfit))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            HStack(alignment: .top, spacing: 12) {
                heroStat("销售额", store.money(pnl.revenue))
                heroStat("毛利", store.money(pnl.grossProfit), caption: "毛利率 \(Fmt.percent(pnl.grossMargin))")
                heroStat("支出", store.money(pnl.expenses + pnl.writeOffs))
            }
            Divider().overlay(.white.opacity(0.25))
            HStack(spacing: 12) {
                heroStat("卖出", "\(pnl.soldCount) 件")
                heroStat("每件赚", pnl.avgProfitPerItem.map { store.money($0) } ?? "—")
                heroStat("平均卖出", Fmt.days(pnl.avgDays))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color(red: 0.31, green: 0.27, blue: 0.9), Color(red: 0.45, green: 0.32, blue: 0.86)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
    }

    private func heroStat(_ title: String, _ value: String, caption: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.white.opacity(0.7))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let caption {
                Text(caption).font(.caption2).foregroundStyle(.white.opacity(0.65))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct QuickActionButton: View {
    let title: String
    let icon: String
    let tint: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(tint)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct InventoryCard: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    let summary: InventorySummary
    let staleDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("库存").font(.headline)
                Spacer()
                Button("查看") { router.open(.inventory(.all)) }
                    .font(.subheadline)
            }
            HStack(spacing: 12) {
                StatView(title: "在库", value: "\(summary.count) 件")
                StatView(title: "占用资金", value: store.money(summary.totalCost))
                StatView(
                    title: "平均库龄",
                    value: Fmt.days(summary.avgAge),
                    tint: (summary.avgAge ?? 0) >= Double(staleDays) ? .orange : .primary
                )
            }
            if summary.count > 0 {
                AgingBar(buckets: summary.buckets)
                HStack(spacing: 8) {
                    if summary.staleCount > 0 {
                        Button { router.open(.inventory(.stale)) } label: {
                            Tag(text: "压货 \(summary.staleCount) 件 · \(store.money(summary.staleCost))", color: .orange)
                        }
                    }
                    if summary.unlistedCount > 0 {
                        Button { router.open(.inventory(.unlisted)) } label: {
                            Tag(text: "待上架 \(summary.unlistedCount) 件", color: .blue)
                        }
                    }
                    if summary.pricedCount > 0 {
                        Tag(text: "挂牌合计 \(store.money(summary.expectedRevenue))", color: .green)
                    }
                }
                .buttonStyle(.plain)
            } else {
                Text("还没有在库的货。收货时记一下，就能跟踪每件货多久卖掉。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .card()
    }
}

/// Stacked bar showing how old the stock is.
struct AgingBar: View {
    let buckets: [AgeBucket]
    private let colors: [Color] = [.green, .teal, .orange, .red]

    var body: some View {
        let total = max(1, buckets.reduce(0) { $0 + $1.count })
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { proxy in
                HStack(spacing: 2) {
                    ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                        if bucket.count > 0 {
                            Rectangle()
                                .fill(colors[index % colors.count])
                                .frame(width: max(4, proxy.size.width * CGFloat(bucket.count) / CGFloat(total) - 2))
                        }
                    }
                }
                .clipShape(Capsule())
            }
            .frame(height: 10)
            HStack(spacing: 10) {
                ForEach(Array(buckets.enumerated()), id: \.offset) { index, bucket in
                    HStack(spacing: 4) {
                        Circle().fill(colors[index % colors.count]).frame(width: 7, height: 7)
                        Text("\(bucket.label) \(bucket.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}

private struct InsightCard: View {
    @Environment(Router.self) private var router
    let insight: Insight

    var body: some View {
        Button {
            if let action = insight.action { router.open(action) }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: insight.icon)
                    .font(.headline)
                    .foregroundStyle(insight.kind.color)
                    .frame(width: 32, height: 32)
                    .background(insight.kind.color.opacity(0.14), in: RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.leading)
                    Text(insight.detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                if insight.action != nil {
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)
                }
            }
            .foregroundStyle(.primary)
            .card(padding: 14)
        }
        .buttonStyle(.plain)
        .disabled(insight.action == nil)
    }
}

private struct RecentActivity: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    let analytics: Analytics

    private enum Entry: Identifiable {
        case sale(Sale)
        case haul(Haul)
        case expense(Expense)

        var id: String {
            switch self {
            case .sale(let sale): "s-\(sale.id)"
            case .haul(let haul): "h-\(haul.day)"
            case .expense(let expense): "e-\(expense.id)"
            }
        }

        var day: Day {
            switch self {
            case .sale(let sale): sale.day
            case .haul(let haul): haul.day
            case .expense(let expense): expense.day
            }
        }
    }

    var body: some View {
        let entries = (
            analytics.data.sales.map(Entry.sale)
                + analytics.hauls().prefix(10).map(Entry.haul)
                + analytics.data.expenses.map(Entry.expense)
        )
        .sorted { $0.day > $1.day }
        .prefix(6)

        VStack(spacing: 10) {
            SectionTitle(title: "最近动态")
            if entries.isEmpty {
                EmptyStateView(icon: "tray", title: "还没有记录", message: "点上面的「收货」开始记录第一批货。")
                    .card()
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        row(entry)
                        if index < entries.count - 1 {
                            Divider().padding(.leading, 44)
                        }
                    }
                }
                .card(padding: 12)
            }
        }
    }

    @ViewBuilder
    private func row(_ entry: Entry) -> some View {
        switch entry {
        case .sale(let sale):
            let lines = Analytics.lines(for: sale, itemsByID: analytics.itemsByID)
            let profit = lines.sum(\.profit)
            Button { router.sheet = .editSale(sale.id) } label: {
                ActivityRow(
                    icon: "tag.fill", tint: .green,
                    title: store.displayName(of: sale),
                    subtitle: "卖出 · \(Fmt.dayWithWeekday(sale.day))",
                    value: store.money(sale.amount, signed: true),
                    detail: "利润 \(store.money(profit))",
                    detailTint: Palette.profit(profit)
                )
            }
            .buttonStyle(.plain)
        case .haul(let haul):
            Button { router.open(.hauls) } label: {
                ActivityRow(
                    icon: "cart.fill", tint: .orange,
                    title: "收货 \(haul.items.count) 件" + (haul.sources.isEmpty ? "" : " · \(haul.sources.joined(separator: "、"))"),
                    subtitle: Fmt.dayWithWeekday(haul.day),
                    value: store.money(-haul.spend),
                    detail: "已卖 \(haul.soldCount)/\(haul.items.count)",
                    detailTint: .secondary
                )
            }
            .buttonStyle(.plain)
        case .expense(let expense):
            Button { router.sheet = .expense(expense.id) } label: {
                ActivityRow(
                    icon: "minus.circle.fill", tint: .pink,
                    title: expense.note.isEmpty ? expense.category : "\(expense.category) · \(expense.note)",
                    subtitle: Fmt.dayWithWeekday(expense.day),
                    value: store.money(-expense.amount),
                    detail: nil,
                    detailTint: .secondary
                )
            }
            .buttonStyle(.plain)
        }
    }
}

private struct ActivityRow: View {
    let icon: String
    let tint: Color
    let title: String
    let subtitle: String
    let value: String
    let detail: String?
    let detailTint: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline).lineLimit(1)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(value).font(.subheadline.weight(.semibold)).monospacedDigit()
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(detailTint)
                }
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
