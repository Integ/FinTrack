#!/bin/bash

# GitHub Pages 部署修复脚本

echo "🔧 GitHub Pages 部署修复工具"
echo "=================================="

# 重新构建项目
echo "🏗️  重新构建项目..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ 构建失败，请修复构建错误"
    exit 1
fi

echo "✅ 构建成功"

# 确保build目录结构正确
echo "📁 检查 build 目录结构..."

required_files=("index.html" "static" "manifest.json")
for file in "${required_files[@]}"; do
    if [ -e "build/$file" ]; then
        echo "   ✅ build/$file 存在"
    else
        echo "   ❌ build/$file 不存在"
        exit 1
    fi
done

# 处理自定义域名
if [ -f "CNAME" ]; then
    echo "🌐 处理自定义域名..."
    cp CNAME build/CNAME
    echo "   ✅ CNAME 文件已复制到 build 目录"
    echo "   📡 域名: $(cat CNAME)"
fi

# 检查是否有 .nojekyll 文件（GitHub Pages需要）
touch build/.nojekyll
echo "   ✅ 创建 .nojekyll 文件（禁用 Jekyll）"

# 提交和推送
echo ""
echo "📝 提交修复..."

git add .
git commit -m "修复 GitHub Pages 部署配置

🔧 修复内容：
- 移除 package.json 中的 homepage 配置
- 确保 build 目录结构完整
- 添加 .nojekyll 文件禁用 Jekyll
- 优化 GitHub Actions 工作流
- 改进自定义域名处理

🎯 解决目标：
- 修复显示 README 而不是应用的问题
- 确保正确的文件路径解析
- 优化 GitHub Pages 部署流程"

echo "📤 推送到远程仓库..."
git push origin main

echo ""
echo "🎉 修复完成！"
echo ""
echo "📋 检查清单："
echo "1. 等待 GitHub Actions 完成构建"
echo "2. 在 Settings > Pages 中确认配置："
echo "   ✅ Source: GitHub Actions"
echo "   ✅ Custom domain: 已正确设置（如果有）"
echo "3. 检查 Actions 标签页的构建状态"
echo ""
echo "⏱️  部署可能需要 1-5 分钟生效"
echo ""
echo "🔍 如果问题仍然存在："
echo "   ./diagnose-deployment.sh"
echo "   检查详细诊断信息"