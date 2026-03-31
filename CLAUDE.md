# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供本仓库代码开发指南。

## 必须遵守的规范

- 请使用中文进行回复。
- 仅在收到明确指令时方可提交至 Git。
- 若单条指令包含多项需求，请按适当粒度拆分提交。

## 构建与开发

本项目为面向 Microsoft Store 分发的 Windows Forms 应用程序（.NET 9.0 / C#）。

**解决方案结构：**

- `RunCat365.sln` - 主解决方案文件
- `RunCat365/` - 主应用程序项目
- `WapForStore/` - 适用于 Microsoft Store 的 Windows 应用程序打包项目

**构建方式：**

- 在 Visual Studio 中打开 `RunCat365.sln`
- 支持平台：x64、x86、ARM64
- 目标框架：.NET 9.0（Windows 10.0.26100.0）

**版本号管理：**

发布时须在以下两处同步更新版本号：

1. `RunCat365/RunCat365.csproj` - `<Version>X.Y.Z</Version>`（三位版本号）
2. `WapForStore/Package.appxmanifest` - `<Identity>` 元素中的 `Version="X.Y.Z.0"`（四位版本号）

## 架构设计

**入口点：** `Program.cs` 中包含 `RunCat365ApplicationContext`，负责管理系统托盘应用程序的生命周期。

**核心组件：**

- `ContextMenuManager` - 管理系统托盘图标、上下文菜单及通知图标动画；使用 `iconLock` 实现线程安全的图标更新
- `Runner` - 动画类型枚举（Cat、Parrot、Horse）及帧数定义
- `EndlessGameForm` - 以奔跑猫咪为主题的迷你游戏
- `LaunchAtStartupManager` - 通过 Windows App Runtime 实现开机启动注册

**系统信息仓库（Repository 模式）：**

- `CPURepository` - 通过 PerformanceCounter 获取 CPU 使用率
- `GPURepository` - GPU 使用率监控
- `MemoryRepository` - 内存使用率
- `StorageRepository` - 磁盘使用率
- `NetworkRepository` - 网络统计信息

**动画流程：**

1. `fetchTimer`（1 秒间隔）将系统信息更新至 `*Info` 结构体（CPUInfo、GPUInfo 等）
2. `animateTimer` 根据选定的 `SpeedSource`（CPU/GPU/Memory）推进帧动画
3. `BitmapExtension` 处理主题感知的图标重着色与转换

**EndlessGame 组件：**

- `Cat` - 奔跑/跳跃状态及碰撞帧数据
- `Road` - 障碍物类型（Flat/Hill/Crater/Sprout）
- `GameStatus` - 游戏状态（NewGame/Playing/GameOver）

**工具类：**

- `ByteFormatter` - 将字节值格式化为人类可读的字符串（B/KB/MB/GB/TB）
- `TreeFormatter` - 格式化系统信息以供上下文菜单显示（支持多语言）

**设置：**

- `Properties/UserSettings.settings` - 用户偏好设置（Runner、Theme、SpeedSource、FPSMaxLimit）
- `Properties/Resources.resx` - 嵌入的图像与图标资源
- `Properties/Strings.resx` - 本地化字符串（默认英文）；
  - `Strings.zh-CN.resx`（简体中文）
  - `Strings.zh-TW.resx`（繁体中文）
  - `Strings.fr.resx`（法语）
  - `Strings.de.resx`（德语）
  - `Strings.ja.resx`（日语）
  - `Strings.es.resx`（西班牙语）

**本地化注意事项：**

- 新增字符串须同时添加至全部七个 `.resx` 文件
- 英文/西班牙文/法文/德文使用 "Consolas" 字体
- 日文使用 "Noto Sans JP" 字体
- 简体中文使用 "Microsoft YaHei" 字体
- 繁体中文使用 "Microsoft JhengHei" 字体

## 编码规范

- 禁止在源代码中编写注释。
- 使用能够清晰表达代码用途的命名规范，即使无注释也能理解。
- C# 代码规范：
  - 缩写词如 URL 或 ID 应全部小写或全部大写（请勿使用首字母大写的驼峰式）。
  - 禁止使用 `img` 代替 `image`、`cnt` 代替 `count` 等缩写形式。
