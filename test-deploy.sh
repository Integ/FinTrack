#!/bin/bash

# 快速部署测试脚本

echo "🧪 部署测试和修复验证"
echo "=========================="

# 1. 清理环境
echo "🧹 清理环境..."
rm -rf node_modules package-lock.json build

# 2. 重新安装依赖
echo "📦 安装依赖..."
npm install --prefer-offline --no-audit

# 3. 构建项目
echo "🏗️  构建项目..."
npm run build

# 4. 检查构建结果
if [ $? -eq 0 ]; then
    echo "✅ 构建成功"
    echo "📁 检查关键文件："
    
    required_files=("build/index.html" "build/static" "build/manifest.json")
    for file in "${required_files[@]}"; do
        if [ -e "$file" ]; then
            echo "   ✅ $file"
        else
            echo "   ❌ $file (缺失)"
            exit 1
        fi
    done
    
    # 5. 部署测试
    echo ""
    echo "📤 执行部署测试..."
    if [ -f "CNAME" ]; then
        echo "🌐 检测到自定义域名: $(cat CNAME)"
        cp CNAME build/CNAME
    fi
    
    touch build/.nojekyll
    echo "✅ 准备部署文件"
    
    echo ""
    echo "🎯 所有测试通过！"
    echo "📋 现在可以安全地运行："
    echo "   ./deploy.sh"
    echo "   或者推送到 main 分支触发 GitHub Actions"
    
else
    echo "❌ 构建失败，请检查代码"
    exit 1
fi