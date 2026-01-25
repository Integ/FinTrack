#!/bin/bash

# FinTrack GitHub Pages 部署脚本

echo "🚀 开始部署 FinTrack 到 GitHub Pages..."

# 检查是否有未提交的更改
if [[ -n $(git status --porcelain) ]]; then
    echo "⚠️  检测到未提交的更改，请先提交所有更改："
    echo "   git add ."
    echo "   git commit -m \"你的提交信息\""
    echo "   git push origin main"
    exit 1
fi

echo "✅ 代码状态检查通过"

# 安装依赖（如果需要）
if [ ! -d "node_modules" ]; then
    echo "📦 安装依赖..."
    npm install
fi

# 构建项目
echo "🔨 构建项目..."
npm run build

if [ $? -eq 0 ]; then
    echo "✅ 构建成功！"
    
    # 处理自定义域名
    if [ -f "CNAME" ]; then
        echo "🌐 检测到 CNAME 文件，配置自定义域名..."
        cp CNAME build/CNAME
        DOMAIN=$(cat CNAME)
        echo "📡 自定义域名: $DOMAIN"
    else
        echo "ℹ️  使用默认 GitHub Pages 域名"
        echo "💡 要使用自定义域名，请创建 CNAME 文件"
    fi
    
    # 确保构建文件正确
    touch build/.nojekyll
    echo "✅ 创建 .nojekyll 文件"
    
    # 部署到 GitHub Pages
    echo "📤 部署到 GitHub Pages..."
    npx gh-pages -d build --dotfiles=true
    
    if [ $? -eq 0 ]; then
        echo "🎉 部署成功！"
        echo ""
        echo "📱 您的应用将在几分钟内可访问："
        if [ -f "CNAME" ]; then
            echo "   🌐 自定义域名: https://$DOMAIN"
            echo ""
            echo "🔧 域名配置检查清单："
            echo "   1. DNS 记录: CNAME 或 A 记录已正确配置"
            echo "   2. GitHub Pages: Settings > Pages > Custom domain 已设置"
            echo "   3. HTTPS: 等待 SSL 证书自动配置完成"
        else
            echo "   📡 GitHub Pages: https://[您的用户名].github.io/FinTrack"
        fi
        echo ""
        echo "💡 部署提示："
        echo "   1. 请确保在 Settings > Pages 中启用了 GitHub Pages"
        echo "   2. 选择 Source 为 'GitHub Actions'"
        echo "   3. 首次部署可能需要几分钟时间"
        echo "   4. 自定义域名可能需要 DNS 传播时间"
        echo ""
        echo "🔍 测试访问："
        if [ -f "CNAME" ]; then
            echo "   主页: https://$DOMAIN"
            echo "   测试页: https://$DOMAIN/deploy-test.html"
        else
            echo "   主页: https://[您的用户名].github.io/FinTrack"
        fi
    else
        echo "❌ 部署失败！"
        exit 1
    fi
else
    echo "❌ 构建失败！"
    exit 1
fi