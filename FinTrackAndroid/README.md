# FinTrack Android

FinTrack 的原生 Android 版本，以 `FinTrackiOS` 的功能和数据语义为基线，界面使用 Jetpack Compose 与 Material 3。

## 功能

- 收入、关联成本和额外支出记录、编辑、删除
- 今日 / 7 天 / 30 天汇总与每日收支图表
- 分类和备注搜索、收入/支出筛选、按日期分组
- 本地 JSON 持久化，数据不会上传网络
- 与 Web / iOS 版兼容的 CSV 导入导出，支持追加或替换
- CNY、USD、CAD、EUR 与系统默认货币
- 简体中文和英文，自动跟随 Android 系统语言
- Material 3 动态配色、深色模式和系统文件选择器

## 环境

- Android Studio Koala (2024.1.1) 或兼容版本
- JDK 17
- Android SDK 34
- 最低 Android 8.0（API 26）

## 运行

用 Android Studio 打开本目录，等待 Gradle 同步完成后运行 `app` 配置。

命令行验证：

```bash
./gradlew testDebugUnitTest assembleDebug
```

Debug APK 位于 `app/build/outputs/apk/debug/app-debug.apk`。
