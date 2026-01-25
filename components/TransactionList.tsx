import React, { useState } from 'react';
import {
    List,
    ListItem,
    IconButton,
    Typography,
    Paper,
    Box,
    Chip,
    Tooltip,
    Divider,
    Grid,
} from '@mui/material';
import {
    Delete as DeleteIcon,
    Edit as EditIcon,
    TrendingUp as TrendingUpIcon,
    TrendingDown as TrendingDownIcon,
} from '@mui/icons-material';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../store';
import { deleteTransaction } from '../store/transactionSlice';
import { Transaction } from '../types/transaction';
import TransactionForm from './TransactionForm';

const TransactionList: React.FC = () => {
    const dispatch = useDispatch();
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );
    const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);

    const handleDelete = (id: string) => {
        dispatch(deleteTransaction(id));
    };

    const handleEdit = (transaction: Transaction) => {
        setEditingTransaction(transaction);
    };

    const handleCloseEdit = () => {
        setEditingTransaction(null);
    };

    // Sort transactions by date (newest first)
    const sortedTransactions = [...transactions].sort((a, b) => 
        new Date(b.date).getTime() - new Date(a.date).getTime()
    );

    const TransactionItem: React.FC<{ transaction: Transaction }> = ({ transaction }) => {
        const isIncome = transaction.type === 'income';
        
        return (
            <Box
                sx={{
                    p: 2,
                    border: '1px solid',
                    borderColor: 'divider',
                    borderRadius: 2,
                    mb: 2,
                    transition: 'all 0.2s ease-in-out',
                    '&:hover': {
                        borderColor: 'primary.main',
                        transform: 'translateX(4px)',
                    },
                }}
            >
                <Grid container spacing={2} alignItems="center">
                    <Grid item>
                        <Box
                            sx={{
                                p: 1,
                                borderRadius: 1,
                                backgroundColor: isIncome ? 'success.main' : 'error.main',
                                color: 'background.paper',
                            }}
                        >
                            {isIncome ? <TrendingUpIcon /> : <TrendingDownIcon />}
                        </Box>
                    </Grid>
                    
                    <Grid item xs>
                        <Typography variant="body1" sx={{ fontWeight: 500 }}>
                            {transaction.description}
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 1, mt: 0.5, alignItems: 'center' }}>
                            <Chip
                                label={transaction.category}
                                size="small"
                                variant="outlined"
                                sx={{ fontSize: '0.75rem' }}
                            />
                            <Typography variant="caption" color="text.secondary">
                                {transaction.date}
                            </Typography>
                            {(transaction as any).cost && (
                                <Typography variant="caption" color="warning.main">
                                    成本: ${(transaction as any).cost.toFixed(2)}
                                </Typography>
                            )}
                        </Box>
                    </Grid>
                    
                    <Grid item>
                        <Typography
                            variant="h6"
                            color={isIncome ? 'success.main' : 'error.main'}
                            sx={{ fontWeight: 600 }}
                        >
                            {isIncome ? '+' : '-'}${transaction.amount.toFixed(2)}
                        </Typography>
                    </Grid>
                    
                    <Grid item>
                        <Box sx={{ display: 'flex', gap: 0.5 }}>
                            <Tooltip title="编辑">
                                <IconButton
                                    size="small"
                                    onClick={() => handleEdit(transaction)}
                                    sx={{ color: 'text.secondary' }}
                                >
                                    <EditIcon fontSize="small" />
                                </IconButton>
                            </Tooltip>
                            <Tooltip title="删除">
                                <IconButton
                                    size="small"
                                    onClick={() => handleDelete(transaction.id)}
                                    sx={{ color: 'text.secondary' }}
                                >
                                    <DeleteIcon fontSize="small" />
                                </IconButton>
                            </Tooltip>
                        </Box>
                    </Grid>
                </Grid>
            </Box>
        );
    };

    return (
        <Paper sx={{ mt: 2, p: 0, overflow: 'hidden' }}>
            <Box sx={{ p: 3, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Typography variant="h4" sx={{ fontWeight: 600 }}>
                    交易记录
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                    共 {transactions.length} 笔交易
                </Typography>
            </Box>
            
            <Box sx={{ p: 3, maxHeight: 600, overflowY: 'auto' }}>
                {sortedTransactions.length === 0 ? (
                    <Box sx={{ textAlign: 'center', py: 8 }}>
                        <Typography variant="body1" color="text.secondary">
                            暂无交易记录
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                            点击右下角的添加按钮开始记录您的第一笔交易
                        </Typography>
                    </Box>
                ) : (
                    sortedTransactions.map((transaction) => (
                        <TransactionItem key={transaction.id} transaction={transaction} />
                    ))
                )}
            </Box>

            {editingTransaction && (
                <TransactionForm
                    open={true}
                    onClose={handleCloseEdit}
                    editingTransaction={editingTransaction}
                />
            )}
        </Paper>
    );
};

export default TransactionList;