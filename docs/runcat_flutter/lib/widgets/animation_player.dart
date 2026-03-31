import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AnimationFrame {
  final ui.Image image;
  final Duration duration;

  const AnimationFrame({
    required this.image,
    this.duration = const Duration(milliseconds: 100),
  });
}

class AnimationPlayer extends StatefulWidget {
  final List<AnimationFrame> frames;
  final double speed;
  final bool reverse;
  final bool loop;
  final VoidCallback? onAnimationComplete;

  const AnimationPlayer({
    super.key,
    required this.frames,
    this.speed = 1.0,
    this.reverse = false,
    this.loop = true,
    this.onAnimationComplete,
  });

  @override
  State<AnimationPlayer> createState() => _AnimationPlayerState();
}

class _AnimationPlayerState extends State<AnimationPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Timer? _frameTimer;
  int _currentFrameIndex = 0;
  List<AnimationFrame> _displayFrames = [];

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  @override
  void didUpdateWidget(AnimationPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.frames != widget.frames ||
        oldWidget.speed != widget.speed ||
        oldWidget.reverse != widget.reverse) {
      _setupAnimation();
    }
  }

  void _setupAnimation() {
    _frameTimer?.cancel();
    
    _displayFrames = widget.reverse
        ? widget.frames.reversed.toList()
        : widget.frames;

    if (_displayFrames.isEmpty) return;

    _currentFrameIndex = 0;
    _startFrameTimer();
  }

  void _startFrameTimer() {
    if (_displayFrames.isEmpty) return;

    final currentFrame = _displayFrames[_currentFrameIndex];
    final adjustedDuration = Duration(
      milliseconds: (currentFrame.duration.inMilliseconds / widget.speed).round(),
    );

    _frameTimer = Timer(adjustedDuration, () {
      if (!mounted) return;

      setState(() {
        _currentFrameIndex++;
        
        if (_currentFrameIndex >= _displayFrames.length) {
          if (widget.loop) {
            _currentFrameIndex = 0;
          } else {
            _currentFrameIndex = _displayFrames.length - 1;
            _frameTimer?.cancel();
            widget.onAnimationComplete?.call();
            return;
          }
        }
      });

      _startFrameTimer();
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayFrames.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentFrame = _displayFrames[_currentFrameIndex];

    return CustomPaint(
      painter: _AnimationPainter(currentFrame.image),
      size: Size(
        currentFrame.image.width.toDouble(),
        currentFrame.image.height.toDouble(),
      ),
    );
  }
}

class _AnimationPainter extends CustomPainter {
  final ui.Image image;

  _AnimationPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none; // 保持像素清晰度

    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    final dstRect = Rect.fromLTWH(
      0,
      0,
      size.width,
      size.height,
    );

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimationPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

/// 加载动画资源
class AnimationLoader {
  static final Map<String, List<AnimationFrame>> _cache = {};

  /// 从 assets 加载动画序列
  static Future<List<AnimationFrame>> loadFromAssets(
    String basePath,
    List<String> frameNames, {
    Duration frameDuration = const Duration(milliseconds: 100),
  }) async {
    final cacheKey = '$basePath/${frameNames.join(',')}';
    
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    final frames = <AnimationFrame>[];
    
    for (final frameName in frameNames) {
      try {
        final imagePath = '$basePath/$frameName';
        final image = await _loadImageFromAsset(imagePath);
        
        frames.add(AnimationFrame(
          image: image,
          duration: frameDuration,
        ));
      } catch (e) {
        debugPrint('加载动画帧失败: $frameName - $e');
      }
    }

    _cache[cacheKey] = frames;
    return frames;
  }

  static Future<ui.Image> _loadImageFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// 清理缓存
  static void clearCache() {
    _cache.clear();
  }
}