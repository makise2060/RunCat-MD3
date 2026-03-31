import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum CharacterType {
  cat,
  horse,
  parrot,
}

class RunnerCharacter {
  final CharacterType type;
  final String name;
  final String nameKey;
  final List<ui.Image> runningFrames;
  final Duration frameDuration;

  const RunnerCharacter({
    required this.type,
    required this.name,
    required this.nameKey,
    required this.runningFrames,
    this.frameDuration = const Duration(milliseconds: 100),
  });

  /// 获取动画帧数
  int get frameCount => runningFrames.length;

  /// 获取动画总时长（循环一次）
  Duration get totalDuration => Duration(
    milliseconds: frameDuration.inMilliseconds * frameCount,
  );
}

/// 角色工厂类
class CharacterFactory {
  static final Map<CharacterType, RunnerCharacter> _cache = {};

  /// 获取角色实例
  static Future<RunnerCharacter> getCharacter(
    CharacterType type, {
    Duration frameDuration = const Duration(milliseconds: 100),
  }) async {
    if (_cache.containsKey(type)) {
      return _cache[type]!;
    }

    final character = await _loadCharacter(type, frameDuration);
    _cache[type] = character;
    return character;
  }

  /// 加载角色资源
  static Future<RunnerCharacter> _loadCharacter(
    CharacterType type,
    Duration frameDuration,
  ) async {
    final String basePath = 'assets/animations/${type.name}/';
    final List<String> frameNames = await _getFrameNames(type);
    final List<ui.Image> frames = [];

    for (final frameName in frameNames) {
      try {
        final imagePath = '$basePath$frameName';
        final image = await _loadImageFromAsset(imagePath);
        frames.add(image);
      } catch (e) {
        debugPrint('加载动画帧失败: $frameName - $e');
      }
    }

    return RunnerCharacter(
      type: type,
      name: _getCharacterName(type),
      nameKey: _getCharacterNameKey(type),
      runningFrames: frames,
      frameDuration: frameDuration,
    );
  }

  /// 获取角色帧文件名
  static Future<List<String>> _getFrameNames(CharacterType type) async {
    switch (type) {
      case CharacterType.cat:
        return ['cat_0.png', 'cat_1.png', 'cat_2.png', 'cat_3.png', 'cat_4.png'];
      case CharacterType.horse:
        return ['horse_0.png', 'horse_1.png', 'horse_2.png', 'horse_3.png', 'horse_4.png'];
      case CharacterType.parrot:
        return [
          'parrot_0.png', 'parrot_1.png', 'parrot_2.png', 'parrot_3.png', 'parrot_4.png',
          'parrot_5.png', 'parrot_6.png', 'parrot_7.png', 'parrot_8.png', 'parrot_9.png',
        ];
    }
  }

  /// 获取角色显示名称
  static String _getCharacterName(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return '猫咪';
      case CharacterType.horse:
        return '马儿';
      case CharacterType.parrot:
        return '鹦鹉';
    }
  }

  /// 获取角色本地化键
  static String _getCharacterNameKey(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return 'character_cat';
      case CharacterType.horse:
        return 'character_horse';
      case CharacterType.parrot:
        return 'character_parrot';
    }
  }

  /// 加载图片资源
  static Future<ui.Image> _loadImageFromAsset(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  /// 预加载所有角色
  static Future<void> preloadAllCharacters() async {
    for (final type in CharacterType.values) {
      await getCharacter(type);
    }
  }

  /// 清理缓存
  static void clearCache() {
    _cache.clear();
  }

  /// 获取所有可用角色类型
  static List<CharacterType> get availableCharacters => CharacterType.values;

  /// 获取角色缩略图
  static Future<ui.Image?> getCharacterThumbnail(CharacterType type) async {
    final character = await getCharacter(type);
    if (character.runningFrames.isNotEmpty) {
      return character.runningFrames.first;
    }
    return null;
  }
}

/// 角色选择器 Widget
class CharacterSelector extends StatefulWidget {
  final CharacterType selectedCharacter;
  final ValueChanged<CharacterType> onCharacterChanged;

  const CharacterSelector({
    super.key,
    required this.selectedCharacter,
    required this.onCharacterChanged,
  });

  @override
  State<CharacterSelector> createState() => _CharacterSelectorState();
}

class _CharacterSelectorState extends State<CharacterSelector> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '选择角色',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: CharacterType.values.map((type) {
                return _buildCharacterOption(type);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCharacterOption(CharacterType type) {
    final isSelected = type == widget.selectedCharacter;
    
    return FilterChip(
      label: Text(_getCharacterName(type)),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          widget.onCharacterChanged(type);
        }
      },
      avatar: FutureBuilder<ui.Image?>(
        future: CharacterFactory.getCharacterThumbnail(type),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            return SizedBox(
              width: 24,
              height: 24,
              child: CustomPaint(
                painter: _ThumbnailPainter(snapshot.data!),
              ),
            );
          }
          return const SizedBox(
            width: 24,
            height: 24,
            child: Icon(Icons.pets, size: 16),
          );
        },
      ),
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

class _ThumbnailPainter extends CustomPainter {
  final ui.Image image;

  _ThumbnailPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    
    final srcRect = Rect.fromLTWH(
      0, 0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    
    final dstRect = Rect.fromLTWH(
      0, 0,
      size.width,
      size.height,
    );
    
    canvas.drawImageRect(image, srcRect, dstRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}