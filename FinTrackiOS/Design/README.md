# App 图标

保留靛紫底色、金色猫头鹰、眨眼和抱金币的品牌形象。新版使用连续的圆润轮廓和一体面罩，去掉脚趾、腮红、独立眼圈和地面投影，减少桌面小尺寸下的视觉噪声。

| 文件 | 用途 |
|---|---|
| `AppIcon.svg` | 默认外观，柔和靛紫渐变背景 |
| `AppIcon-Dark.svg` | 深色外观，深靛蓝背景 |
| `AppIcon-Tinted.svg` | 着色外观，透明背景的专用灰度图形 |
| `AppIcon-Preview.png` | 三种外观及 60 / 40 / 29 px 尺寸预览；圆角仅用于预览 |
| `owl_icon.py` | 三种 SVG 的统一生成入口，保持几何与配色同步 |
| `render_svg.swift` | 用 macOS CoreSVG 导出 PNG，支持去除 alpha 通道 |

在本目录执行以下命令可重新生成生产素材：

```bash
python3 owl_icon.py
swiftc -O render_svg.swift -o /tmp/fintrack-render-svg
/tmp/fintrack-render-svg AppIcon.svg ../FinTrack/Assets.xcassets/AppIcon.appiconset/AppIcon.png 1024 opaque
/tmp/fintrack-render-svg AppIcon-Dark.svg ../FinTrack/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png 1024 opaque
/tmp/fintrack-render-svg AppIcon-Tinted.svg ../FinTrack/Assets.xcassets/AppIcon.appiconset/AppIcon-Tinted.png 1024
```

默认和深色 PNG 为 1024 × 1024 RGB，不含 alpha；着色 PNG 为 RGBA，图形为中性灰度。生产素材保持完整正方形，由系统处理圆角。
