import SwiftUI

struct RecordsView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var search = ""
    @State private var pendingDelete: Sale?

    var body: some View {
        @Bindable var router = router
        let analytics = store.analytics()

        NavigationStack {
            List {
                Section {
                    Picker("类型", selection: $router.recordsSegment) {
                        ForEach(RecordsSegment.allCases) { segment in
                            Text(segment.title).tag(segment)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                switch router.recordsSegment {
                case .sales: salesList(analytics)
                case .hauls: haulsList(analytics)
                case .expenses: expensesList()
                }
            }
            .listSectionSpacing(.compact)
            .searchable(text: $search, prompt: "搜索")
            .navigationTitle("记录")
            .navigationDestination(for: Day.self) { HaulDetailView(day: $0) }
            .navigationDestination(for: UUID.self) { ItemDetailView(itemID: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) { AddMenu() }
            }
            .confirmationDialog("删除这笔销售？", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            ), titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    if let sale = pendingDelete { store.deleteSale(sale.id) }
                    pendingDelete = nil
                }
            } message: {
                Text("关联的货会回到库存。")
            }
        }
    }

    // MARK: Sales

    @ViewBuilder
    private func salesList(_ analytics: Analytics) -> some View {
        let tokens = Analytics.searchTokens(search)
        let rows = analytics.data.sales
            .map { sale in SaleRow(sale: sale, name: store.displayName(of: sale), lines: Analytics.lines(for: sale, itemsByID: analytics.itemsByID)) }
            .filter { row in
                tokens.isEmpty || Analytics.matches(
                    "\(row.name) \(row.sale.channel) \(row.sale.note) \(row.lines.map(\.category).joined(separator: " "))",
                    tokens: tokens
                )
            }
            .sorted { $0.sale.day > $1.sale.day }
        let months = Dictionary(grouping: rows) { Month($0.sale.day) }.sorted { $0.key > $1.key }

        if rows.isEmpty {
            EmptyStateView(icon: "tag", title: "还没有销售记录", message: "卖出时从库存选中那件货，利润和用时会自动算好。")
        }
        ForEach(months, id: \.key) { month, monthRows in
            let revenue = monthRows.sum { $0.sale.amount }
            let profit = monthRows.sum { $0.lines.sum(\.profit) }
            Section {
                ForEach(monthRows) { row in
                    let profit = row.lines.sum(\.profit)
                    Button { router.sheet = .editSale(row.sale.id) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(row.name).foregroundStyle(.primary).lineLimit(1)
                                HStack(spacing: 6) {
                                    Text("\(Fmt.dayWithWeekday(row.sale.day)) · \(row.lines.first?.category ?? "")")
                                    if let days = Stats.mean(row.lines.compactMap(\.daysToSell)) {
                                        Text("· \(Fmt.days(days))卖出")
                                    }
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(store.money(row.sale.amount)).monospacedDigit().foregroundStyle(.primary)
                                Text(store.money(profit, signed: true))
                                    .font(.caption.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(Palette.profit(profit))
                            }
                        }
                    }
                    .swipeActions {
                        Button("删除", role: .destructive) { pendingDelete = row.sale }
                    }
                }
            } header: {
                HStack {
                    Text(Fmt.month(month))
                    Spacer()
                    Text("\(monthRows.count) 单 · \(store.money(revenue)) · 赚 \(store.money(profit))")
                        .monospacedDigit()
                }
            }
        }
    }

    // MARK: Hauls

    @ViewBuilder
    private func haulsList(_ analytics: Analytics) -> some View {
        let tokens = Analytics.searchTokens(search)
        let hauls = analytics.hauls().filter { haul in
            tokens.isEmpty || haul.items.contains {
                Analytics.matches("\($0.name) \($0.category) \($0.source)", tokens: tokens)
            }
        }
        if hauls.isEmpty {
            EmptyStateView(icon: "cart", title: "还没有收货记录", message: "每次从二手店回来，用「收货」把这一趟的货记下来。")
        } else {
            Section {
                ForEach(hauls) { haul in
                    NavigationLink(value: haul.day) {
                        HaulRow(haul: haul)
                    }
                }
            } footer: {
                Text("回本进度 = 已卖出的货收回的钱 ÷（这天的进货 + 交通费）。")
            }
        }
    }

    // MARK: Expenses

    @ViewBuilder
    private func expensesList() -> some View {
        let tokens = Analytics.searchTokens(search)
        let expenses = store.data.expenses
            .filter { tokens.isEmpty || Analytics.matches("\($0.category) \($0.note)", tokens: tokens) }
            .sorted { $0.day > $1.day }
        let months = Dictionary(grouping: expenses) { Month($0.day) }.sorted { $0.key > $1.key }
        if expenses.isEmpty {
            EmptyStateView(icon: "minus.circle", title: "还没有支出", message: "交通、平台费、清洁维修用品都记在这里。")
        }
        ForEach(months, id: \.key) { month, rows in
            Section {
                ForEach(rows) { expense in
                    Button { router.sheet = .expense(expense.id) } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(expense.category).foregroundStyle(.primary)
                                Text(expense.note.isEmpty ? Fmt.dayWithWeekday(expense.day) : "\(Fmt.dayWithWeekday(expense.day)) · \(expense.note)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(store.money(expense.amount)).monospacedDigit().foregroundStyle(.primary)
                        }
                    }
                    .swipeActions {
                        Button("删除", role: .destructive) { store.deleteExpense(expense.id) }
                    }
                }
            } header: {
                HStack {
                    Text(Fmt.month(month))
                    Spacer()
                    Text(store.money(rows.sum(\.amount))).monospacedDigit()
                }
            }
        }
    }
}

private struct SaleRow: Identifiable {
    let sale: Sale
    let name: String
    let lines: [SaleLine]
    var id: UUID { sale.id }
}

struct HaulRow: View {
    @Environment(AppStore.self) private var store
    let haul: Haul

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(Fmt.dayWithWeekday(haul.day)).font(.headline)
                if !haul.sources.isEmpty {
                    Text(haul.sources.joined(separator: "、"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
                Text(store.money(haul.outlay)).monospacedDigit()
            }
            ProgressView(value: min(haul.payback, 1))
                .tint(haul.payback >= 1 ? .green : .accentColor)
            HStack {
                Text("\(haul.items.count) 件 · 已卖 \(haul.soldCount)" + (haul.writtenOffCount > 0 ? " · 报废 \(haul.writtenOffCount)" : ""))
                Spacer()
                if haul.payback >= 1 {
                    Text("已回本 · 多赚 \(store.money(haul.balance))").foregroundStyle(.green)
                } else {
                    Text("回本 \(Fmt.percent(haul.payback))")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct HaulDetailView: View {
    @Environment(AppStore.self) private var store
    let day: Day

    var body: some View {
        let analytics = store.analytics()
        let haul = analytics.hauls().first { $0.day == day }

        List {
            if let haul {
                Section {
                    LabeledContent("进货", value: "\(haul.items.count) 件 · \(store.money(haul.spend))")
                    LabeledContent("交通", value: store.money(haul.transport))
                    LabeledContent("已卖出", value: "\(haul.soldCount) 件，回款 \(store.money(haul.proceeds))")
                    LabeledContent("已卖部分利润") {
                        Text(store.money(haul.soldProfit, signed: true)).foregroundStyle(Palette.profit(haul.soldProfit))
                    }
                    LabeledContent("这一趟结余") {
                        Text(store.money(haul.balance, signed: true)).foregroundStyle(Palette.profit(haul.balance))
                    }
                    if haul.inStockCount > 0 {
                        let stock = haul.items.filter { analytics.status(of: $0) == .inStock }
                        LabeledContent("还在库", value: "\(stock.count) 件 · \(store.money(stock.sum(\.cost)))")
                    }
                } footer: {
                    Text("结余 = 回款 − 进货 − 交通。还没卖的货卖掉后结余会继续增加。")
                }
                Section("这一趟的货") {
                    ForEach(haul.items) { item in
                        NavigationLink(value: item.id) {
                            ItemRow(item: item, analytics: analytics)
                        }
                    }
                }
            } else {
                EmptyStateView(icon: "cart", title: "这天没有收货", message: "")
            }
        }
        .navigationTitle("\(Fmt.day(day, includeYear: true)) 收货")
        .navigationBarTitleDisplayMode(.inline)
    }
}
