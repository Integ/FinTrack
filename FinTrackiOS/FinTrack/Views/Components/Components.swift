import SwiftUI

extension View {
    func card(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

enum Palette {
    static func profit(_ value: Decimal) -> Color {
        value > 0 ? .green : (value < 0 ? .red : .secondary)
    }

    static func age(_ days: Int, staleDays: Int) -> Color {
        if days >= staleDays * 2 { return .red }
        if days >= staleDays { return .orange }
        if days > 7 { return .secondary }
        return .green
    }
}

extension Verdict {
    var color: Color {
        switch self {
        case .buyMore: .green
        case .slow, .thin: .orange
        case .stuck: .red
        }
    }
}

extension Insight.Kind {
    var color: Color {
        switch self {
        case .warning: .orange
        case .positive: .green
        case .info: .accentColor
        }
    }
}

struct StatView: View {
    let title: String
    let value: String
    var tint: Color = .primary
    var caption: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
                .monospacedDigit()
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            if let caption {
                Text(caption)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct Tag: View {
    let text: String
    var color: Color = .accentColor

    var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .foregroundStyle(color)
            .background(color.opacity(0.14), in: Capsule())
    }
}

struct AgeBadge: View {
    let days: Int
    let staleDays: Int

    var body: some View {
        Label("\(days)天", systemImage: "clock")
            .labelStyle(.titleAndIcon)
            .font(.caption2.weight(.semibold))
            .monospacedDigit()
            .foregroundStyle(Palette.age(days, staleDays: staleDays))
    }
}

/// Horizontal list of suggestion chips; tapping one fills the field.
struct ChipRow: View {
    let options: [String]
    let selected: String
    let onSelect: (String) -> Void

    var body: some View {
        if !options.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(options, id: \.self) { option in
                        let isSelected = option == selected
                        Button(option) { onSelect(option) }
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill), in: Capsule())
                            .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

/// Category picker with a "new category" option.
struct CategoryPicker: View {
    let title: String
    @Binding var selection: String
    let options: [String]
    var onPick: (() -> Void)?
    @State private var addingCustom = false
    @State private var custom = ""

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                    onPick?()
                } label: {
                    if option == selection {
                        Label(option, systemImage: "checkmark")
                    } else {
                        Text(option)
                    }
                }
            }
            Divider()
            Button {
                custom = ""
                addingCustom = true
            } label: {
                Label("新类别…", systemImage: "plus")
            }
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Text(selection.isEmpty ? "选择" : selection).foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .alert("新类别", isPresented: $addingCustom) {
            TextField("类别名称", text: $custom)
            Button("取消", role: .cancel) {}
            Button("添加") {
                let trimmed = custom.trimmingCharacters(in: .whitespaces)
                if !trimmed.isEmpty {
                    selection = trimmed
                    onPick?()
                }
            }
        }
    }
}

struct MoneyField: View {
    let title: String
    @Binding var text: String
    var prompt: String = "0"

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            TextField(title, text: $text, prompt: Text(prompt))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .monospacedDigit()
                .frame(maxWidth: 160)
        }
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text(title).font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
    }
}

/// Inventory / haul row.
struct ItemRow: View {
    @Environment(AppStore.self) private var store
    let item: Item
    let analytics: Analytics

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                Text([item.category, item.source].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                tags
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                trailing
            }
        }
        .padding(.vertical, 2)
    }

    @ViewBuilder private var tags: some View {
        HStack(spacing: 6) {
            switch analytics.status(of: item) {
            case .inStock:
                if item.listedDay == nil, analytics.usesListing {
                    Tag(text: "待上架", color: .blue)
                }
                if let usual = analytics.slowerThanUsual(item) {
                    Tag(text: "同类平均 \(Fmt.days(usual)) 卖出", color: .orange)
                }
            case .sold:
                Tag(text: "已售", color: .green)
            case .writtenOff:
                Tag(text: "报废", color: .red)
            }
        }
    }

    @ViewBuilder private var trailing: some View {
        switch analytics.status(of: item) {
        case .inStock:
            Text(store.money(item.cost))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
            if let listPrice = item.listPrice {
                Text("挂 \(store.money(listPrice))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            AgeBadge(days: item.age(on: analytics.today), staleDays: analytics.settings.staleDays)
        case .sold:
            if let line = analytics.lineByItemID[item.id] {
                Text(store.money(line.revenue))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                Text(store.money(line.profit, signed: true))
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(Palette.profit(line.profit))
                if let days = line.daysToSell {
                    Text("\(days) 天卖出")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        case .writtenOff:
            Text(store.money(-item.cost))
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.red)
        }
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.title3.weight(.bold))
            if let subtitle {
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
