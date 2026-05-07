import React, { useMemo, useState } from 'react';
import {
    Paper,
    Typography,
    Box,
    Stack,
    Divider,
    Chip,
    Tabs,
    Tab,
    Grid,
} from '@mui/material';
import {
    TrendingUp as TrendingUpIcon,
    TrendingDown as TrendingDownIcon,
    Today as TodayIcon,
    DateRange as DateRangeIcon,
    CalendarMonth as CalendarMonthIcon,
    ReceiptLong as ReceiptLongIcon,
    Payments as PaymentsIcon,
    PointOfSale as PointOfSaleIcon,
    Savings as SavingsIcon,
} from '@mui/icons-material';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';
import { useLanguage } from '../i18n/LanguageContext';

type ReportTab = 'daily' | 'last7Days' | 'last30Days';

interface PeriodStatsData {
    income: number;
    costs: number;
    expense: number;
    totalExpense: number;
    profit: number;
    transactionCount: number;
    incomeCount: number;
    expenseCount: number;
}

const PeriodStats: React.FC = () => {
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );
    const { t } = useLanguage();
    const [activeTab, setActiveTab] = useState<ReportTab>('daily');

    const formatLocalDate = (d: Date): string => {
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    };

    const formatCurrency = (value: number): string => `$${value.toFixed(2)}`;

    const stats = useMemo(() => {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const daily: string[] = [formatLocalDate(today)];
        const last7Days: string[] = [];
        const last30Days: string[] = [];

        for (let i = 0; i < 7; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() - i);
            last7Days.push(formatLocalDate(date));
        }

        for (let i = 0; i < 30; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() - i);
            last30Days.push(formatLocalDate(date));
        }

        const calculateStats = (dates: string[]): PeriodStatsData => {
            const dateSet = new Set(dates);
            const result: PeriodStatsData = {
                income: 0,
                costs: 0,
                expense: 0,
                totalExpense: 0,
                profit: 0,
                transactionCount: 0,
                incomeCount: 0,
                expenseCount: 0,
            };

            transactions.forEach((transaction: Transaction) => {
                if (dateSet.has(transaction.date)) {
                    result.transactionCount += 1;

                    if (transaction.type === 'income') {
                        result.incomeCount += 1;
                        result.income += transaction.amount;
                        result.costs += transaction.cost || 0;
                    } else {
                        result.expenseCount += 1;
                        result.expense += transaction.amount;
                    }
                }
            });

            result.totalExpense = result.costs + result.expense;
            result.profit = result.income - result.totalExpense;
            return result;
        };

        return {
            daily: calculateStats(daily),
            last7Days: calculateStats(last7Days),
            last30Days: calculateStats(last30Days),
        };
    }, [transactions]);

    const reportConfig: Record<ReportTab, {
        label: string;
        subtitle: string;
        days: number;
        icon: React.ReactElement;
    }> = {
        daily: {
            label: t.stats.daily,
            subtitle: t.stats.dailySubtitle,
            days: 1,
            icon: <TodayIcon sx={{ fontSize: 16 }} />,
        },
        last7Days: {
            label: t.stats.last7Days,
            subtitle: t.stats.last7DaysSubtitle,
            days: 7,
            icon: <DateRangeIcon sx={{ fontSize: 16 }} />,
        },
        last30Days: {
            label: t.stats.last30Days,
            subtitle: t.stats.last30DaysSubtitle,
            days: 30,
            icon: <CalendarMonthIcon sx={{ fontSize: 16 }} />,
        },
    };

    const currentReport = stats[activeTab];
    const currentConfig = reportConfig[activeTab];
    const reportTabs: ReportTab[] = ['daily', 'last7Days', 'last30Days'];
    const averageNet = currentReport.profit / currentConfig.days;
    const averageSales = currentReport.income / currentConfig.days;
    const handleTabChange = (_: React.SyntheticEvent, value: unknown) => {
        if (value === 'daily' || value === 'last7Days' || value === 'last30Days') {
            setActiveTab(value);
        }
    };

    const SummaryTile: React.FC<{
        label: string;
        value: string;
        icon: React.ReactNode;
        color: string;
        helper?: string;
    }> = ({ label, value, icon, color, helper }) => (
        <Grid item xs={12} sm={6}>
            <Box
                sx={{
                    p: 1.5,
                    height: '100%',
                    border: '1px solid',
                    borderColor: 'divider',
                    borderRadius: 1,
                    backgroundColor: 'background.paper',
                }}
            >
                <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1 }}>
                    <Box
                        sx={{
                            width: 30,
                            height: 30,
                            borderRadius: 1,
                            display: 'flex',
                            alignItems: 'center',
                            justifyContent: 'center',
                            color,
                            backgroundColor: `${color}18`,
                        }}
                    >
                        {icon}
                    </Box>
                    <Typography variant="caption" color="text.secondary" sx={{ fontWeight: 600 }}>
                        {label}
                    </Typography>
                </Stack>
                <Typography
                    variant="h6"
                    sx={{
                        fontWeight: 700,
                        color,
                        overflowWrap: 'anywhere',
                        lineHeight: 1.2,
                    }}
                >
                    {value}
                </Typography>
                {helper && (
                    <Typography variant="caption" color="text.secondary">
                        {helper}
                    </Typography>
                )}
            </Box>
        </Grid>
    );

    const DetailRow: React.FC<{ label: string; value: string; tone?: 'success' | 'error' | 'warning' }> = ({
        label,
        value,
        tone,
    }) => (
        <Box sx={{ display: 'flex', justifyContent: 'space-between', gap: 1.5 }}>
            <Typography variant="body2" color="text.secondary">
                {label}
            </Typography>
            <Typography
                variant="body2"
                sx={{
                    fontWeight: 600,
                    color: tone ? `${tone}.main` : 'text.primary',
                    textAlign: 'right',
                    overflowWrap: 'anywhere',
                }}
            >
                {value}
            </Typography>
        </Box>
    );

    return (
        <Paper sx={{ mt: { xs: 1, sm: 2 }, overflow: 'hidden' }}>
            <Box sx={{ p: { xs: 2, sm: 3 }, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Typography variant="h5" sx={{ fontWeight: 600, mb: 0.8 }}>
                    {t.stats.title}
                </Typography>
                <Stack direction="row" spacing={1} alignItems="center" sx={{ color: 'text.secondary' }}>
                    {currentConfig.icon}
                    <Typography variant="body2">{currentConfig.subtitle}</Typography>
                </Stack>
            </Box>

            <Tabs
                value={activeTab}
                onChange={handleTabChange}
                variant="scrollable"
                scrollButtons="auto"
                sx={{
                    minHeight: 44,
                    px: { xs: 1, sm: 2 },
                    borderBottom: '1px solid',
                    borderColor: 'divider',
                    '& .MuiTab-root': {
                        minHeight: 44,
                        textTransform: 'none',
                        fontWeight: 600,
                    },
                }}
            >
                {reportTabs.map((value) => (
                    <Tab
                        key={value}
                        value={value}
                        label={reportConfig[value].label}
                        icon={reportConfig[value].icon}
                        iconPosition="start"
                    />
                ))}
            </Tabs>

            <Box sx={{ p: { xs: 2, sm: 3 }, display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Grid container spacing={1.5}>
                    <SummaryTile
                        label={t.stats.totalSales}
                        value={formatCurrency(currentReport.income)}
                        icon={<PointOfSaleIcon fontSize="small" />}
                        color="#2e7d32"
                        helper={`${currentReport.incomeCount} ${t.stats.incomeCount}`}
                    />
                    <SummaryTile
                        label={t.stats.netAmount}
                        value={formatCurrency(currentReport.profit)}
                        icon={currentReport.profit >= 0 ? <TrendingUpIcon fontSize="small" /> : <TrendingDownIcon fontSize="small" />}
                        color={currentReport.profit >= 0 ? '#2e7d32' : '#d32f2f'}
                        helper={`${t.stats.dailyAverage} ${formatCurrency(averageNet)}`}
                    />
                    <SummaryTile
                        label={t.stats.totalCosts}
                        value={formatCurrency(currentReport.costs)}
                        icon={<SavingsIcon fontSize="small" />}
                        color="#ed6c02"
                        helper={t.stats.costNote}
                    />
                    <SummaryTile
                        label={t.stats.totalExpense}
                        value={formatCurrency(currentReport.totalExpense)}
                        icon={<PaymentsIcon fontSize="small" />}
                        color="#d32f2f"
                        helper={`${t.stats.expenseNote} ${currentReport.expenseCount}`}
                    />
                </Grid>

                <Box
                    sx={{
                        p: 1.5,
                        border: '1px solid',
                        borderColor: 'divider',
                        borderRadius: 1,
                        backgroundColor: 'rgba(46, 125, 50, 0.06)',
                    }}
                >
                    <Stack direction="row" spacing={1} alignItems="center" sx={{ mb: 1.2 }}>
                        <ReceiptLongIcon sx={{ fontSize: 18, color: 'primary.main' }} />
                        <Typography variant="body2" sx={{ fontWeight: 700 }}>
                            {t.stats.reportDetail}
                        </Typography>
                        <Chip size="small" label={`${currentReport.transactionCount} ${t.stats.transactions}`} variant="outlined" />
                    </Stack>
                    <Stack spacing={1}>
                        <DetailRow label={t.stats.grossSales} value={formatCurrency(currentReport.income)} tone="success" />
                        <DetailRow label={t.stats.costOfGoods} value={formatCurrency(currentReport.costs)} tone="warning" />
                        <DetailRow label={t.stats.extraExpense} value={formatCurrency(currentReport.expense)} tone="error" />
                        <Divider />
                        <DetailRow label={t.stats.totalExpenseLabel} value={formatCurrency(currentReport.totalExpense)} tone="error" />
                        <DetailRow label={t.stats.netSales} value={formatCurrency(currentReport.profit)} tone={currentReport.profit >= 0 ? 'success' : 'error'} />
                        <Divider />
                        <DetailRow label={t.stats.averageSales} value={formatCurrency(averageSales)} />
                        <DetailRow label={t.stats.averageNet} value={formatCurrency(averageNet)} />
                    </Stack>
                </Box>

                <Box sx={{ display: 'flex', justifyContent: 'space-between', gap: 1, flexWrap: 'wrap' }}>
                    <Chip
                        size="small"
                        label={`${t.stats.incomeCount} ${currentReport.incomeCount}`}
                        color="success"
                        variant="outlined"
                    />
                    <Chip
                        size="small"
                        label={`${t.stats.expenseCount} ${currentReport.expenseCount}`}
                        color="error"
                        variant="outlined"
                    />
                </Box>
            </Box>
        </Paper>
    );
};

export default PeriodStats;
