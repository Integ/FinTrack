import React, { useState } from 'react';
import { Container, Fab, Box } from '@mui/material';
import { Add as AddIcon } from '@mui/icons-material';
import Header from '../components/Header';
import TransactionList from '../components/TransactionList';
import TransactionForm from '../components/TransactionForm';
import TransactionSummary from '../components/TransactionSummary';

const Dashboard: React.FC = () => {
    const [isFormOpen, setIsFormOpen] = useState(false);
    const [isDrawerOpen, setIsDrawerOpen] = useState(false);

    return (
        <Box sx={{ display: 'flex', flexDirection: 'column', flexGrow: 1 }}>
            <Header onMenuClick={() => setIsDrawerOpen(!isDrawerOpen)} />
            <Container maxWidth="md" sx={{ mt: 4, mb: 8, flex: 1 }}>
                <TransactionSummary />
                <TransactionList />
                <Fab
                    color="primary"
                    aria-label="add"
                    sx={{ 
                        position: 'fixed', 
                        bottom: 16, 
                        right: 16,
                        bgcolor: '#FFD700',
                        '&:hover': {
                            bgcolor: '#DAA520',
                        }
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