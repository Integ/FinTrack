import SwiftUI

/// Record a sale, linked to the inventory items that were sold.
struct SaleEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let saleID: UUID?
    let preselected: [UUID]

    @State private var loaded = false
    @State private var itemIDs: [UUID] = []
    @State private var amount = ""
    @State private var extraCost = ""
    @State private var channel = ""
    @State private var day = Date()
    @State private var note = ""
    @State private var title = ""
    @State private var category = Defaults.otherCategory
    @State private var categoryPicked = false
    @State private var manualCost = ""
    @State private var showPicker = false
    @State private var confirmDelete = false

    private var amountValue: Decimal? { Decimal(userInput: amount) }
    private var linkedItems: [Item] { itemIDs.compactMap(store.item) }
    private var isLinked: Bool { !itemIDs.isEmpty }

    private var cost: Decimal {
        isLinked
            ? linkedItems.sum(\.cost) + (Decimal(userInput: extraCost) ?? 0)
            : (Decimal(userInput: manualCost) ?? 0)
    }

    private var canSave: Bool {
        guard let amountValue, amountValue >= 0 else { return false }
        return isLinked || !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                itemsSection
                Section("成交") {
                    MoneyField(title: "售价", text: $amount)
                    DatePicker("日期", selection: $day, in: ...Date(), displayedComponents: .date)
                    TextField("渠道", text: $channel)
                    ChipRow(options: Array(store.recentChannels.prefix(6)), selected: channel) { channel = $0 }
                    if isLinked {
                        MoneyField(title: "其他成本", text: $extraCost, prompt: "配件/运费/平台费")
                    }
                    TextField("备注", text: $note, axis: .vertical)
                }
                if let amountValue {
                    previewSection(amount: amountValue)
                }
                if saleID != nil {
                    Section {
                        Button("删除这笔销售", role: .destructive) { confirmDelete = true }
                    } footer: {
                        if isLinked { Text("删除后，关联的货会回到库存。") }
                    }
                }
            }
            .navigationTitle(saleID == nil ? "卖出" : "编辑销售")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }.disabled(!canSave)
                }
            }
            .sheet(isPresented: $showPicker) {
                ItemPickerView(selection: $itemIDs, saleID: saleID)
                    .environment(store)
            }
            .confirmationDialog("删除这笔销售？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    if let saleID { store.deleteSale(saleID) }
                    dismiss()
                }
            }
            .onAppear(perform: load)
            .onChange(of: itemIDs) { old, new in
                // Suggest the asking price when items are first picked.
                if old.isEmpty, !new.isEmpty, amount.isEmpty {
                    let prices = new.compactMap { store.item($0)?.listPrice }
                    if prices.count == new.count { amount = prices.reduce(0, +).plainString }
                }
            }
        }
    }

    @ViewBuilder
    private var itemsSection: some View {
        let today = Day(day)
        Section {
            ForEach(linkedItems) { item in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name).lineLimit(1)
                        Text("\(item.category) · \(Fmt.day(item.purchaseDay)) 收 · 放了 \(max(0, item.purchaseDay.days(until: today))) 天")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(store.money(item.cost))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
            .onDelete { offsets in
                let ids = offsets.map { linkedItems[$0].id }
                itemIDs.removeAll { ids.contains($0) }
            }
            Button {
                showPicker = true
            } label: {
                Label(isLinked ? "添加 / 修改" : "从库存选择", systemImage: "shippingbox")
            }
        } header: {
            Text("卖了哪些货")
        } footer: {
            if isLinked {
                Text("一起卖的多件货，售价按进价比例分摊到每件。")
            } else {
                Text("从库存选中卖出的货，才能算出这件货放了多久、哪家店收的货最赚钱。")
            }
        }

        if !isLinked {
            Section {
                TextField("名称", text: $title)
                    .onChange(of: title) { _, value in
                        if !categoryPicked { category = CategoryGuesser.guess(value) }
                    }
                CategoryPicker(title: "类别", selection: $category, options: store.itemCategories) {
                    categoryPicked = true
                }
                MoneyField(title: "成本", text: $manualCost)
            } header: {
                Text("或者直接填写（不关联库存）")
            }
        }
    }

    private func previewSection(amount: Decimal) -> some View {
        let profit = amount - cost
        let days = linkedItems.map { max(0, $0.purchaseDay.days(until: Day(day))) }
        return Section("这一单") {
            LabeledContent("成本", value: store.money(cost))
            LabeledContent("利润") {
                Text(store.money(profit, signed: true))
                    .foregroundStyle(Palette.profit(profit))
                    .monospacedDigit()
            }
            LabeledContent("回报率", value: cost > 0 ? Fmt.percent(profit.double / cost.double) : "—")
            if let average = Stats.mean(days) {
                LabeledContent("持有", value: Fmt.days(average))
            }
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let saleID, let sale = store.sale(saleID) {
            itemIDs = sale.itemIDs
            amount = sale.amount.plainString
            channel = sale.channel
            day = sale.day.date
            note = sale.note
            if sale.isLinked {
                extraCost = sale.extraCost == 0 ? "" : sale.extraCost.plainString
            } else {
                title = sale.title
                category = sale.category.isEmpty ? Defaults.otherCategory : sale.category
                categoryPicked = true
                manualCost = sale.extraCost.plainString
            }
        } else {
            itemIDs = preselected
            channel = store.recentChannels.first ?? Defaults.channels[0]
            let prices = preselected.compactMap { store.item($0)?.listPrice }
            if !preselected.isEmpty, prices.count == preselected.count {
                amount = prices.reduce(0, +).plainString
            }
        }
    }

    private func save() {
        guard let amountValue else { return }
        var sale = (saleID.flatMap(store.sale)) ?? Sale(day: Day(day), amount: amountValue, channel: "")
        sale.day = Day(day)
        sale.amount = amountValue
        sale.channel = channel.trimmingCharacters(in: .whitespaces)
        sale.note = note.trimmingCharacters(in: .whitespaces)
        sale.itemIDs = itemIDs
        if isLinked {
            sale.extraCost = Decimal(userInput: extraCost) ?? 0
            sale.title = ""
            sale.category = ""
        } else {
            sale.extraCost = Decimal(userInput: manualCost) ?? 0
            sale.title = title.trimmingCharacters(in: .whitespaces)
            sale.category = category
        }
        store.saveSale(sale)
        dismiss()
    }
}

/// Multi-select list of in-stock items.
struct ItemPickerView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: [UUID]
    let saleID: UUID?
    @State private var search = ""

    var body: some View {
        let analytics = store.analytics()
        let tokens = Analytics.searchTokens(search)
        let candidates = store.data.items
            .filter { item in
                item.status != .sold || (saleID != nil && item.saleID == saleID) || selection.contains(item.id)
            }
            .filter { tokens.isEmpty || Analytics.matches("\($0.name) \($0.category) \($0.source)", tokens: tokens) }
            .sorted { $0.purchaseDay > $1.purchaseDay }

        NavigationStack {
            List {
                if candidates.isEmpty {
                    EmptyStateView(icon: "shippingbox", title: "没有可选的货", message: "先在「收货」里把货记下来。")
                }
                ForEach(candidates) { item in
                    let selected = selection.contains(item.id)
                    Button {
                        if selected {
                            selection.removeAll { $0 == item.id }
                        } else {
                            selection.append(item.id)
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                                .foregroundStyle(selected ? Color.accentColor : Color.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name).foregroundStyle(.primary).lineLimit(1)
                                Text([item.category, item.source, "\(Fmt.day(item.purchaseDay)) 收"].filter { !$0.isEmpty }.joined(separator: " · "))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                if item.status == .writtenOff {
                                    Tag(text: "已报废", color: .red)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(store.money(item.cost)).monospacedDigit().foregroundStyle(.primary)
                                AgeBadge(days: item.age(on: analytics.today), staleDays: analytics.settings.staleDays)
                            }
                        }
                    }
                }
            }
            .searchable(text: $search, prompt: "搜索库存")
            .navigationTitle(selection.isEmpty ? "选择卖出的货" : "已选 \(selection.count) 件")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
    }
}
