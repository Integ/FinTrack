import { configureStore, Middleware } from '@reduxjs/toolkit';
import transactionReducer from './transactionSlice';
import { localStorageMiddleware, loadFromLocalStorage } from './localStorage';

// 定义 RootState 类型
export interface RootState {
    transactions: ReturnType<typeof transactionReducer>;
}

// 从 localStorage 加载初始状态
const preloadedState = loadFromLocalStorage();

// 创建 store
export const store = configureStore({
    reducer: {
        transactions: transactionReducer,
    },
    preloadedState,
    middleware: (getDefaultMiddleware) =>
        getDefaultMiddleware().concat(localStorageMiddleware as Middleware),
});

export type AppDispatch = typeof store.dispatch;