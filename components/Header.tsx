import React, { useRef, useState } from 'react';
import { AppBar, Toolbar, Typography, IconButton, Box, Button, Menu, MenuItem } from '@mui/material';
import { Menu as MenuIcon, FileUpload as FileUploadIcon, FileDownload as FileDownloadIcon } from '@mui/icons-material';
import { useSelector, useDispatch } from 'react-redux';
import { RootState } from '../store';
import { Transaction } from '../types/transaction';
import { addTransaction } from '../store/transactionSlice';
import logo from '../assets/logo.png';

interface HeaderProps {
    onMenuClick: () => void;
}

const Header: React.FC<HeaderProps> = ({ onMenuClick }) => {
    const fileInputRef = useRef<HTMLInputElement>(null);
    const [anchorEl, setAnchorEl] = useState<null | HTMLElement>(null);
    const dispatch = useDispatch();
    const transactions = useSelector((state: RootState) => state.transactions.transactions);

    const handleExport = () => {
        // 将交易数据转换为CSV格式
        const headers = ['日期', '类型', '金额', '类别', '描述'];
        const csvContent = [
            headers.join(','),
            ...transactions.map(t => [
                t.date,
                t.type,
                t.amount,
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

            // 跳过表头，处理每一行数据
            lines.slice(1).forEach(line => {
                if (!line.trim()) return; // 跳过空行
                
                const values = line.split(',');
                const transaction: Omit<Transaction, 'id'> = {
                    date: values[0],
                    type: values[1] as 'income' | 'expense',
                    amount: parseFloat(values[2]),
                    category: values[3],
                    description: values[4].replace(/^"|"$/g, '').replace(/""/g, '"'), // 处理引号
                };

                // 添加到 store
                dispatch(addTransaction({
                    ...transaction,
                    id: crypto.randomUUID(), // 生成新的 ID
                }));
            });
        };
        reader.readAsText(file);
        
        // 清除文件输入，允许重复导入同一个文件
        if (fileInputRef.current) {
            fileInputRef.current.value = '';
        }
    };

    return (
        <AppBar 
            position="static" 
            sx={{ 
                background: 'linear-gradient(45deg, #FFD700 30%, #DAA520 90%)',
                boxShadow: '0 3px 5px 2px rgba(218, 165, 32, .3)'
            }}>
            <Toolbar>
                <Box sx={{ display: 'flex', alignItems: 'center', flexGrow: 1 }}>
                    <Box
                        component="img"
                        src={logo}
                        alt="FinTrack Logo"
                        sx={{
                            height: 40,
                            mr: 2,
                            objectFit: 'contain'
                        }}
                    />
                    {/* Full title on sm and up, shorter title on xs (mobile) */}
                    <Typography variant="h6" component="div" sx={{ display: { xs: 'none', sm: 'block' } }}>
                        FinTrack - 您的个人财务管理助手
                    </Typography>
                    <Typography variant="h6" component="div" sx={{ display: { xs: 'block', sm: 'none' } }}>
                        FinTrack - 财务管理助手
                    </Typography>
                </Box>
                <Box sx={{ display: 'flex', gap: 1, alignItems: 'center' }}>
                    {/* Desktop / larger screens: show buttons */}
                    <Box sx={{ display: { xs: 'none', sm: 'flex' }, gap: 1 }}>
                        <Button
                            color="inherit"
                            startIcon={<FileUploadIcon />}
                            onClick={() => fileInputRef.current?.click()}
                        >
                            导入
                        </Button>
                        <Button
                            color="inherit"
                            startIcon={<FileDownloadIcon />}
                            onClick={handleExport}
                        >
                            导出
                        </Button>
                    </Box>

                    {/* Mobile: menu icon that opens a menu with import/export */}
                    <Box sx={{ display: { xs: 'flex', sm: 'none' } }}>
                        <IconButton
                            color="inherit"
                            aria-label="open import export menu"
                            onClick={(e) => setAnchorEl(e.currentTarget)}
                        >
                            <MenuIcon />
                        </IconButton>
                        <Menu
                            anchorEl={anchorEl}
                            open={Boolean(anchorEl)}
                            onClose={() => setAnchorEl(null)}
                        >
                            <MenuItem onClick={() => { setAnchorEl(null); fileInputRef.current?.click(); }}>
                                <FileUploadIcon sx={{ mr: 1 }} /> 导入
                            </MenuItem>
                            <MenuItem onClick={() => { setAnchorEl(null); handleExport(); }}>
                                <FileDownloadIcon sx={{ mr: 1 }} /> 导出
                            </MenuItem>
                        </Menu>
                    </Box>

                    <input
                        type="file"
                        ref={fileInputRef}
                        accept=".csv"
                        style={{ display: 'none' }}
                        onChange={handleImport}
                    />
                </Box>
            </Toolbar>
        </AppBar>
    );
};

export default Header;