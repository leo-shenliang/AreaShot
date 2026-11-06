# AreaShot

macOS 选区截图原型：菜单栏常驻，按 `Option + Shift + A` 或菜单项进入选区，松开鼠标后截图并弹出预览（自动复制到剪贴板）。

> 当前分享版只暴露「区域截图」入口。全屏、一体化、定时、重复上次、剪贴板、
> 窗口吸附与窗口阴影暂时隐藏，相关实现仍保留在代码中，便于后续恢复。

## 环境要求

- macOS 14+
- Swift 6.x（Command Line Tools 即可，不要求完整 Xcode）

## 构建与运行

```bash
chmod +x scripts/build-app.sh
./scripts/build-app.sh
open build/AreaShot.app
```

首次触发截图时，系统会要求「屏幕录制」权限：

1. 在提示中允许，或到「系统设置 > 隐私与安全性 > 屏幕录制」勾选 AreaShot
2. 授权后重新启动应用（TCC 对进程生效）

## 打包分享

```bash
./scripts/package-dmg.sh
```

生成 `dist/AreaShot-<版本>-universal.dmg`（arm64 + x86_64），内含
`Applications` 快捷方式和安装说明。

分发版使用 ad-hoc 签名，未经 Apple 公证，朋友首次打开需要右键点击应用 →
「打开」，或在「系统设置 > 隐私与安全性」中点击「仍要打开」。若本机有
Developer ID，可传入签名身份：

```bash
CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" ./scripts/package-dmg.sh
```

仍需使用 `notarytool` 公证并 stapling 后才能免除首次确认。

## 已实现

- 菜单栏图标与菜单
- 快捷键：`Option + Shift + A` 区域截图
- 截图模式：区域、窗口吸附、全屏、All-in-One（Area/Window/Screen 切换）、5 秒自拍定时、重复上次区域、从剪贴板截图
- 捕获选项：显示光标、包含窗口阴影
- 多显示器：每块屏幕一个选区覆盖层
- 标注工具：选择、箭头（标准/双头/曲线）、直线、矩形、椭圆、画笔、高亮、文字、序号、聚光灯、放大镜、马赛克、模糊、纯色遮盖
- 编辑器工具栏：上方为工具选择 + 随当前工具变化的属性（颜色/线宽/箭头样式/文字样式/聚光灯/强度/序号），下方为缩放、图层、撤销/重做、插图、Emoji、Pin、复制、保存、关闭
- 聚光灯：可调变暗程度与椭圆/矩形形状；马赛克/模糊：可调强度；序号可重置
- 文字：内联输入、自动扩展、四套样式、对齐/字重/字体/字号
- 对象：多选、移动、八向缩放、对齐吸附、复制/粘贴、层级调整、锁定/隐藏、图层列表
- 插入图片、Emoji
- Pin 浮窗：置顶显示、拖动、缩放、复制、关闭
- 编辑后可复制到剪贴板或保存 PNG；撤销/重做（Cmd+Z / Cmd+Shift+Z）

## 结构

```
Sources/AreaShot/
  main.swift                 应用入口（accessory 模式，无 Dock 图标）
  AppDelegate.swift          权限检查与截图流程编排
  StatusItemController.swift 菜单栏与菜单
  HotKeyManager.swift        Carbon 全局快捷键
  SelectionOverlay.swift     覆盖层窗口与选区视图
  ScreenCaptureService.swift ScreenCaptureKit 截图与裁剪
  AnnotationEditor.swift      标注画布、工具与编辑器窗口
Support/Info.plist
Support/AppIcon.icns          应用图标
scripts/build-app.sh
scripts/package-dmg.sh       通用版 DMG 打包
scripts/make-icon.swift      图标绘制脚本
```

## 原型边界与后续

当前只覆盖单屏内选区（跨屏拖拽会被限制在起始屏幕）。

尚未实现：

1. 跨屏选区（需要全局选区会话与多屏拼接）
2. 裁剪、旋转、翻转（需要可调整尺寸的编辑器与文档级变换撤销）
3. 背景美化（壁纸/纯色/透明、内边距、投影）
4. 对象旋转
5. 隐藏桌面图标、录制时隐藏通知（系统级行为）

## 注意

- 截图为全屏捕获后裁剪，保证不同显示器坐标系下结果正确；若追求性能，可改用 `SCStreamConfiguration.sourceRect` 直接截取选区。
- 覆盖层关闭后延迟 80ms 再截图，避免遮罩本身被拍进去。
- 本地开发使用 ad-hoc 签名；更换签名会重置屏幕录制授权。发布前需 Developer ID 签名并公证。

## License

MIT
