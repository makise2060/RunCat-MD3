import 'dart:io';
import 'package:system_tray/system_tray.dart';
import 'package:flutter/foundation.dart';

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

  /// 销毁系统托盘
  Future<void> dispose() async {
    if (_isInitialized) {
      await _systemTray.destroy();
      _isInitialized = false;
    }
  }
}