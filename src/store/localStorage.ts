import { Middleware } from '@reduxjs/toolkit';
import { RootState } from './index';

export const localStorageMiddleware: Middleware<{}, RootState> = store => next => action => {
    const result = next(action);
    if (typeof action === 'object' && action !== null && 'type' in action && 
        typeof action.type === 'string' && action.type.startsWith('transactions/')) {
        const state = store.getState();
        localStorage.setItem('fintrack_transactions', JSON.stringify(state.transactions.transactions));
    }
    return result;
};

export const loadFromLocalStorage = () => {
    try {
        const serializedTransactions = localStorage.getItem('fintrack_transactions');
        if (serializedTransactions === null) {
            return undefined;
        }
        return {
            transactions: {
                transactions: JSON.parse(serializedTransactions)
            }
        };
    } catch (err) {
        console.error('Error loading state from localStorage:', err);
        return undefined;
    }
};