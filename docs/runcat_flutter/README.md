# RunCat Flutter 重构项目

RunCat 的 Flutter 重构版本，使用 Material Design 3 设计，支持 Windows 桌面平台。

## 🚀 快速开始

### 环境要求

- Windows 10/11 (64位)
- Flutter SDK 3.0+
- Visual Studio 2019/2022 (Windows 桌面开发)

### 环境配置

由于国内网络环境，我们已经配置了 Flutter 国内镜像。运行以下命令配置环境：

```powershell
# PowerShell
.\setup_flutter_env.ps1

# 或 CMD
setup_flutter_env.bat
```

### 运行项目

```bash
# 1. 获取依赖
flutter pub get

# 2. 检查环境
flutter doctor

# 3. 运行应用
flutter run -d windows

# 4. 构建发布版本
flutter build windows --release
```

## 🏗️ 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/
│   └── runner_character.dart    # 角色数据模型
├── providers/
│   └── animation_providers.dart # 状态管理
├── services/
│   ├── system_tray_service.dart # 系统托盘
│   └── system_monitor_service.dart # 系统监控
└── widgets/
    ├── animation_player.dart    # 动画播放器
    └── character_animation.dart # 角色动画组件

assets/
├── animations/
│   ├── cat/                     # 猫咪动画 (5帧)
│   ├── horse/                   # 马儿动画 (5帧)
│   └── parrot/                  # 鹦鹉动画 (10帧)
└── images/                      # 图片资源
```

## ✨ 功能特性

- 🎨 **Material Design 3** 现代化界面
- 🐱 **多角色支持** - 猫咪、马儿、鹦鹉
- ⚡ **高性能动画** - CustomPaint 渲染，60fps 流畅体验
- 📊 **系统监控** - 实时显示 CPU/GPU/内存使用率
- 🎛️ **智能速度控制** - 根据系统负载自动调节动画速度
- 🔄 **角色热切换** - 运行时无刷新切换角色
- 🌙 **深色模式** - 自动适配系统主题
- 🖥️ **系统托盘** - 最小化到托盘，右键菜单控制

## 🛠️ 开发指南

### 添加新角色

1. 准备 PNG 格式的动画帧（推荐 64x64 像素）
2. 放入 `assets/animations/{角色名}/` 目录
3. 在 `runner_character.dart` 中添加角色类型
4. 更新 `pubspec.yaml` 添加资源路径

### 调试技巧

```bash
# 热重载
flutter run -d windows --hot

# 性能分析
flutter run -d windows --profile

# 详细日志
flutter run -d windows --verbose
```

## 📦 依赖说明

| 包名 | 版本 | 用途 |
|------|------|------|
| window_manager | ^0.3.7 | 窗口管理 |
| system_tray | ^2.0.3 | 系统托盘 |
| flutter_riverpod | ^2.4.9 | 状态管理 |
| win32 | ^5.1.1 | Windows API |
| shared_preferences | ^2.2.2 | 数据持久化 |

## 🔧 常见问题

### Q: 依赖下载失败？
A: 确保已运行 `setup_flutter_env.ps1` 配置国内镜像

### Q: Windows 构建失败？
A: 安装 Visual Studio 并勾选 "Desktop development with C++"

### Q: 动画不显示？
A: 检查 `assets/animations/` 目录下的 PNG 文件是否存在

## 📄 许可证

MIT License - 详见项目根目录 LICENSE 文件

## 🙏 致谢

- 原始 RunCat 项目灵感
- Flutter 团队提供的优秀框架
- Material Design 设计规范