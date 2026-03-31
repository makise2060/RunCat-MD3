import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';

class SystemInfo {
  final double cpuUsage;
  final double memoryUsage;
  final double gpuUsage;
  final DateTime timestamp;

  const SystemInfo({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.gpuUsage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'SystemInfo(cpu: ${cpuUsage.toStringAsFixed(1)}%, '
           'memory: ${memoryUsage.toStringAsFixed(1)}%, '
           'gpu: ${gpuUsage.toStringAsFixed(1)}%)';
  }
}

enum SpeedSource { cpu, memory, gpu }

class SystemMonitorService {
  static final SystemMonitorService _instance = SystemMonitorService._internal();
  factory SystemMonitorService() => _instance;
  SystemMonitorService._internal();

  Timer? _timer;
  final StreamController<SystemInfo> _controller = StreamController<SystemInfo>.broadcast();
  SystemInfo? _lastInfo;

  /// 系统信息流
  Stream<SystemInfo> get systemInfoStream => _controller.stream;

  /// 最后获取的系统信息
  SystemInfo? get lastSystemInfo => _lastInfo;

  /// 开始监控
  void startMonitoring({Duration interval = const Duration(milliseconds: 500)}) {
    stopMonitoring();
    
    _timer = Timer.periodic(interval, (_) async {
      final info = await _getSystemInfo();
      if (info != null) {
        _lastInfo = info;
        _controller.add(info);
      }
    });
  }

  /// 停止监控
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
  }

  /// 获取系统信息
  Future<SystemInfo?> _getSystemInfo() async {
    try {
      final cpuUsage = await _getCpuUsage();
      final memoryUsage = _getMemoryUsage();
      final gpuUsage = await _getGpuUsage();

      return SystemInfo(
        cpuUsage: cpuUsage,
        memoryUsage: memoryUsage,
        gpuUsage: gpuUsage,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('获取系统信息失败: $e');
      return null;
    }
  }

  /// 获取CPU使用率
  Future<double> _getCpuUsage() async {
    try {
      return await _queryPerformanceCounter('Processor', '% Processor Time', '_Total');
    } catch (e) {
      debugPrint('获取CPU使用率失败: $e');
      return 0.0;
    }
  }

  /// 获取内存使用率
  double _getMemoryUsage() {
    try {
      final memoryStatus = calloc<MEMORYSTATUSEX>();
      memoryStatus.ref.dwLength = sizeOf<MEMORYSTATUSEX>();
      
      if (GlobalMemoryStatusEx(memoryStatus) != 0) {
        final totalMemory = memoryStatus.ref.ullTotalPhys;
        final availableMemory = memoryStatus.ref.ullAvailPhys;
        final usedMemory = totalMemory - availableMemory;
        
        final usagePercent = (usedMemory / totalMemory) * 100.0;
        calloc.free(memoryStatus);
        return usagePercent.clamp(0.0, 100.0);
      }
      
      calloc.free(memoryStatus);
      return 0.0;
    } catch (e) {
      debugPrint('获取内存使用率失败: $e');
      return 0.0;
    }
  }

  /// 获取GPU使用率（简化版本）
  Future<double> _getGpuUsage() async {
    // TODO: 实现更精确的GPU使用率获取
    // 这里暂时返回一个随机值作为占位符
    return 10.0 + (DateTime.now().millisecondsSinceEpoch % 50);
  }

  /// 查询性能计数器
  Future<double> _queryPerformanceCounter(
    String category,
    String counter,
    String instance,
  ) async {
    // TODO: 实现Windows性能计数器查询
    // 这里暂时返回一个模拟值
    return 20.0 + (DateTime.now().millisecondsSinceEpoch % 60);
  }

  /// 计算动画速度
  double calculateAnimationSpeed(SpeedSource source) {
    final info = _lastInfo;
    if (info == null) return 1.0;

    double usage = switch (source) {
      SpeedSource.cpu => info.cpuUsage,
      SpeedSource.memory => info.memoryUsage,
      SpeedSource.gpu => info.gpuUsage,
    };

    // 将使用率映射到动画速度 (0.5x - 3.0x)
    return 0.5 + (usage / 100.0) * 2.5;
  }

  /// 销毁服务
  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}