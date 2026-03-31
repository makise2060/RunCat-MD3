import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'services/system_tray_service.dart';
import 'services/system_monitor_service.dart';
import 'widgets/tray_popup_window.dart';
import 'models/runner_character.dart';
import 'providers/animation_providers.dart';

/// 纯托盘应用入口
/// 
/// 这个版本没有主窗口，只有一个托盘图标。
/// 点击托盘图标会显示一个 Flutter 弹出窗口。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化窗口管理器（用于创建弹出窗口）
  await windowManager.ensureInitialized();

  // 配置窗口为无边框、透明背景，用于弹出菜单
  WindowOptions windowOptions = const WindowOptions(
    size: Size(280, 400),
    minimumSize: Size(280, 300),
    maximumSize: Size(280, 500),
    center: false,
    backgroundColor: Colors.transparent,
    skipTaskbar: true,  // 不在任务栏显示
    titleBarStyle: TitleBarStyle.hidden,  // 隐藏标题栏
    alwaysOnTop: true,  // 始终置顶
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // 初始时隐藏窗口
    await windowManager.hide();
  });

  runApp(const ProviderScope(child: TrayOnlyApp()));
}

class TrayOnlyApp extends StatelessWidget {
  const TrayOnlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RunCat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.orange),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.orange,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const TrayOnlyHomePage(),
    );
  }
}

class TrayOnlyHomePage extends ConsumerStatefulWidget {
  const TrayOnlyHomePage({super.key});

  @override
  ConsumerState<TrayOnlyHomePage> createState() => _TrayOnlyHomePageState();
}

class _TrayOnlyHomePageState extends ConsumerState<TrayOnlyHomePage> {
  final SystemTrayService _trayService = SystemTrayService();
  final SystemMonitorService _monitorService = SystemMonitorService();
  
  PerformanceData? _currentSystemInfo;
  bool _isPopupVisible = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  @override
  void dispose() {
    _trayService.dispose();
    _monitorService.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // 初始化系统托盘
      final trayInitialized = await _trayService.initialize();
      
      if (trayInitialized) {
        // 设置托盘菜单（使用简单的原生菜单作为后备）
        await _trayService.setContextMenu(
          onShow: _togglePopup,
          onExit: _exitApp,
        );
        
        // 设置左键点击显示弹出窗口
        _trayService.setLeftClickCallback(_togglePopup);
      }

      // 初始化系统监控
      final monitorInitialized = await _monitorService.initialize();
      if (monitorInitialized) {
        _monitorService.startMonitoring();
        
        // 监听系统信息更新
        _monitorService.systemInfoStream.listen((data) {
          if (mounted) {
            setState(() {
              _currentSystemInfo = data;
            });
          }
        });
      }

      // 预加载角色资源
      await CharacterFactory.preloadAllCharacters();
      
      debugPrint('纯托盘应用初始化完成');
    } catch (e, stackTrace) {
      debugPrint('初始化失败: $e');
      debugPrint('堆栈: $stackTrace');
    }
  }

  /// 切换弹出窗口显示/隐藏
  Future<void> _togglePopup() async {
    if (_isPopupVisible) {
      await _hidePopup();
    } else {
      await _showPopup();
    }
  }

  /// 显示弹出窗口
  Future<void> _showPopup() async {
    try {
      // 获取弹出窗口位置
      final position = await _getPopupPosition();
      const windowSize = Size(280, 400);

      // 设置窗口位置并显示
      await windowManager.setPosition(position);
      await windowManager.setSize(windowSize);
      await windowManager.show();
      await windowManager.focus();
      
      setState(() {
        _isPopupVisible = true;
      });

      debugPrint('弹出窗口已显示: $position');
    } catch (e, stackTrace) {
      debugPrint('显示弹出窗口失败: $e');
      debugPrint('堆栈: $stackTrace');
    }
  }

  /// 隐藏弹出窗口
  Future<void> _hidePopup() async {
    await windowManager.hide();
    setState(() {
      _isPopupVisible = false;
    });
  }

  /// 获取弹出窗口位置（屏幕右下角，任务栏上方）
  Future<Offset> _getPopupPosition() async {
    try {
      // 获取主显示器信息
      final display = await screenRetriever.getPrimaryDisplay();
      final visiblePosition = display.visiblePosition ?? const Offset(0, 0);
      final visibleSize = display.visibleSize ?? display.size;
      
      // 计算窗口位置（右下角，任务栏上方）
      const windowSize = Size(280, 400);
      final x = visiblePosition.dx + visibleSize.width - windowSize.width - 10;
      final y = visiblePosition.dy + visibleSize.height - windowSize.height - 10;
      
      debugPrint('屏幕信息: visiblePosition=$visiblePosition, visibleSize=$visibleSize');
      debugPrint('计算位置: ($x, $y)');
      
      return Offset(x, y);
    } catch (e) {
      debugPrint('获取屏幕信息失败: $e');
      // 返回默认值（屏幕右下角）
      return const Offset(1620, 650);  // 1920x1080 屏幕的右下角
    }
  }

  /// 退出应用
  Future<void> _exitApp() async {
    await _trayService.dispose();
    _monitorService.dispose();
    await windowManager.destroy();
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    // 监听点击外部区域隐藏窗口
    return GestureDetector(
      onTap: () {
        // 点击窗口内部不处理
      },
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: TrayPopupWindow(
            systemInfo: _currentSystemInfo,
            onExit: _exitApp,
          ),
        ),
      ),
    );
  }
}
