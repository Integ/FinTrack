import React, { useState } from 'react';
import { Container, Fab, Box, Button, Stack, Typography } from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import Header from '../components/Header';
import TransactionList from '../components/TransactionList';
import TransactionForm from '../components/TransactionForm';
import TransactionSummary from '../components/TransactionSummary';
import PeriodStats from '../components/PeriodStats';

const Dashboard: React.FC = () => {
    const [isFormOpen, setIsFormOpen] = useState(false);

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1 }}>
            <Header />
            <Container 
                maxWidth="lg" 
                sx={{ 
                    mt: { xs: 2, sm: 4 }, 
                    mb: { xs: 6, sm: 8 }, 
                    flex: 1,
                    px: { xs: 2, sm: 3 }
                }}
            >
                <Stack
                    direction={{ xs: 'column', sm: 'row' }}
                    justifyContent="space-between"
                    alignItems={{ xs: 'flex-start', sm: 'center' }}
                    spacing={1.5}
                    sx={{ mb: { xs: 2, sm: 3 } }}
                >
                    <Box>
                        <Typography variant="h4" sx={{ fontWeight: 700, fontSize: { xs: '1.3rem', sm: '1.5rem' } }}>
                            收入看板
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            记录每笔副业收支，快速查看趋势变化
                        </Typography>
                    </Box>

                    <Button
                        variant="contained"
                        startIcon={<AddIcon />}
                        onClick={() => setIsFormOpen(true)}
                        sx={{ display: { xs: 'none', sm: 'inline-flex' } }}
                    >
                        新增交易
                    </Button>
                </Stack>

                <TransactionSummary />
                <Box sx={{ display: 'flex', flexDirection: { xs: 'column', lg: 'row' }, gap: { xs: 2, sm: 3 } }}>
                    <Box sx={{ flex: 1, minWidth: 0, width: { xs: '100%', lg: 'auto' } }}>
                        <TransactionList />
                    </Box>
                    <Box sx={{ width: { xs: '100%', lg: '400px' }, flexShrink: 0 }}>
                        <PeriodStats />
                    </Box>
                </Box>
                
                <Fab
                    color="primary"
                    aria-label="add"
                    sx={{ 
                        position: 'fixed', 
                        bottom: { xs: 16, sm: 24 }, 
                        right: { xs: 16, sm: 24 },
                        zIndex: 1000,
                    }}
                    onClick={() => setIsFormOpen(true)}
                >
                    <AddIcon />
                </Fab>
                
                <TransactionForm
                    open={isFormOpen}
                    onClose={() => setIsFormOpen(false)}
                />
            </Container>
        </Box>
    );
};

export default Dashboard;
