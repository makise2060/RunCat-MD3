# RunCat Windows Flutter 重构设计规范

## 一、项目概述

### 1.1 重构目标

将现有的 Windows Forms 版本 RunCat 365 完全重构为 **Flutter + Material Design 3** 版本，参考 macOS 版本的精美 UI 和丰富功能，打造一个具有独立设置窗口、现代化界面的 Windows 系统监控应用。

### 1.2 核心特性对标

| 特性 | macOS 版本 | 当前 Windows 版本 | 重构目标 |
|------|-----------|------------------|---------|
| 动画角色 | 50+ 种（含付费） | 3 种 | 20+ 种免费角色 |
| 系统监控 | CPU/内存/电池/磁盘/网络 | CPU/GPU/内存/磁盘/网络 | CPU/GPU/内存/磁盘/网络/电池/温度 |
| 设置窗口 | 独立 Preferences 窗口 | 右键菜单 | **独立设置窗口** |
| 主题支持 | 系统/浅色/深色 | 系统/浅色/深色 | 系统/浅色/深色 + MD3 动态配色 |
| 动画速度 | 可反转（越快=负载越低） | 固定正比 | 支持反转设置 |
| 菜单栏显示 | 始终显示系统信息 | 仅右键菜单 | 可选常驻信息显示 |
| 自定义角色 | 支持导入自制动画 | 不支持 | 支持导入 PNG 序列帧 |
| 角色商店 | 应用内购买 | 无 | 暂不实现 |

---

## 二、技术架构

### 2.1 技术栈

```yaml
框架: Flutter 3.24+ (stable)
语言: Dart 3.5+
桌面支持: flutter_windows_desktop
状态管理: Riverpod 2.x
本地存储: hive / shared_preferences
系统监控: win32 package + PerformanceCounter
系统托盘: system_tray
窗口管理: window_manager
主题管理: dynamic_color (Material You)
动画: Lottie / 自定义帧动画
本地化: flutter_localizations + intl
```

### 2.2 项目结构

```
runcat_flutter/
├── lib/
│   ├── main.dart                    # 应用入口
│   ├── app.dart                     # MaterialApp 配置
│   ├── core/                        # 核心基础设施
│   │   ├── constants/               # 常量定义
│   │   ├── theme/                   # 主题配置
│   │   ├── localization/            # 国际化
│   │   └── utils/                   # 工具类
│   ├── data/                        # 数据层
│   │   ├── models/                  # 数据模型
│   │   ├── repositories/            # 仓库模式
│   │   └── services/                # 服务层
│   ├── domain/                      # 领域层
│   │   ├── entities/                # 领域实体
│   │   └── usecases/                # 用例
│   ├── presentation/                # 表现层
│   │   ├── providers/               # Riverpod Providers
│   │   ├── pages/                   # 页面
│   │   ├── widgets/                 # 组件
│   │   └── windows/                 # 窗口管理
│   └── runners/                     # 动画角色资源
├── assets/
│   ├── runners/                     # 角色动画帧
│   │   ├── cat/
│   │   ├── dog/
│   │   ├── parrot/
│   │   └── ...
│   ├── icons/                       # 应用图标
│   └── lottie/                      # Lottie 动画
├── windows/                         # Windows 原生配置
├── test/                            # 测试
└── pubspec.yaml
```

### 2.3 架构模式

采用 **Clean Architecture + MVVM** 模式：

```
┌─────────────────────────────────────────────────────────────┐
│                      Presentation Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐  │
│  │   Pages     │  │  Widgets    │  │    Providers        │  │
│  │  (UI)       │  │  (UI组件)   │  │  (Riverpod)         │  │
│  └──────┬──────┘  └─────────────┘  └──────────┬──────────┘  │
│         │                                      │             │
├─────────┼──────────────────────────────────────┼─────────────┤
│         │           Domain Layer               │             │
│         │  ┌─────────────┐  ┌─────────────┐   │             │
│         │  │   Entities  │  │   UseCases  │   │             │
│         │  └─────────────┘  └──────┬──────┘   │             │
│         │                          │          │             │
├─────────┼──────────────────────────┼──────────┼─────────────┤
│         │          Data Layer      │          │             │
│         │  ┌─────────────┐  ┌──────┴──────┐  │             │
│         │  │   Models    │  │ Repositories│  │             │
│         │  └─────────────┘  └──────┬──────┘  │             │
│         │                          │         │             │
├─────────┼──────────────────────────┼─────────┼─────────────┤
│         │      Platform Layer       │         │             │
│         │  ┌─────────────┐  ┌──────┴──────┐ │             │
│         │  │SystemMonitor│  │   Services  │ │             │
│         │  │  (win32)    │  │  (托盘/窗口) │ │             │
│         │  └─────────────┘  └─────────────┘ │             │
└─────────┴───────────────────────────────────┴─────────────┘
```

---

## 三、UI/UX 设计规范

### 3.1 设计原则

基于 **Material Design 3** 设计系统：

1. **动态配色 (Dynamic Color)**: 支持 Windows 强调色同步
2. **圆角设计**: 所有卡片和按钮使用 12-16dp 圆角
3. **层次感**: 使用 Elevation 和阴影创造深度
4. **动画流畅**: 60fps 标准，使用 Material Motion
5. **响应式**: 适配不同窗口尺寸
6. **高分辨率适配**: 完美支持 4K/8K 显示器，自动 DPI 缩放
7. **极致性能**: 16ms 帧时间预算，零掉帧体验

### 3.2 窗口设计

#### 3.2.1 主窗口（系统托盘）

```
┌─────────────────────────────────────┐
│  [托盘图标: 当前动画角色]              │
└─────────────────────────────────────┘
         │
         ▼ 左键点击
┌─────────────────────────────────────┐
│  🐱 RunCat          [设置] [退出]   │  ← 标题栏
├─────────────────────────────────────┤
│  ┌─────────────────────────────────┐│
│  │      [动画角色展示区域]          ││  ← 大尺寸动画预览
│  │         🐱 (奔跑中)              ││
│  └─────────────────────────────────┘│
├─────────────────────────────────────┤
│  📊 系统状态                         │
│  ├─ CPU:    45%  ▓▓▓▓▓░░░░░        │
│  ├─ 内存:   62%  ▓▓▓▓▓▓▓░░░        │
│  ├─ GPU:    23%  ▓▓▓░░░░░░░        │
│  ├─ 磁盘:   78%  ▓▓▓▓▓▓▓▓░░        │
│  └─ 网络:   ↑ 1.2 MB/s ↓ 3.5 MB/s  │
├─────────────────────────────────────┤
│  [选择角色]  [速度来源: CPU ▼]      │
└─────────────────────────────────────┘
```

#### 3.2.2 设置窗口（独立窗口）

采用 **Navigation Rail + 内容区** 布局：

```
┌─────────────────────────────────────────────────────────────┐
│  🐱 RunCat 设置                                    [_][□][X]│
├──────────┬──────────────────────────────────────────────────┤
│          │                                                  │
│  🏠 通用   │           通用设置                              │
│          │  ┌──────────────────────────────────────────┐   │
│  🎨 外观   │  │ 开机启动                          [开关]  │   │
│          │  │                                           │   │
│  🐱 角色   │  │ 语言                                      │   │
│          │  │  ├─ English                              │   │
│  📊 监控   │  │  ├─ 简体中文                    ●        │   │
│          │  │  ├─ 日本語                               │   │
│  ⚡ 高级   │  │  └─ ...                                  │   │
│          │  │                                           │   │
│          │  │ 动画速度反转                              │   │
│          │  │  [ ] 动画越快表示负载越低                  │   │
│          │  └──────────────────────────────────────────┘   │
│          │                                                  │
│          │  ┌──────────────────────────────────────────┐   │
│          │  │  关于                                     │   │
│          │  │  RunCat for Windows v4.0.0               │   │
│          │  │  © 2024 Studio Kyome                     │   │
│          │  └──────────────────────────────────────────┘   │
│          │                                                  │
└──────────┴──────────────────────────────────────────────────┘
```

##### 外观设置页

```
┌─────────────────────────────────────────────────────────────┐
│  外观设置                                                    │
├─────────────────────────────────────────────────────────────┤
│  主题模式                                                    │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐                    │
│  │  🖥️      │ │  ☀️      │ │  🌙      │                    │
│  │  跟随系统 │ │  浅色    │ │  深色    │                    │
│  │    ●     │ │          │ │          │                    │
│  └──────────┘ └──────────┘ └──────────┘                    │
│                                                             │
│  强调色 (Material You)                                      │
│  ┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐┌────┐        │
│  │ 🔵 ││ 🟢 ││ 🟡 ││ 🟠 ││ 🔴 ││ 🟣 ││ 🩷 ││ ⬜ │        │
│  │ ●  ││    ││    ││    ││    ││    ││    ││    │        │
│  └────┘└────┘└────┘└────┘└────┘└────┘└────┘└────┘        │
│                                                             │
│  菜单栏显示选项                                              │
│  ☑ 始终在菜单栏显示系统信息                                 │
│  ☑ 显示 CPU 使用率                                          │
│  ☑ 显示内存使用率                                           │
│  ☐ 显示网络速度                                             │
│                                                             │
│  动画帧率限制                                                │
│  ├─○ 60 FPS (流畅)                                          │
│  ├──○ 30 FPS (标准)                                         │
│  └──○ 15 FPS (省电)                                         │
└─────────────────────────────────────────────────────────────┘
```

##### 角色选择页

```
┌─────────────────────────────────────────────────────────────┐
│  选择角色                                                    │
├─────────────────────────────────────────────────────────────┤
│  [🔍 搜索角色...                     ] [全部 ▼] [导入+]     │
│                                                             │
│  动物类                                                     │
│  ┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐        │
│  │  🐱    ││  🐶    ││  🐰    ││  🐸    ││  🐦    │        │
│  │  猫咪  ││  小狗  ││  兔子  ││  青蛙  ││  小鸟  │        │
│  │  ●使用中││        ││        ││        ││        │        │
│  └────────┘└────────┘└────────┘└────────┘└────────┘        │
│                                                             │
│  ┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐        │
│  │  🐧    ││  🐬    ││  🐲    ││  🦉    ││  🦔    │        │
│  │  企鹅  ││  海豚  ││  龙    ││  猫头鹰││  刺猬  │        │
│  └────────┘└────────┘└────────┘└────────┘└────────┘        │
│                                                             │
│  抽象类                                                     │
│  ┌────────┐┌────────┐┌────────┐┌────────┐┌────────┐        │
│  │  ⚙️    ││  🔥    ││  💧    ││  🚀    ││  ⭕    │        │
│  │  齿轮  ││  火焰  ││  水滴  ││  火箭  ││  圆环  │        │
│  └────────┘└────────┘└────────┘└────────┘└────────┘        │
│                                                             │
│  自定义                                                     │
│  ┌────────┐                                                 │
│  │  ➕    │                                                 │
│  │ 导入   │                                                 │
│  └────────┘                                                 │
└─────────────────────────────────────────────────────────────┘
```

##### 监控设置页

```
┌─────────────────────────────────────────────────────────────┐
│  监控设置                                                    │
├─────────────────────────────────────────────────────────────┤
│  动画速度来源                                               │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ○ CPU 使用率    ○ GPU 使用率    ● 内存使用率       │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  监控项设置                                                  │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ ☑ CPU 监控                                             │
│  │   └─ 刷新间隔: 1000 ms                                │
│  │                                                       │   │
│  │ ☑ GPU 监控                                             │
│  │   └─ 刷新间隔: 1000 ms                                │   │
│  │                                                       │   │
│  │ ☑ 内存监控                                             │
│  │   └─ 刷新间隔: 1000 ms                                │   │
│  │                                                       │   │
│  │ ☑ 磁盘监控                                             │
│  │   └─ 监控磁盘: [C: ▼] [D: ▼]                         │   │
│  │                                                       │   │
│  │ ☑ 网络监控                                             │
│  │   └─ 显示单位: [自动 ▼]                               │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  警告阈值设置                                                │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ CPU 超过 [80%] 时显示警告                            │   │
│  │ 内存超过 [85%] 时显示警告                            │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

---

## 四、核心功能实现

### 4.1 系统监控服务

```dart
// lib/data/services/system_monitor_service.dart

abstract class SystemMonitorService {
  Stream<SystemInfo> get systemInfoStream;
  Future<SystemInfo> getCurrentInfo();
  void startMonitoring();
  void stopMonitoring();
}

class WindowsSystemMonitorService implements SystemMonitorMonitorService {
  final _controller = StreamController<SystemInfo>.broadcast();
  Timer? _timer;
  
  // 使用 win32 包调用 Windows API
  final _cpuMonitor = CpuMonitor();
  final _gpuMonitor = GpuMonitor();
  final _memoryMonitor = MemoryMonitor();
  final _diskMonitor = DiskMonitor();
  final _networkMonitor = NetworkMonitor();
  
  @override
  Stream<SystemInfo> get systemInfoStream => _controller.stream;
  
  @override
  void startMonitoring() {
    _timer = Timer.periodic(Duration(milliseconds: 500), (_) async {
      final info = SystemInfo(
        cpu: await _cpuMonitor.getUsage(),
        gpu: await _gpuMonitor.getUsage(),
        memory: await _memoryMonitor.getUsage(),
        disk: await _diskMonitor.getUsage(),
        network: await _networkMonitor.getSpeed(),
      );
      _controller.add(info);
    });
  }
}
```

### 4.2 动画系统

```dart
// lib/presentation/widgets/runner_animation.dart

class RunnerAnimation extends StatefulWidget {
  final RunnerType runner;
  final double speed; // 0.0 - 1.0
  final bool inverted;
  
  const RunnerAnimation({
    required this.runner,
    required this.speed,
    this.inverted = false,
  });
  
  @override
  State<RunnerAnimation> createState() => _RunnerAnimationState();
}

class _RunnerAnimationState extends State<RunnerAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _updateSpeed();
  }
  
  void _updateSpeed() {
    final effectiveSpeed = widget.inverted ? 1.0 - widget.speed : widget.speed;
    // 速度越快，动画间隔越短
    final interval = lerpDouble(500, 50, effectiveSpeed);
    _controller.duration = Duration(milliseconds: interval.round());
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final frame = (_controller.value * widget.runner.frameCount).floor();
        return Image.asset(
          'assets/runners/${widget.runner.id}/frame_$frame.png',
          width: 64,
          height: 64,
        );
      },
    );
  }
}
```

### 4.3 系统托盘集成

```dart
// lib/presentation/services/tray_service.dart

class TrayService {
  final SystemTray _systemTray = SystemTray();
  final WindowManager _windowManager = WindowManager();
  
  Future<void> init() async {
    await _systemTray.initSystemTray(
      title: "RunCat",
      iconPath: 'assets/icons/tray_icon.ico',
      toolTip: "RunCat - 系统监控",
    );
    
    // 创建托盘菜单
    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '显示主窗口',
        onClicked: (menuItem) => _showMainWindow(),
      ),
      MenuItemLabel(
        label: '设置',
        onClicked: (menuItem) => _showSettingsWindow(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (menuItem) => _exitApp(),
      ),
    ]);
    await _systemTray.setContextMenu(menu);
    
    // 左键点击显示主窗口
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        _showMainWindow();
      } else if (eventName == kSystemTrayEventRightClick) {
        _systemTray.popUpContextMenu();
      }
    });
  }
  
  Future<void> updateTrayIcon(Uint8List iconData) async {
    // 动态更新托盘图标为当前动画帧
    await _systemTray.setImage(iconData);
  }
}
```

### 4.4 多窗口管理

```dart
// lib/presentation/windows/window_manager.dart

class RunCatWindowManager {
  static const String mainWindow = 'main';
  static const String settingsWindow = 'settings';
  
  Future<void> init() async {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = WindowOptions(
      size: Size(400, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden, // 自定义标题栏
    );
    
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }
  
  Future<void> openSettingsWindow() async {
    // 检查设置窗口是否已存在
    if (await _isWindowOpen(settingsWindow)) {
      await _focusWindow(settingsWindow);
      return;
    }
    
    // 创建新窗口
    await DesktopMultiWindow.createWindow(jsonEncode({
      'type': settingsWindow,
    }));
  }
}
```

---

## 五、数据模型

### 5.1 核心模型

```dart
// lib/data/models/system_info.dart

@freezed
class SystemInfo with _$SystemInfo {
  const factory SystemInfo({
    required CpuInfo cpu,
    required GpuInfo gpu,
    required MemoryInfo memory,
    required DiskInfo disk,
    required NetworkInfo network,
    BatteryInfo? battery,
    TemperatureInfo? temperature,
  }) = _SystemInfo;
}

@freezed
class CpuInfo with _$CpuInfo {
  const factory CpuInfo({
    required double totalUsage,
    required double userUsage,
    required double kernelUsage,
    required int coreCount,
    required String processorName,
  }) = _CpuInfo;
}

@freezed
class MemoryInfo with _$MemoryInfo {
  const factory MemoryInfo({
    required double usagePercent,
    required int totalBytes,
    required int usedBytes,
    required int availableBytes,
  }) = _MemoryInfo;
}

@freezed
class Runner with _$Runner {
  const factory Runner({
    required String id,
    required String name,
    required String category,
    required int frameCount,
    required String previewPath,
    required bool isCustom,
    String? author,
  }) = _Runner;
}

@freezed
class AppSettings with _$AppSettings {
  const factory AppSettings({
    @Default('cat') String currentRunnerId,
    @Default(SpeedSource.cpu) SpeedSource speedSource,
    @Default(ThemeMode.system) ThemeMode themeMode,
    @Default(false) bool invertedSpeed,
    @Default(true) bool launchAtStartup,
    @Default(true) bool showInTray,
    @Default(false) bool alwaysShowSystemInfo,
    @Default(30) int maxFps,
    @Default('zh_CN') String locale,
    @Default([]) List<String> enabledMonitors,
  }) = _AppSettings;
}
```

---

## 六、状态管理 (Riverpod)

```dart
// lib/presentation/providers/system_info_provider.dart

final systemMonitorProvider = Provider<SystemMonitorService>((ref) {
  return WindowsSystemMonitorService();
});

final systemInfoStreamProvider = StreamProvider<SystemInfo>((ref) {
  final monitor = ref.watch(systemMonitorProvider);
  monitor.startMonitoring();
  ref.onDispose(() => monitor.stopMonitoring());
  return monitor.systemInfoStream;
});

// lib/presentation/providers/settings_provider.dart

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(settingsRepositoryProvider));
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  final SettingsRepository _repository;
  
  SettingsNotifier(this._repository) : super(const AppSettings()) {
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    state = await _repository.load();
  }
  
  Future<void> updateRunner(String runnerId) async {
    state = state.copyWith(currentRunnerId: runnerId);
    await _repository.save(state);
  }
  
  Future<void> updateSpeedSource(SpeedSource source) async {
    state = state.copyWith(speedSource: source);
    await _repository.save(state);
  }
  
  Future<void> updateTheme(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _repository.save(state);
  }
}

// lib/presentation/providers/animation_speed_provider.dart

final animationSpeedProvider = Provider<double>((ref) {
  final settings = ref.watch(settingsProvider);
  final systemInfo = ref.watch(systemInfoStreamProvider);
  
  return systemInfo.when(
    data: (info) {
      double usage;
      switch (settings.speedSource) {
        case SpeedSource.cpu:
          usage = info.cpu.totalUsage / 100;
          break;
        case SpeedSource.gpu:
          usage = info.gpu.averageUsage / 100;
          break;
        case SpeedSource.memory:
          usage = info.memory.usagePercent / 100;
          break;
      }
      return settings.invertedSpeed ? 1.0 - usage : usage;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});
```

---

## 七、主题配置

```dart
// lib/core/theme/app_theme.dart

class AppTheme {
  static ThemeData light(ColorScheme? dynamicColor) {
    final baseScheme = dynamicColor ?? _defaultLightScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      brightness: Brightness.light,
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: baseScheme.surface,
        selectedIconTheme: IconThemeData(color: baseScheme.primary),
        selectedLabelTextStyle: TextStyle(color: baseScheme.primary),
      ),
      pageTransitionsTheme: PageTransitionsTheme(
        builders: {
          TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
        },
      ),
    );
  }
  
  static ThemeData dark(ColorScheme? dynamicColor) {
    final baseScheme = dynamicColor ?? _defaultDarkScheme;
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseScheme,
      brightness: Brightness.dark,
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
  
  static final _defaultLightScheme = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.light,
  );
  
  static final _defaultDarkScheme = ColorScheme.fromSeed(
    seedColor: Colors.blue,
    brightness: Brightness.dark,
  );
}

// lib/core/theme/dynamic_color_provider.dart

final dynamicColorProvider = FutureProvider<ColorScheme?>((ref) async {
  if (Platform.isWindows) {
    // 尝试获取 Windows 强调色
    final accentColor = await _getWindowsAccentColor();
    return ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: ref.watch(brightnessProvider),
    );
  }
  return null;
});
```

---

## 八、本地化配置

```dart
// lib/core/localization/app_localizations.dart

class AppLocalizations {
  static const supportedLocales = [
    Locale('en', 'US'),
    Locale('zh', 'CN'),
    Locale('zh', 'TW'),
    Locale('ja', 'JP'),
    Locale('fr', 'FR'),
    Locale('de', 'DE'),
    Locale('es', 'ES'),
  ];
  
  static const localizationsDelegates = [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];
}

// ARB 文件示例: lib/l10n/app_zh.arb
{
  "@@locale": "zh_CN",
  "appTitle": "RunCat",
  "settings": "设置",
  "general": "通用",
  "appearance": "外观",
  "runners": "角色",
  "monitoring": "监控",
  "advanced": "高级",
  "launchAtStartup": "开机启动",
  "language": "语言",
  "theme": "主题",
  "themeSystem": "跟随系统",
  "themeLight": "浅色",
  "themeDark": "深色",
  "invertedSpeed": "反转速度",
  "invertedSpeedDescription": "动画越快表示负载越低",
  "cpu": "CPU",
  "gpu": "GPU",
  "memory": "内存",
  "disk": "磁盘",
  "network": "网络",
  "upload": "上传",
  "download": "下载",
  "selectRunner": "选择角色",
  "speedSource": "速度来源",
  "about": "关于",
  "version": "版本",
  "quit": "退出"
}
```

---

## 九、依赖配置

```yaml
# pubspec.yaml

name: runcat_windows
version: 4.0.0
publish_to: 'none'

environment:
  sdk: '>=3.5.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # 状态管理
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # Windows 桌面支持
  window_manager: ^0.3.9
  system_tray: ^2.0.3
  desktop_multi_window: ^0.2.0
  screen_retriever: ^0.1.9
  
  # Windows API 调用
  win32: ^5.5.1
  ffi: ^2.1.2
  
  # 系统监控
  system_info2: ^4.0.0
  
  # 主题
  dynamic_color: ^1.7.0
  
  # 本地存储
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.3
  
  # 动画
  lottie: ^3.1.2
  flutter_animate: ^4.5.0
  
  # 本地化
  flutter_localizations:
    sdk: flutter
  intl: ^0.19.0
  
  # 工具
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  path_provider: ^2.1.3
  path: ^1.9.0
  
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  build_runner: ^2.4.11
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  custom_lint: ^0.6.4
  riverpod_lint: ^2.3.10

flutter:
  uses-material-design: true
  
  assets:
    - assets/runners/
    - assets/runners/cat/
    - assets/runners/dog/
    - assets/runners/parrot/
    - assets/icons/
    - assets/lottie/
    - assets/fonts/
```

---

## 十、构建与发布

### 10.1 构建配置

```powershell
# 启用 Windows 桌面支持
flutter config --enable-windows-desktop

# 获取依赖
flutter pub get

# 生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 调试运行
flutter run -d windows

# 发布构建
flutter build windows --release
```

### 10.2 MSIX 打包

```yaml
# pubspec.yaml 添加
msix_config:
  display_name: RunCat
  publisher_display_name: Studio Kyome
  identity_name: StudioKyome.RunCat
  msix_version: 4.0.0.0
  certificate_path: C:\path\to\certificate.pfx
  certificate_password: password
  logo_path: assets/icons/logo.png
  capabilities: internetClient, runFullTrust
```

---

## 十一、开发路线图

### Phase 1: 基础框架 (2 周)
- [ ] Flutter 项目初始化
- [ ] Windows 桌面支持配置
- [ ] 基础架构搭建 (Clean Architecture)
- [ ] 主题系统 (MD3 + 动态配色)
- [ ] 本地化框架

### Phase 2: 核心功能 (3 周)
- [ ] 系统监控服务 (CPU/GPU/内存/磁盘/网络)
- [ ] 动画系统 (帧动画播放器)
- [ ] 系统托盘集成
- [ ] 基础角色 (猫/狗/鹦鹉)

### Phase 3: UI 实现 (3 周)
- [ ] 主窗口 (系统托盘弹出)
- [ ] 设置窗口 (独立窗口)
- [ ] 通用设置页
- [ ] 外观设置页
- [ ] 角色选择页
- [ ] 监控设置页

### Phase 4: 高级功能 (2 周)
- [ ] 自定义角色导入
- [ ] 电池监控
- [ ] 温度监控
- [ ] 性能优化
- [ ] 动画缓存

### Phase 5: 发布准备 (1 周)
- [ ] 多语言完善
- [ ] MSIX 打包
- [ ] 签名配置
- [ ] 测试与修复

---

## 十二、高分辨率与性能优化专项

### 12.1 高分辨率支持 (HiDPI)

#### 12.1.1 DPI 感知配置

```dart
// windows/runner/main.cpp 修改
#include <windows.h>
#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <utils.h>

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // 设置 DPI 感知模式为 PerMonitorV2（支持多显示器不同 DPI）
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);
  
  // ... 其余代码
}
```

#### 12.1.2 Flutter 高分辨率适配

```dart
// lib/main.dart
void main() {
  // 确保 Flutter 绑定初始化
  WidgetsFlutterBinding.ensureInitialized();
  
  // 配置 Windows 高分辨率支持
  if (Platform.isWindows) {
    _configureHiDPI();
  }
  
  runApp(const RunCatApp());
}

Future<void> _configureHiDPI() async {
  // 监听 DPI 变化
  final window = await getWindowHandle();
  // 使用 flutter_windows_desktop 的 DPI 支持
}
```

#### 12.1.3 资源多倍图支持

```yaml
# pubspec.yaml
flutter:
  assets:
    # 1x 分辨率
    - assets/icons/app_icon.png
    # 2x 分辨率 (用于 4K 显示器)
    - assets/icons/2.0x/app_icon.png
    # 3x 分辨率 (用于超高 DPI)
    - assets/icons/3.0x/app_icon.png
    
    # 角色动画多倍图
    - assets/runners/cat/
    - assets/runners/cat/2.0x/
    - assets/runners/cat/3.0x/
```

```dart
// 自动选择合适的分辨率
Image.asset(
  'assets/runners/cat/frame_0.png',
  // Flutter 会自动根据设备像素比选择 1x/2x/3x 版本
)
```

#### 12.1.4 字体清晰度优化

```dart
// lib/core/theme/app_theme.dart
ThemeData _createHighResolutionTheme() {
  return ThemeData(
    // 使用字体渲染优化
    fontFamily: 'Segoe UI Variable',
    // 启用子像素渲染
    textTheme: TextTheme(
      bodyMedium: TextStyle(
        fontSize: 14,
        // 在高 DPI 下保持清晰
        height: 1.4,
        letterSpacing: 0.25,
      ),
    ),
  );
}
```

### 12.2 性能优化策略

#### 12.2.1 渲染性能目标

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| 帧率 | 60 FPS | Flutter DevTools |
| 帧时间 | < 16.67ms | Timeline 分析 |
| 卡顿率 | < 1% | FrameTiming |
| 内存占用 | < 100MB | Task Manager |
| CPU 占用 | < 1% | 系统监控 |

#### 12.2.2 动画性能优化

```dart
// lib/presentation/widgets/optimized_runner_animation.dart

class OptimizedRunnerAnimation extends StatefulWidget {
  final RunnerType runner;
  final double speed;
  
  @override
  State<OptimizedRunnerAnimation> createState() => _OptimizedRunnerAnimationState();
}

class _OptimizedRunnerAnimationState extends State<OptimizedRunnerAnimation> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ui.Image> _frameCache;
  int _currentFrame = 0;
  
  // 使用自定义绘制而非 Widget 重建
  final _paint = Paint()
    ..filterQuality = FilterQuality.low // 降低滤镜质量提升性能
    ..isAntiAlias = false; // 动画不需要抗锯齿
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _loadFrames();
    _startOptimizedLoop();
  }
  
  void _startOptimizedLoop() {
    // 使用 Ticker 而非 setState 重建
    _controller.addListener(() {
      final newFrame = (_controller.value * _frameCache.length).floor();
      if (newFrame != _currentFrame) {
        _currentFrame = newFrame;
        // 使用 markNeedsPaint 而非 setState
        (context as Element).markNeedsBuild();
      }
    });
    _controller.repeat();
  }
  
  @override
  Widget build(BuildContext context) {
    // 使用 CustomPaint 避免 Widget 树重建
    return CustomPaint(
      size: const Size(64, 64),
      painter: _RunnerPainter(
        frames: _frameCache,
        currentFrame: _currentFrame,
        paint: _paint,
      ),
    );
  }
}

class _RunnerPainter extends CustomPainter {
  final List<ui.Image> frames;
  final int currentFrame;
  final Paint paint;
  
  _RunnerPainter({
    required this.frames,
    required this.currentFrame,
    required this.paint,
  }) : super(repaint: null);
  
  @override
  void paint(Canvas canvas, Size size) {
    if (frames.isEmpty || currentFrame >= frames.length) return;
    
    final frame = frames[currentFrame];
    canvas.drawImageRect(
      frame,
      Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }
  
  @override
  bool shouldRepaint(covariant _RunnerPainter oldDelegate) {
    // 仅在帧索引变化时重绘
    return oldDelegate.currentFrame != currentFrame;
  }
}
```

#### 12.2.3 图片资源预加载与缓存

```dart
// lib/core/utils/image_cache_manager.dart

class ImageCacheManager {
  static final ImageCacheManager _instance = ImageCacheManager._internal();
  factory ImageCacheManager() => _instance;
  ImageCacheManager._internal();
  
  final Map<String, List<ui.Image>> _frameCache = {};
  final Map<String, Uint8List> _iconCache = {};
  
  // 预加载角色动画帧
  Future<void> preloadRunner(String runnerId, int frameCount) async {
    if (_frameCache.containsKey(runnerId)) return;
    
    final frames = <ui.Image>[];
    for (int i = 0; i < frameCount; i++) {
      final data = await rootBundle.load(
        'assets/runners/$runnerId/frame_$i.png',
      );
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(),
        targetWidth: 64,  // 预缩放，减少运行时计算
        targetHeight: 64,
      );
      final frame = await codec.getNextFrame();
      frames.add(frame.image);
    }
    _frameCache[runnerId] = frames;
  }
  
  // 获取缓存的帧
  List<ui.Image>? getFrames(String runnerId) => _frameCache[runnerId];
  
  // 清理不用的缓存
  void disposeRunner(String runnerId) {
    final frames = _frameCache.remove(runnerId);
    for (final frame in frames ?? []) {
      frame.dispose();
    }
  }
}
```

#### 12.2.4 监控数据采样优化

```dart
// lib/data/services/optimized_system_monitor.dart

class OptimizedSystemMonitor {
  final _cpuSampler = AdaptiveSampler(
    minInterval: Duration(milliseconds: 200),
    maxInterval: Duration(seconds: 2),
  );
  
  Stream<SystemInfo> get optimizedStream async* {
    await for (final sample in _rawDataStream) {
      // 自适应采样：系统负载高时增加采样频率
      final interval = _calculateAdaptiveInterval(sample);
      await Future.delayed(interval);
      yield sample;
    }
  }
  
  Duration _calculateAdaptiveInterval(SystemInfo info) {
    final load = info.cpu.totalUsage;
    // 负载高时采样更频繁（动画更流畅）
    // 负载低时降低采样（节省资源）
    final ms = lerpDouble(2000, 200, load / 100).round();
    return Duration(milliseconds: ms);
  }
}
```

#### 12.2.5 避免不必要的重建

```dart
// 使用 const 构造函数
const Card(
  child: const Text('Static Content'),
);

// 使用 const 集合
const availableRunners = [
  Runner(id: 'cat', name: '猫咪'),
  Runner(id: 'dog', name: '小狗'),
];

// 使用 memoization
final expensiveComputation = useMemoizer(() {
  return heavyCalculation();
}, [dependency]);

// 选择性监听 Provider
final cpuOnly = ref.watch(
  systemInfoProvider.select((info) => info.cpu),
);
```

#### 12.2.6 托盘图标优化

```dart
// lib/presentation/services/optimized_tray_service.dart

class OptimizedTrayService {
  final SystemTray _systemTray = SystemTray();
  Timer? _trayUpdateTimer;
  int _lastFrameIndex = -1;
  
  // 托盘图标更新频率限制（降低 CPU 占用）
  static const _trayUpdateInterval = Duration(milliseconds: 100);
  
  Future<void> startAnimation(List<Uint8List> frames) async {
    _trayUpdateTimer?.cancel();
    var frameIndex = 0;
    
    _trayUpdateTimer = Timer.periodic(_trayUpdateInterval, (_) async {
      if (frameIndex == _lastFrameIndex) return;
      _lastFrameIndex = frameIndex;
      
      // 异步更新托盘图标，不阻塞 UI
      await _systemTray.setImage(frames[frameIndex]);
      
      frameIndex = (frameIndex + 1) % frames.length;
    });
  }
  
  // 使用离屏渲染预生成托盘图标
  Future<List<Uint8List>> _generateTrayIcons(RunnerType runner) async {
    final icons = <Uint8List>[];
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    
    for (final frame in runner.frames) {
      // 绘制到 16x16（托盘图标标准尺寸）
      canvas.drawImageRect(
        frame,
        Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
        const Rect.fromLTWH(0, 0, 16, 16),
        Paint(),
      );
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(16, 16);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      icons.add(byteData!.buffer.asUint8List());
    }
    
    return icons;
  }
}
```

### 12.3 性能监控与调试

```dart
// lib/core/utils/performance_monitor.dart

class PerformanceMonitor {
  static void startMonitoring() {
    // 监听帧时间
    SchedulerBinding.instance.addTimingsCallback((timings) {
      for (final timing in timings) {
        final frameTime = timing.totalSpan.inMicroseconds / 1000;
        if (frameTime > 16.67) {
          // 记录掉帧
          debugPrint('Jank detected: ${frameTime.toStringAsFixed(2)}ms');
        }
      }
    });
  }
  
  // 性能检查 Widget
  static Widget wrapWithPerformanceOverlay(Widget child) {
    return PerformanceOverlay.allEnabled(
      child: child,
    );
  }
}
```

### 12.4 构建优化

```yaml
# pubspec.yaml 发布配置
flutter:
  # 压缩资源
  assets:
    - assets/runners/
    
  # 字体子集化（减少包体积）
  fonts:
    - family: NotoSansSC
      fonts:
        - asset: assets/fonts/NotoSansSC-Regular.otf
          # 只包含需要的字符
          
# 构建命令优化
# flutter build windows --release --obfuscate --split-debug-info=symbols
```

---

## 十三、参考资源

- [Material Design 3 设计规范](https://m3.material.io/)
- [Flutter 桌面开发文档](https://docs.flutter.dev/desktop)
- [Flutter 性能优化最佳实践](https://docs.flutter.dev/perf)
- [win32 package 文档](https://pub.dev/packages/win32)
- [window_manager 文档](https://pub.dev/packages/window_manager)
- [Riverpod 文档](https://riverpod.dev/)
- [RunCat macOS 官网](https://kyome.io/runcat/index.html)
- [Windows HiDPI 开发指南](https://docs.microsoft.com/en-us/windows/win32/hidpi/high-dpi-desktop-application-development-on-windows)

---

**文档版本**: 1.0  
**创建日期**: 2024  
**作者**: Studio Kyome
