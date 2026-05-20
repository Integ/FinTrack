import React, { useMemo, useState } from 'react';
import {
    IconButton,
    Typography,
    Paper,
    Box,
    Chip,
    Tooltip,
    Grid,
    ToggleButtonGroup,
    ToggleButton,
    TextField,
    InputAdornment,
} from '@mui/material';
import {
    Delete as DeleteIcon,
    Edit as EditIcon,
    TrendingUp as TrendingUpIcon,
    TrendingDown as TrendingDownIcon,
    Search as SearchIcon,
} from '@mui/icons-material';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../store';
import { deleteTransaction } from '../store/transactionSlice';
import { Transaction } from '../types/transaction';
import TransactionForm from './TransactionForm';
import { useLanguage } from '../i18n/LanguageContext';

type FilterType = 'all' | 'income' | 'expense';

const TransactionList: React.FC = () => {
    const dispatch = useDispatch();
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );
    const { t } = useLanguage();
    const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);
    const [filterType, setFilterType] = useState<FilterType>('all');
    const [keyword, setKeyword] = useState('');

    const handleDelete = (id: string) => {
        dispatch(deleteTransaction(id));
    };

    const handleEdit = (transaction: Transaction) => {
        setEditingTransaction(transaction);
    };

    const handleCloseEdit = () => {
        setEditingTransaction(null);
    };

    const filteredTransactions = useMemo(() => {
        const normalizedKeyword = keyword.trim().toLowerCase();

        return [...transactions]
            .filter((transaction) => filterType === 'all' || transaction.type === filterType)
            .filter((transaction) => {
                if (!normalizedKeyword) {
                    return true;
                }

                return (
                    transaction.description.toLowerCase().includes(normalizedKeyword) ||
                    transaction.category.toLowerCase().includes(normalizedKeyword)
                );
            })
            .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());
    }, [transactions, filterType, keyword]);

    const TransactionItem: React.FC<{ transaction: Transaction }> = ({ transaction }) => {
        const isIncome = transaction.type === 'income';
        
        return (
            <Box
                sx={{
                    p: { xs: 1.25, sm: 2 },
                    border: '1px solid',
                    borderColor: 'divider',
                    borderRadius: { xs: 1.5, sm: 2 },
                    mb: { xs: 1, sm: 1.5 },
                    transition: 'all 0.2s ease-in-out',
                    '&:hover': {
                        borderColor: 'primary.main',
                        transform: { xs: 'none', sm: 'translateX(4px)' },
                    },
                }}
            >
                <Grid container spacing={{ xs: 1, sm: 1.5 }} alignItems="center">
                    <Grid item>
                        <Box
                            sx={{
                                width: { xs: 32, sm: 36 },
                                height: { xs: 32, sm: 36 },
                                borderRadius: 1,
                                backgroundColor: isIncome ? 'success.main' : 'error.main',
                                color: 'background.paper',
                                display: 'flex',
                                alignItems: 'center',
                                justifyContent: 'center',
                            }}
                        >
                            {isIncome ? <TrendingUpIcon sx={{ fontSize: { xs: 16, sm: 20 } }} /> : <TrendingDownIcon sx={{ fontSize: { xs: 16, sm: 20 } }} />}
                        </Box>
                    </Grid>
                    
                    <Grid item xs>
                        <Typography
                            variant="body1"
                            sx={{
                                fontWeight: 600,
                                fontSize: { xs: '0.875rem', sm: '1rem' },
                                lineHeight: 1.25,
                                overflowWrap: 'anywhere',
                            }}
                        >
                            {transaction.description}
                        </Typography>
                        <Box sx={{ display: 'flex', gap: 0.5, mt: 0.5, alignItems: 'center', flexWrap: 'wrap' }}>
                            <Chip
                                label={transaction.category}
                                size="small"
                                variant="outlined"
                                sx={{ fontSize: '0.7rem', height: 20 }}
                            />
                            <Typography variant="caption" color="text.secondary" sx={{ fontSize: '0.7rem' }}>
                                {transaction.date}
                            </Typography>
                            {(transaction as any).cost && (
                                <Typography variant="caption" color="warning.main" sx={{ fontSize: '0.7rem' }}>
                                    {t.list.cost} ${(transaction as any).cost.toFixed(2)}
                                </Typography>
                            )}
                        </Box>
                    </Grid>
                    
                    <Grid item xs={4} sm={3} sx={{ textAlign: 'right', minWidth: 0 }}>
                        <Typography
                            variant="body1"
                            color={isIncome ? 'success.main' : 'error.main'}
                            sx={{
                                fontWeight: 700,
                                fontSize: { xs: '0.9rem', sm: '1.25rem' },
                                lineHeight: 1.2,
                                overflowWrap: 'anywhere',
                            }}
                        >
                            {isIncome ? '+' : '-'}${transaction.amount.toFixed(2)}
                        </Typography>
                    </Grid>
                    
                    <Grid item>
                        <Box sx={{ display: 'flex', gap: { xs: 0, sm: 0.25 } }}>
                            <Tooltip title={t.list.edit}>
                                <IconButton
                                    size="small"
                                    onClick={() => handleEdit(transaction)}
                                    sx={{ color: 'text.secondary', p: { xs: 0.25, sm: 0.5 } }}
                                >
                                    <EditIcon fontSize="small" />
                                </IconButton>
                            </Tooltip>
                            <Tooltip title={t.list.delete}>
                                <IconButton
                                    size="small"
                                    onClick={() => handleDelete(transaction.id)}
                                    sx={{ color: 'text.secondary', p: { xs: 0.25, sm: 0.5 } }}
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
        <Paper sx={{ mt: { xs: 1, sm: 2 }, p: 0, overflow: 'hidden' }}>
            <Box sx={{ p: { xs: 1.5, sm: 3 }, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Typography variant="h5" sx={{ fontWeight: 600, fontSize: { xs: '1.1rem', sm: '1.5rem' } }}>
                    {t.list.title}
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                    {t.list.totalRecords.replace('{total}', String(transactions.length)).replace('{showing}', String(filteredTransactions.length))}
                </Typography>

                <Box sx={{ mt: 1.5, display: 'flex', gap: 1, flexWrap: 'wrap' }}>
                    <ToggleButtonGroup
                        color="primary"
                        size="small"
                        value={filterType}
                        exclusive
                        onChange={(_, value: FilterType | null) => {
                            if (value) setFilterType(value);
                        }}
                        sx={{
                            width: { xs: '100%', sm: 'auto' },
                            '& .MuiToggleButton-root': {
                                flex: { xs: 1, sm: 'initial' },
                                minHeight: 40,
                                px: { xs: 1, sm: 1.5 },
                            },
                        }}
                    >
                        <ToggleButton value="all">{t.list.filterAll}</ToggleButton>
                        <ToggleButton value="income">{t.list.filterIncome}</ToggleButton>
                        <ToggleButton value="expense">{t.list.filterExpense}</ToggleButton>
                    </ToggleButtonGroup>

                    <TextField
                        size="small"
                        placeholder={t.list.searchPlaceholder}
                        value={keyword}
                        onChange={(e) => setKeyword(e.target.value)}
                        sx={{ minWidth: { xs: '100%', sm: 220 }, flex: { sm: '0 0 auto' } }}
                        InputProps={{
                            startAdornment: (
                                <InputAdornment position="start">
                                    <SearchIcon fontSize="small" />
                                </InputAdornment>
                            ),
                        }}
                    />
                </Box>
            </Box>
            
            <Box sx={{ p: { xs: 1, sm: 3 }, maxHeight: { xs: 'none', sm: 600 }, overflowY: { xs: 'visible', sm: 'auto' } }}>
                {filteredTransactions.length === 0 ? (
                    <Box sx={{ textAlign: 'center', py: 8 }}>
                        <Typography variant="body1" color="text.secondary">
                            {t.list.noRecords}
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                            {t.list.noRecordsHint}
                        </Typography>
                    </Box>
                ) : (
                    filteredTransactions.map((transaction) => (
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
