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
            main: '#2563EB', // 专业蓝色
            dark: '#1D4ED8',
            light: '#3B82F6',
            contrastText: '#FFFFFF',
        },
        secondary: {
            main: '#10B981', // 成功绿色
            dark: '#059669',
            light: '#34D399',
        },
        error: {
            main: '#EF4444', // 错误红色
            dark: '#DC2626',
        },
        warning: {
            main: '#F59E0B', // 警告橙色
            dark: '#D97706',
        },
        background: {
            default: '#0F172A', // 深蓝灰背景
            paper: '#1E293B', // 卡片背景
        },
        text: {
            primary: '#F1F5F9',
            secondary: '#94A3B8',
        },
        divider: 'rgba(148, 163, 184, 0.1)',
    },
    typography: {
        fontFamily: '"Inter", -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif',
        h4: {
            fontWeight: 600,
            fontSize: '1.5rem',
        },
        h6: {
            fontWeight: 500,
            fontSize: '1rem',
        },
        body1: {
            fontSize: '0.875rem',
            lineHeight: 1.5,
        },
    },
    components: {
        MuiPaper: {
            styleOverrides: {
                root: {
                    borderRadius: 12,
                    boxShadow: '0 1px 3px rgba(0, 0, 0, 0.1), 0 1px 2px rgba(0, 0, 0, 0.06)',
                    backgroundColor: '#1E293B',
                    border: '1px solid rgba(148, 163, 184, 0.1)',
                },
            },
        },
        MuiAppBar: {
            styleOverrides: {
                root: {
                    background: '#1E293B',
                    color: '#F1F5F9',
                    borderBottom: '1px solid rgba(148, 163, 184, 0.1)',
                    boxShadow: 'none',
                },
            },
        },
        MuiButton: {
            styleOverrides: {
                root: {
                    textTransform: 'none',
                    borderRadius: 8,
                    fontWeight: 500,
                },
                containedPrimary: {
                    background: '#2563EB',
                    '&:hover': {
                        background: '#1D4ED8',
                    },
                },
            },
        },
        MuiFab: {
            styleOverrides: {
                root: {
                    borderRadius: 12,
                    boxShadow: '0 4px 6px -1px rgba(0, 0, 0, 0.1), 0 2px 4px -1px rgba(0, 0, 0, 0.06)',
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
