#!/bin/bash

# CI构建验证脚本

echo "🔍 GitHub Actions CI 验证工具"
echo "=============================="

echo "📋 检查清单："
echo ""

# 1. 检查ESLint错误
echo "1. 检查ESLint状态..."
if npm run build 2>&1 | grep -q "Failed to compile"; then
    echo "   ❌ 发现ESLint错误或编译失败"
    echo "   🔧 运行 npm run build 查看详细信息"
    exit 1
else
    echo "   ✅ 无ESLint错误，编译成功"
fi

# 2. 检查关键文件
echo ""
echo "2. 检查构建产物..."
if [ -f "build/index.html" ] && [ -d "build/static" ]; then
    echo "   ✅ 构建文件完整"
else
    echo "   ❌ 构建文件缺失"
    exit 1
fi

# 3. 检查依赖同步
echo ""
echo "3. 检查依赖状态..."
if [ -f "package-lock.json" ]; then
    echo "   ✅ package-lock.json 存在"
else
    echo "   ❌ package-lock.json 缺失"
    echo "   🔧 运行 npm install 重新生成"
    exit 1
fi

# 4. 检查代码质量
echo ""
echo "4. 检查代码质量..."
unused_imports=$(grep -r "import.*from" src/ | grep -E "(useState|useMediaQuery|useTheme|DollarSignIcon)" | wc -l)
if [ "$unused_imports" -gt 0 ]; then
    echo "   ⚠️  发现可能的未使用导入"
    echo "   🔧 请检查并清理未使用的代码"
else
    echo "   ✅ 代码导入检查通过"
fi

echo ""
echo "🎉 CI验证通过！"
echo ""
echo "📤 可以安全地推送到 main 分支触发 GitHub Actions"
echo "🌐 部署完成后访问您的自定义域名"