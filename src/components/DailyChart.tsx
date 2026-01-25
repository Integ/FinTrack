import React, { useMemo, useState } from 'react';
import { Paper, Typography, Box, ToggleButton, ToggleButtonGroup } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ReferenceLine, LineChart, Line, Area, AreaChart } from 'recharts';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';

interface DailyData {
    date: string;
    income: number;
    expense: number;
    cost: number;
    totalExpense: number; // 支出和成本的总和
}

const DailyChart: React.FC = () => {
    const transactions = useSelector(
        (state: RootState) => state.transactions.transactions
    );
    const [chartType, setChartType] = useState<'bar' | 'line' | 'area'>('bar');

    const chartData = useMemo(() => {
        const formatLocalDate = (d: Date): string => {
            const year = d.getFullYear();
            const month = String(d.getMonth() + 1).padStart(2, '0');
            const day = String(d.getDate()).padStart(2, '0');
            return `${year}-${month}-${day}`;
        };

        // 生成最近30天的日期数组（含今天）
        const dates: string[] = [];
        const today = new Date();
        
        for (let i = 29; i >= 0; i--) {
            const date = new Date(today);
            date.setDate(date.getDate() - i);
            // 使用本地时间格式化 YYYY-MM-DD，避免UTC导致的跨天偏移
            dates.push(formatLocalDate(date));
        }

        // 按日期统计收入
        const dailyMap = new Map<string, DailyData>();
        
        // 初始化所有日期为0
        dates.forEach(date => {
            dailyMap.set(date, {
                date: date,
                income: 0,
                expense: 0,
                cost: 0,
                totalExpense: 0,
            });
        });

        // 统计每笔交易的收入、支出和成本
        transactions.forEach((transaction: Transaction) => {
            const transactionDate = transaction.date;
            if (dailyMap.has(transactionDate)) {
                const dayData = dailyMap.get(transactionDate)!;
                if (transaction.type === 'income') {
                    dayData.income += transaction.amount;
                    // 如果有成本，累加成本
                    if (transaction.cost !== undefined) {
                        dayData.cost += transaction.cost;
                    }
                } else if (transaction.type === 'expense') {
                    dayData.expense += transaction.amount;
                }
            }
        });

        // 转换为数组并格式化日期显示（以本地时间解析）
        // 将支出和成本合并，并转换为负值，使柱状图向下展示
        const data = Array.from(dailyMap.values()).map(item => {
            const [yearStr, monthStr, dayStr] = item.date.split('-');
            const dateObj = new Date(
                Number(yearStr),
                Number(monthStr) - 1,
                Number(dayStr)
            );
            const month = dateObj.getMonth() + 1;
            const day = dateObj.getDate();
            // 合并支出和成本
            const totalExpense = item.expense + item.cost;
            return {
                ...item,
                // 保留原始正值用于 tooltip 显示
                expense: item.expense,
                cost: item.cost,
                // 合并后的总值，转换为负值，向下展示
                totalExpense: -totalExpense,
                dateLabel: `${month}/${day}`, // 显示为 MM/DD 格式
            };
        });
        return data;
    }, [transactions]);

    const CustomTooltip = ({ active, payload, label }: any) => {
        if (active && payload && payload.length) {
            const p0 = payload[0];
            const dateLabel = p0?.payload?.dateLabel || label;
            
            return (
                <Paper
                    sx={{
                        p: 2,
                        backgroundColor: 'background.paper',
                        border: '1px solid',
                        borderColor: 'divider',
                        borderRadius: 2,
                        boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
                    }}
                >
                    {dateLabel && (
                        <Typography variant="body2" sx={{ fontWeight: 600, mb: 1.5 }}>
                            {dateLabel}
                        </Typography>
                    )}
                    {payload.map((entry: any, index: number) => {
                        const value = Math.abs(entry.value || 0);
                        return (
                            <Box key={index} sx={{ mb: 0.5 }}>
                                <Typography variant="body2" sx={{ color: entry.color }}>
                                    {entry.name}: ${value.toFixed(2)}
                                </Typography>
                            </Box>
                        );
                    })}
                </Paper>
            );
        }
        return null;
    };

    const renderChart = () => {
        const commonProps = {
            data: chartData,
            margin: { top: 20, right: 30, left: 20, bottom: 20 }
        };

        switch (chartType) {
            case 'line':
                return (
                    <LineChart {...commonProps}>
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                        <XAxis 
                            dataKey="dateLabel" 
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <YAxis 
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend />
                        <Line 
                            type="monotone" 
                            dataKey="income" 
                            name="收入" 
                            stroke="success.main" 
                            strokeWidth={2}
                            dot={{ fill: 'success.main', r: 3 }}
                        />
                        <Line 
                            type="monotone" 
                            dataKey="totalExpense" 
                            name="支出" 
                            stroke="error.main" 
                            strokeWidth={2}
                            dot={{ fill: 'error.main', r: 3 }}
                        />
                    </LineChart>
                );
            case 'area':
                return (
                    <AreaChart {...commonProps}>
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                        <XAxis 
                            dataKey="dateLabel" 
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <YAxis 
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend />
                        <Area 
                            type="monotone" 
                            dataKey="income" 
                            name="收入" 
                            stroke="success.main" 
                            fill="success.main"
                            fillOpacity={0.3}
                        />
                        <Area 
                            type="monotone" 
                            dataKey="totalExpense" 
                            name="支出" 
                            stroke="error.main" 
                            fill="error.main"
                            fillOpacity={0.3}
                        />
                    </AreaChart>
                );
            default:
                return (
                    <BarChart {...commonProps} barGap={0}>
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                        <XAxis 
                            dataKey="dateLabel" 
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <YAxis 
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <ReferenceLine y={0} stroke="divider" strokeWidth={1} />
                        <Tooltip cursor={false} content={<CustomTooltip />} />
                        <Legend />
                        <Bar
                            dataKey="income"
                            name="收入"
                            fill="success.main"
                            radius={[2, 2, 0, 0]}
                        />
                        <Bar
                            dataKey="totalExpense"
                            name="支出"
                            fill="error.main"
                            radius={[2, 2, 0, 0]}
                        />
                    </BarChart>
                );
        }
    };

    return (
        <Paper sx={{ mt: 2, overflow: 'hidden' }}>
            <Box sx={{ p: 3, borderBottom: '1px solid', borderColor: 'divider' }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
                    <Typography variant="h4" sx={{ fontWeight: 600 }}>
                        收支趋势
                    </Typography>
                    <ToggleButtonGroup
                        value={chartType}
                        exclusive
                        onChange={(_, value) => value && setChartType(value)}
                        size="small"
                        sx={{ backgroundColor: 'background.paper' }}
                    >
                        <ToggleButton value="bar">柱状图</ToggleButton>
                        <ToggleButton value="line">折线图</ToggleButton>
                        <ToggleButton value="area">面积图</ToggleButton>
                    </ToggleButtonGroup>
                </Box>
                <Typography variant="body2" color="text.secondary">
                    最近30天的收支趋势分析
                </Typography>
            </Box>
            
            <Box sx={{ p: 3, height: 350 }}>
                <ResponsiveContainer width="100%" height="100%">
                    {renderChart()}
                </ResponsiveContainer>
            </Box>
        </Paper>
    );
};

export default DailyChart;

