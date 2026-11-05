import SwiftUI

enum InventorySort: String, CaseIterable, Identifiable {
    case oldest, newest, costHigh, category

    var id: String { rawValue }

    var title: String {
        switch self {
        case .oldest: "库龄最长"
        case .newest: "最新收货"
        case .costHigh: "进价最高"
        case .category: "按类别"
        }
    }
}

struct InventoryView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @State private var search = ""
    @State private var sort: InventorySort = .oldest
    @State private var pendingWriteOff: Item?

    var body: some View {
        @Bindable var router = router
        let analytics = store.analytics()
        let summary = analytics.inventory()
        let items = filtered(summary.items, analytics: analytics)

        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            StatView(title: "在库", value: "\(summary.count) 件")
                            StatView(title: "占用资金", value: store.money(summary.totalCost))
                            StatView(
                                title: "挂牌合计",
                                value: summary.pricedCount > 0 ? store.money(summary.expectedRevenue) : "—",
                                caption: summary.pricedCount > 0 ? "\(summary.pricedCount) 件已定价" : nil
                            )
                        }
                        if summary.count > 0 {
                            AgingBar(buckets: summary.buckets)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Picker("筛选", selection: $router.inventoryFilter) {
                        ForEach(InventoryFilter.allCases) { filter in
                            Text(filter.title).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section {
                    if items.isEmpty {
                        EmptyStateView(
                            icon: "shippingbox",
                            title: summary.count == 0 ? "库存是空的" : "没有符合条件的货",
                            message: summary.count == 0
                                ? "从二手店收货回来后，点右上角 + 选「收货」记下来。"
                                : "换个筛选条件或搜索词试试。"
                        )
                    } else {
                        ForEach(items) { item in
                            NavigationLink(value: item.id) {
                                ItemRow(item: item, analytics: analytics)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button { router.sheet = .newSale([item.id]) } label: {
                                    Label("卖出", systemImage: "tag")
                                }
                                .tint(.green)
                                Button { pendingWriteOff = item } label: {
                                    Label("报废", systemImage: "trash.slash")
                                }
                                .tint(.gray)
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    store.setListed(item.id, on: item.listedDay == nil ? .today : nil)
                                } label: {
                                    Label(item.listedDay == nil ? "上架" : "下架", systemImage: item.listedDay == nil ? "camera" : "arrow.uturn.backward")
                                }
                                .tint(.blue)
                            }
                        }
                    }
                } header: {
                    if !items.isEmpty {
                        Text("\(items.count) 件 · \(store.money(items.sum(\.cost)))")
                    }
                } footer: {
                    if !items.isEmpty {
                        Text("向左滑：卖出 / 报废；向右滑：标记上架。超过 \(analytics.settings.staleDays) 天的货标为压货，可在设置里调整。")
                    }
                }
            }
            .listSectionSpacing(.compact)
            .searchable(text: $search, prompt: "搜索名称、类别、店铺")
            .navigationTitle("库存")
            .navigationDestination(for: UUID.self) { ItemDetailView(itemID: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("排序", selection: $sort) {
                            ForEach(InventorySort.allCases) { sort in
                                Text(sort.title).tag(sort)
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) { AddMenu() }
            }
            .confirmationDialog(
                "把「\(pendingWriteOff?.name ?? "")」标记为报废？",
                isPresented: Binding(get: { pendingWriteOff != nil }, set: { if !$0 { pendingWriteOff = nil } }),
                titleVisibility: .visible
            ) {
                Button("报废 / 自用", role: .destructive) {
                    if let item = pendingWriteOff { store.writeOff(item.id, on: .today) }
                    pendingWriteOff = nil
                }
            } message: {
                Text("进价 \(store.money(pendingWriteOff?.cost ?? 0)) 会记为损失。以后可以在详情里恢复。")
            }
        }
    }

    private func filtered(_ items: [Item], analytics: Analytics) -> [Item] {
        let tokens = Analytics.searchTokens(search)
        let result = items.filter { item in
            analytics.matches(item, filter: router.inventoryFilter)
                && (tokens.isEmpty || Analytics.matches("\(item.name) \(item.category) \(item.source) \(item.note)", tokens: tokens))
        }
        switch sort {
        case .oldest: return result.sorted { $0.purchaseDay < $1.purchaseDay }
        case .newest: return result.sorted { $0.purchaseDay > $1.purchaseDay }
        case .costHigh: return result.sorted { $0.cost > $1.cost }
        case .category: return result.sorted { ($0.category, $0.purchaseDay) < ($1.category, $1.purchaseDay) }
        }
    }
}

struct ItemDetailView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router
    @Environment(\.dismiss) private var dismiss
    let itemID: UUID

    @State private var loaded = false
    @State private var costText = ""
    @State private var listPriceText = ""
    @State private var confirmWriteOff = false
    @State private var confirmDelete = false

    var body: some View {
        let analytics = store.analytics()
        Group {
            if let item = store.item(itemID) {
                form(item: item, analytics: analytics)
            } else {
                EmptyStateView(icon: "questionmark.folder", title: "这件货已删除", message: "")
            }
        }
        .navigationTitle(store.item(itemID)?.name ?? "货品")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: load)
    }

    private func load() {
        guard !loaded, let item = store.item(itemID) else { return }
        loaded = true
        costText = item.cost.plainString
        listPriceText = item.listPrice?.plainString ?? ""
    }

    /// Always reads the latest stored item so edits never overwrite a sale made from another screen.
    private func binding(fallback: Item) -> Binding<Item> {
        Binding(
            get: { store.item(itemID) ?? fallback },
            set: { store.updateItem($0) }
        )
    }

    @ViewBuilder
    private func form(item: Item, analytics: Analytics) -> some View {
        let editable = binding(fallback: item)
        Form {
            statusSection(item: item, analytics: analytics)

            Section("货品") {
                TextField("名称", text: editable.name)
                CategoryPicker(title: "类别", selection: editable.category, options: store.itemCategories)
                TextField("收货店铺", text: editable.source)
                DatePicker("收货日期", selection: Binding(
                    get: { editable.wrappedValue.purchaseDay.date },
                    set: { editable.wrappedValue.purchaseDay = Day($0) }
                ), in: ...Date(), displayedComponents: .date)
                MoneyField(title: "进价", text: $costText)
                    .onChange(of: costText) { _, value in
                        if let cost = Decimal(userInput: value), cost >= 0 { editable.wrappedValue.cost = cost }
                    }
                MoneyField(title: "挂牌价", text: $listPriceText, prompt: "可选")
                    .onChange(of: listPriceText) { _, value in
                        editable.wrappedValue.listPrice = Decimal(userInput: value)
                    }
                TextField("备注（成色、配件、问题）", text: editable.note, axis: .vertical)
            }

            if item.status == .inStock {
                Section {
                    Toggle("已上架", isOn: Binding(
                        get: { editable.wrappedValue.listedDay != nil },
                        set: { editable.wrappedValue.listedDay = $0 ? .today : nil }
                    ))
                    if let listed = editable.wrappedValue.listedDay {
                        DatePicker("上架日期", selection: Binding(
                            get: { listed.date },
                            set: { editable.wrappedValue.listedDay = Day($0) }
                        ), in: ...Date(), displayedComponents: .date)
                    }
                } footer: {
                    Text("记录上架时间，能看出是货难卖，还是收回来压着没挂出去。")
                }
            }

            referenceSection(item: item, analytics: analytics)
            actionsSection(item: item)
        }
        .confirmationDialog("标记为报废 / 自用？", isPresented: $confirmWriteOff, titleVisibility: .visible) {
            Button("报废 / 自用", role: .destructive) { store.writeOff(item.id, on: .today) }
        } message: {
            Text("进价会记为损失，不再算在库存里。")
        }
        .confirmationDialog("删除这件货？", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("删除", role: .destructive) {
                store.deleteItems([item.id])
                dismiss()
            }
        } message: {
            Text(item.status == .sold ? "它会从销售记录中移除，但那笔销售的金额和成本会保留。" : "此操作无法撤销。")
        }
    }

    @ViewBuilder
    private func statusSection(item: Item, analytics: Analytics) -> some View {
        Section {
            switch item.status {
            case .inStock:
                LabeledContent("状态") { Tag(text: "在库", color: .blue) }
                LabeledContent("已放了", value: "\(item.age(on: analytics.today)) 天")
            case .sold:
                if let line = analytics.lineByItemID[item.id] {
                    LabeledContent("状态") { Tag(text: "已售", color: .green) }
                    LabeledContent("卖出日期", value: Fmt.day(line.day, includeYear: true))
                    LabeledContent("售价", value: store.money(line.revenue))
                    LabeledContent("利润") {
                        Text("\(store.money(line.profit, signed: true))（\(Fmt.percent(line.roi))）")
                            .foregroundStyle(Palette.profit(line.profit))
                    }
                    if let days = line.daysToSell {
                        LabeledContent("用了", value: "\(days) 天卖出")
                    }
                    Button("查看这笔销售") { router.sheet = .editSale(line.saleID) }
                }
            case .writtenOff:
                LabeledContent("状态") { Tag(text: "报废 / 自用", color: .red) }
                if let day = item.writtenOffDay {
                    LabeledContent("日期", value: Fmt.day(day, includeYear: true))
                }
                LabeledContent("损失", value: store.money(item.cost))
            }
        }
    }

    @ViewBuilder
    private func referenceSection(item: Item, analytics: Analytics) -> some View {
        let stats = analytics.categoryStat(item.category)
        if stats.soldCount > 0 {
            Section {
                LabeledContent("平均售价", value: stats.avgPrice.map { store.money($0) } ?? "—")
                LabeledContent("平均利润", value: stats.avgProfit.map { store.money($0) } ?? "—")
                LabeledContent("平均卖出用时", value: Fmt.days(stats.avgDays))
                if let maxBuy = stats.maxBuyPrice(targetROI: analytics.settings.targetROI) {
                    LabeledContent("建议进价上限", value: store.money(maxBuy))
                }
            } header: {
                Text("「\(item.category)」历史参考")
            } footer: {
                Text("基于已卖出的 \(stats.soldCount) 件\(stats.daysSamples.isEmpty ? "" : "，其中 \(stats.daysSamples.count) 件有收货日期")。")
            }
        }
    }

    @ViewBuilder
    private func actionsSection(item: Item) -> some View {
        Section {
            switch item.status {
            case .inStock:
                Button { router.sheet = .newSale([item.id]) } label: { Label("卖出", systemImage: "tag") }
                Button { confirmWriteOff = true } label: { Label("报废 / 自用", systemImage: "trash.slash") }
                    .foregroundStyle(.orange)
            case .writtenOff:
                Button {
                    store.restore(item.id)
                } label: { Label("恢复到库存", systemImage: "arrow.uturn.backward") }
            case .sold:
                EmptyView()
            }
            Button(role: .destructive) { confirmDelete = true } label: { Label("删除这件货", systemImage: "trash") }
        }
    }
}
