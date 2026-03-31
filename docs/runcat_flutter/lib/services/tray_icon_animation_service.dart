import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

/// 托盘图标动画服务
/// 
/// 注意：由于 win32 包的 API 限制，当前版本使用简化实现。
/// 实际的原生托盘动画需要更底层的 Windows API 集成。
/// 
/// 当前实现：
/// 1. 提供动画帧管理
/// 2. 提供回调接口供外部更新托盘图标
/// 3. 为未来原生实现预留接口
class TrayIconAnimationService {
  static final TrayIconAnimationService _instance = TrayIconAnimationService._internal();
  factory TrayIconAnimationService() => _instance;
  TrayIconAnimationService._internal();

  // 托盘图标尺寸
  static const int trayIconSize = 16;

  Timer? _animationTimer;
  List<ui.Image> _frames = [];
  int _currentFrame = 0;
  bool _isInitialized = false;
  String _tooltip = 'RunCat';

  // 回调函数
  Function(ui.Image frame)? _onFrameUpdate;
  Function(String tooltip)? _onTooltipUpdate;

  /// 是否已初始化
  bool get isInitialized => _isInitialized;

  /// 当前帧索引
  int get currentFrameIndex => _currentFrame;

  /// 总帧数
  int get frameCount => _frames.length;

  /// 初始化托盘动画服务
  Future<bool> initialize({
    int? windowHandle,
    String tooltip = 'RunCat',
    Function(ui.Image frame)? onFrameUpdate,
    Function(String tooltip)? onTooltipUpdate,
  }) async {
    if (_isInitialized) return true;

    try {
      _tooltip = tooltip;
      _onFrameUpdate = onFrameUpdate;
      _onTooltipUpdate = onTooltipUpdate;

      _isInitialized = true;
      debugPrint('托盘动画服务初始化成功');
      return true;
    } catch (e) {
      debugPrint('托盘动画服务初始化失败: $e');
      return false;
    }
  }

  /// 开始动画
  void startAnimation({
    required List<ui.Image> frames,
    Duration frameDuration = const Duration(milliseconds: 200),
  }) {
    if (!_isInitialized || frames.isEmpty) return;

    _frames = frames;
    _currentFrame = 0;
    _stopAnimation();

    // 立即显示第一帧
    _notifyFrameUpdate();

    // 启动定时器
    _animationTimer = Timer.periodic(frameDuration, (_) {
      _currentFrame = (_currentFrame + 1) % _frames.length;
      _notifyFrameUpdate();
    });

    debugPrint('托盘动画已启动，帧数: ${frames.length}');
  }

  /// 停止动画
  void stopAnimation() {
    _stopAnimation();
    _frames = [];
    _currentFrame = 0;
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
  }

  /// 通知帧更新
  void _notifyFrameUpdate() {
    if (_frames.isEmpty) return;
    final frame = _frames[_currentFrame];
    _onFrameUpdate?.call(frame);
  }

  /// 设置提示文本
  Future<void> setTooltip(String tooltip) async {
    _tooltip = tooltip;
    _onTooltipUpdate?.call(tooltip);
  }

  /// 获取当前帧作为图标字节数据
  Future<Uint8List?> getCurrentFrameBytes() async {
    if (_frames.isEmpty) return null;
    return _imageToPngBytes(_frames[_currentFrame]);
  }

  /// 将 ui.Image 转换为 PNG 字节
  Future<Uint8List?> _imageToPngBytes(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('转换图像失败: $e');
      return null;
    }
  }

  /// 销毁服务
  Future<void> dispose() async {
    _stopAnimation();
    _isInitialized = false;
    _frames = [];
    _onFrameUpdate = null;
    _onTooltipUpdate = null;
  }
}
