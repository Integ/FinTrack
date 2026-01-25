import React from 'react';
import { Box, Paper, Typography, Grid } from '@mui/material';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';
import { TrendingUp as TrendingUpIcon, TrendingDown as TrendingDownIcon, TrackChanges as TargetIcon } from '@mui/icons-material';

interface Summary {
    totalIncome: number;
    totalExpense: number;
    revenue: number;
    costs: number;
    profit: number;
}

const TransactionSummary: React.FC = () => {
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );

    const summary = transactions.reduce<Summary>(
        (acc: Summary, transaction: Transaction) => {
            if (transaction.type === 'income') {
                acc.totalIncome += transaction.amount;
                // If this income has an associated cost, add it to costs
                if ((transaction as any).cost !== undefined) {
                    acc.costs += (transaction as any).cost || 0;
                }
            } else {
                acc.totalExpense += transaction.amount;
            }
            // profit = total income - total costs
            acc.profit = acc.totalIncome - acc.costs - acc.totalExpense;
            return acc;
        },
        {
            totalIncome: 0,
            totalExpense: 0,
            revenue: 0, // kept for type compatibility though not used in UI
            costs: 0,
            profit: 0,
        }
    );

    const SummaryCard: React.FC<{ 
        title: string; 
        value: number; 
        color: string; 
        icon: React.ReactNode;
        trend?: number;
    }> = ({ title, value, color, icon, trend }) => (
        <Paper
            sx={{
                p: 3,
                height: '100%',
                display: 'flex',
                flexDirection: 'column',
                position: 'relative',
                overflow: 'hidden',
                transition: 'all 0.2s ease-in-out',
                '&:hover': {
                    transform: 'translateY(-2px)',
                    boxShadow: '0 8px 16px rgba(0, 0, 0, 0.1)',
                },
            }}
        >
            <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Box sx={{ 
                    p: 1, 
                    borderRadius: 1, 
                    backgroundColor: `${color}15`,
                    color: color,
                    mr: 2
                }}>
                    {icon}
                </Box>
                <Typography variant="body2" color="text.secondary">
                    {title}
                </Typography>
            </Box>
            
            <Typography 
                variant="h4" 
                sx={{ 
                    fontWeight: 600,
                    color: color,
                    mb: trend !== undefined ? 1 : 0
                }}
            >
                ${value.toFixed(2)}
            </Typography>
            
            {trend !== undefined && (
                <Box sx={{ display: 'flex', alignItems: 'center', mt: 'auto' }}>
                    {trend > 0 ? (
                        <TrendingUpIcon sx={{ fontSize: 16, color: 'success.main', mr: 0.5 }} />
                    ) : (
                        <TrendingDownIcon sx={{ fontSize: 16, color: 'error.main', mr: 0.5 }} />
                    )}
                    <Typography variant="caption" color="text.secondary">
                        {Math.abs(trend).toFixed(1)}%
                    </Typography>
                </Box>
            )}
        </Paper>
    );

    return (
        <Box sx={{ mb: 4 }}>
            <Typography variant="h4" sx={{ mb: 3, fontWeight: 600 }}>
                财务概览
            </Typography>
            
            <Grid container spacing={2}>
                <Grid item xs={12} sm={6} md={3}>
                    <SummaryCard
                        title="总收入"
                        value={summary.totalIncome}
                        color="success.main"
                        icon={<TrendingUpIcon />}
                    />
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                    <SummaryCard
                        title="净利润"
                        value={summary.profit}
                        color={summary.profit >= 0 ? 'success.main' : 'error.main'}
                        icon={summary.profit >= 0 ? <TrendingUpIcon /> : <TrendingDownIcon />}
                    />
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                    <SummaryCard
                        title="总成本"
                        value={summary.costs}
                        color="warning.main"
                        icon={<TargetIcon />}
                    />
                </Grid>
                <Grid item xs={12} sm={6} md={3}>
                    <SummaryCard
                        title="总支出"
                        value={summary.totalExpense}
                        color="error.main"
                        icon={<TrendingDownIcon />}
                    />
                </Grid>
            </Grid>
        </Box>
    );
};

export default TransactionSummary;