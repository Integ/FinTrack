# FinTrack - 二手回收转卖小生意记账

<div align="center">
  <img src="logo.svg" alt="FinTrack Logo" width="200"/>

  [![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)
  [![iOS](https://img.shields.io/badge/iOS-SwiftUI-orange.svg)](FinTrackiOS/README.md)
  [![Web](https://img.shields.io/badge/Web-React%2018-blue.svg)](#web-版)
  [![Android](https://img.shields.io/badge/Android-Jetpack%20Compose-3DDC84.svg)](FinTrackAndroid/README.md)
</div>

给「去二手店收货 → 网上转卖」这类小生意用的记账工具。不只记收支，还跟踪**每件货从收货到卖出的全过程**，回答这些问题：

- 每类货平均多久卖掉？哪类最赚钱、回报率多少？
- 哪家二手店收的货最值得去？这一趟收货回本了没有？
- 哪些货压太久了，有多少钱压在库存里？
- 在店里看到一件货，以前卖过多少钱、值不值得收？

数据只保存在你自己的设备上，不上传任何服务器。

## 三个版本

| 版本 | 技术 | 定位 | 目录 |
|---|---|---|---|
| **iOS** | SwiftUI · iOS 17+ | 主力版本：收货、库存、卖出关联、经营分析 | [`FinTrackiOS/`](FinTrackiOS/README.md) |
| **Web** | React 18 · TypeScript · MUI · Redux Toolkit · Recharts | 浏览器里记收支，部署在 GitHub Pages | [`src/`](src/) |
| **Android** | Kotlin · Jetpack Compose · Material 3 | 原生收支记账，功能与 Web 版一致 | [`FinTrackAndroid/`](FinTrackAndroid/README.md) |

库存、收货和经营分析目前只在 iOS 版。三个版本通过同一种 CSV 格式互通（见[数据互通](#数据互通)）。

## iOS 版

完整说明见 [FinTrackiOS/README.md](FinTrackiOS/README.md)。

- **收货**：一次录入一趟的店铺、多件货、进价和交通费；按名称自动归类；边录边显示这类货的历史均价、平均几天卖掉、建议进价上限
- **库存**：在库件数、占用资金、库龄分布；压货提醒；左滑卖出 / 报废，右滑标记上架
- **卖出**：从库存选中卖出的货（可多件打包），自动算利润、回报率、持有天数
- **分析**：利润表（含现金流）、近 12 个月趋势、品类表现（多收 / 卖得慢 / 利润薄 / 压货）、售出速度、进价区间、店铺对比、每趟收货的回本进度
- **查历史售价**：在店里输入名称，看以前卖过几次、均价、多久卖掉、库存里有没有同款
- **经营建议**：根据自己的数据自动给出提示，比如最赚钱的品类、压货、交通费占比
- **备份**：JSON 完整备份、记账 CSV、货品明细 CSV；首次安装会自动迁移旧版 App 的数据

## Web 版

在线使用：**https://integ.eu.cc/FinTrack/**

- 记录收入（可填关联成本）和支出，编辑、删除、分页浏览
- 收入、净利润、成本、支出汇总
- 今日 / 7 天 / 30 天统计和每日报告，周收支对比图
- 中英文切换，适配手机和桌面
- CSV 导入导出

## Android 版

完整说明见 [FinTrackAndroid/README.md](FinTrackAndroid/README.md)。

- 收入、关联成本和支出的记录、编辑、删除
- 今日 / 7 天 / 30 天汇总与每日收支图表，分类和备注搜索
- CSV 导入导出（追加或替换），多币种，中英文，Material 3 动态配色

## 数据互通

三个版本都支持同一种记账 CSV：

```
日期,类型,金额,成本,类别,描述
2026-11-04,income,200,100,"Marketplace","罗技G25"
2026-11-04,expense,6,,"Transportation","daypass"
```

- iOS 导入这种 CSV 时：收入变成销售记录，「类别」作为销售渠道，并按描述自动归类货品（「戴森 V10」→ 小家电，「TI-84」→ 计算器）
- iOS 导出的记账 CSV 可以直接导入 Web 和 Android 版，但收货、库存和卖出关联只保存在 iOS 的 JSON 完整备份里

## 快速开始

### Web

需要 Node.js 18+。

```bash
npm install
npm start          # http://localhost:3000
npm run build      # 生产构建，输出到 build/
npm test
```

### iOS

需要 Xcode 16+。用 Xcode 打开 `FinTrackiOS/FinTrack.xcodeproj`，运行 `FinTrack` scheme。Bundle ID 是 `com.vicecity.fintrack`，签名 Team 是 Shanghai ViceCity Technology（`XVP69344DG`）。

```bash
cd FinTrackiOS
xcodebuild -project FinTrack.xcodeproj -scheme FinTrack -destination 'platform=iOS Simulator,name=iPhone 17' test
```

装到真机的命令见 [FinTrackiOS/README.md](FinTrackiOS/README.md#开发)。

### Android

需要 Android Studio、JDK 17、Android SDK 34。用 Android Studio 打开 `FinTrackAndroid`，或：

```bash
cd FinTrackAndroid
./gradlew testDebugUnitTest assembleDebug
```

## 分支与部署

- Web、iOS、Android 三个版本的代码都在同一个仓库，统一合并到 **`main`** 分支；`main` 始终是最新、可用的版本
- 新功能在单独分支上开发，测试通过后合并回 `main`
- 推送到 `main` 会触发 GitHub Actions（[`deploy.yml`](.github/workflows/deploy.yml)）自动构建 Web 版并发布到 GitHub Pages；iOS 和 Android 版需要在本地编译安装

## 项目结构

```
FinTrack/
├── FinTrackiOS/          # SwiftUI iOS App（收货、库存、经营分析）
│   ├── FinTrack/         #   Model/ 数据与统计，Views/ 界面
│   └── FinTrackTests/    #   单元测试
├── FinTrackAndroid/      # Kotlin + Jetpack Compose Android App
├── src/                  # React Web 版
│   ├── components/       #   界面组件
│   ├── pages/            #   页面
│   ├── store/            #   Redux 状态与本地存储
│   ├── i18n/             #   中英文翻译
│   └── types/            #   TypeScript 类型
├── public/               # Web 静态资源
└── .github/workflows/    # GitHub Pages 自动部署
```

## 许可证

本项目采用 [GNU GPL v3](LICENSE) 许可证。
