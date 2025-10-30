import React from 'react';
import { Provider } from 'react-redux';
import { ThemeProvider, createTheme, CssBaseline, Box } from '@mui/material';
import { store } from './store';
import Dashboard from './pages/Dashboard';
import Footer from './components/Footer';

const theme = createTheme({
    palette: {
        mode: 'dark',
        primary: {
            main: '#FFD700', // 金色
            dark: '#DAA520', // 深金色
            light: '#FFE55C', // 浅金色
            contrastText: '#000000', // 文字颜色设为黑色以确保在金色背景上可读
        },
        background: {
            default: '#121212', // 深色背景
            paper: '#1E1E1E', // 稍浅一点的黑色，用于卡片
        },
        text: {
            primary: '#FFFFFF',
            secondary: 'rgba(255, 255, 255, 0.7)',
        },
    },
    components: {
        MuiPaper: {
            styleOverrides: {
                root: {
                    borderRadius: 8,
                    boxShadow: '0 2px 8px rgba(255, 215, 0, 0.15)', // 金色阴影
                    backgroundColor: '#1E1E1E', // 确保所有Paper组件使用稍浅的黑色
                },
            },
        },
        MuiAppBar: {
            styleOverrides: {
                root: {
                    background: 'linear-gradient(45deg, #FFD700 30%, #DAA520 90%)',
                    color: '#000000',
                },
            },
        },
    },
});

const App: React.FC = () => {
    return (
        <Provider store={store}>
            <ThemeProvider theme={theme}>
                <CssBaseline />
                <Box
                    sx={{
                        display: 'flex',
                        flexDirection: 'column',
                        minHeight: '100vh',
                    }}
                >
                    <Dashboard />
                    <Footer />
                </Box>
            </ThemeProvider>
        </Provider>
    );
};

export default App;
