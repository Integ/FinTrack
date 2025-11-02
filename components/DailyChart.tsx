import React, { useMemo } from 'react';
import { Paper, Typography, Box } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer } from 'recharts';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';

interface DailyData {
    date: string;
    income: number;
    expense: number;
    cost: number;
}

const DailyChart: React.FC = () => {
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );

    const chartData = useMemo(() => {
        // 生成最近7天的日期数组
        const dates: string[] = [];
        const today = new Date();
        
        for (let i = 6; i >= 0; i--) {
            const date = new Date(today);
            date.setDate(date.getDate() - i);
            dates.push(date.toISOString().split('T')[0]); // YYYY-MM-DD格式
        }

        // 按日期统计收支
        const dailyMap = new Map<string, DailyData>();
        
        // 初始化所有日期为0
        dates.forEach(date => {
            dailyMap.set(date, {
                date: date,
                income: 0,
                expense: 0,
                cost: 0,
            });
        });

        // 统计每笔交易的收支和成本
        transactions.forEach((transaction: Transaction) => {
            const transactionDate = transaction.date;
            if (dailyMap.has(transactionDate)) {
                const dayData = dailyMap.get(transactionDate)!;
                if (transaction.type === 'income') {
                    dayData.income += transaction.amount;
                    // 统计收入交易的成本
                    if ((transaction as any).cost !== undefined) {
                        dayData.cost += (transaction as any).cost || 0;
                    }
                } else {
                    dayData.expense += transaction.amount;
                    // 支出也是成本的一部分
                    dayData.cost += transaction.amount;
                }
            }
        });

        // 转换为数组并格式化日期显示
        const data = Array.from(dailyMap.values()).map(item => {
            const dateObj = new Date(item.date);
            const month = dateObj.getMonth() + 1;
            const day = dateObj.getDate();
            return {
                ...item,
                dateLabel: `${month}/${day}`, // 显示为 MM/DD 格式
            };
        });

        return data;
    }, [transactions]);

    // 自定义Tooltip
    const CustomTooltip = ({ active, payload }: any) => {
        if (active && payload && payload.length) {
            return (
                <Paper
                    sx={{
                        p: 1.5,
                        backgroundColor: 'rgba(30, 30, 30, 0.95)',
                        border: '1px solid rgba(255, 215, 0, 0.3)',
                    }}
                >
                    {payload.map((entry: any, index: number) => (
                        <Typography
                            key={index}
                            sx={{
                                color: entry.color,
                                fontSize: '0.875rem',
                                mb: 0.5,
                            }}
                        >
                            {entry.name}: ${entry.value.toFixed(2)}
                        </Typography>
                    ))}
                </Paper>
            );
        }
        return null;
    };

    return (
        <Paper
            sx={{
                mt: 2,
                p: 2,
                background: 'linear-gradient(145deg, #1E1E1E 0%, #2A2A2A 100%)',
                borderTop: '1px solid rgba(255, 215, 0, 0.1)',
            }}
        >
            <Typography variant="h6" gutterBottom sx={{ color: '#FFD700', mb: 2 }}>
                最近7天收支与成本统计
            </Typography>
            <Box sx={{ width: '100%', height: 300 }}>
                <ResponsiveContainer width="100%" height="100%">
                    <BarChart
                        data={chartData}
                        margin={{
                            top: 20,
                            right: 30,
                            left: 20,
                            bottom: 5,
                        }}
                    >
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(255, 255, 255, 0.1)" />
                        <XAxis
                            dataKey="dateLabel"
                            stroke="#FFD700"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <YAxis
                            stroke="#FFD700"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend
                            wrapperStyle={{ color: '#FFD700' }}
                            iconType="rect"
                        />
                        <Bar
                            dataKey="income"
                            name="收入"
                            fill="#4caf50"
                            radius={[4, 4, 0, 0]}
                        />
                        <Bar
                            dataKey="expense"
                            name="支出"
                            fill="#f44336"
                            radius={[4, 4, 0, 0]}
                        />
                        <Bar
                            dataKey="cost"
                            name="成本"
                            fill="#ff9800"
                            radius={[4, 4, 0, 0]}
                        />
                    </BarChart>
                </ResponsiveContainer>
            </Box>
        </Paper>
    );
};

export default DailyChart;

