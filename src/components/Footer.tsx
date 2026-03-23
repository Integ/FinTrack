import React from 'react';
import { Box, Chip, Container, Paper, Typography } from '@mui/material';

const Footer: React.FC = () => {
    return (
        <Paper
            component="footer"
            sx={{
                mt: 'auto',
                py: { xs: 2, sm: 2.5 },
                background: 'rgba(15, 23, 42, 0.72)',
                backdropFilter: 'blur(14px)',
                borderTop: '1px solid rgba(148, 163, 184, 0.12)',
                borderRadius: 0,
                boxShadow: 'none',
            }}
        >
            <Container maxWidth="lg">
                <Box
                    sx={{
                        display: 'flex',
                        flexDirection: { xs: 'column', md: 'row' },
                        alignItems: { xs: 'flex-start', md: 'center' },
                        justifyContent: 'space-between',
                        gap: 2,
                    }}
                >
                    <Box
                        sx={{
                            display: 'flex',
                            flexDirection: 'column',
                            gap: 0.5,
                        }}
                    >
                        <Typography
                            variant="subtitle1"
                            sx={{
                                color: 'text.primary',
                                fontWeight: 700,
                                letterSpacing: '-0.02em',
                            }}
                        >
                            FinTrack
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                            简洁记录每一笔收支，清楚掌握现金流。
                        </Typography>
                    </Box>

                    <Box sx={{ width: { xs: '100%', md: 'auto' } }}>
                        <Box
                            sx={{
                                display: 'flex',
                                flexWrap: 'wrap',
                                gap: 1,
                                justifyContent: { xs: 'flex-start', md: 'flex-end' },
                                mb: 1,
                            }}
                        >
                            <Chip
                                label="本地存储"
                                size="small"
                                sx={chipStyles}
                            />
                            <Chip
                                label="CSV 导入 / 导出"
                                size="small"
                                sx={chipStyles}
                            />
                        </Box>
                        <Typography
                            variant="caption"
                            color="text.secondary"
                            sx={{ display: 'block', textAlign: { xs: 'left', md: 'right' } }}
                        >
                            © {new Date().getFullYear()} FinTrack
                        </Typography>
                    </Box>
                </Box>
            </Container>
        </Paper>
    );
};

const chipStyles = {
    height: 28,
    color: '#CBD5E1',
    backgroundColor: 'rgba(30, 41, 59, 0.88)',
    border: '1px solid rgba(148, 163, 184, 0.12)',
    '& .MuiChip-label': {
        px: 1.25,
        fontSize: '0.75rem',
    },
};

export default Footer;
