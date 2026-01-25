export interface Transaction {
    id: string;
    date: string;
    type: 'income' | 'expense';
    amount: number;
    // 可选的成本字段，仅在 type === 'income' 时使用
    cost?: number;
    category: string;
    description: string;
}

export interface TransactionSummary {
    totalIncome: number;
    totalExpense: number;
    revenue: number;
    costs: number;
    profit: number;
}