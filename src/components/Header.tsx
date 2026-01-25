import React, { useRef } from 'react';
import { AppBar, Toolbar, Typography, IconButton, Box, Tooltip } from '@mui/material';
import { FileUpload as FileUploadIcon, FileDownload as FileDownloadIcon } from '@mui/icons-material';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';
import { addTransaction } from '../store/transactionSlice';


const Header: React.FC = () => {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const dispatch = useDispatch();
    const transactions = useSelector((state: RootState) => state.transactions.transactions);

    const handleExport = () => {
        // 将交易数据转换为CSV格式
        const headers = ['日期', '类型', '金额', '成本', '类别', '描述'];
        const csvContent = [
            headers.join(','),
            ...transactions.map(t => [
                t.date,
                t.type,
                t.amount,
                // 对于收入类型，导出成本字段；对于支出类型，导出空字符串或0
                t.type === 'income' ? (t.cost !== undefined ? t.cost : '') : '',
                t.category,
                `"${t.description.replace(/"/g, '""')}"`  // 处理描述中的引号
            ].join(','))
        ].join('\n');

        // 添加 BOM 标记以确保 Excel 正确识别 UTF-8 编码
        const BOM = '\ufeff';
        // 创建下载链接
        const blob = new Blob([BOM + csvContent], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        link.download = `fintrack_backup_${new Date().toISOString().split('T')[0]}.csv`;
        link.click();
    };

    const handleImport = (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            const text = e.target?.result as string;
            // 处理不同操作系统的换行符
            const lines = text.replace(/\r\n/g, '\n').split('\n');

            // 解析表头，判断CSV格式版本
            const headerLine = lines[0];
            // 使用相同的CSV解析逻辑处理表头
            const parseCSVLine = (line: string): string[] => {
                const values: string[] = [];
                let current = '';
                let inQuotes = false;
                
                for (let i = 0; i < line.length; i++) {
                    const char = line[i];
                    if (char === '"') {
                        if (inQuotes && line[i + 1] === '"') {
                            current += '"';
                            i++;
                        } else {
                            inQuotes = !inQuotes;
                        }
                    } else if (char === ',' && !inQuotes) {
                        values.push(current);
                        current = '';
                    } else {
                        current += char;
                    }
                }
                values.push(current);
                return values;
            };
            
            const headers = parseCSVLine(headerLine);
            const hasCostColumn = headers.includes('成本') || headers.length > 5;
            const costIndex = headers.includes('成本') ? headers.indexOf('成本') : 3; // 默认成本在索引3位置
            
            // 跳过表头，处理每一行数据
            lines.slice(1).forEach(line => {
                if (!line.trim()) return; // 跳过空行
                
                // 使用相同的CSV解析逻辑处理数据行
                const values = parseCSVLine(line);
                
                // 兼容旧格式（没有成本列）和新格式（有成本列）
                const dateIndex = 0;
                const typeIndex = 1;
                const amountIndex = 2;
                const categoryIndex = hasCostColumn ? 4 : 3;
                const descriptionIndex = hasCostColumn ? 5 : 4;
                
                const transactionType = values[typeIndex] as 'income' | 'expense';
                const transaction: Transaction = {
                    id: crypto.randomUUID(),
                    date: values[dateIndex],
                    type: transactionType,
                    amount: parseFloat(values[amountIndex]) || 0,
                    category: values[categoryIndex] || '',
                    description: values[descriptionIndex]?.replace(/^"|"$/g, '').replace(/""/g, '"') || '',
                };

                // 如果是收入类型且有成本列，设置成本字段
                if (transactionType === 'income' && hasCostColumn && values[costIndex] !== undefined && values[costIndex].trim() !== '') {
                    const costValue = parseFloat(values[costIndex]);
                    if (!isNaN(costValue)) {
                        transaction.cost = costValue;
                    }
                }

                // 添加到 store
                dispatch(addTransaction(transaction));
            });
        };
        reader.readAsText(file);
        
        // 清除文件输入，允许重复导入同一个文件
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    return (
        <AppBar position="static" sx={{ height: 64 }}>
            <Toolbar sx={{ height: 64, minHeight: 'auto !important' }}>
                <Box sx={{ display: 'flex', alignItems: 'center', flexGrow: 1 }}>
                    <Typography 
                        variant="h6" 
                        component="div" 
                        sx={{ 
                            fontWeight: 600,
                            fontSize: '1.125rem',
                            letterSpacing: '-0.025em'
                        }}
                    >
                        FinTrack
                    </Typography>
                </Box>
                
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                    <Tooltip title="导入数据">
                        <IconButton
                            size="small"
                            onClick={() => fileInputRef.current?.click()}
                            sx={{ 
                                color: 'text.secondary',
                                '&:hover': { color: 'primary.main' }
                            }}
                        >
                            <FileUploadIcon fontSize="small" />
                        </IconButton>
                    </Tooltip>
                    
                    <Tooltip title="导出数据">
                        <IconButton
                            size="small"
                            onClick={handleExport}
                            sx={{ 
                                color: 'text.secondary',
                                '&:hover': { color: 'primary.main' }
                            }}
                        >
                            <FileDownloadIcon fontSize="small" />
                        </IconButton>
                    </Tooltip>
                </Box>

                <input
                    type="file"
                    ref={fileInputRef}
                    accept=".csv"
                    style={{ display: 'none' }}
                    onChange={handleImport}
                />
            </Toolbar>
        </AppBar>
    );
};

export default Header;