import React, { useMemo, useState } from 'react';
import { Paper, Typography, Box, ToggleButton, ToggleButtonGroup } from '@mui/material';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ReferenceLine, LineChart, Line, Area, AreaChart } from 'recharts';
import { useSelector } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';

interface WeeklyComparisonData {
    dayLabel: string;      // "周一", "周二", etc.
    date: string;          // 本周日期 YYYY-MM-DD
    lastWeekDate: string;  // 上周同一天日期
    income: number;        // 本周收入
    expense: number;       // 本周支出（包含成本）
    lastWeekIncome: number;    // 上周收入
    lastWeekExpense: number;   // 上周支出
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

        const dayLabels = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];

        // 获取本周的周一日期
        const today = new Date();
        const dayOfWeek = today.getDay(); // 0 = 周日, 1 = 周一, ...
        const mondayOffset = dayOfWeek === 0 ? -6 : 1 - dayOfWeek;

        const thisMonday = new Date(today);
        thisMonday.setDate(today.getDate() + mondayOffset);

        const lastMonday = new Date(thisMonday);
        lastMonday.setDate(thisMonday.getDate() - 7);

        // 生成本周和上周的日期数组（周一到周日）
        const thisWeekDates: string[] = [];
        const lastWeekDates: string[] = [];

        for (let i = 0; i < 7; i++) {
            const thisWeekDate = new Date(thisMonday);
            thisWeekDate.setDate(thisMonday.getDate() + i);
            thisWeekDates.push(formatLocalDate(thisWeekDate));

            const lastWeekDate = new Date(lastMonday);
            lastWeekDate.setDate(lastMonday.getDate() + i);
            lastWeekDates.push(formatLocalDate(lastWeekDate));
        }

        // 初始化每周数据
        const weeklyData: WeeklyComparisonData[] = [];
        for (let i = 0; i < 7; i++) {
            const dayIndex = (i + 1) % 7; // 周一=1, 周二=2, ..., 周日=0
            weeklyData.push({
                dayLabel: dayLabels[dayIndex === 0 ? 0 : dayIndex],
                date: thisWeekDates[i],
                lastWeekDate: lastWeekDates[i],
                income: 0,
                expense: 0,
                lastWeekIncome: 0,
                lastWeekExpense: 0,
            });
        }

        // 统计每笔交易
        transactions.forEach((transaction: Transaction) => {
            const transactionDate = transaction.date;

            // 检查是否在本周
            const thisWeekIndex = thisWeekDates.indexOf(transactionDate);
            if (thisWeekIndex !== -1) {
                if (transaction.type === 'income') {
                    weeklyData[thisWeekIndex].income += transaction.amount;
                    // 成本也计入支出
                    if (transaction.cost !== undefined) {
                        weeklyData[thisWeekIndex].expense += transaction.cost;
                    }
                } else if (transaction.type === 'expense') {
                    weeklyData[thisWeekIndex].expense += transaction.amount;
                }
            }

            // 检查是否在上周
            const lastWeekIndex = lastWeekDates.indexOf(transactionDate);
            if (lastWeekIndex !== -1) {
                if (transaction.type === 'income') {
                    weeklyData[lastWeekIndex].lastWeekIncome += transaction.amount;
                    // 成本也计入支出
                    if (transaction.cost !== undefined) {
                        weeklyData[lastWeekIndex].lastWeekExpense += transaction.cost;
                    }
                } else if (transaction.type === 'expense') {
                    weeklyData[lastWeekIndex].lastWeekExpense += transaction.amount;
                }
            }
        });

        // 转换支出为负值用于图表展示
        return weeklyData.map(item => ({
            ...item,
            // 保留原始正值用于 tooltip
            expensePositive: item.expense,
            lastWeekExpensePositive: item.lastWeekExpense,
            // 转换为负值用于图表
            expense: -item.expense,
            lastWeekExpense: -item.lastWeekExpense,
        }));
    }, [transactions]);

    const CustomTooltip = ({ active, payload }: any) => {
        if (active && payload && payload.length) {
            const data = payload[0]?.payload;
            if (!data) return null;

            // 计算变化百分比
            const incomeChange = data.lastWeekIncome > 0
                ? ((data.income - data.lastWeekIncome) / data.lastWeekIncome * 100).toFixed(1)
                : data.income > 0 ? '+∞' : '0';
            const expenseChange = data.lastWeekExpensePositive > 0
                ? ((data.expensePositive - data.lastWeekExpensePositive) / data.lastWeekExpensePositive * 100).toFixed(1)
                : data.expensePositive > 0 ? '+∞' : '0';

            return (
                <Paper
                    sx={{
                        p: 2,
                        backgroundColor: 'background.paper',
                        border: '1px solid',
                        borderColor: 'divider',
                        borderRadius: 2,
                        boxShadow: '0 4px 12px rgba(0, 0, 0, 0.15)',
                        minWidth: 200,
                    }}
                >
                    <Typography variant="body2" sx={{ fontWeight: 600, mb: 1.5 }}>
                        {data.dayLabel}
                    </Typography>

                    <Box sx={{ mb: 1.5 }}>
                        <Typography variant="caption" color="text.secondary">
                            本周 ({data.date.slice(5)})
                        </Typography>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2" sx={{ color: 'success.main' }}>
                                收入: ${data.income.toFixed(2)}
                            </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2" sx={{ color: 'error.main' }}>
                                支出: ${data.expensePositive.toFixed(2)}
                            </Typography>
                        </Box>
                    </Box>

                    <Box sx={{ mb: 1.5 }}>
                        <Typography variant="caption" color="text.secondary">
                            上周 ({data.lastWeekDate.slice(5)})
                        </Typography>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2" sx={{ color: 'success.light' }}>
                                收入: ${Math.abs(data.lastWeekIncome).toFixed(2)}
                            </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2" sx={{ color: 'error.light' }}>
                                支出: ${data.lastWeekExpensePositive.toFixed(2)}
                            </Typography>
                        </Box>
                    </Box>

                    <Box sx={{ borderTop: '1px solid', borderColor: 'divider', pt: 1 }}>
                        <Typography variant="caption" color="text.secondary">
                            环比变化
                        </Typography>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2" sx={{
                                color: Number(incomeChange) >= 0 ? 'success.main' : 'error.main'
                            }}>
                                收入: {Number(incomeChange) >= 0 ? '+' : ''}{incomeChange}%
                            </Typography>
                        </Box>
                        <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                            <Typography variant="body2" sx={{
                                color: Number(expenseChange) <= 0 ? 'success.main' : 'error.main'
                            }}>
                                支出: {Number(expenseChange) >= 0 ? '+' : ''}{expenseChange}%
                            </Typography>
                        </Box>
                    </Box>
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

        // 颜色定义
        const colors = {
            thisWeekIncome: '#4caf50',    // 绿色
            lastWeekIncome: '#81c784',    // 浅绿色
            thisWeekExpense: '#f44336',   // 红色
            lastWeekExpense: '#e57373',   // 浅红色
        };

        switch (chartType) {
            case 'line':
                return (
                    <LineChart {...commonProps}>
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                        <XAxis
                            dataKey="dayLabel"
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <YAxis
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend />
                        <ReferenceLine y={0} stroke="divider" strokeWidth={1} />
                        <Line
                            type="monotone"
                            dataKey="income"
                            name="本周收入"
                            stroke={colors.thisWeekIncome}
                            strokeWidth={2}
                            dot={{ fill: colors.thisWeekIncome, r: 4 }}
                        />
                        <Line
                            type="monotone"
                            dataKey="lastWeekIncome"
                            name="上周收入"
                            stroke={colors.lastWeekIncome}
                            strokeWidth={2}
                            strokeDasharray="5 5"
                            dot={{ fill: colors.lastWeekIncome, r: 3 }}
                        />
                        <Line
                            type="monotone"
                            dataKey="expense"
                            name="本周支出"
                            stroke={colors.thisWeekExpense}
                            strokeWidth={2}
                            dot={{ fill: colors.thisWeekExpense, r: 4 }}
                        />
                        <Line
                            type="monotone"
                            dataKey="lastWeekExpense"
                            name="上周支出"
                            stroke={colors.lastWeekExpense}
                            strokeWidth={2}
                            strokeDasharray="5 5"
                            dot={{ fill: colors.lastWeekExpense, r: 3 }}
                        />
                    </LineChart>
                );
            case 'area':
                return (
                    <AreaChart {...commonProps}>
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                        <XAxis
                            dataKey="dayLabel"
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <YAxis
                            stroke="text.secondary"
                            style={{ fontSize: '0.75rem' }}
                        />
                        <Tooltip content={<CustomTooltip />} />
                        <Legend />
                        <ReferenceLine y={0} stroke="divider" strokeWidth={1} />
                        <Area
                            type="monotone"
                            dataKey="income"
                            name="本周收入"
                            stroke={colors.thisWeekIncome}
                            fill={colors.thisWeekIncome}
                            fillOpacity={0.3}
                        />
                        <Area
                            type="monotone"
                            dataKey="lastWeekIncome"
                            name="上周收入"
                            stroke={colors.lastWeekIncome}
                            fill={colors.lastWeekIncome}
                            fillOpacity={0.2}
                        />
                        <Area
                            type="monotone"
                            dataKey="expense"
                            name="本周支出"
                            stroke={colors.thisWeekExpense}
                            fill={colors.thisWeekExpense}
                            fillOpacity={0.3}
                        />
                        <Area
                            type="monotone"
                            dataKey="lastWeekExpense"
                            name="上周支出"
                            stroke={colors.lastWeekExpense}
                            fill={colors.lastWeekExpense}
                            fillOpacity={0.2}
                        />
                    </AreaChart>
                );
            default:
                return (
                    <BarChart {...commonProps} barGap={2} barCategoryGap="20%">
                        <CartesianGrid strokeDasharray="3 3" stroke="rgba(148, 163, 184, 0.1)" />
                        <XAxis
                            dataKey="dayLabel"
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
                            name="本周收入"
                            fill={colors.thisWeekIncome}
                            radius={[2, 2, 0, 0]}
                        />
                        <Bar
                            dataKey="lastWeekIncome"
                            name="上周收入"
                            fill={colors.lastWeekIncome}
                            radius={[2, 2, 0, 0]}
                        />
                        <Bar
                            dataKey="expense"
                            name="本周支出"
                            fill={colors.thisWeekExpense}
                            radius={[0, 0, 2, 2]}
                        />
                        <Bar
                            dataKey="lastWeekExpense"
                            name="上周支出"
                            fill={colors.lastWeekExpense}
                            radius={[0, 0, 2, 2]}
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
                        每周收支对比
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
                    本周 vs 上周同一天对比
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
