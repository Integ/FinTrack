import SwiftUI
import UniformTypeIdentifiers

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText, .json] }

    var data: Data
    var contentType: UTType
    var filename: String

    init(data: Data, contentType: UTType, filename: String) {
        self.data = data
        self.contentType = contentType
        self.filename = filename
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
        contentType = configuration.contentType
        filename = "fintrack"
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct SettingsView: View {
    @Environment(AppStore.self) private var store

    private enum PendingImport {
        case backup(AppData)
        case ledger(sales: [Sale], expenses: [Expense])

        var count: Int {
            switch self {
            case .backup(let data): data.items.count + data.sales.count + data.expenses.count
            case .ledger(let sales, let expenses): sales.count + expenses.count
            }
        }
    }

    @State private var exportDocument: ExportDocument?
    @State private var showExporter = false
    @State private var showImporter = false
    @State private var pendingImport: PendingImport?
    @State private var message: String?
    @State private var confirmErase = false

    private let currencies: [(code: String, name: String)] = [
        ("", "跟随系统"), ("CAD", "加元"), ("USD", "美元"), ("CNY", "人民币"), ("EUR", "欧元"),
        ("GBP", "英镑"), ("AUD", "澳元"), ("JPY", "日元"), ("HKD", "港币"),
    ]

    var body: some View {
        let analytics = store.analytics()
        let allTime = analytics.pnl(.all)

        NavigationStack {
            Form {
                Section {
                    Picker("货币", selection: Binding(
                        get: { store.settings.currencyCode },
                        set: { code in store.updateSettings { $0.currencyCode = code } }
                    )) {
                        ForEach(currencies, id: \.code) { currency in
                            Text(currency.code.isEmpty
                                 ? "跟随系统（\(Fmt.resolvedCurrency(""))）"
                                 : "\(currency.name) \(currency.code)")
                                .tag(currency.code)
                        }
                    }
                    Stepper(value: Binding(
                        get: { store.settings.staleDays },
                        set: { value in store.updateSettings { $0.staleDays = value } }
                    ), in: 7...180, step: 7) {
                        LabeledContent("压货提醒", value: "\(store.settings.staleDays) 天")
                    }
                    Stepper(value: Binding(
                        get: { store.settings.targetROI },
                        set: { value in store.updateSettings { $0.targetROI = value } }
                    ), in: 20...500, step: 10) {
                        LabeledContent("目标回报率", value: "\(store.settings.targetROI)%")
                    }
                } header: {
                    Text("经营设置")
                } footer: {
                    Text("在库超过「压货提醒」天数的货会被标出来。目标回报率用来算建议进价：100% 表示进价 10 块的货要卖 20 块。")
                }

                Section {
                    Button {
                        exportBackup()
                    } label: {
                        Label("导出完整备份（JSON）", systemImage: "externaldrive")
                    }
                    Button {
                        exportDocument = ExportDocument(
                            data: Data(("\u{FEFF}" + LedgerCSV.encode(analytics)).utf8),
                            contentType: .commaSeparatedText,
                            filename: "fintrack_backup_\(Day.today).csv"
                        )
                        showExporter = true
                    } label: {
                        Label("导出记账 CSV（兼容网页版 / Android）", systemImage: "tablecells")
                    }
                    Button {
                        exportDocument = ExportDocument(
                            data: Data(("\u{FEFF}" + InventoryCSV.encode(analytics)).utf8),
                            contentType: .commaSeparatedText,
                            filename: "fintrack_items_\(Day.today).csv"
                        )
                        showExporter = true
                    } label: {
                        Label("导出货品明细 CSV", systemImage: "list.bullet.rectangle")
                    }
                    Button {
                        showImporter = true
                    } label: {
                        Label("导入备份或 CSV", systemImage: "square.and.arrow.down")
                    }
                } header: {
                    Text("数据")
                } footer: {
                    Text("完整备份包含收货、库存和销售的关联，换手机时用它。导入旧版 CSV 时，收入会变成销售记录，并按名称自动归类（比如“戴森”归到小家电）。数据只保存在这台设备上。")
                }

                if let error = store.saveError {
                    Section {
                        Label(error, systemImage: "exclamationmark.triangle").foregroundStyle(.red)
                    }
                }

                Section("概况") {
                    LabeledContent("货品", value: "\(store.data.items.count) 件（在库 \(analytics.inStockItems.count)）")
                    LabeledContent("销售", value: "\(store.data.sales.count) 笔")
                    LabeledContent("支出", value: "\(store.data.expenses.count) 笔")
                    LabeledContent("累计净利润", value: store.money(allTime.netProfit))
                    LabeledContent("版本", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")
                }

                Section {
                    Button("清空所有数据", role: .destructive) { confirmErase = true }
                }
            }
            .navigationTitle("设置")
            .fileExporter(
                isPresented: $showExporter,
                document: exportDocument,
                contentType: exportDocument?.contentType ?? .commaSeparatedText,
                defaultFilename: exportDocument?.filename
            ) { result in
                if case .failure(let error) = result {
                    message = "导出失败：\(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $showImporter,
                allowedContentTypes: [.commaSeparatedText, .json, .plainText]
            ) { result in
                handleImport(result)
            }
            .confirmationDialog(
                "导入 \(pendingImport?.count ?? 0) 条记录",
                isPresented: Binding(get: { pendingImport != nil }, set: { if !$0 { pendingImport = nil } }),
                titleVisibility: .visible
            ) {
                switch pendingImport {
                case .backup(let data):
                    Button("合并到现有数据") { message = "已合并 \(store.merge(data)) 条记录" }
                    Button("替换全部数据", role: .destructive) {
                        store.replaceAll(with: data)
                        message = "已导入 \(data.items.count + data.sales.count + data.expenses.count) 条记录"
                    }
                case .ledger(let sales, let expenses):
                    Button("追加（跳过重复）") {
                        message = "已追加 \(store.appendLedger(sales: sales, expenses: expenses)) 条记录"
                    }
                    Button("替换全部数据", role: .destructive) {
                        store.replaceAll(with: AppData(sales: sales, expenses: expenses, settings: store.settings))
                        message = "已导入 \(sales.count + expenses.count) 条记录"
                    }
                case nil:
                    EmptyView()
                }
            } message: {
                Text("替换会删除当前所有收货、销售和支出。")
            }
            .confirmationDialog("清空所有数据？", isPresented: $confirmErase, titleVisibility: .visible) {
                Button("清空", role: .destructive) { store.eraseAll() }
            } message: {
                Text("建议先导出完整备份。此操作无法撤销。")
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("好") {}
            }
        }
    }

    private func exportBackup() {
        do {
            exportDocument = ExportDocument(
                data: try store.encodedBackup(),
                contentType: .json,
                filename: "fintrack_full_\(Day.today).json"
            )
            showExporter = true
        } catch {
            message = "导出失败：\(error.localizedDescription)"
        }
    }

    private func handleImport(_ result: Result<URL, Error>) {
        do {
            let url = try result.get()
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }
            let data = try Data(contentsOf: url)
            let firstByte = data.drop { [0x20, 0x0A, 0x0D, 0x09, 0xEF, 0xBB, 0xBF].contains($0) }.first
            if firstByte == UInt8(ascii: "{") {
                pendingImport = .backup(try AppStore.decoder.decode(AppData.self, from: data))
            } else {
                guard let text = String(data: data, encoding: .utf8) else { throw CSVError.empty }
                let records = LedgerCSV.records(from: try LedgerCSV.parse(text))
                pendingImport = .ledger(sales: records.sales, expenses: records.expenses)
            }
        } catch {
            message = "无法导入：\(error.localizedDescription)"
        }
    }
}
