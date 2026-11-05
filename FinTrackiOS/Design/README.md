# App 图标

可爱的猫头鹰：靛蓝背景（和 App 主色一致）、暖金色猫头鹰（延续旧 logo 的金色和眨眼）、抱着一枚金币（记账 / 赚钱）。

| 文件 | 用途 |
|---|---|
| `AppIcon.svg` | 浅色图标（带背景）→ `AppIcon.png` |
| `AppIcon-Dark.svg` | 深色模式图标（透明背景）→ `AppIcon-Dark.png`；着色模式用它的灰度版 `AppIcon-Tinted.png` |
| `owl_icon.py` | 图标生成脚本，`CONCEPTS` 里有 A–D 四个方案，App 用的是 D |
| `render_svg.swift` | 用 macOS 自带的 CoreSVG 把 SVG 渲染成 PNG |

```bash
swiftc -O render_svg.swift -o /tmp/render_svg
/tmp/render_svg AppIcon.svg ../FinTrack/Assets.xcassets/AppIcon.appiconset/AppIcon.png 1024 opaque
/tmp/render_svg AppIcon-Dark.svg ../FinTrack/Assets.xcassets/AppIcon.appiconset/AppIcon-Dark.png 1024
```

浅色图标要加 `opaque`：App Store 不接受带透明通道的图标。
