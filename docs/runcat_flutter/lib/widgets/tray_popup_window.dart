import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/runner_character.dart';
import '../providers/animation_providers.dart';
import '../services/system_monitor_service.dart';
import 'character_animation.dart';

/// 托盘弹出窗口
/// 
/// 这是一个小型的 Flutter 窗口，显示在托盘图标附近，
/// 包含完整的 RunCat 功能：动画展示、系统信息、设置等
class TrayPopupWindow extends ConsumerStatefulWidget {
  final PerformanceData? systemInfo;
  final VoidCallback onExit;

  const TrayPopupWindow({
    super.key,
    this.systemInfo,
    required this.onExit,
  });

  @override
  ConsumerState<TrayPopupWindow> createState() => _TrayPopupWindowState();
}

class _TrayPopupWindowState extends ConsumerState<TrayPopupWindow> {
  bool _showSettings = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _showSettings ? _buildSettingsPanel() : _buildMainPanel(),
        ),
      ),
    );
  }

  /// 主面板
  Widget _buildMainPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 系统信息区域
        _buildSystemInfoHeader(),
        const Divider(height: 1),
        // 动画展示区域
        _buildAnimationSection(),
        const Divider(height: 1),
        // 菜单选项
        _buildMenuItems(),
      ],
    );
  }

  /// 系统信息头部
  Widget _buildSystemInfoHeader() {
    final data = widget.systemInfo;
    
    return Container(
      padding: const EdgeInsets.all(12),
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.memory,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'CPU: ${data?.cpuUsage.toStringAsFixed(1) ?? "--"}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.storage,
                size: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(width: 6),
              Text(
                '内存: ${data?.memoryUsage.toStringAsFixed(1) ?? "--"}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          if (data?.gpuUsage != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.videocam,
                  size: 14,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  'GPU: ${data?.gpuUsage?.toStringAsFixed(1) ?? "--"}%',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// 动画展示区域
  Widget _buildAnimationSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // 动画
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Consumer(
              builder: (context, ref, child) {
                final selectedCharacter = ref.watch(selectedCharacterProvider);
                final effectiveSpeed = ref.watch(effectiveAnimationSpeedProvider);
                final reverse = ref.watch(reverseAnimationProvider);

                return CharacterAnimationWidget(
                  characterType: selectedCharacter,
                  speed: effectiveSpeed,
                  reverse: reverse,
                  size: const Size(56, 56),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          // 角色选择
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final selectedCharacter = ref.watch(selectedCharacterProvider);
                
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '角色',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      children: CharacterType.values.map((type) {
                        final isSelected = type == selectedCharacter;
                        return InkWell(
                          onTap: () {
                            ref.read(selectedCharacterProvider.notifier).state = type;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primaryContainer
                                  : Theme.of(context).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _getCharacterName(type),
                              style: TextStyle(
                                fontSize: 11,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.onPrimaryContainer
                                    : Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// 菜单项
  Widget _buildMenuItems() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildMenuItem(
          icon: Icons.speed,
          label: '速度来源',
          trailing: Consumer(
            builder: (context, ref, child) {
              final source = ref.watch(speedSourceProvider);
              return Text(
                _getSpeedSourceName(source),
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          onTap: () {
            _showSpeedSourceSelector();
          },
        ),
        _buildMenuItem(
          icon: Icons.settings,
          label: '设置',
          onTap: () {
            setState(() {
              _showSettings = true;
            });
          },
        ),
        _buildMenuItem(
          icon: Icons.info_outline,
          label: '关于 RunCat',
          onTap: () {
            _showAboutDialog();
          },
        ),
        const Divider(height: 1),
        _buildMenuItem(
          icon: Icons.exit_to_app,
          label: '退出',
          textColor: Theme.of(context).colorScheme.error,
          onTap: widget.onExit,
        ),
      ],
    );
  }

  /// 单个菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    Widget? trailing,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: textColor ?? Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: textColor ?? Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  /// 设置面板
  Widget _buildSettingsPanel() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 返回按钮和标题
        Container(
          padding: const EdgeInsets.all(12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _showSettings = false;
                  });
                },
                child: Icon(
                  Icons.arrow_back,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '设置',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        // 设置选项
        _buildSettingItem(
          label: '主题',
          child: Consumer(
            builder: (context, ref, child) {
              // TODO: 实现主题切换
              return Text(
                '跟随系统',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ),
        _buildSettingItem(
          label: '开机启动',
          child: Consumer(
            builder: (context, ref, child) {
              // TODO: 实现开机启动
              return Switch(
                value: false,
                onChanged: (value) {},
              );
            },
          ),
        ),
      ],
    );
  }

  /// 设置项
  Widget _buildSettingItem({
    required String label,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }

  /// 显示速度来源选择器
  void _showSpeedSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentSource = ref.watch(speedSourceProvider);
            
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('CPU'),
                    trailing: currentSource == SpeedSource.cpu
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref.read(speedSourceProvider.notifier).state = SpeedSource.cpu;
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('内存'),
                    trailing: currentSource == SpeedSource.memory
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref.read(speedSourceProvider.notifier).state = SpeedSource.memory;
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('GPU'),
                    trailing: currentSource == SpeedSource.gpu
                        ? const Icon(Icons.check)
                        : null,
                    onTap: () {
                      ref.read(speedSourceProvider.notifier).state = SpeedSource.gpu;
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 显示关于对话框
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('RunCat Flutter'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('版本: 1.0.0'),
              SizedBox(height: 8),
              Text('基于 Flutter + Material Design 3 重构'),
              Text('显示系统繁忙程度的可爱桌面宠物'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('确定'),
            ),
          ],
        );
      },
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

  String _getSpeedSourceName(SpeedSource source) {
    switch (source) {
      case SpeedSource.cpu:
        return 'CPU';
      case SpeedSource.memory:
        return '内存';
      case SpeedSource.gpu:
        return 'GPU';
    }
  }
}
