import SwiftUI

/// "Have I sold one of these before?" — quick lookup while standing in the thrift store.
struct PriceCheckView: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var cost = ""
    @FocusState private var focused: Bool

    var body: some View {
        let analytics = store.analytics()
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        let check = trimmed.isEmpty ? nil : analytics.priceCheck(trimmed)
        let guessed = CategoryGuesser.guess(trimmed)
        let categoryStats = analytics.categoryStat(guessed)

        NavigationStack {
            List {
                Section {
                    TextField("输入名称，如 dyson v8、键盘、ti-84", text: $query)
                        .focused($focused)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                    MoneyField(title: "店里标价", text: $cost, prompt: "可选")
                }

                if let check, check.count > 0 {
                    summary(check)
                    if !check.inStock.isEmpty {
                        Section("库存里还有 \(check.inStock.count) 件类似的") {
                            ForEach(check.inStock) { item in
                                ItemRow(item: item, analytics: analytics)
                            }
                        }
                    }
                    Section("历史成交") {
                        ForEach(check.lines.prefix(50)) { line in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(line.name).lineLimit(1)
                                    Text([Fmt.day(line.day, includeYear: line.day.year != analytics.today.year), line.daysToSell.map { "\($0) 天卖出" }]
                                        .compactMap { $0 }
                                        .joined(separator: " · "))
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text("\(store.money(line.cost)) → \(store.money(line.revenue))")
                                    .font(.subheadline)
                                    .monospacedDigit()
                            }
                        }
                    }
                } else if !trimmed.isEmpty {
                    Section {
                        if let check, !check.inStock.isEmpty {
                            Text("没有卖过，但库存里已经有 \(check.inStock.count) 件类似的。")
                        } else {
                            Text("没有卖过「\(trimmed)」。")
                        }
                        if categoryStats.soldCount >= 2, let avg = categoryStats.avgPrice {
                            Text("按「\(guessed)」类平均：卖 \(store.money(avg))，\(Fmt.days(categoryStats.avgDays)) 卖出，回报率 \(Fmt.percent(categoryStats.roi))。")
                                .foregroundStyle(.secondary)
                            if let maxBuy = categoryStats.maxBuyPrice(targetROI: analytics.settings.targetROI) {
                                Text("建议进价不超过 \(store.money(maxBuy))。").foregroundStyle(.secondary)
                            }
                        }
                    }
                    .font(.subheadline)
                } else {
                    Section {
                        Text("用你自己的成交记录判断值不值得收：卖过几次、卖多少钱、多久卖掉、库存里是不是已经有了。")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("查历史售价")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
            .onAppear { focused = true }
        }
    }

    private func summary(_ check: PriceCheck) -> some View {
        Section {
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 14) {
                GridRow {
                    StatView(title: "卖过", value: "\(check.count) 次")
                    StatView(title: "均价", value: check.avgPrice.map { store.money($0) } ?? "—")
                    StatView(title: "区间", value: "\(store.money(check.minPrice ?? 0))–\(store.money(check.maxPrice ?? 0))")
                }
                GridRow {
                    StatView(title: "平均成本", value: check.avgCost.map { store.money($0) } ?? "—")
                    StatView(title: "回报率", value: Fmt.percent(check.roi))
                    StatView(title: "平均卖出", value: Fmt.days(check.avgDays))
                }
            }
            .padding(.vertical, 4)
            if let price = Decimal(userInput: cost), price > 0, let avg = check.avgPrice {
                let profit = avg - price
                HStack {
                    Image(systemName: profit > 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(Palette.profit(profit))
                    Text("按均价卖，约赚 \(store.money(profit))（回报 \(Fmt.percent(profit.double / price.double))）")
                        .font(.subheadline)
                }
            }
        }
    }
}
