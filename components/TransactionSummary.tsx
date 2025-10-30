import React from 'react';
import { Box, Paper, Typography } from '@mui/material';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';

interface Summary {
    totalIncome: number;
    totalExpense: number;
    revenue: number;
    costs: number;
    profit: number;
}

interface SummaryItemProps {
    title: string;
    value: number;
    color?: string;
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
                // expense transactions are also part of overall costs
                acc.costs += transaction.amount;
            }
            // profit = total income - total costs
            acc.profit = acc.totalIncome - acc.costs;
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

    const SummaryItem: React.FC<SummaryItemProps> = ({ title, value, color = 'inherit' }) => (
        <Box sx={{ flex: 1, minWidth: 200, m: 1 }}>
            <Paper
                sx={{
                    p: 2,
                    display: 'flex',
                    flexDirection: 'column',
                    alignItems: 'center',
                    background: 'linear-gradient(145deg, #1E1E1E 0%, #2A2A2A 100%)',
                    borderTop: '1px solid rgba(255, 215, 0, 0.1)',
                    '&:hover': {
                        boxShadow: '0 4px 12px rgba(255, 215, 0, 0.2)',
                        transition: 'all 0.3s ease-in-out',
                    },
                }}
            >
                <Typography variant="h6" gutterBottom>
                    {title}
                </Typography>
                <Typography
                    variant="h4"
                    color={color}
                >{`$${value.toFixed(2)}`}</Typography>
            </Paper>
        </Box>
    );

    return (
        <Box sx={{ mb: 3 }}>
            {/* First row: 总收入/总支出 */}
            <Box sx={{ display: 'flex', flexWrap: 'wrap', mb: 2 }}>
                <SummaryItem title="总收入" value={summary.totalIncome} color="success.main" />
                <SummaryItem title="总支出" value={summary.totalExpense} color="error.main" />
            </Box>
            {/* Second row: 成本/利润 */}
            <Box sx={{ display: 'flex', flexWrap: 'wrap' }}>
                <SummaryItem
                    title="成本"
                    value={summary.costs}
                    color="warning.main"
                />
                <SummaryItem
                    title="利润"
                    value={summary.profit}
                    color={summary.profit >= 0 ? 'success.main' : 'error.main'}
                />
            </Box>
        </Box>
    );
};

export default TransactionSummary;