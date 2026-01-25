#!/bin/bash

# GitHub Pages 部署诊断脚本

echo "🔍 GitHub Pages 部署诊断工具"
echo "=================================="

# 检查仓库信息
echo "📁 仓库信息："
REPO_URL=$(git config --get remote.origin.url)
echo "   远程仓库: $REPO_URL"
echo "   当前分支: $(git branch --show-current)"
echo ""

# 检查build目录
echo "🏗️  Build 目录检查："
if [ -d "build" ]; then
    echo "   ✅ build 目录存在"
    echo "   📄 build/index.html: $([ -f "build/index.html" ] && echo "存在" || echo "不存在")"
    echo "   📁 build/static: $([ -d "build/static" ] && echo "存在" || echo "不存在")"
    echo "   📊 build 大小: $(du -sh build 2>/dev/null | cut -f1)"
else
    echo "   ❌ build 目录不存在"
fi
echo ""

# 检查CNAME文件
echo "🌐 域名配置："
if [ -f "CNAME" ]; then
    DOMAIN=$(cat CNAME)
    echo "   ✅ CNAME 文件存在: $DOMAIN"
    echo "   🔗 预期访问地址: https://$DOMAIN"
else
    echo "   ℹ️  无 CNAME 文件，使用默认域名"
    echo "   🔗 预期访问地址: https://[用户名].github.io/FinTrack"
fi

# 检查build/CNAME
if [ -f "build/CNAME" ]; then
    BUILD_DOMAIN=$(cat build/CNAME)
    echo "   ✅ build/CNAME 文件存在: $BUILD_DOMAIN"
else
    echo "   ⚠️  build/CNAME 文件不存在"
fi
echo ""

# 检查GitHub Pages设置
echo "⚙️  GitHub Pages 设置检查清单："
echo "   1. Settings > Pages 是否已启用？"
echo "   2. Source 是否设置为 'GitHub Actions'？"
echo "   3. Custom domain 是否正确配置？"
echo "   4. DNS 记录是否正确？"
echo ""

# 提供解决方案
echo "🔧 常见问题和解决方案："
echo ""
echo "❓ 问题：显示README而不是应用"
echo "   解决方案："
echo "   1. 确保 GitHub Pages Source 设置为 'GitHub Actions'"
echo "   2. 检查仓库设置是否启用了 Pages"
echo "   3. 确认 Actions 工作流运行成功"
echo ""
echo "❓ 问题：404错误"
echo "   解决方案："
echo "   1. 等待部署完成（可能需要几分钟）"
echo "   2. 检查文件路径是否正确"
echo "   3. 确认DNS配置"
echo ""
echo "❓ 问题：CSS/JS文件404"
echo "   解决方案："
echo "   1. 检查 build/static 目录结构"
echo "   2. 确认相对路径正确"
echo "   3. 重新触发部署"
echo ""

# 提供调试命令
echo "🔍 调试命令："
echo "   curl -I https://yourdomain.com"
echo "   检查服务器响应头"
echo ""
echo "   dig CNAME yourdomain.com"
echo "   检查DNS解析"
echo ""

echo "📞 如果问题仍然存在："
echo "   1. 查看 GitHub Actions 构建日志"
echo "   2. 检查仓库 Settings > Pages 状态"
echo "   3. 提交 Issue 到项目仓库"