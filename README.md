# FinTrack - 专业副业财务管理工具

<div align="center">
  <img src="assets/logo.png" alt="FinTrack Logo" width="200"/>
  
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
  [![React](https://img.shields.io/badge/React-18.2.0-blue.svg)](https://reactjs.org/)
  [![TypeScript](https://img.shields.io/badge/TypeScript-4.9.5-blue.svg)](https://www.typescriptlang.org/)
  [![Material-UI](https://img.shields.io/badge/Material--UI-5.15.1-blue.svg)](https://mui.com/)
  [![Redux](https://img.shields.io/badge/Redux-Toolkit-764ABC.svg)](https://redux.js.org/)
</div>

## ✨ 功能特性

🏦 **财务管理** - 轻松记录收入、支出和成本  
📊 **数据可视化** - 实时图表展示收支趋势  
📱 **响应式设计** - 完美适配手机和桌面端  
🎨 **专业界面** - 现代化UI设计，简洁高效  
💾 **数据导入导出** - 支持CSV格式的数据备份和恢复  
🔍 **分类管理** - 灵活的交易分类系统  
📈 **利润分析** - 自动计算净利润和成本分析  

## 🚀 快速开始

### 环境要求

- Node.js 16+ 
- npm 或 yarn

### 本地开发

```bash
# 克隆项目
git clone https://github.com/[您的用户名]/FinTrack.git
cd FinTrack

# 安装依赖
npm install

# 启动开发服务器
npm start
```

访问 http://localhost:3000 查看应用

## 🌐 部署到 GitHub Pages

### 自动部署（推荐）

1. **启用GitHub Pages**
   - 进入仓库 Settings > Pages
   - Source 选择 "GitHub Actions"

2. **推送代码**
   ```bash
   git add .
   git commit -m "提交代码"
   git push origin main
   ```

3. **查看部署**
   - 在 Actions 标签页查看部署进度
   - 完成后访问：`https://[您的用户名].github.io/FinTrack`

### 手动部署

```bash
# 使用部署脚本
./deploy.sh

# 或手动部署
npm run deploy
```

### 🌐 自定义域名配置

如果您想使用自定义域名：

1. **在 GitHub Pages 中设置**
   - Settings > Pages > Custom domain
   - 输入您的域名（如：fintrack.yourdomain.com）

2. **配置 DNS 记录**
   - 根据域名提供商添加 CNAME 或 A 记录
   - 详细指南请查看：[CUSTOM_DOMAIN.md](./CUSTOM_DOMAIN.md)

3. **通过代码管理域名**
```bash
# 方法一：手动创建 CNAME 文件
echo "yourdomain.com" > CNAME
git add CNAME
git commit -m "配置自定义域名"
git push origin main

# 方法二：使用配置脚本（推荐）
./setup-domain.sh fintrack.yourdomain.com
```

## 📱 在线演示

🔗 **体验地址**：`https://[您的用户名].github.io/FinTrack`

## 🛠️ 技术栈

| 技术 | 版本 | 用途 |
|------|------|------|
| React | 18.2.0 | 前端框架 |
| TypeScript | 4.9.5 | 类型安全 |
| Material-UI | 5.15.1 | UI组件库 |
| Redux Toolkit | 2.11.2 | 状态管理 |
| Recharts | 2.8.0 | 图表组件 |
| React Router | 6.x+ | 路由管理 |
| gh-pages | 6.1.1 | 部署工具 |

## 📁 项目结构

```
FinTrack/
├── public/           # 静态资源
│   ├── index.html    # HTML模板
│   └── manifest.json # PWA配置
├── src/             # 源代码
│   ├── components/   # React组件
│   ├── pages/       # 页面组件
│   ├── store/       # Redux状态管理
│   ├── types/       # TypeScript类型定义
│   └── assets/      # 资源文件
├── .github/workflows/ # GitHub Actions配置
└── build/          # 构建输出
```

## 🔧 开发脚本

```bash
npm start          # 启动开发服务器
npm run build      # 构建生产版本
npm test           # 运行测试
npm run deploy     # 部署到GitHub Pages
./deploy.sh        # 使用部署脚本（推荐）
./setup-domain.sh # 配置自定义域名
```

## 📊 核心功能

### 💰 财务概览
- 实时显示总收入、净利润、成本和支出
- 卡片式布局，数据一目了然
- 自动计算利润率和成本占比

### 📝 交易管理
- 添加收入/支出记录
- 支持成本关联（收入类型）
- 灵活的分类系统
- 编辑和删除功能

### 📈 数据分析
- 30天收支趋势图表
- 支持柱状图、折线图、面积图
- 实时数据更新
- 交互式图表体验

### 📤 数据管理
- CSV格式数据导出
- 支持数据导入恢复
- 自动备份功能

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 项目
2. 创建功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情

## 🙏 致谢

感谢以下开源项目：
- [React](https://reactjs.org/)
- [Material-UI](https://mui.com/)
- [Redux Toolkit](https://redux.js.org/)
- [Recharts](https://recharts.org/)
- [TypeScript](https://www.typescriptlang.org/)

---

<div align="center">
  <p>用 ❤️ 为自由职业者和副业创业者打造</p>
</div>