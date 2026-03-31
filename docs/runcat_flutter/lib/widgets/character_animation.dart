import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/runner_character.dart';

/// 角色动画播放器
class CharacterAnimationWidget extends ConsumerStatefulWidget {
  final CharacterType characterType;
  final double speed;
  final bool reverse;
  final Size size;

  const CharacterAnimationWidget({
    super.key,
    required this.characterType,
    this.speed = 1.0,
    this.reverse = false,
    this.size = const Size(64, 64),
  });

  @override
  ConsumerState<CharacterAnimationWidget> createState() => _CharacterAnimationWidgetState();
}

class _CharacterAnimationWidgetState extends ConsumerState<CharacterAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  RunnerCharacter? _character;
  Timer? _frameTimer;
  int _currentFrameIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _loadCharacter();
  }

  @override
  void didUpdateWidget(CharacterAnimationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.characterType != widget.characterType) {
      _loadCharacter();
    } else if (oldWidget.speed != widget.speed || oldWidget.reverse != widget.reverse) {
      _startAnimation();
    }
  }

  Future<void> _loadCharacter() async {
    try {
      final character = await CharacterFactory.getCharacter(widget.characterType);
      if (mounted) {
        setState(() {
          _character = character;
          _currentFrameIndex = 0;
        });
        _startAnimation();
      }
    } catch (e) {
      debugPrint('加载角色失败: $e');
    }
  }

  void _startAnimation() {
    _frameTimer?.cancel();
    
    if (_character == null || _character!.runningFrames.isEmpty) {
      return;
    }

    final frames = widget.reverse
        ? _character!.runningFrames.reversed.toList()
        : _character!.runningFrames;

    final adjustedDuration = Duration(
      milliseconds: (_character!.frameDuration.inMilliseconds / widget.speed).round(),
    );

    _frameTimer = Timer.periodic(adjustedDuration, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _currentFrameIndex = (_currentFrameIndex + 1) % frames.length;
      });
    });
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_character == null || _character!.runningFrames.isEmpty) {
      return SizedBox(
        width: widget.size.width,
        height: widget.size.height,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final frames = widget.reverse
        ? _character!.runningFrames.reversed.toList()
        : _character!.runningFrames;

    final currentFrame = frames[_currentFrameIndex % frames.length];

    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: CustomPaint(
        painter: _CharacterPainter(currentFrame),
      ),
    );
  }
}

class _CharacterPainter extends CustomPainter {
  final ui.Image image;

  _CharacterPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..filterQuality = FilterQuality.none; // 保持像素风格清晰度

    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );

    // 计算居中缩放
    final imageAspectRatio = image.width / image.height;
    final widgetAspectRatio = size.width / size.height;
    
    late final Rect dstRect;
    
    if (imageAspectRatio > widgetAspectRatio) {
      // 图片更宽，以宽度为准
      final scaledHeight = size.width / imageAspectRatio;
      final yOffset = (size.height - scaledHeight) / 2;
      dstRect = Rect.fromLTWH(0, yOffset, size.width, scaledHeight);
    } else {
      // 图片更高，以高度为准  
      final scaledWidth = size.height * imageAspectRatio;
      final xOffset = (size.width - scaledWidth) / 2;
      dstRect = Rect.fromLTWH(xOffset, 0, scaledWidth, size.height);
    }

    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) {
    return oldDelegate.image != image;
  }
}

/// 动画控制面板
class AnimationControlPanel extends ConsumerWidget {
  final CharacterType selectedCharacter;
  final ValueChanged<CharacterType> onCharacterChanged;
  final double speed;
  final ValueChanged<double> onSpeedChanged;
  final bool reverse;
  final ValueChanged<bool> onReverseChanged;

  const AnimationControlPanel({
    super.key,
    required this.selectedCharacter,
    required this.onCharacterChanged,
    required this.speed,
    required this.onSpeedChanged,
    required this.reverse,
    required this.onReverseChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '动画控制',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            
            // 角色选择
            _buildCharacterSelector(),
            const SizedBox(height: 16),
            
            // 速度控制
            _buildSpeedControl(),
            const SizedBox(height: 16),
            
            // 反转选项
            _buildReverseOption(),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('角色'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CharacterType.values.map((type) {
            return ChoiceChip(
              label: Text(_getCharacterName(type)),
              selected: type == selectedCharacter,
              onSelected: (selected) {
                if (selected) {
                  onCharacterChanged(type);
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpeedControl() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('速度: ${speed.toStringAsFixed(1)}x'),
        Slider(
          value: speed,
          min: 0.1,
          max: 3.0,
          divisions: 29,
          onChanged: onSpeedChanged,
        ),
      ],
    );
  }

  Widget _buildReverseOption() {
    return SwitchListTile(
      title: const Text('倒序播放'),
      value: reverse,
      onChanged: onReverseChanged,
    );
  }

  String _getCharacterName(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return '猫咪';
      case CharacterType.horse:
        return '马儿';
      case CharacterType.parrot:
        return '鹦鹉';
    }
  }
}

import 'dart:ui' as ui;