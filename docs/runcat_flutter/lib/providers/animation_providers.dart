import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/runner_character.dart';
import '../services/system_monitor_service.dart';

/// 当前选择的角色类型
final selectedCharacterProvider = StateProvider<CharacterType>((ref) {
  return CharacterType.cat;
});

/// 当前速度倍数
final animationSpeedProvider = StateProvider<double>((ref) {
  return 1.0;
});

/// 是否反转播放
final reverseAnimationProvider = StateProvider<bool>((ref) {
  return false;
});

/// 速度来源类型
final speedSourceProvider = StateProvider<SpeedSource>((ref) {
  return SpeedSource.cpu;
});

/// 系统监控服务提供者
final systemMonitorProvider = Provider<SystemMonitorService>((ref) {
  return SystemMonitorService();
});

/// 系统信息流
final systemInfoStreamProvider = StreamProvider<PerformanceData>((ref) {
  final monitor = ref.watch(systemMonitorProvider);
  return monitor.systemInfoStream;
});

/// 基于系统监控的动画速度
final dynamicAnimationSpeedProvider = Provider<double>((ref) {
  final speedSource = ref.watch(speedSourceProvider);
  final systemInfo = ref.watch(systemInfoStreamProvider);
  
  return systemInfo.when(
    data: (info) {
      final baseSpeed = switch (speedSource) {
        SpeedSource.cpu => info.cpuUsage,
        SpeedSource.memory => info.memoryUsage,
        SpeedSource.gpu => info.gpuUsage ?? 0.0,
      };
      
      // 将使用率映射到速度倍数 (0.5x - 3.0x)
      return 0.5 + (baseSpeed / 100.0) * 2.5;
    },
    loading: () => 1.0,
    error: (_, __) => 1.0,
  );
});

/// 实际生效的动画速度
final effectiveAnimationSpeedProvider = Provider<double>((ref) {
  final manualSpeed = ref.watch(animationSpeedProvider);
  final useDynamicSpeed = ref.watch(useDynamicSpeedProvider);
  
  if (useDynamicSpeed) {
    return ref.watch(dynamicAnimationSpeedProvider);
  } else {
    return manualSpeed;
  }
});

/// 是否使用动态速度
final useDynamicSpeedProvider = StateProvider<bool>((ref) {
  return true; // 默认使用系统监控驱动的动态速度
});

/// 托盘图标更新流
final trayIconStreamProvider = StreamProvider<RunnerCharacter>((ref) {
  final selectedCharacter = ref.watch(selectedCharacterProvider);
  
  // 每200ms更新一次托盘图标
  return Stream.periodic(
    const Duration(milliseconds: 200),
    (_) => selectedCharacter,
  ).asyncMap((characterType) async {
    return await CharacterFactory.getCharacter(characterType);
  });
});

/// 角色预加载提供者
final characterPreloadProvider = FutureProvider<void>((ref) async {
  await CharacterFactory.preloadAllCharacters();
});

/// 当前角色的详细信息
final currentCharacterProvider = FutureProvider<RunnerCharacter>((ref) async {
  final selectedCharacter = ref.watch(selectedCharacterProvider);
  return await CharacterFactory.getCharacter(selectedCharacter);
});

/// 动画控制面板状态
class AnimationControlState {
  final CharacterType selectedCharacter;
  final double manualSpeed;
  final bool isReverse;
  final SpeedSource speedSource;
  final bool useDynamicSpeed;

  const AnimationControlState({
    required this.selectedCharacter,
    required this.manualSpeed,
    required this.isReverse,
    required this.speedSource,
    required this.useDynamicSpeed,
  });

  AnimationControlState copyWith({
    CharacterType? selectedCharacter,
    double? manualSpeed,
    bool? isReverse,
    SpeedSource? speedSource,
    bool? useDynamicSpeed,
  }) {
    return AnimationControlState(
      selectedCharacter: selectedCharacter ?? this.selectedCharacter,
      manualSpeed: manualSpeed ?? this.manualSpeed,
      isReverse: isReverse ?? this.isReverse,
      speedSource: speedSource ?? this.speedSource,
      useDynamicSpeed: useDynamicSpeed ?? this.useDynamicSpeed,
    );
  }
}

/// 动画控制状态提供者
final animationControlProvider = StateNotifierProvider<AnimationControlNotifier, AnimationControlState>((ref) {
  return AnimationControlNotifier();
});

class AnimationControlNotifier extends StateNotifier<AnimationControlState> {
  AnimationControlNotifier() : super(const AnimationControlState(
    selectedCharacter: CharacterType.cat,
    manualSpeed: 1.0,
    isReverse: false,
    speedSource: SpeedSource.cpu,
    useDynamicSpeed: true,
  ));

  void setCharacter(CharacterType character) {
    state = state.copyWith(selectedCharacter: character);
  }

  void setManualSpeed(double speed) {
    state = state.copyWith(manualSpeed: speed);
  }

  void setReverse(bool reverse) {
    state = state.copyWith(isReverse: reverse);
  }

  void setSpeedSource(SpeedSource source) {
    state = state.copyWith(speedSource: source);
  }

  void setUseDynamicSpeed(bool useDynamic) {
    state = state.copyWith(useDynamicSpeed: useDynamic);
  }
}

/// 动画性能监控
final animationPerfProvider = Provider<Map<String, dynamic>>((ref) {
  final useDynamicSpeed = ref.watch(useDynamicSpeedProvider);
  final effectiveSpeed = ref.watch(effectiveAnimationSpeedProvider);
  final speedSource = ref.watch(speedSourceProvider);
  
  return {
    'dynamicSpeedEnabled': useDynamicSpeed,
    'effectiveSpeed': effectiveSpeed,
    'speedSource': speedSource,
    'timestamp': DateTime.now(),
  };
});