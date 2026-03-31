import 'dart:async';
import 'dart:typed_data';
import 'package:system_tray/system_tray.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import 'tray_icon_animation_service.dart';

/// 系统托盘服务
/// 整合 system_tray 包和动画服务，提供完整的托盘功能
class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  final TrayIconAnimationService _animationService = TrayIconAnimationService();
  bool _isInitialized = false;

  // 动画状态
  Timer? _iconUpdateTimer;
  List<Uint8List> _iconFrames = [];
  int _currentIconFrame = 0;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 初始化系统托盘
  Future<bool> initialize({int? windowHandle}) async {
    if (_isInitialized) return true;

    try {
      // 初始化 system_tray（使用空图标路径）
      await _systemTray.initSystemTray(
        title: "RunCat",
        iconPath: '',
      );

      // 初始化动画服务
      await _animationService.initialize(
        windowHandle: windowHandle,
        tooltip: 'RunCat - 系统监控',
      );

      _isInitialized = true;
      debugPrint('系统托盘初始化成功');
      return true;
    } catch (e) {
      debugPrint('系统托盘初始化失败: $e');
      return false;
    }
  }

  /// 设置托盘菜单
  Future<void> setContextMenu({
    required VoidCallback onShow,
    required VoidCallback onExit,
    VoidCallback? onSettings,
    VoidCallback? onAbout,
  }) async {
    if (!_isInitialized) {
      throw StateError('系统托盘未初始化');
    }

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '显示主窗口',
        onClicked: (menuItem) => onShow(),
      ),
      MenuSeparator(),
      if (onSettings != null)
        MenuItemLabel(
          label: '设置',
          onClicked: (menuItem) => onSettings(),
        ),
      if (onAbout != null)
        MenuItemLabel(
          label: '关于',
          onClicked: (menuItem) => onAbout(),
        ),
      if (onSettings != null || onAbout != null)
        MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (menuItem) => onExit(),
      ),
    ]);

    await _systemTray.setContextMenu(menu);
  }

  /// 设置左键点击回调
  void setLeftClickCallback(VoidCallback callback) {
    _systemTray.registerSystemTrayEventHandler((eventName) {
      debugPrint('托盘事件: $eventName');
      if (eventName == kSystemTrayEventClick) {
        callback();
      }
    });
  }

  /// 启动动画托盘图标
  ///
  /// 注意：当前 system_tray 包 (2.0.3) 不支持运行时动态修改图标。
  /// 此方法会预先将所有帧转换为图标文件，然后通过定时器切换。
  void startAnimatedIcon({
    required List<ui.Image> frames,
    Duration frameDuration = const Duration(milliseconds: 200),
  }) async {
    if (!_isInitialized || frames.isEmpty) return;

    // 停止现有动画
    stopAnimatedIcon();

    // 启动动画服务
    _animationService.startAnimation(
      frames: frames,
      frameDuration: frameDuration,
    );

    // 注意：由于 system_tray 包限制，当前版本无法真正实现托盘图标动画
    // 这里仅记录日志，实际动画需要在主窗口显示
    debugPrint('托盘动画已启动（${frames.length} 帧）');
    debugPrint('注意：当前 system_tray 版本不支持动态图标切换');
  }

  /// 停止动画托盘图标
  void stopAnimatedIcon() {
    _animationService.stopAnimation();
    _iconUpdateTimer?.cancel();
    _iconUpdateTimer = null;
    _iconFrames = [];
    _currentIconFrame = 0;
  }

  /// 设置托盘提示文本
  Future<void> setTooltip(String tooltip) async {
    // system_tray 2.0.3 不支持动态修改 tooltip
    debugPrint('设置提示文本: $tooltip');
  }

  /// 显示通知气泡
  Future<void> showNotification({
    required String title,
    required String message,
  }) async {
    // system_tray 2.0.3 不支持通知功能
    debugPrint('通知: $title - $message');
  }

  /// 销毁系统托盘
  Future<void> dispose() async {
    stopAnimatedIcon();
    await _animationService.dispose();

    if (_isInitialized) {
      await _systemTray.destroy();
      _isInitialized = false;
    }
  }
}
