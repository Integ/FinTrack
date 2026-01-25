#!/bin/bash

# 自定义域名快速配置脚本

echo "🌐 FinTrack 自定义域名配置工具"
echo "=================================="

# 检查参数
if [ $# -eq 0 ]; then
    echo "使用方法: ./setup-domain.sh <yourdomain.com>"
    echo "示例: ./setup-domain.sh fintrack.example.com"
    echo ""
    echo "支持的域名格式："
    echo "  - 子域名: fintrack.yourdomain.com"
    echo "  - www 域名: www.yourdomain.com"
    echo "  - 根域名: yourdomain.com"
    exit 1
fi

DOMAIN=$1

# 验证域名格式
if [[ ! $DOMAIN =~ ^[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
    echo "❌ 无效的域名格式: $DOMAIN"
    exit 1
fi

echo "✅ 域名格式验证通过: $DOMAIN"
echo ""

# 检查是否已存在 CNAME 文件
if [ -f "CNAME" ]; then
    echo "⚠️  检测到已存在的 CNAME 文件"
    echo "当前配置: $(cat CNAME)"
    echo ""
    read -p "是否要覆盖当前配置? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ 操作已取消"
        exit 1
    fi
fi

# 创建 CNAME 文件
echo "$DOMAIN" > CNAME
echo "✅ CNAME 文件已创建: $DOMAIN"

# 提交更改
echo ""
echo "📝 提交配置更改..."
git add CNAME
git commit -m "配置自定义域名: $DOMAIN"

# 询问是否推送
echo ""
read -p "是否立即推送到远程仓库? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    echo "📤 推送到远程仓库..."
    git push origin main
    echo "✅ 推送成功！"
fi

echo ""
echo "🎉 自定义域名配置完成！"
echo ""
echo "📋 后续步骤："
echo "1. 等待 GitHub Actions 完成部署"
echo "2. 配置 DNS 记录："
echo "   - 类型: CNAME"
echo "   - 主机: ${DOMAIN%%.*}"  # 提取子域名部分
echo "   - 值: [您的GitHub用户名].github.io"
echo "3. 在 GitHub Pages 设置中确认自定义域名"
echo ""
echo "📖 详细配置指南: ./CUSTOM_DOMAIN.md"
echo ""
echo "⏱️  DNS 传播可能需要几分钟到几小时时间"
echo "🌐 配置完成后访问: https://$DOMAIN"