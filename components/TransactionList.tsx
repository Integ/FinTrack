import React, { useState } from 'react';
import {
    List,
    ListItem,
    ListItemText,
    IconButton,
    Typography,
    Paper,
    Box,
} from '@mui/material';
import {
    Delete as DeleteIcon,
    Edit as EditIcon,
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

    // Split transactions by type for separate display columns
    const sellTransactions = transactions.filter(t => t.type === 'expense');
    const buyTransactions = transactions.filter(t => t.type === 'income');

    return (
        <Paper sx={{
            mt: 2,
            p: 2,
            background: 'linear-gradient(145deg, #1E1E1E 0%, #2A2A2A 100%)',
            borderTop: '1px solid rgba(255, 215, 0, 0.1)',
        }}>
            <Typography variant="h6" gutterBottom sx={{ color: '#FFD700' }}>
                交易记录
            </Typography>

            <Box sx={{ display: 'flex', gap: 2, alignItems: 'flex-start', flexDirection: { xs: 'column', sm: 'row' } }}>
                <Box sx={{ flex: 1, width: { xs: '100%', sm: 'auto' } }}>
                    <Typography variant="subtitle1" sx={{ color: '#FFD700', mb: 1 }}>
                        支出
                    </Typography>
                    <List>
                        {sellTransactions.map((transaction: Transaction) => (
                            <ListItem
                                key={transaction.id}
                                secondaryAction={
                                    <Box>
                                        <IconButton
                                            edge="end"
                                            aria-label="edit"
                                            onClick={() => handleEdit(transaction)}
                                            sx={{ mr: 1 }}
                                        >
                                            <EditIcon />
                                        </IconButton>
                                        <IconButton
                                            edge="end"
                                            aria-label="delete"
                                            onClick={() => handleDelete(transaction.id)}
                                        >
                                            <DeleteIcon />
                                        </IconButton>
                                    </Box>
                                }
                            >
                                <ListItemText
                                    primary={`${transaction.description} - 支出 $${transaction.amount}`}
                                    secondary={`${transaction.date} | ${transaction.category}`}
                                />
                            </ListItem>
                        ))}
                    </List>
                </Box>

                <Box sx={{ flex: 1, width: { xs: '100%', sm: 'auto' } }}>
                    <Typography variant="subtitle1" sx={{ color: '#FFD700', mb: 1 }}>
                        收入
                    </Typography>
                    <List>
                        {buyTransactions.map((transaction: Transaction) => (
                            <ListItem
                                key={transaction.id}
                                secondaryAction={
                                    <Box>
                                        <IconButton
                                            edge="end"
                                            aria-label="edit"
                                            onClick={() => handleEdit(transaction)}
                                            sx={{ mr: 1 }}
                                        >
                                            <EditIcon />
                                        </IconButton>
                                        <IconButton
                                            edge="end"
                                            aria-label="delete"
                                            onClick={() => handleDelete(transaction.id)}
                                        >
                                            <DeleteIcon />
                                        </IconButton>
                                    </Box>
                                }
                            >
                                <ListItemText
                                    primary={`${transaction.description} - 收入 $${transaction.amount}`}
                                    secondary={`${transaction.date} | ${transaction.category}`}
                                />
                            </ListItem>
                        ))}
                    </List>
                </Box>
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