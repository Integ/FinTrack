import React, { useMemo } from 'react';
import { Paper, Typography, Box, Grid, Divider } from '@mui/material';
import { TrendingUp as TrendingUpIcon, TrendingDown as TrendingDownIcon } from '@mui/icons-material';
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

    const StatItem: React.FC<{
        label: string;
        value: number;
        color: string;
        icon: React.ReactNode;
    }> = ({ label, value, color, icon }) => (
        <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
                <Box sx={{ 
                    p: 0.75, 
                    borderRadius: 1, 
                    backgroundColor: `${color}15`,
                    color: color,
                    mr: 1.5,
                    display: 'flex',
                    alignItems: 'center',
                    justifyContent: 'center'
                }}>
                    {icon}
                </Box>
                <Typography variant="body2" color="text.secondary">
                    {label}
                </Typography>
            </Box>
            <Typography variant="h6" sx={{ fontWeight: 600, color: color }}>
                ${value.toFixed(2)}
            </Typography>
        </Box>
    );

    const PeriodCard: React.FC<{
        title: string;
        subtitle: string;
        stats: PeriodStatsData;
    }> = ({ title, subtitle, stats }) => (
        <Paper sx={{ p: { xs: 2, sm: 3 }, height: '100%' }}>
            <Typography variant="h6" sx={{ fontWeight: 600, mb: 0.5, fontSize: { xs: '1rem', sm: '1.25rem' } }}>
                {title}
            </Typography>
            <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                {subtitle}
            </Typography>

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 1.5 }}>
                <StatItem
                    label="收入"
                    value={stats.income}
                    color="success.main"
                    icon={<TrendingUpIcon sx={{ fontSize: 16 }} />}
                />
                <StatItem
                    label="支出"
                    value={stats.expense}
                    color="error.main"
                    icon={<TrendingDownIcon sx={{ fontSize: 16 }} />}
                />
                <Divider sx={{ my: 0.5 }} />
                <StatItem
                    label="收支差额"
                    value={stats.profit}
                    color={stats.profit >= 0 ? 'success.main' : 'error.main'}
                    icon={stats.profit >= 0 
                        ? <TrendingUpIcon sx={{ fontSize: 16 }} /> 
                        : <TrendingDownIcon sx={{ fontSize: 16 }} />
                    }
                />
            </Box>
        </Paper>
    );

    return (
        <Paper sx={{ mt: { xs: 1, sm: 2 }, overflow: 'hidden' }}>
            <Box sx={{ p: { xs: 2, sm: 3 }, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Typography variant="h5" sx={{ fontWeight: 600, mb: 0.5 }}>
                    收支统计
                </Typography>
                <Typography variant="body2" color="text.secondary">
                    最近7天 vs 最近30天
                </Typography>
            </Box>

            <Box sx={{ p: { xs: 2, sm: 3 } }}>
                <Grid container spacing={2}>
                    <Grid item xs={12} md={6}>
                        <PeriodCard
                            title="最近7天"
                            subtitle="过去7天的收支情况"
                            stats={stats.last7Days}
                        />
                    </Grid>
                    <Grid item xs={12} md={6}>
                        <PeriodCard
                            title="最近30天"
                            subtitle="过去30天的收支情况"
                            stats={stats.last30Days}
                        />
                    </Grid>
                </Grid>
            </Box>
        </Paper>
    );
};

export default PeriodStats;
