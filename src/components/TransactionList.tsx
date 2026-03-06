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

type FilterType = 'all' | 'income' | 'expense';

const TransactionList: React.FC = () => {
    const dispatch = useDispatch();
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );
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
                    p: { xs: 1.5, sm: 2 },
                    border: '1px solid',
                    borderColor: 'divider',
                    borderRadius: 2,
                    mb: 1.5,
                    transition: 'all 0.2s ease-in-out',
                    '&:hover': {
                        borderColor: 'primary.main',
                        transform: 'translateX(4px)',
                    },
                }}
            >
                <Grid container spacing={1.5} alignItems="center">
                    <Grid item>
                        <Box
                            sx={{
                                p: 0.75,
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
                        <Typography variant="body1" sx={{ fontWeight: 500, fontSize: { xs: '0.9rem', sm: '1rem' } }}>
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
                                    成本: ${(transaction as any).cost.toFixed(2)}
                                </Typography>
                            )}
                        </Box>
                    </Grid>
                    
                    <Grid item xs={3} sx={{ textAlign: 'right' }}>
                        <Typography
                            variant="body1"
                            color={isIncome ? 'success.main' : 'error.main'}
                            sx={{ fontWeight: 600, fontSize: { xs: '0.95rem', sm: '1.25rem' } }}
                        >
                            {isIncome ? '+' : '-'}${transaction.amount.toFixed(2)}
                        </Typography>
                    </Grid>
                    
                    <Grid item>
                        <Box sx={{ display: 'flex', gap: 0.25 }}>
                            <Tooltip title="编辑">
                                <IconButton
                                    size="small"
                                    onClick={() => handleEdit(transaction)}
                                    sx={{ color: 'text.secondary', p: 0.5 }}
                                >
                                    <EditIcon fontSize="small" />
                                </IconButton>
                            </Tooltip>
                            <Tooltip title="删除">
                                <IconButton
                                    size="small"
                                    onClick={() => handleDelete(transaction.id)}
                                    sx={{ color: 'text.secondary', p: 0.5 }}
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
            <Box sx={{ p: { xs: 2, sm: 3 }, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Typography variant="h5" sx={{ fontWeight: 600 }}>
                    交易记录
                </Typography>
                <Typography variant="body2" color="text.secondary" sx={{ mt: 0.5 }}>
                    共 {transactions.length} 笔，当前显示 {filteredTransactions.length} 笔
                </Typography>

                <Box sx={{ mt: 2, display: 'flex', gap: 1.5, flexWrap: 'wrap' }}>
                    <ToggleButtonGroup
                        color="primary"
                        size="small"
                        value={filterType}
                        exclusive
                        onChange={(_, value: FilterType | null) => {
                            if (value) setFilterType(value);
                        }}
                    >
                        <ToggleButton value="all">全部</ToggleButton>
                        <ToggleButton value="income">收入</ToggleButton>
                        <ToggleButton value="expense">支出</ToggleButton>
                    </ToggleButtonGroup>

                    <TextField
                        size="small"
                        placeholder="搜索描述/类别"
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
            
            <Box sx={{ p: { xs: 1.5, sm: 3 }, maxHeight: { xs: '50vh', sm: 600 }, overflowY: 'auto' }}>
                {filteredTransactions.length === 0 ? (
                    <Box sx={{ textAlign: 'center', py: 8 }}>
                        <Typography variant="body1" color="text.secondary">
                            没有匹配的记录
                        </Typography>
                        <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
                            可以调整筛选条件，或点击右下角按钮新增交易
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
