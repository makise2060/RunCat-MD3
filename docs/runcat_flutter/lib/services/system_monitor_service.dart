import 'dart:async';
import 'package:flutter/foundation.dart';
import 'windows_performance_service.dart';

export 'windows_performance_service.dart' show PerformanceData;

enum SpeedSource { cpu, memory, gpu }

class SystemMonitorService {
  static final SystemMonitorService _instance = SystemMonitorService._internal();
  factory SystemMonitorService() => _instance;
  SystemMonitorService._internal();

  final WindowsPerformanceService _performanceService = WindowsPerformanceService();
  PerformanceData? _lastData;
  bool _isInitialized = false;

  /// 系统信息流
  Stream<PerformanceData> get systemInfoStream => _performanceService.performanceStream;

  /// 最后获取的系统信息
  PerformanceData? get lastSystemInfo => _lastData;

  /// 初始化服务
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    _isInitialized = await _performanceService.initialize();
    
    // 监听性能数据
    _performanceService.performanceStream.listen((data) {
      _lastData = data;
    });
    
    return _isInitialized;
  }

  /// 开始监控
  void startMonitoring({Duration interval = const Duration(milliseconds: 1000)}) {
    if (!_isInitialized) {
      debugPrint('系统监控服务未初始化');
      return;
    }
    
    _performanceService.startMonitoring(interval: interval);
    debugPrint('系统监控已启动');
  }

  /// 停止监控
  void stopMonitoring() {
    _performanceService.stopMonitoring();
  }

  /// 计算动画速度
  double calculateAnimationSpeed(SpeedSource source) {
    final data = _lastData;
    if (data == null) return 1.0;

    double usage = switch (source) {
      SpeedSource.cpu => data.cpuUsage,
      SpeedSource.memory => data.memoryUsage,
      SpeedSource.gpu => data.gpuUsage ?? 0.0,
    };

    // 将使用率映射到动画速度 (0.5x - 3.0x)
    return 0.5 + (usage / 100.0) * 2.5;
  }

  /// 销毁服务
  void dispose() {
    _performanceService.dispose();
    _isInitialized = false;
  }
}