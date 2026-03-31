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
    size: Size(350, 450),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
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
      debugShowCheckedModeBanner: false,
    );
  }
}

class RunCatHomePage extends ConsumerStatefulWidget {
  const RunCatHomePage({super.key});

  @override
  ConsumerState<RunCatHomePage> createState() => _RunCatHomePageState();
}

class _RunCatHomePageState extends ConsumerState<RunCatHomePage> {
  final SystemTrayService _trayService = SystemTrayService();
  final SystemMonitorService _monitorService = SystemMonitorService();

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 初始化系统托盘
    await _trayService.initialize();
    await _trayService.setContextMenu(
      onShow: _showWindow,
      onExit: _exitApp,
    );
    
    _trayService.setLeftClickCallback(_toggleWindow);
    
    // 开始系统监控
    _monitorService.startMonitoring();
  }

  void _showWindow() {
    windowManager.show();
    windowManager.focus();
  }

  void _hideWindow() {
    windowManager.hide();
  }

  void _toggleWindow() {
    windowManager.isVisible().then((isVisible) {
      if (isVisible) {
        _hideWindow();
      } else {
        _showWindow();
      }
    });
  }

  void _exitApp() {
    _trayService.dispose();
    _monitorService.dispose();
    windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        margin: const EdgeInsets.all(8),
        child: Column(
          children: [
            // 自定义标题栏
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(
                    Icons.pets,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'RunCat Flutter',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.minimize),
                    onPressed: _hideWindow,
                    iconSize: 20,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _exitApp,
                    iconSize: 20,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            // 主要内容区域
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 动画显示区域
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
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
                            size: const Size(96, 96),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 系统信息显示
                    _buildSystemInfoCards(),
                    const SizedBox(height: 24),
                    // 控制按钮
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Consumer(
                          builder: (context, ref, child) {
                            final selectedCharacter = ref.watch(selectedCharacterProvider);
                            return DropdownButton<CharacterType>(
                              value: selectedCharacter,
                              items: CharacterType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(_getCharacterName(type)),
                                );
                              }).toList(),
                              onChanged: (type) {
                                if (type != null) {
                                  ref.read(selectedCharacterProvider.notifier).state = type;
                                }
                              },
                            );
                          },
                        ),
                        ElevatedButton.icon(
                          onPressed: _hideWindow,
                          icon: const Icon(Icons.minimize),
                          label: const Text('最小化'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemInfoCards() {
    return StreamBuilder<SystemInfo>(
      stream: _monitorService.systemInfoStream,
      builder: (context, snapshot) {
        final info = snapshot.data;
        
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildInfoCard('CPU', info?.cpuUsage ?? 0, Colors.blue),
            _buildInfoCard('内存', info?.memoryUsage ?? 0, Colors.green),
            _buildInfoCard('GPU', info?.gpuUsage ?? 0, Colors.purple),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard(String label, double value, Color color) {
    return Container(
      width: 100,
      height: 80,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 16,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          LinearProgressIndicator(
            value: value / 100,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 3,
          ),
        ],
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