export type Language = 'zh' | 'en';

export interface Translations {
    header: {
        subtitle: string;
        import: string;
        export: string;
    };
    summary: {
        title: string;
        totalIncome: string;
        netProfit: string;
        totalCosts: string;
        totalExpense: string;
    };
    form: {
        newTransaction: string;
        editTransaction: string;
        date: string;
        transactionType: string;
        income: string;
        expense: string;
        amount: string;
        cost: string;
        costHelper: string;
        category: string;
        categoryPlaceholder: string;
        description: string;
        descriptionPlaceholder: string;
        cancel: string;
        save: string;
        update: string;
    };
    list: {
        title: string;
        totalRecords: string;
        showingRecords: string;
        filterAll: string;
        filterIncome: string;
        filterExpense: string;
        searchPlaceholder: string;
        noRecords: string;
        noRecordsHint: string;
        cost: string;
        edit: string;
        delete: string;
    };
    stats: {
        title: string;
        daily: string;
        dailySubtitle: string;
        last7Days: string;
        last7DaysSubtitle: string;
        last30Days: string;
        last30DaysSubtitle: string;
        totalSales: string;
        netAmount: string;
        dailyAverage: string;
        totalCosts: string;
        costNote: string;
        totalExpense: string;
        expenseNote: string;
        reportDetail: string;
        transactions: string;
        grossSales: string;
        costOfGoods: string;
        extraExpense: string;
        totalExpenseLabel: string;
        netSales: string;
        averageSales: string;
        averageNet: string;
        incomeCount: string;
        expenseCount: string;
    };
    footer: {
        description: string;
        localStorage: string;
        csvImportExport: string;
        copyright: string;
    };
}

export const translations: Record<Language, Translations> = {
    zh: {
        header: {
            subtitle: '副业收入记录',
            import: '导入',
            export: '导出',
        },
        summary: {
            title: '财务概览',
            totalIncome: '总收入',
            netProfit: '净利润',
            totalCosts: '总成本',
            totalExpense: '总支出',
        },
        form: {
            newTransaction: '新增交易',
            editTransaction: '编辑交易',
            date: '日期',
            transactionType: '交易类型',
            income: '收入',
            expense: '支出',
            amount: '金额',
            cost: '成本',
            costHelper: '可选：记录与收入相关的成本',
            category: '类别',
            categoryPlaceholder: '例如：工资、餐饮、交通等',
            description: '描述',
            descriptionPlaceholder: '添加详细描述...',
            cancel: '取消',
            save: '保存',
            update: '更新',
        },
        list: {
            title: '交易记录',
            totalRecords: '共 {total} 笔，当前显示 {showing} 笔',
            filterAll: '全部',
            filterIncome: '收入',
            filterExpense: '支出',
            searchPlaceholder: '搜索描述/类别',
            noRecords: '没有匹配的记录',
            noRecordsHint: '可以调整筛选条件，或点击右下角按钮新增交易',
            cost: '成本:',
            edit: '编辑',
            delete: '删除',
        },
        stats: {
            title: '销售报告',
            daily: '今日',
            dailySubtitle: '今天的营业统计',
            last7Days: '最近7天',
            last7DaysSubtitle: '含今天在内最近 7 天',
            last30Days: '最近30天',
            last30DaysSubtitle: '含今天在内最近 30 天',
            totalSales: '总销售额',
            netAmount: '净额',
            dailyAverage: '日均',
            totalCosts: '总成本',
            costNote: '收入记录关联成本',
            totalExpense: '总支出',
            expenseNote: '成本 + 支出',
            reportDetail: '报告明细',
            transactions: '笔',
            grossSales: '总销售额',
            costOfGoods: '商品成本',
            extraExpense: '额外支出',
            totalExpenseLabel: '总支出',
            netSales: '净额',
            averageSales: '日均销售额',
            averageNet: '日均净额',
            incomeCount: '收入',
            expenseCount: '支出',
        },
        footer: {
            description: '简洁记录每一笔收支，清楚掌握现金流。',
            localStorage: '本地存储',
            csvImportExport: 'CSV 导入/导出',
            copyright: '©',
        },
    },
    en: {
        header: {
            subtitle: 'Side Income Tracker',
            import: 'Import',
            export: 'Export',
        },
        summary: {
            title: 'Financial Overview',
            totalIncome: 'Total Income',
            netProfit: 'Net Profit',
            totalCosts: 'Total Costs',
            totalExpense: 'Total Expenses',
        },
        form: {
            newTransaction: 'New Transaction',
            editTransaction: 'Edit Transaction',
            date: 'Date',
            transactionType: 'Type',
            income: 'Income',
            expense: 'Expense',
            amount: 'Amount',
            cost: 'Cost',
            costHelper: 'Optional: record costs associated with income',
            category: 'Category',
            categoryPlaceholder: 'e.g., Salary, Food, Transport',
            description: 'Description',
            descriptionPlaceholder: 'Add details...',
            cancel: 'Cancel',
            save: 'Save',
            update: 'Update',
        },
        list: {
            title: 'Transactions',
            totalRecords: '{total} total, showing {showing}',
            filterAll: 'All',
            filterIncome: 'Income',
            filterExpense: 'Expense',
            searchPlaceholder: 'Search description/category',
            noRecords: 'No matching records',
            noRecordsHint: 'Adjust filters or click the button below to add a new transaction',
            cost: 'Cost:',
            edit: 'Edit',
            delete: 'Delete',
        },
        stats: {
            title: 'Sales Report',
            daily: 'Today',
            dailySubtitle: "Today's statistics",
            last7Days: 'Last 7 Days',
            last7DaysSubtitle: 'Including today, last 7 days',
            last30Days: 'Last 30 Days',
            last30DaysSubtitle: 'Including today, last 30 days',
            totalSales: 'Total Sales',
            netAmount: 'Net Amount',
            dailyAverage: 'Daily Avg',
            totalCosts: 'Total Costs',
            costNote: 'Costs linked to income',
            totalExpense: 'Total Expense',
            expenseNote: 'Costs + Expenses',
            reportDetail: 'Report Details',
            transactions: 'transactions',
            grossSales: 'Gross Sales',
            costOfGoods: 'Cost of Goods',
            extraExpense: 'Extra Expense',
            totalExpenseLabel: 'Total Expense',
            netSales: 'Net Sales',
            averageSales: 'Avg Sales',
            averageNet: 'Avg Net',
            incomeCount: 'Income',
            expenseCount: 'Expense',
        },
        footer: {
            description: 'Track every income and expense clearly.',
            localStorage: 'Local Storage',
            csvImportExport: 'CSV Import/Export',
            copyright: '©',
        },
    },
};