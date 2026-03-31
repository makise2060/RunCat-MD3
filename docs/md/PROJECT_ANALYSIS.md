# RunCat 365 项目分析报告

## 一、项目概述

### 1.1 项目简介

**RunCat 365** 是一款 Windows 系统托盘应用程序，通过在任务栏显示可爱的奔跑动物动画来直观展示系统资源使用情况。动物奔跑的速度与 CPU、GPU 或内存使用率相关联——负载越高，跑得越快。

### 1.2 基本信息

| 项目属性 | 值 |
|---------|-----|
| 项目名称 | RunCat 365 |
| 作者 | Takuto Nakamura |
| 公司 | Studio Kyome |
| 开源协议 | Apache License 2.0 |
| 当前版本 | 3.4.0 |
| 目标平台 | Windows 10 version 19041.0+ |
| 支持架构 | x64, x86, ARM64 |
| 发布渠道 | Microsoft Store |

### 1.3 项目定位

- **类型**: 系统工具 / 桌面美化
- **特色**: 将系统监控以趣味化方式呈现
- **目标用户**: 追求桌面个性化的 Windows 用户

---

## 二、技术栈

### 2.1 核心框架

| 技术 | 版本 | 用途 |
|------|------|------|
| .NET | 9.0 | 运行时框架 |
| Windows Forms | - | GUI 框架 |
| Windows App SDK | - | Windows 应用模型 API |

### 2.2 开发工具

- **IDE**: Visual Studio
- **构建系统**: MSBuild
- **版本管理**: Git

### 2.3 Windows API 依赖

| API | 来源 | 用途 |
|-----|------|------|
| PerformanceCounter | System.Diagnostics | CPU/GPU 性能监控 |
| GlobalMemoryStatusEx | kernel32.dll (P/Invoke) | 内存状态获取 |
| Registry | Microsoft.Win32 | 主题检测、启动项配置 |
| NetworkInterface | System.Net.NetworkInformation | 网络流量监控 |
| DriveInfo | System.IO | 存储空间监控 |
| StartupTask | Windows.ApplicationModel | 打包应用启动项 |

---

## 三、架构设计

### 3.1 设计模式

| 模式 | 应用场景 | 实现类 |
|------|---------|--------|
| Repository Pattern | 系统信息数据获取 | `CPURepository`, `GPURepository`, `MemoryRepository`, `StorageRepository`, `NetworkRepository` |
| ApplicationContext | 应用生命周期管理 | `RunCat365ApplicationContext` |
| Strategy Pattern | 启动项管理 | `ILaunchAtStartupManager` → `PackagedLaunchAtStartupManager` / `UnpackagedLaunchAtStartupManager` |
| State Pattern | 游戏状态管理 | `GameStatus` 枚举 |
| Template Method | 菜单项创建 | `CustomToolStripMenuItem.SetupSubMenusFromEnum<T>` |

### 3.2 项目结构

```
RunCat-MD3/
├── RunCat365/                      # 主项目
│   ├── Program.cs                  # 入口点、应用上下文
│   ├── ContextMenuManager.cs       # 系统托盘管理
│   ├── *Repository.cs              # 系统信息仓库
│   ├── EndlessGameForm.cs          # 内置小游戏
│   ├── BitmapExtension.cs          # 图像处理扩展
│   ├── Runner.cs                   # 动画角色枚举
│   ├── Theme.cs                    # 主题枚举
│   ├── SpeedSource.cs              # 速度来源枚举
│   ├── FPSMaxLimit.cs              # FPS 限制枚举
│   ├── SupportedLanguage.cs        # 支持语言枚举
│   ├── Cat.cs                      # 游戏角色状态机
│   ├── Road.cs                     # 游戏障碍物枚举
│   ├── GameStatus.cs               # 游戏状态枚举
│   ├── TreeFormatter.cs            # 树形文本格式化
│   ├── ByteFormatter.cs            # 字节格式化工具
│   ├── BalloonTipType.cs           # 气泡通知类型
│   ├── CustomToolStripMenuItem.cs  # 自定义菜单项
│   ├── ContextMenuRenderer.cs      # 菜单渲染器
│   ├── LaunchAtStartupManager.cs   # 开机启动管理
│   ├── Properties/                 # 资源和设置
│   │   ├── Resources.resx          # 嵌入资源
│   │   ├── Strings.*.resx          # 多语言字符串
│   │   └── UserSettings.settings   # 用户设置
│   └── resources/                  # 静态资源
│       ├── app_icon.ico
│       ├── game/                   # 游戏素材
│       └── runners/                # 动画帧图片
├── WapForStore/                    # Microsoft Store 打包项目
│   ├── Package.appxmanifest        # 应用清单
│   └── Images/                     # Store 图标
├── docs/                           # 文档和网站
│   ├── index.html                  # 项目主页
│   └── privacy_policy.html         # 隐私政策
├── CLAUDE.md                       # AI 助手指南
├── CONTRIBUTING.md                 # 贡献指南
├── LICENSE                         # 许可证
└── README.md                       # 项目说明
```

### 3.3 核心组件交互流程

```
┌─────────────────────────────────────────────────────────────┐
│                    RunCat365ApplicationContext               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ fetchTimer  │  │animateTimer │  │  ContextMenuManager │  │
│  │  (1s间隔)   │  │ (动态间隔)  │  │                     │  │
│  └──────┬──────┘  └──────┬──────┘  └──────────┬──────────┘  │
│         │                │                     │             │
│         ▼                ▼                     ▼             │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │ Repositories│  │ AdvanceFrame│  │    NotifyIcon       │  │
│  │ Update()    │  │ 切换图标    │  │   显示动画          │  │
│  └─────────────┘  └─────────────┘  └─────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## 四、功能特性

### 4.1 系统监控

| 监控项 | 指标 | 数据源 |
|--------|------|--------|
| CPU | Total, User, Kernel, Idle (%) | PerformanceCounter |
| GPU | Average, Maximum (%) | PerformanceCounter ("GPU Engine") |
| 内存 | Load (%), Total, Used, Available | GlobalMemoryStatusEx |
| 存储 | C/D 盘使用量和可用空间 | DriveInfo |
| 网络 | 发送/接收速度 (B/s) | NetworkInterface |

### 4.2 动画系统

| 角色 | 帧数 | 特点 |
|------|------|------|
| Cat (猫) | 5 帧 | 默认角色 |
| Parrot (鹦鹉) | 10 帧 | 翅膀扇动效果 |
| Horse (马) | 14 帧 | 奔跑效果 |

### 4.3 速度控制

- **速度来源**: CPU / GPU / 内存使用率
- **动画间隔计算**: `interval = 500 / (load / 5 * fpsRate)`
- **FPS 限制**: 40fps / 30fps / 20fps / 10fps

### 4.4 主题支持

| 主题模式 | 实现方式 |
|---------|---------|
| System | 跟随 Windows 系统主题 |
| Light | 黑色图标 |
| Dark | 白色图标 |

主题检测: 读取注册表 `Software\Microsoft\Windows\CurrentVersion\Themes\Personalize`

### 4.5 内置小游戏 (EndlessGame)

- **类型**: 横向滚动跑酷游戏
- **操作**: 按空格键跳跃
- **障碍物**: Flat, Hill, Crater, Sprout
- **状态**: 猫咪有 Running 和 Jumping 两种状态
- **分数**: 记录最高分到用户设置

### 4.6 开机启动

| 运行模式 | 实现方式 |
|---------|---------|
| 打包应用 (MSIX) | `StartupTask.GetAsync()` |
| 非打包应用 | 注册表 `HKCU\...\Run` |

---

## 五、国际化 (i18n)

### 5.1 支持语言

| 语言 | 区域设置 | 资源文件 |
|------|---------|---------|
| 英语 (默认) | en-US | Strings.resx |
| 简体中文 | zh-CN | Strings.zh-CN.resx |
| 繁体中文 | zh-TW | Strings.zh-TW.resx |
| 法语 | fr-FR | Strings.fr.resx |
| 德语 | de-DE | Strings.de.resx |
| 日语 | ja-JP | Strings.ja.resx |
| 西班牙语 | es-ES | Strings.es.resx |

### 5.2 字体适配

| 语言 | 字体 |
|------|------|
| 英语、法语、德语、西班牙语 | Consolas |
| 简体中文 | Microsoft YaHei (微软雅黑) |
| 繁体中文 | Microsoft JhengHei (微软正黑体) |
| 日语 | Noto Sans JP |

### 5.3 全角/半角适配

- 中文和日语使用全角树形字符 (`├─`, `└─`, `│　`)
- 其他语言使用半角字符 (`├─ `, `└─ `, `│  `)

---

## 六、代码质量分析

### 6.1 代码规范

| 规范项 | 描述 |
|--------|------|
| 命名规范 | 使用有意义的命名，无需注释即可理解代码意图 |
| 缩进风格 | Allman 风格 (大括号单独一行) |
| 类型推断 | 类型明显时使用 `var` |
| 空值处理 | 启用 Nullable 引用类型 |
| 缩写规范 | URL/ID 等缩写使用全大写或全小写 |

### 6.2 现代 C# 特性使用

| 特性 | 应用位置 |
|------|---------|
| Record struct | `CPUInfo`, `GPUInfo`, `MemoryInfo` 等数据结构 |
| Primary constructor | `BalloonTipInfo` |
| Switch expression | 各种枚举扩展方法 |
| Pattern matching | 状态判断、类型检查 |
| File-scoped namespaces | 所有源文件 |
| Global usings | ImplicitUsings 启用 |
| Lock object | 线程安全图标更新 |
| Unsafe code | 高性能位图处理 |

### 6.3 资源管理

- 所有 `IDisposable` 对象正确释放
- 使用 `using` 语句管理资源生命周期
- `ApplicationContext` 重写 `Dispose` 方法

### 6.4 线程安全

- `iconLock` 对象保护图标列表的并发访问
- `FormsTimer` 在 UI 线程执行回调

---

## 七、发布与分发

### 7.1 Microsoft Store 打包

| 配置项 | 值 |
|--------|-----|
| 包名 | StudioKyome.RunCat |
| capabilities | runFullTrust, internetClient |
| Extensions | startupTask, fullTrustProcess |

### 7.2 应用清单

- **DPI 感知**: PerMonitorV2
- **执行级别**: asInvoker (非管理员)
- **兼容性**: Windows 10

### 7.3 版本号管理

需同时更新两处:
1. `RunCat365.csproj`: `<Version>X.Y.Z</Version>`
2. `Package.appxmanifest`: `Version="X.Y.Z.0"`

---

## 八、项目优势

### 8.1 技术优势

1. **轻量级**: 纯 Windows Forms，无外部依赖
2. **高性能**: 使用 unsafe 代码进行位图处理
3. **现代 .NET**: 基于 .NET 9.0，支持最新 C# 特性
4. **跨架构**: 支持 x64、x86、ARM64

### 8.2 用户体验优势

1. **非侵入式**: 系统托盘运行，不干扰工作
2. **趣味化**: 将枯燥的系统监控变得有趣
3. **可定制**: 多角色、多主题、多速度来源
4. **国际化**: 7 种语言支持

### 8.3 工程化优势

1. **清晰的架构**: Repository 模式分离数据获取
2. **良好的代码质量**: 无注释也能理解的命名
3. **完整的贡献流程**: CONTRIBUTING.md 指引

---

## 九、潜在改进方向

### 9.1 功能扩展

| 方向 | 建议 |
|------|------|
| 更多角色 | 支持自定义角色导入 |
| 数据记录 | 添加历史数据记录和图表 |
| 告警功能 | 资源超阈值时通知 |
| 云同步 | 设置同步到云端 |

### 9.2 技术优化

| 方向 | 建议 |
|------|------|
| 配置系统 | 迁移到 System.Text.Json 配置文件 |
| 日志系统 | 添加结构化日志 |
| 单元测试 | 添加测试项目 |
| CI/CD | 添加 GitHub Actions 自动构建 |

### 9.3 代码改进

| 方向 | 建议 |
|------|------|
| 依赖注入 | 使用 DI 容器管理依赖 |
| MVVM | 小游戏部分可考虑 MVVM 模式 |
| 异步优化 | 部分操作可改为异步 |

---

## 十、总结

RunCat 365 是一个设计精良的 Windows 桌面应用，展示了如何将系统监控功能以趣味化的方式呈现。项目采用现代 C# 和 .NET 9.0，代码质量高，架构清晰，是一个优秀的 Windows Forms 应用参考案例。

### 关键数据

| 指标 | 值 |
|------|-----|
| 源文件数量 | ~25 个 .cs 文件 |
| 支持语言数 | 7 种 |
| 动画角色数 | 3 种 |
| 系统监控项 | 5 类 |
| 目标框架 | .NET 9.0 |
| 最低系统要求 | Windows 10 2004 |
