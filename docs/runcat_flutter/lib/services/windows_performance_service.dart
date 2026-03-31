import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';
import 'package:flutter/foundation.dart';

/// 系统性能数据
class PerformanceData {
  final double cpuUsage;
  final double memoryUsage;
  final double memoryUsedGB;
  final double memoryTotalGB;
  final double? gpuUsage;
  final DateTime timestamp;

  const PerformanceData({
    required this.cpuUsage,
    required this.memoryUsage,
    required this.memoryUsedGB,
    required this.memoryTotalGB,
    this.gpuUsage,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'PerformanceData(cpu: ${cpuUsage.toStringAsFixed(1)}%, '
           'memory: ${memoryUsage.toStringAsFixed(1)}% (${memoryUsedGB.toStringAsFixed(1)}/${memoryTotalGB.toStringAsFixed(1)} GB), '
           'gpu: ${gpuUsage?.toStringAsFixed(1) ?? 'N/A'}%)';
  }
}

/// Windows 性能监控服务
class WindowsPerformanceService {
  static final WindowsPerformanceService _instance = WindowsPerformanceService._internal();
  factory WindowsPerformanceService() => _instance;
  WindowsPerformanceService._internal();

  Timer? _timer;
  final StreamController<PerformanceData> _controller = StreamController<PerformanceData>.broadcast();
  
  // CPU 监控相关
  Pointer<Uint32>? _cpuQuery;
  Pointer<Uint32>? _cpuCounter;
  bool _cpuInitialized = false;
  
  // 上次 CPU 采样数据
  int _lastCpuIdleTime = 0;
  int _lastCpuKernelTime = 0;
  int _lastCpuUserTime = 0;
  DateTime _lastCpuSampleTime = DateTime.now();

  /// 性能数据流
  Stream<PerformanceData> get performanceStream => _controller.stream;

  /// 初始化服务
  Future<bool> initialize() async {
    try {
      // 初始化 CPU 监控
      await _initializeCpuMonitoring();
      
      debugPrint('Windows 性能监控服务初始化成功');
      return true;
    } catch (e) {
      debugPrint('Windows 性能监控服务初始化失败: $e');
      return false;
    }
  }

  /// 初始化 CPU 监控
  Future<void> _initializeCpuMonitoring() async {
    try {
      // 使用 GetSystemTimes API 获取 CPU 时间
      _cpuInitialized = true;
      
      // 获取初始采样
      await _sampleCpuTimes();
      
      debugPrint('CPU 监控初始化成功');
    } catch (e) {
      debugPrint('CPU 监控初始化失败: $e');
      _cpuInitialized = false;
    }
  }

  /// 采样 CPU 时间
  Future<void> _sampleCpuTimes() async {
    final idleTime = calloc<Uint64>();
    final kernelTime = calloc<Uint64>();
    final userTime = calloc<Uint64>();

    try {
      final result = GetSystemTimes(
        idleTime.cast(),
        kernelTime.cast(),
        userTime.cast(),
      );

      if (result != 0) {
        _lastCpuIdleTime = idleTime.value;
        _lastCpuKernelTime = kernelTime.value;
        _lastCpuUserTime = userTime.value;
        _lastCpuSampleTime = DateTime.now();
      }
    } finally {
      calloc.free(idleTime);
      calloc.free(kernelTime);
      calloc.free(userTime);
    }
  }

  /// 计算 CPU 使用率
  Future<double> _getCpuUsage() async {
    if (!_cpuInitialized) {
      return 0.0;
    }

    final idleTime = calloc<Uint64>();
    final kernelTime = calloc<Uint64>();
    final userTime = calloc<Uint64>();

    try {
      final result = GetSystemTimes(
        idleTime.cast(),
        kernelTime.cast(),
        userTime.cast(),
      );

      if (result == 0) {
        return 0.0;
      }

      final currentIdleTime = idleTime.value;
      final currentKernelTime = kernelTime.value;
      final currentUserTime = userTime.value;
      final currentTime = DateTime.now();

      // 计算时间差（转换为100纳秒单位）
      final idleDiff = currentIdleTime - _lastCpuIdleTime;
      final kernelDiff = currentKernelTime - _lastCpuKernelTime;
      final userDiff = currentUserTime - _lastCpuUserTime;
      
      // 总系统时间 = 内核时间 + 用户时间
      // 注意：内核时间包含了空闲时间，所以需要减去
      final totalTime = kernelDiff + userDiff;
      final busyTime = totalTime - idleDiff;

      // 更新上次采样
      _lastCpuIdleTime = currentIdleTime;
      _lastCpuKernelTime = currentKernelTime;
      _lastCpuUserTime = currentUserTime;
      _lastCpuSampleTime = currentTime;

      if (totalTime <= 0) {
        return 0.0;
      }

      // 计算使用率
      final usage = (busyTime / totalTime) * 100.0;
      return usage.clamp(0.0, 100.0);
    } finally {
      calloc.free(idleTime);
      calloc.free(kernelTime);
      calloc.free(userTime);
    }
  }

  /// 获取内存使用情况
  PerformanceData _getMemoryUsage() {
    final memoryStatus = calloc<MEMORYSTATUSEX>();
    memoryStatus.ref.dwLength = sizeOf<MEMORYSTATUSEX>();

    try {
      final result = GlobalMemoryStatusEx(memoryStatus);

      if (result == 0) {
        return PerformanceData(
          cpuUsage: 0.0,
          memoryUsage: 0.0,
          memoryUsedGB: 0.0,
          memoryTotalGB: 0.0,
          timestamp: DateTime.now(),
        );
      }

      final totalPhys = memoryStatus.ref.ullTotalPhys;
      final availPhys = memoryStatus.ref.ullAvailPhys;
      final usedPhys = totalPhys - availPhys;

      // 转换为 GB
      final totalGB = totalPhys / (1024 * 1024 * 1024);
      final usedGB = usedPhys / (1024 * 1024 * 1024);
      final usagePercent = (usedPhys / totalPhys) * 100.0;

      return PerformanceData(
        cpuUsage: 0.0, // 稍后更新
        memoryUsage: usagePercent.clamp(0.0, 100.0),
        memoryUsedGB: usedGB,
        memoryTotalGB: totalGB,
        timestamp: DateTime.now(),
      );
    } finally {
      calloc.free(memoryStatus);
    }
  }

  /// 获取 GPU 使用率（简化实现）
  Future<double?> _getGpuUsage() async {
    // TODO: 实现 GPU 监控
    // 需要使用 DXGI 或 NVIDIA/AMD 特定的 API
    // 暂时返回 null
    return null;
  }

  /// 开始监控
  void startMonitoring({Duration interval = const Duration(milliseconds: 1000)}) {
    stopMonitoring();

    _timer = Timer.periodic(interval, (_) async {
      try {
        // 获取 CPU 使用率
        final cpuUsage = await _getCpuUsage();
        
        // 获取内存使用情况
        final memoryData = _getMemoryUsage();
        
        // 获取 GPU 使用率
        final gpuUsage = await _getGpuUsage();

        // 组合数据
        final performanceData = PerformanceData(
          cpuUsage: cpuUsage,
          memoryUsage: memoryData.memoryUsage,
          memoryUsedGB: memoryData.memoryUsedGB,
          memoryTotalGB: memoryData.memoryTotalGB,
          gpuUsage: gpuUsage,
          timestamp: DateTime.now(),
        );

        _controller.add(performanceData);
      } catch (e) {
        debugPrint('性能监控采样失败: $e');
      }
    });

    debugPrint('Windows 性能监控已启动');
  }

  /// 停止监控
  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    debugPrint('Windows 性能监控已停止');
  }

  /// 释放资源
  void dispose() {
    stopMonitoring();
    _controller.close();
    
    // 清理 CPU 监控资源
    if (_cpuQuery != null) {
      calloc.free(_cpuQuery!);
      _cpuQuery = null;
    }
    if (_cpuCounter != null) {
      calloc.free(_cpuCounter!);
      _cpuCounter = null;
    }
  }
}