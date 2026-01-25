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
    Box,
    Typography,
    Grid,
    Tabs,
    Tab,
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
        date: editingTransaction?.date || new Date().toLocaleDateString('sv-SE'),
        type: editingTransaction?.type || 'expense',
        amount: editingTransaction?.amount !== undefined ? String(editingTransaction.amount) : '',
        cost: (editingTransaction as any)?.cost !== undefined ? String((editingTransaction as any).cost) : '',
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
        <Dialog 
            open={open} 
            onClose={onClose}
            maxWidth="sm"
            fullWidth
            PaperProps={{
                sx: { borderRadius: 3 }
            }}
        >
            <DialogTitle sx={{ pb: 1 }}>
                <Typography variant="h4" component="div" sx={{ fontWeight: 600 }}>
                    {editingTransaction ? '编辑交易' : '新增交易'}
                </Typography>
            </DialogTitle>
            
            <DialogContent sx={{ pt: 1 }}>
                <Grid container spacing={3}>
                    <Grid item xs={12}>
                        <TextField
                            label="日期"
                            type="date"
                            fullWidth
                            value={transaction.date}
                            onChange={(e) =>
                                setTransaction({ ...transaction, date: e.target.value })
                            }
                            InputLabelProps={{ shrink: true }}
                            variant="outlined"
                        />
                    </Grid>
                    
                    <Grid item xs={12}>
                        <FormControl fullWidth variant="outlined">
                            <InputLabel>交易类型</InputLabel>
                            <Select
                                label="交易类型"
                                value={transaction.type}
                                onChange={(e) =>
                                    setTransaction({
                                        ...transaction,
                                        type: e.target.value as 'income' | 'expense',
                                    })
                                }
                            >
                                <MenuItem value="income">
                                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                        <Typography color="success.main" sx={{ mr: 1 }}>+</Typography>
                                        收入
                                    </Box>
                                </MenuItem>
                                <MenuItem value="expense">
                                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                        <Typography color="error.main" sx={{ mr: 1 }}>-</Typography>
                                        支出
                                    </Box>
                                </MenuItem>
                            </Select>
                        </FormControl>
                    </Grid>
                    
                    <Grid item xs={12} md={transaction.type === 'income' ? 6 : 12}>
                        <TextField
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
                            variant="outlined"
                            InputProps={{
                                startAdornment: (
                                    <Typography sx={{ mr: 1, color: 'text.secondary' }}>$</Typography>
                                ),
                            }}
                        />
                    </Grid>
                    
                    {transaction.type === 'income' && (
                        <Grid item xs={12} md={6}>
                            <TextField
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
                                variant="outlined"
                                helperText="可选：记录与收入相关的成本"
                                InputProps={{
                                    startAdornment: (
                                        <Typography sx={{ mr: 1, color: 'text.secondary' }}>$</Typography>
                                    ),
                                }}
                            />
                        </Grid>
                    )}
                    
                    <Grid item xs={12}>
                        <TextField
                            label="类别"
                            fullWidth
                            value={transaction.category}
                            onChange={(e) =>
                                setTransaction({ ...transaction, category: e.target.value })
                            }
                            variant="outlined"
                            placeholder="例如：工资、餐饮、交通等"
                        />
                    </Grid>
                    
                    <Grid item xs={12}>
                        <TextField
                            label="描述"
                            fullWidth
                            multiline
                            rows={3}
                            value={transaction.description}
                            onChange={(e) =>
                                setTransaction({
                                    ...transaction,
                                    description: e.target.value,
                                })
                            }
                            variant="outlined"
                            placeholder="添加详细描述..."
                        />
                    </Grid>
                </Grid>
            </DialogContent>
            
            <DialogActions sx={{ p: 3, pt: 0 }}>
                <Button 
                    onClick={onClose}
                    size="large"
                    sx={{ borderRadius: 2 }}
                >
                    取消
                </Button>
                <Button 
                    onClick={handleSubmit}
                    variant="contained" 
                    color="primary"
                    size="large"
                    sx={{ borderRadius: 2, px: 3 }}
                    disabled={!transaction.amount || !transaction.category}
                >
                    {editingTransaction ? '更新' : '保存'}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default TransactionForm;