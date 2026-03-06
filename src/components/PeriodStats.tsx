import React, { useMemo } from 'react';
import {
    Paper,
    Typography,
    Box,
    Stack,
    Divider,
    LinearProgress,
    Chip,
} from '@mui/material';
import {
    TrendingUp as TrendingUpIcon,
    TrendingDown as TrendingDownIcon,
    DateRange as DateRangeIcon,
    CompareArrows as CompareArrowsIcon,
} from '@mui/icons-material';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';

interface PeriodStatsData {
    income: number;
    expense: number;
    profit: number;
}

const PeriodStats: React.FC = () => {
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );

    const formatLocalDate = (d: Date): string => {
        const year = d.getFullYear();
        const month = String(d.getMonth() + 1).padStart(2, '0');
        const day = String(d.getDate()).padStart(2, '0');
        return `${year}-${month}-${day}`;
    };

    const getTrend = (current: number, baseline: number): number => {
        if (baseline === 0) {
            return current === 0 ? 0 : 100;
        }

        return ((current - baseline) / Math.abs(baseline)) * 100;
    };

    const formatCurrency = (value: number): string => `$${value.toFixed(2)}`;

    const formatTrendText = (value: number): string => {
        const prefix = value > 0 ? '+' : '';
        return `${prefix}${value.toFixed(1)}%`;
    };

    const stats = useMemo(() => {
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        const last7Days: string[] = [];
        const last30Days: string[] = [];

        for (let i = 1; i <= 7; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() - i);
            last7Days.push(formatLocalDate(date));
        }

        for (let i = 1; i <= 30; i++) {
            const date = new Date(today);
            date.setDate(today.getDate() - i);
            last30Days.push(formatLocalDate(date));
        }

        const calculateStats = (dates: string[]): PeriodStatsData => {
            const result: PeriodStatsData = { income: 0, expense: 0, profit: 0 };

            transactions.forEach((transaction: Transaction) => {
                if (dates.includes(transaction.date)) {
                    if (transaction.type === 'income') {
                        result.income += transaction.amount;
                        const cost = transaction.cost || 0;
                        result.expense += cost;
                    } else {
                        result.expense += transaction.amount;
                    }
                }
            });

            result.profit = result.income - result.expense;
            return result;
        };

        return {
            last7Days: calculateStats(last7Days),
            last30Days: calculateStats(last30Days),
        };
    }, [transactions]);

    const normalized7Days = {
        income: stats.last7Days.income / 7,
        expense: stats.last7Days.expense / 7,
        profit: stats.last7Days.profit / 7,
    };

    const normalized30Days = {
        income: stats.last30Days.income / 30,
        expense: stats.last30Days.expense / 30,
        profit: stats.last30Days.profit / 30,
    };

    const compare = {
        income: getTrend(normalized7Days.income, normalized30Days.income),
        expense: getTrend(normalized7Days.expense, normalized30Days.expense),
        profit: getTrend(normalized7Days.profit, normalized30Days.profit),
    };

    const maxReferenceValue = Math.max(
        stats.last7Days.income,
        stats.last7Days.expense,
        Math.abs(stats.last7Days.profit),
        stats.last30Days.income,
        stats.last30Days.expense,
        Math.abs(stats.last30Days.profit),
        1
    );

    const MetricRow: React.FC<{
        label: string;
        sevenDayValue: number;
        thirtyDayValue: number;
        averageDailyValue: number;
        trendValue: number;
        positiveWhenIncrease?: boolean;
    }> = ({
        label,
        sevenDayValue,
        thirtyDayValue,
        averageDailyValue,
        trendValue,
        positiveWhenIncrease = true,
    }) => {
        const trendGood = positiveWhenIncrease ? trendValue >= 0 : trendValue <= 0;

        return (
            <Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                    <Typography variant="body2" sx={{ fontWeight: 600 }}>
                        {label}
                    </Typography>
                    <Typography variant="caption" color="text.secondary">
                        日均 {formatCurrency(averageDailyValue)}
                    </Typography>
                </Box>

                <Stack direction="row" spacing={1.2} sx={{ mb: 1 }}>
                    <Box sx={{ flex: 1, minWidth: 0 }}>
                        <Typography variant="caption" color="text.secondary">
                            最近 7 天
                        </Typography>
                        <Typography variant="body2" sx={{ fontWeight: 600, mt: 0.3 }}>
                            {formatCurrency(sevenDayValue)}
                        </Typography>
                        <LinearProgress
                            variant="determinate"
                            value={(Math.abs(sevenDayValue) / maxReferenceValue) * 100}
                            color={label === '支出' ? 'error' : 'success'}
                            sx={{ mt: 0.6, height: 6, borderRadius: 999 }}
                        />
                    </Box>

                    <Box sx={{ flex: 1, minWidth: 0 }}>
                        <Typography variant="caption" color="text.secondary">
                            最近 30 天
                        </Typography>
                        <Typography variant="body2" sx={{ fontWeight: 600, mt: 0.3 }}>
                            {formatCurrency(thirtyDayValue)}
                        </Typography>
                        <LinearProgress
                            variant="determinate"
                            value={(Math.abs(thirtyDayValue) / maxReferenceValue) * 100}
                            color={label === '支出' ? 'error' : 'success'}
                            sx={{ mt: 0.6, height: 6, borderRadius: 999 }}
                        />
                    </Box>
                </Stack>

                <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
                    <Chip
                        size="small"
                        icon={trendGood ? <TrendingUpIcon /> : <TrendingDownIcon />}
                        label={`趋势 ${formatTrendText(trendValue)}`}
                        color={trendGood ? 'success' : 'error'}
                        variant="outlined"
                    />
                </Box>
            </Box>
        );
    };

    const profitTrendGood = compare.profit >= 0;

    return (
        <Paper sx={{ mt: { xs: 1, sm: 2 }, overflow: 'hidden' }}>
            <Box sx={{ p: { xs: 2, sm: 3 }, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Typography variant="h5" sx={{ fontWeight: 600, mb: 0.8 }}>
                    7 天 / 30 天对比
                </Typography>
                <Stack direction="row" spacing={1} alignItems="center" sx={{ color: 'text.secondary' }}>
                    <DateRangeIcon sx={{ fontSize: 16 }} />
                    <Typography variant="body2">包含今天之前的数据（不含今天）</Typography>
                </Stack>
            </Box>

            <Box sx={{ p: { xs: 2, sm: 3 }, display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box
                    sx={{
                        p: 1.5,
                        border: '1px solid',
                        borderColor: 'divider',
                        borderRadius: 2,
                        backgroundColor: 'rgba(37, 99, 235, 0.08)',
                        display: 'flex',
                        justifyContent: 'space-between',
                        alignItems: 'center',
                        gap: 1.5,
                    }}
                >
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                        <CompareArrowsIcon sx={{ fontSize: 18, color: 'primary.main' }} />
                        <Typography variant="body2">
                            近 7 天净额日均 vs 近 30 天净额日均
                        </Typography>
                    </Box>
                    <Chip
                        size="small"
                        icon={profitTrendGood ? <TrendingUpIcon /> : <TrendingDownIcon />}
                        label={formatTrendText(compare.profit)}
                        color={profitTrendGood ? 'success' : 'error'}
                    />
                </Box>

                <MetricRow
                    label="收入"
                    sevenDayValue={stats.last7Days.income}
                    thirtyDayValue={stats.last30Days.income}
                    averageDailyValue={normalized7Days.income}
                    trendValue={compare.income}
                    positiveWhenIncrease
                />

                <Divider />

                <MetricRow
                    label="支出"
                    sevenDayValue={stats.last7Days.expense}
                    thirtyDayValue={stats.last30Days.expense}
                    averageDailyValue={normalized7Days.expense}
                    trendValue={compare.expense}
                    positiveWhenIncrease={false}
                />

                <Divider />

                <MetricRow
                    label="净额"
                    sevenDayValue={stats.last7Days.profit}
                    thirtyDayValue={stats.last30Days.profit}
                    averageDailyValue={normalized7Days.profit}
                    trendValue={compare.profit}
                    positiveWhenIncrease
                />
            </Box>
        </Paper>
    );
};

export default PeriodStats;
