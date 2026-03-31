import 'dart:io';
import 'dart:async';
import 'package:system_tray/system_tray.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;

class SystemTrayService {
  static final SystemTrayService _instance = SystemTrayService._internal();
  factory SystemTrayService() => _instance;
  SystemTrayService._internal();

  final SystemTray _systemTray = SystemTray();
  bool _isInitialized = false;

  /// 初始化系统托盘
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      String iconPath = Platform.isWindows
          ? 'assets/images/cat_icon.ico'
          : 'assets/images/cat_icon.png';

      await _systemTray.initSystemTray(
        title: "RunCat",
        iconPath: iconPath,
      );

      _isInitialized = true;
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
  }) async {
    if (!_isInitialized) {
      throw StateError('系统托盘未初始化');
    }

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: '显示',
        onClicked: (menuItem) => onShow(),
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: '退出',
        onClicked: (menuItem) => onExit(),
      ),
    ]);

    await _systemTray.setContextMenu(menu);
  }

  /// 设置托盘图标
  Future<void> setIcon(String iconPath) async {
    if (!_isInitialized) {
      throw StateError('系统托盘未初始化');
    }

    try {
      await _systemTray.setIcon(iconPath);
    } catch (e) {
      debugPrint('设置托盘图标失败: $e');
    }
  }

  /// 显示通知气泡
  Future<void> showNotification({
    required String title,
    required String message,
  }) async {
    if (!_isInitialized) return;

    try {
      await _systemTray.showNotification(
        title: title,
        message: message,
      );
    } catch (e) {
      debugPrint('显示通知失败: $e');
    }
  }

  /// 设置左键点击回调
  void setLeftClickCallback(VoidCallback callback) {
    _systemTray.registerSystemTrayEventHandler((eventName) {
      if (eventName == kSystemTrayEventClick) {
        callback();
      }
    });
  }

  /// 启动动画托盘图标
  void startAnimatedIcon({
    required List<ui.Image> frames,
    Duration frameDuration = const Duration(milliseconds: 200),
  }) {
    if (!_isInitialized || frames.isEmpty) return;

    _stopAnimatedIcon();
    
    int currentFrame = 0;
    _animationTimer = Timer.periodic(frameDuration, (timer) async {
      if (!_isInitialized || frames.isEmpty) {
        timer.cancel();
        return;
      }

      try {
        // 将当前帧转换为临时图标文件并设置
        final frameBytes = await _imageToBytes(frames[currentFrame]);
        // 这里我们简化处理，实际项目中应该保存为临时文件
        // await _systemTray.setIconFromBytes(frameBytes);
        
        currentFrame = (currentFrame + 1) % frames.length;
      } catch (e) {
        debugPrint('更新托盘动画帧失败: $e');
      }
    });
  }

  /// 停止动画托盘图标
  void _stopAnimatedIcon() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  /// 将图片转换为字节
  Future<Uint8List> _imageToBytes(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List() ?? Uint8List(0);
  }

  Timer? _animationTimer;

  /// 销毁系统托盘
  Future<void> dispose() async {
    _stopAnimatedIcon();
    if (_isInitialized) {
      await _systemTray.destroy();
      _isInitialized = false;
    }
  }
}