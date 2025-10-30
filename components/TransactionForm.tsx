import React, { useState } from 'react';
import {
    Button,
    Dialog,
    DialogActions,
    DialogContent,
    DialogTitle,
    TextField,
    Select,
    MenuItem,
    FormControl,
    InputLabel,
} from '@mui/material';
import { useDispatch } from 'react-redux';
import { addTransaction, updateTransaction } from '../store/transactionSlice';
import { Transaction } from '../types/transaction';
import { v4 as uuidv4 } from 'uuid';

interface TransactionFormProps {
    open: boolean;
    onClose: () => void;
    editingTransaction?: Transaction;
}

const TransactionForm: React.FC<TransactionFormProps> = ({ open, onClose, editingTransaction }) => {
    const dispatch = useDispatch();
    // Keep amount as string in the form state so we can represent an empty field.
        const [transaction, setTransaction] = useState<{
            date: string;
            type: 'income' | 'expense';
            amount: string;
            cost: string;
            category: string;
            description: string;
        }>({
        date: editingTransaction?.date || new Date().toLocaleDateString('sv-SE'), // 'sv-SE' locale gives YYYY-MM-DD format
        type: editingTransaction?.type || 'expense',
        amount: editingTransaction?.amount !== undefined ? String(editingTransaction.amount) : '0',
        cost: (editingTransaction as any)?.cost !== undefined ? String((editingTransaction as any).cost) : '0',
            category: editingTransaction?.category || '',
            description: editingTransaction?.description || '',
        });

    React.useEffect(() => {
        if (editingTransaction) {
            setTransaction({
                date: editingTransaction.date,
                type: editingTransaction.type,
                amount: String(editingTransaction.amount),
                cost: (editingTransaction as any).cost !== undefined ? String((editingTransaction as any).cost) : '0',
                category: editingTransaction.category,
                description: editingTransaction.description,
            });
        }
    }, [editingTransaction]);

    const handleSubmit = () => {
        const amountNumber = parseFloat(transaction.amount) || 0;

        const costNumber = parseFloat(transaction.cost) || 0;
        const payload: Transaction = {
            id: editingTransaction ? editingTransaction.id : uuidv4(),
            date: transaction.date,
            type: transaction.type,
            amount: amountNumber,
            // Only include cost when meaningful
            ...(transaction.type === 'income' ? { cost: costNumber } : {}),
            category: transaction.category,
            description: transaction.description,
        };

        if (editingTransaction) {
            dispatch(updateTransaction(payload));
        } else {
            dispatch(addTransaction(payload));
        }

        onClose();
    };

    return (
        <Dialog open={open} onClose={onClose}>
            <DialogTitle>{editingTransaction ? '编辑交易' : '新增交易'}</DialogTitle>
            <DialogContent>
                <TextField
                    margin="dense"
                    label="日期"
                    type="date"
                    fullWidth
                    value={transaction.date}
                    onChange={(e) =>
                        setTransaction({ ...transaction, date: e.target.value })
                    }
                    InputLabelProps={{ shrink: true }}
                />
                <FormControl fullWidth margin="dense">
                    <InputLabel id="transaction-type-label">类型</InputLabel>
                    <Select
                        labelId="transaction-type-label"
                        label="类型"
                        value={transaction.type}
                        onChange={(e) =>
                            setTransaction({
                                ...transaction,
                                type: e.target.value as 'income' | 'expense',
                            })
                        }
                    >
                        <MenuItem value="income">收入</MenuItem>
                        <MenuItem value="expense">支出</MenuItem>
                    </Select>
                </FormControl>
                <TextField
                    margin="dense"
                    label="金额"
                    type="number"
                    fullWidth
                    value={transaction.amount}
                    onChange={(e) =>
                        setTransaction({
                            ...transaction,
                            amount: e.target.value,
                        })
                    }
                    onFocus={() => {
                        // If current value is exactly '0', clear it so user can type without deleting
                        if (transaction.amount === '0') {
                            setTransaction({ ...transaction, amount: '' });
                        }
                    }}
                />
                    {/* Show cost input only for income type */}
                    {transaction.type === 'income' && (
                        <TextField
                            margin="dense"
                            label="成本"
                            type="number"
                            fullWidth
                            value={transaction.cost}
                            onChange={(e) =>
                                setTransaction({
                                    ...transaction,
                                    cost: e.target.value,
                                })
                            }
                            onFocus={() => {
                                if (transaction.cost === '0') {
                                    setTransaction({ ...transaction, cost: '' });
                                }
                            }}
                        />
                    )}
                <TextField
                    margin="dense"
                    label="类别"
                    fullWidth
                    value={transaction.category}
                    onChange={(e) =>
                        setTransaction({ ...transaction, category: e.target.value })
                    }
                />
                <TextField
                    margin="dense"
                    label="描述"
                    fullWidth
                    multiline
                    rows={4}
                    value={transaction.description}
                    onChange={(e) =>
                        setTransaction({
                            ...transaction,
                            description: e.target.value,
                        })
                    }
                />
            </DialogContent>
            <DialogActions>
                <Button onClick={onClose}>取消</Button>
                <Button onClick={handleSubmit} variant="contained" color="primary">
                    保存
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default TransactionForm;