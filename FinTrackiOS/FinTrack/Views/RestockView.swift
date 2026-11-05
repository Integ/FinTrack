import SwiftUI

/// Record one trip to the thrift store: where, which items, what they cost, and the fare.
struct RestockView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    private struct Draft: Identifiable {
        let id = UUID()
        var name = ""
        var category = Defaults.otherCategory
        var categoryPicked = false
        var cost = ""
        var quantity = 1
        var listPrice = ""
        var note = ""

        var costValue: Decimal? { Decimal(userInput: cost) }
        var isValid: Bool {
            !name.trimmingCharacters(in: .whitespaces).isEmpty && (costValue.map { $0 >= 0 } ?? false)
        }
    }

    @State private var day = Date()
    @State private var source = ""
    @State private var drafts = [Draft()]
    @State private var includeTransport = false
    @State private var transportText = ""
    @State private var listedNow = false
    @State private var prepared = false
    @FocusState private var focusedDraft: UUID?

    var body: some View {
        let analytics = store.analytics()
        let valid = drafts.filter(\.isValid)
        let total = valid.reduce(Decimal.zero) { $0 + ($1.costValue ?? 0) * Decimal($1.quantity) }
        let count = valid.reduce(0) { $0 + $1.quantity }

        NavigationStack {
            Form {
                Section {
                    DatePicker("日期", selection: $day, in: ...Date(), displayedComponents: .date)
                    TextField("店铺（如 Value Village）", text: $source)
                    ChipRow(options: Array(store.recentSources.prefix(8)), selected: source) { source = $0 }
                } header: {
                    Text("在哪收的货")
                }

                ForEach($drafts) { $draft in
                    Section {
                        TextField("名称（如 Magic Keyboard）", text: $draft.name)
                            .focused($focusedDraft, equals: draft.id)
                            .onChange(of: draft.name) { _, name in
                                if !draft.categoryPicked { draft.category = CategoryGuesser.guess(name) }
                            }
                        CategoryPicker(title: "类别", selection: $draft.category, options: store.itemCategories) {
                            draft.categoryPicked = true
                        }
                        MoneyField(title: draft.quantity > 1 ? "每件进价" : "进价", text: $draft.cost)
                        Stepper("数量 \(draft.quantity)", value: $draft.quantity, in: 1...50)
                        MoneyField(title: "打算卖", text: $draft.listPrice, prompt: "可选")
                        TextField("备注（成色、缺配件…）", text: $draft.note)
                        RestockHint(draft: draft.name, category: draft.category, cost: draft.costValue, analytics: analytics)
                    } header: {
                        HStack {
                            Text("第 \(index(of: draft) + 1) 件")
                            Spacer()
                            if drafts.count > 1 {
                                Button("移除", role: .destructive) {
                                    drafts.removeAll { $0.id == draft.id }
                                }
                                .font(.caption)
                                .textCase(nil)
                            }
                        }
                    }
                }

                Section {
                    Button {
                        let next = Draft()
                        drafts.append(next)
                        focusedDraft = next.id
                    } label: {
                        Label("再加一件", systemImage: "plus.circle.fill")
                    }
                }

                Section {
                    Toggle("记一笔交通费", isOn: $includeTransport)
                    if includeTransport {
                        MoneyField(title: "金额", text: $transportText)
                        ChipRow(
                            options: store.recentTransportAmounts.map(\.plainString),
                            selected: transportText
                        ) { transportText = $0 }
                    }
                    Toggle("这些货已经上架", isOn: $listedNow)
                } footer: {
                    if store.transport(on: Day(day)) > 0 {
                        Text("这天已经记过 \(store.money(store.transport(on: Day(day)))) 交通费。")
                    } else {
                        Text("交通费会记到「交通」支出里，用来计算这一趟有没有回本。")
                    }
                }

                Section {
                    LabeledContent("合计", value: "\(count) 件 · \(store.money(total))")
                }
            }
            .navigationTitle("收货")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(valid.isEmpty)
                }
            }
            .onAppear(perform: prepare)
        }
    }

    private func index(of draft: Draft) -> Int {
        drafts.firstIndex { $0.id == draft.id } ?? 0
    }

    private func prepare() {
        guard !prepared else { return }
        prepared = true
        source = store.recentSources.first ?? ""
        if let fare = store.recentTransportAmounts.first {
            transportText = fare.plainString
            includeTransport = store.transport(on: .today) == 0
        }
        focusedDraft = drafts.first?.id
    }

    private func save() {
        let purchaseDay = Day(day)
        let batchID = UUID()
        let trimmedSource = source.trimmingCharacters(in: .whitespaces)
        var items: [Item] = []
        for draft in drafts where draft.isValid {
            for _ in 0..<draft.quantity {
                items.append(Item(
                    name: draft.name.trimmingCharacters(in: .whitespaces),
                    category: draft.category,
                    source: trimmedSource,
                    purchaseDay: purchaseDay,
                    cost: draft.costValue ?? 0,
                    listPrice: Decimal(userInput: draft.listPrice),
                    listedDay: listedNow ? purchaseDay : nil,
                    note: draft.note.trimmingCharacters(in: .whitespaces),
                    batchID: batchID
                ))
            }
        }
        var transport: Expense?
        if includeTransport, let fare = Decimal(userInput: transportText), fare > 0 {
            transport = Expense(
                day: purchaseDay,
                amount: fare,
                category: Defaults.transportCategory,
                note: trimmedSource.isEmpty ? "收货" : "收货 · \(trimmedSource)"
            )
        }
        store.addItems(items, transport: transport)
        dismiss()
    }
}

/// Decision help while standing in the store: past prices for similar items, or the category average.
struct RestockHint: View {
    @Environment(AppStore.self) private var store
    let draft: String
    let category: String
    let cost: Decimal?
    let analytics: Analytics

    var body: some View {
        let name = draft.trimmingCharacters(in: .whitespaces)
        let check = name.count >= 2 ? analytics.priceCheck(name) : nil
        let stats = analytics.categoryStat(category)

        if let check, check.count > 0, let avgPrice = check.avgPrice {
            hint(
                icon: "clock.arrow.circlepath",
                lines: [
                    "卖过 \(check.count) 次，均价 \(store.money(avgPrice))（\(store.money(check.minPrice ?? 0))–\(store.money(check.maxPrice ?? 0))）"
                        + (check.avgDays.map { "，平均 \(Fmt.days($0)) 卖出" } ?? ""),
                    check.inStock.isEmpty ? nil : "库存里还有 \(check.inStock.count) 件类似的",
                    expectation(avgPrice: avgPrice),
                ]
            )
        } else if stats.soldCount >= 2, let avgPrice = stats.avgPrice {
            hint(
                icon: "chart.bar",
                lines: [
                    "「\(category)」平均卖 \(store.money(avgPrice))"
                        + (stats.avgDays.map { "，平均 \(Fmt.days($0)) 卖出" } ?? ""),
                    stats.maxBuyPrice(targetROI: analytics.settings.targetROI).map { "建议进价不超过 \(store.money($0))" },
                    expectation(avgPrice: avgPrice),
                ]
            )
        } else if let check, !check.inStock.isEmpty {
            hint(icon: "shippingbox", lines: ["库存里还有 \(check.inStock.count) 件类似的"])
        }
    }

    private func expectation(avgPrice: Decimal) -> String? {
        guard let cost, cost > 0 else { return nil }
        let profit = avgPrice - cost
        return "按均价卖约赚 \(store.money(profit))（回报 \(Fmt.percent(profit.double / cost.double))）"
    }

    private func hint(icon: String, lines: [String?]) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                ForEach(lines.compactMap { $0 }, id: \.self) { line in
                    Text(line)
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }
}
