import SwiftUI

struct ExpenseEditor: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let expenseID: UUID?

    @State private var loaded = false
    @State private var amount = ""
    @State private var category = Defaults.transportCategory
    @State private var day = Date()
    @State private var note = ""
    @State private var confirmDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    MoneyField(title: "金额", text: $amount)
                    if category == Defaults.transportCategory {
                        ChipRow(options: store.recentTransportAmounts.map(\.plainString), selected: amount) { amount = $0 }
                    }
                    DatePicker("日期", selection: $day, in: ...Date(), displayedComponents: .date)
                }
                Section("类别") {
                    ChipRow(options: store.expenseCategories, selected: category) { category = $0 }
                    TextField("类别", text: $category)
                }
                Section {
                    TextField("备注", text: $note, axis: .vertical)
                } footer: {
                    Text("进货的钱不用在这里记：收货时填的进价会自动算进成本。")
                }
                if expenseID != nil {
                    Section {
                        Button("删除这笔支出", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .navigationTitle(expenseID == nil ? "记支出" : "编辑支出")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled((Decimal(userInput: amount) ?? 0) <= 0 || category.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .confirmationDialog("删除这笔支出？", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("删除", role: .destructive) {
                    if let expenseID { store.deleteExpense(expenseID) }
                    dismiss()
                }
            }
            .onAppear(perform: load)
        }
    }

    private func load() {
        guard !loaded else { return }
        loaded = true
        if let expenseID, let expense = store.expense(expenseID) {
            amount = expense.amount.plainString
            category = expense.category
            day = expense.day.date
            note = expense.note
        } else {
            category = store.expenseCategories.first ?? Defaults.transportCategory
            if category == Defaults.transportCategory, let fare = store.recentTransportAmounts.first {
                amount = fare.plainString
            }
        }
    }

    private func save() {
        guard let value = Decimal(userInput: amount) else { return }
        var expense = expenseID.flatMap(store.expense) ?? Expense(day: Day(day), amount: value, category: category)
        expense.day = Day(day)
        expense.amount = value
        expense.category = category.trimmingCharacters(in: .whitespaces)
        expense.note = note.trimmingCharacters(in: .whitespaces)
        store.saveExpense(expense)
        dismiss()
    }
}
