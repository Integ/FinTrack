import React, { useState } from 'react';
import { Container, Fab, Box } from '@mui/material';
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
                    mt: { xs: 1.5, sm: 4 },
                    mb: { xs: 'calc(88px + env(safe-area-inset-bottom))', sm: 8 },
                    flex: 1,
                    px: { xs: 1.5, sm: 3 },
                }}
            >
                <TransactionSummary />
                <Box sx={{ display: 'flex', flexDirection: { xs: 'column', lg: 'row' }, gap: { xs: 2, sm: 3 } }}>
                    <Box sx={{ width: { xs: '100%', lg: '400px' }, flexShrink: 0 }}>
                        <PeriodStats />
                    </Box>
                    <Box sx={{ flex: 1, minWidth: 0, width: { xs: '100%', lg: 'auto' } }}>
                        <TransactionList />
                    </Box>
                </Box>
                
                <Fab
                    color="primary"
                    aria-label="add"
                    sx={{ 
                        position: 'fixed', 
                        bottom: { xs: 'calc(18px + env(safe-area-inset-bottom))', sm: 24 },
                        right: { xs: 18, sm: 24 },
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
