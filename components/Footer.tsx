import React from 'react';
import { Box, Container, Typography, Paper } from '@mui/material';
import logo from '../assets/logo.png';

const Footer: React.FC = () => {
    return (
        <Paper
            component="footer"
            sx={{
                mt: 'auto',
                py: 3,
                background: 'linear-gradient(145deg, #1E1E1E 0%, #2A2A2A 100%)',
                borderTop: '1px solid rgba(255, 215, 0, 0.1)',
            }}
        >
            <Container maxWidth="md">
                <Box
                    sx={{
                        display: 'flex',
                        flexDirection: 'column',
                        alignItems: 'center',
                        gap: 2,
                    }}
                >
                    <Box
                        component="img"
                        src={logo}
                        alt="FinTrack Logo"
                        sx={{
                            height: 60,
                            objectFit: 'contain',
                            opacity: 0.9,
                        }}
                    />
                    <Typography
                        variant="h6"
                        align="center"
                        sx={{ color: '#FFD700' }}
                    >
                        FinTrack - 您的个人财务管理助手
                    </Typography>
                    <Typography
                        variant="body1"
                        align="center"
                        color="text.secondary"
                        sx={{ maxWidth: 600 }}
                    >
                        轻松记录每一笔收支，智能统计分析您的财务状况。
                        帮助您更好地规划预算，实现财务目标。
                    </Typography>
                    <Box
                        sx={{
                            display: 'flex',
                            gap: 4,
                            mt: 1,
                        }}
                    >
                        <Feature
                            title="便捷记账"
                            description="快速记录日常收支，分类明确，一目了然"
                        />
                        <Feature
                            title="智能分析"
                            description="自动计算收入支出，实时掌握财务状况"
                        />
                        <Feature
                            title="安全可靠"
                            description="数据本地存储，确保您的隐私安全"
                        />
                    </Box>
                    <Typography
                        variant="caption"
                        color="text.secondary"
                        sx={{ mt: 2 }}
                    >
                        © {new Date().getFullYear()} FinTrack. All rights reserved.
                    </Typography>
                </Box>
            </Container>
        </Paper>
    );
};

interface FeatureProps {
    title: string;
    description: string;
}

const Feature: React.FC<FeatureProps> = ({ title, description }) => (
    <Box sx={{ textAlign: 'center', maxWidth: 200 }}>
        <Typography
            variant="subtitle1"
            sx={{ color: '#FFD700', mb: 1 }}
        >
            {title}
        </Typography>
        <Typography
            variant="body2"
            color="text.secondary"
        >
            {description}
        </Typography>
    </Box>
);

export default Footer;