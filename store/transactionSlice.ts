import { createSlice, PayloadAction } from '@reduxjs/toolkit';
import { Transaction } from '../types/transaction';

interface TransactionState {
    transactions: Transaction[];
}

const initialState: TransactionState = {
    transactions: []
};

export const transactionSlice = createSlice({
    name: 'transactions',
    initialState,
    reducers: {
        addTransaction: (state, action: PayloadAction<Transaction>) => {
            state.transactions.push(action.payload);
        },
        deleteTransaction: (state, action: PayloadAction<string>) => {
            state.transactions = state.transactions.filter(t => t.id !== action.payload);
        },
        updateTransaction: (state, action: PayloadAction<Transaction>) => {
            const index = state.transactions.findIndex(t => t.id === action.payload.id);
            if (index !== -1) {
                state.transactions[index] = action.payload;
            }
        }
    }
});

export const { addTransaction, deleteTransaction, updateTransaction } = transactionSlice.actions;
export default transactionSlice.reducer;