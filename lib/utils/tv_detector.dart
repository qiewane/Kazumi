import 'dart:io';
import 'package:flutter/services.dart';

/// TV 设备检测器
class TVDetector {
  static final TVDetector _instance = TVDetector._internal();
  factory TVDetector() => _instance;
  TVDetector._internal();

  static const MethodChannel _channel = MethodChannel('com.predidit.kazumi/tv');
  
  bool? _isTV;
  String? _deviceType;

  /// 是否为 TV 设备
  Future<bool> get isTV async {
    if (_isTV != null) return _isTV!;
    if (!Platform.isAndroid) {
      _isTV = false;
      return false;
    }
    try {
      _isTV = await _channel.invokeMethod('isTVDevice') ?? false;
    } catch (e) {
      _isTV = false;
    }
    return _isTV!;
  }

  /// 获取设备类型: tv, tablet, phone
  Future<String> get deviceType async {
    if (_deviceType != null) return _deviceType!;
    if (!Platform.isAndroid) return 'phone';
    try {
      _deviceType = await _channel.invokeMethod('getDeviceType') ?? 'phone';
    } catch (e) {
      _deviceType = 'phone';
    }
    return _deviceType!;
  }

  /// 屏幕尺寸判断 (备用方案)
  bool get isLikelyTV {
    // 基于屏幕物理尺寸启发式判断
    // 实际项目中可通过 MediaQuery 获取
    return false;
  }
}
