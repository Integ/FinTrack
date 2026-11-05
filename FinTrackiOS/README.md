# FinTrack iOS（二手回收倒卖版）

给「去二手店收货 → 网上卖出」的小生意用的记账 App。SwiftUI，iOS 17+，数据只存在手机上。

## 核心思路

每件收回来的货都是一条**库存记录**（进价、店铺、收货日期）。卖出时从库存里选中它，App 就能算出：

- 这件货**放了几天才卖掉**、赚了多少、回报率多少
- 每类货**平均 / 中位多久卖掉**、平均利润、回报率、售罄率
- 哪家**店铺**收的货最赚钱、卖得最快
- 每一趟**收货回本了没有**（回款 ÷（进货 + 交通费））
- 哪些货**压太久**了、多少钱压在库存里

## 功能

| 页面 | 内容 |
|---|---|
| 首页 | 净利润 / 毛利 / 每件赚多少 / 平均几天卖出；库存和库龄分布；自动生成的经营建议；最近动态 |
| 收货 | 一次录入一趟的多件货（数量可批量）；按名称自动归类；**边录边显示历史均价、平均卖出天数、建议进价上限、按均价卖能赚多少**；可顺手记交通费 |
| 库存 | 在库件数、占用资金、挂牌合计、库龄条；筛选 待上架 / 在售 / 压货；左滑卖出或报废，右滑标记上架 |
| 卖出 | 从库存多选（打包卖按进价分摊售价）；或不关联库存直接填；实时显示利润、回报率、持有天数 |
| 记录 | 销售（按月汇总）、收货（每趟回本进度）、支出 |
| 分析 | 利润表（含现金流）、近 12 个月净利润、收货 vs 卖出、品类表现（多收 / 卖得慢 / 利润薄 / 压货）、售出速度分布、进价区间、店铺、渠道 |
| 查历史售价 | 在店里输入名称，看以前卖过几次、均价、价格区间、多久卖掉、库存里有没有同款 |
| 设置 | 货币、压货提醒天数、目标回报率（决定建议进价）；JSON 完整备份、记账 CSV、货品明细 CSV；导入 |

## 从旧版迁移

设置 → 导入备份或 CSV，选旧版导出的 `fintrack_backup_*.csv`：

- 收入 → 销售记录（旧的「类别」如 Marketplace 变成销售渠道）
- 按描述自动归类（「戴森 V10」→ 小家电，「TI-84」→ 计算器 …），旧数据立刻能参与品类利润分析
- 支出中的 Transportation / 交通 → 「交通」
- 追加模式会跳过重复记录

旧记录没有收货日期，所以只参与金额统计；「多久卖掉」从新记录开始积累。

## 开发

用 Xcode 打开 `FinTrack.xcodeproj`，运行 `FinTrack` scheme。Bundle ID 是 `com.vicecity.fintrack.ios`，真机运行前在 Signing 里选你的 Team。

命令行测试：

```bash
xcodebuild -project FinTrack.xcodeproj -scheme FinTrack -destination 'platform=iOS Simulator,name=iPhone 17' test
```

Debug 版支持启动参数，便于在模拟器里调试（见 `FinTrack/DebugLaunch.swift`）：
`-resetData YES`、`-importLedger <csv路径>`、`-demoInventory YES`、`-tab analytics`、`-records hauls`、`-sheet restock`。

## 代码结构

```
FinTrack/
  Model/      Day（无时区日期）、Models、AppStore（JSON 持久化）、Analytics（全部统计）、
              CSVCodec、CategoryGuesser（按名称归类）、Formatting
  Views/      Dashboard、Inventory（含货品详情）、Restock、SaleEditor、Records（含收货详情）、
              Analytics（含品类详情）、PriceCheck、ExpenseEditor、Settings、Components
FinTrackTests/  日期、归类、CSV、统计、存储的单元测试
```
