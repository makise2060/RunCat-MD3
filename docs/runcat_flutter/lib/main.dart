import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'services/system_tray_service.dart';
import 'services/system_monitor_service.dart';
import 'widgets/character_animation.dart';
import 'models/runner_character.dart';
import 'providers/animation_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 配置窗口
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(420, 520),
    minimumSize: Size(350, 400),
    center: true,
    backgroundColor: Colors.white,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    alwaysOnTop: false,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ProviderScope(child: RunCatApp()));
}

class RunCatApp extends StatelessWidget {
  const RunCatApp({super.key});

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
      home: const RunCatHomePage(),
    );
  }
}

class RunCatHomePage extends ConsumerStatefulWidget {
  const RunCatHomePage({super.key});

  @override
  ConsumerState<RunCatHomePage> createState() => _RunCatHomePageState();
}

class _RunCatHomePageState extends ConsumerState<RunCatHomePage>
    with WindowListener {
  final SystemTrayService _trayService = SystemTrayService();
  final SystemMonitorService _monitorService = SystemMonitorService();

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _initializeApp();
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _trayService.dispose();
    _monitorService.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    try {
      // 获取窗口句柄用于托盘动画
      final hwnd = await _getWindowHandle();
      debugPrint('窗口句柄: $hwnd');

      // 初始化系统托盘
      final trayInitialized = await _trayService.initialize(
        windowHandle: hwnd,
      );

      if (trayInitialized) {
        await _trayService.setContextMenu(
          onShow: _showWindow,
          onExit: _exitApp,
          onSettings: _showSettings,
          onAbout: _showAbout,
        );
        _trayService.setLeftClickCallback(_toggleWindow);

        // 启动托盘动画
        await _startTrayAnimation();
      }

      // 初始化并启动系统监控
      final monitorInitialized = await _monitorService.initialize();
      if (monitorInitialized) {
        _monitorService.startMonitoring();
      }
    } catch (e, stackTrace) {
      debugPrint('初始化失败: $e');
      debugPrint('堆栈: $stackTrace');
    }
  }

  /// 获取窗口句柄
  /// 
  /// 注意：当前 window_manager 版本不直接支持获取原生窗口句柄。
  /// 如需原生托盘动画，需要通过平台通道或原生插件实现。
  Future<int?> _getWindowHandle() async {
    // 返回 null，使用纯 Dart 实现的动画服务
    return null;
  }

  /// 启动托盘动画
  Future<void> _startTrayAnimation() async {
    try {
      // 加载猫咪角色作为托盘动画
      final character = await CharacterFactory.getCharacter(CharacterType.cat);
      if (character.runningFrames.isNotEmpty) {
        _trayService.startAnimatedIcon(
          frames: character.runningFrames,
          frameDuration: const Duration(milliseconds: 150),
        );
        debugPrint('托盘动画已启动');
      }
    } catch (e) {
      debugPrint('启动托盘动画失败: $e');
    }
  }

  // ========== 窗口操作 ==========

  void _showWindow() async {
    await windowManager.show();
    await windowManager.focus();
    await windowManager.restore(); // 确保窗口从最小化恢复
  }

  void _hideWindow() async {
    await windowManager.hide();
  }

  void _toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    if (isVisible) {
      _hideWindow();
    } else {
      _showWindow();
    }
  }

  void _exitApp() async {
    await _trayService.dispose();
    _monitorService.dispose();
    await windowManager.destroy();
  }

  void _showSettings() {
    // TODO: 显示设置对话框
    debugPrint('显示设置');
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: 'RunCat Flutter',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.pets, size: 48, color: Colors.orange),
      children: [
        const Text('基于 Flutter + Material Design 3 重构'),
        const Text('显示系统繁忙程度的可爱桌面宠物'),
      ],
    );
  }

  // ========== WindowListener 回调 ==========

  @override
  void onWindowClose() async {
    // 关闭按钮点击时最小化到托盘而不是退出
    await windowManager.hide();
  }

  @override
  void onWindowMinimize() {
    // 最小化时可选：隐藏到托盘
    // windowManager.hide();
  }

  @override
  void onWindowRestore() {
    // 窗口恢复时确保可见
    windowManager.show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RunCat Flutter'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: _showSettings,
            tooltip: '设置',
          ),
          IconButton(
            icon: const Icon(Icons.minimize),
            onPressed: _hideWindow,
            tooltip: '最小化到托盘',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 动画显示区域
            _buildAnimationCard(),
            const SizedBox(height: 16),
            // 系统信息显示
            _buildSystemInfoCard(),
            const SizedBox(height: 16),
            // 控制面板
            _buildControlPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimationCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'RunCat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // 动画显示区域
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
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
                    size: const Size(100, 100),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '系统状态',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            StreamBuilder<PerformanceData>(
              stream: _monitorService.systemInfoStream,
              builder: (context, snapshot) {
                final data = snapshot.data;

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildInfoItem('CPU', data?.cpuUsage ?? 0, Colors.blue),
                    _buildInfoItem(
                      '内存',
                      data?.memoryUsage ?? 0,
                      Colors.green,
                      subtitle: data != null
                          ? '${data.memoryUsedGB.toStringAsFixed(1)}/${data.memoryTotalGB.toStringAsFixed(1)} GB'
                          : null,
                    ),
                    _buildInfoItem('GPU', data?.gpuUsage ?? 0, Colors.purple),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, double value, Color color,
      {String? subtitle}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 18,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9,
                color: color.withOpacity(0.8),
              ),
            ),
          ],
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlPanel() {
    return Consumer(
      builder: (context, ref, child) {
        final selectedCharacter = ref.watch(selectedCharacterProvider);
        final speedSource = ref.watch(speedSourceProvider);

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '控制面板',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                // 角色选择
                _buildCharacterSelector(selectedCharacter, ref),
                const SizedBox(height: 16),
                // 速度源选择
                _buildSpeedSourceSelector(speedSource, ref),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCharacterSelector(
      CharacterType selected, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('角色选择', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: CharacterType.values.map((type) {
            final isSelected = type == selected;
            return FilterChip(
              label: Text(_getCharacterName(type)),
              selected: isSelected,
              onSelected: (_) {
                ref.read(selectedCharacterProvider.notifier).state = type;
                // 切换角色时更新托盘动画
                _updateTrayAnimation(type);
              },
              avatar: Icon(
                _getCharacterIcon(type),
                size: 16,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpeedSourceSelector(SpeedSource source, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('动画速度来源', style: TextStyle(fontSize: 12)),
        const SizedBox(height: 8),
        SegmentedButton<SpeedSource>(
          segments: const [
            ButtonSegment(
              value: SpeedSource.cpu,
              label: Text('CPU'),
              icon: Icon(Icons.memory, size: 16),
            ),
            ButtonSegment(
              value: SpeedSource.memory,
              label: Text('内存'),
              icon: Icon(Icons.storage, size: 16),
            ),
            ButtonSegment(
              value: SpeedSource.gpu,
              label: Text('GPU'),
              icon: Icon(Icons.videocam, size: 16),
            ),
          ],
          selected: {source},
          onSelectionChanged: (selected) {
            if (selected.isNotEmpty) {
              ref.read(speedSourceProvider.notifier).state = selected.first;
            }
          },
        ),
      ],
    );
  }

  Future<void> _updateTrayAnimation(CharacterType type) async {
    _trayService.stopAnimatedIcon();
    try {
      final character = await CharacterFactory.getCharacter(type);
      if (character.runningFrames.isNotEmpty) {
        _trayService.startAnimatedIcon(
          frames: character.runningFrames,
          frameDuration: const Duration(milliseconds: 150),
        );
      }
    } catch (e) {
      debugPrint('更新托盘动画失败: $e');
    }
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

  IconData _getCharacterIcon(CharacterType type) {
    switch (type) {
      case CharacterType.cat:
        return Icons.pets;
      case CharacterType.horse:
        return Icons.emoji_nature;
      case CharacterType.parrot:
        return Icons.flutter_dash;
    }
  }
}
