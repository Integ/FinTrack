import SwiftUI

@main
struct FinTrackApp: App {
    @State private var store: AppStore
    @State private var router = Router()

    init() {
        let store = AppStore()
        #if DEBUG
        DebugLaunch.apply(to: store)
        #endif
        _store = State(initialValue: store)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(router)
                #if DEBUG
                .onAppear { DebugLaunch.route(router) }
                #endif
        }
    }
}

enum AppTab: Hashable {
    case home, inventory, records, analytics, settings
}

enum RecordsSegment: String, CaseIterable, Identifiable {
    case sales, hauls, expenses

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sales: "销售"
        case .hauls: "收货"
        case .expenses: "支出"
        }
    }
}

enum AppSheet: Identifiable {
    case restock
    case newSale([UUID])
    case editSale(UUID)
    case expense(UUID?)
    case priceCheck

    var id: String {
        switch self {
        case .restock: "restock"
        case .newSale(let ids): "newSale-\(ids.map(\.uuidString).joined())"
        case .editSale(let id): "editSale-\(id)"
        case .expense(let id): "expense-\(id?.uuidString ?? "new")"
        case .priceCheck: "priceCheck"
        }
    }
}

@MainActor
@Observable
final class Router {
    var tab: AppTab = .home
    var sheet: AppSheet?
    var inventoryFilter: InventoryFilter = .all
    var recordsSegment: RecordsSegment = .sales
    var analyticsPath = NavigationPath()

    func open(_ action: Insight.Action) {
        switch action {
        case .inventory(let filter):
            inventoryFilter = filter
            tab = .inventory
        case .category(let category):
            analyticsPath = NavigationPath([category])
            tab = .analytics
        case .hauls:
            recordsSegment = .hauls
            tab = .records
        }
    }
}

struct RootView: View {
    @Environment(AppStore.self) private var store
    @Environment(Router.self) private var router

    var body: some View {
        @Bindable var router = router
        TabView(selection: $router.tab) {
            DashboardView()
                .tabItem { Label("首页", systemImage: "house") }
                .tag(AppTab.home)
            InventoryView()
                .tabItem { Label("库存", systemImage: "shippingbox") }
                .tag(AppTab.inventory)
            RecordsView()
                .tabItem { Label("记录", systemImage: "list.bullet.rectangle") }
                .tag(AppTab.records)
            AnalyticsView()
                .tabItem { Label("分析", systemImage: "chart.bar.xaxis") }
                .tag(AppTab.analytics)
            SettingsView()
                .tabItem { Label("设置", systemImage: "gearshape") }
                .tag(AppTab.settings)
        }
        .sheet(item: $router.sheet) { sheet in
            Group {
                switch sheet {
                case .restock: RestockView()
                case .newSale(let ids): SaleEditor(saleID: nil, preselected: ids)
                case .editSale(let id): SaleEditor(saleID: id, preselected: [])
                case .expense(let id): ExpenseEditor(expenseID: id)
                case .priceCheck: PriceCheckView()
                }
            }
            .environment(store)
            .environment(router)
        }
    }
}

/// The "+" menu shown on every tab.
struct AddMenu: View {
    @Environment(Router.self) private var router

    var body: some View {
        Menu {
            Button { router.sheet = .restock } label: { Label("收货", systemImage: "cart.badge.plus") }
            Button { router.sheet = .newSale([]) } label: { Label("卖出", systemImage: "tag") }
            Button { router.sheet = .expense(nil) } label: { Label("记支出", systemImage: "minus.circle") }
            Divider()
            Button { router.sheet = .priceCheck } label: { Label("查历史售价", systemImage: "magnifyingglass") }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title2)
                .symbolRenderingMode(.hierarchical)
        }
        .accessibilityLabel("记一笔")
    }
}
