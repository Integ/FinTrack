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
    useMediaQuery,
    useTheme,
} from '@mui/material';
import { useDispatch } from 'react-redux';
import { addTransaction, updateTransaction } from '../store/transactionSlice';
import { Transaction } from '../types/transaction';
import { v4 as uuidv4 } from 'uuid';
import { useLanguage } from '../i18n/LanguageContext';

interface TransactionFormProps {
    open: boolean;
    onClose: () => void;
    editingTransaction?: Transaction;
}

const TransactionForm: React.FC<TransactionFormProps> = ({ open, onClose, editingTransaction }) => {
    const dispatch = useDispatch();
    const { t } = useLanguage();
    const theme = useTheme();
    const fullScreen = useMediaQuery(theme.breakpoints.down('sm'));
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
            fullScreen={fullScreen}
            PaperProps={{
                sx: {
                    borderRadius: { xs: 0, sm: 3 },
                    m: { xs: 0, sm: 2 },
                    maxHeight: { xs: '100dvh', sm: 'calc(100% - 64px)' },
                }
            }}
        >
            <DialogTitle sx={{ px: { xs: 2, sm: 3 }, pt: { xs: 'calc(18px + env(safe-area-inset-top))', sm: 3 }, pb: 1 }}>
                <Typography variant="h4" component="div" sx={{ fontWeight: 600, fontSize: { xs: '1.25rem', sm: '1.5rem' } }}>
                    {editingTransaction ? t.form.editTransaction : t.form.newTransaction}
                </Typography>
            </DialogTitle>
            
            <DialogContent sx={{ px: { xs: 2, sm: 3 }, pt: 1, pb: { xs: 2, sm: 3 } }}>
                <Grid container spacing={{ xs: 2, sm: 3 }}>
                    <Grid item xs={12}>
                        <TextField
                            label={t.form.date}
                            type="date"
                            fullWidth
                            value={transaction.date}
                            onChange={(e) =>
                                setTransaction({ ...transaction, date: e.target.value })
                            }
                            InputLabelProps={{ shrink: true }}
                            inputProps={{ inputMode: 'numeric' }}
                            variant="outlined"
                        />
                    </Grid>
                    
                    <Grid item xs={12}>
                        <FormControl fullWidth variant="outlined">
                            <InputLabel>{t.form.transactionType}</InputLabel>
                            <Select
                                label={t.form.transactionType}
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
                                        {t.form.income}
                                    </Box>
                                </MenuItem>
                                <MenuItem value="expense">
                                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                                        <Typography color="error.main" sx={{ mr: 1 }}>-</Typography>
                                        {t.form.expense}
                                    </Box>
                                </MenuItem>
                            </Select>
                        </FormControl>
                    </Grid>
                    
                    <Grid item xs={12} md={transaction.type === 'income' ? 6 : 12}>
                        <TextField
                            label={t.form.amount}
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
                            inputProps={{
                                inputMode: 'decimal',
                                min: 0,
                            }}
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
                                label={t.form.cost}
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
                                helperText={t.form.costHelper}
                                inputProps={{
                                    inputMode: 'decimal',
                                    min: 0,
                                }}
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
                            label={t.form.category}
                            fullWidth
                            value={transaction.category}
                            onChange={(e) =>
                                setTransaction({ ...transaction, category: e.target.value })
                            }
                            variant="outlined"
                            placeholder={t.form.categoryPlaceholder}
                            inputProps={{ autoComplete: 'off' }}
                        />
                    </Grid>
                    
                    <Grid item xs={12}>
                        <TextField
                            label={t.form.description}
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
                            placeholder={t.form.descriptionPlaceholder}
                            inputProps={{ autoComplete: 'off' }}
                        />
                    </Grid>
                </Grid>
            </DialogContent>
            
            <DialogActions
                sx={{
                    p: { xs: 2, sm: 3 },
                    pt: { xs: 1, sm: 0 },
                    pb: { xs: 'calc(16px + env(safe-area-inset-bottom))', sm: 3 },
                    gap: 1,
                }}
            >
                <Button 
                    onClick={onClose}
                    size="large"
                    fullWidth={fullScreen}
                    sx={{ borderRadius: 2 }}
                >
                    {t.form.cancel}
                </Button>
                <Button 
                    onClick={handleSubmit}
                    variant="contained" 
                    color="primary"
                    size="large"
                    fullWidth={fullScreen}
                    sx={{ borderRadius: 2, px: 3 }}
                    disabled={!transaction.amount || !transaction.category}
                >
                    {editingTransaction ? t.form.update : t.form.save}
                </Button>
            </DialogActions>
        </Dialog>
    );
};

export default TransactionForm;
