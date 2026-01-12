import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// Utility class for device-specific information and checks
class DeviceUtils {
  static bool _isSimulator = false;
  static bool _initialized = false;

  /// Returns true if the app is running on a simulator/emulator
  static bool get isSimulator {
    if (!_initialized && !kIsWeb) {
      // If accessed before initialization, we can't be 100% sure without async
      // But we should have initialized it in app startup
    }
    return _isSimulator;
  }

  /// Initialize device information
  static Future<void> initialize() async {
    if (_initialized) return;
    
    if (kIsWeb) {
      _isSimulator = false;
    } else {
      try {
        final deviceInfo = DeviceInfoPlugin();
        if (Platform.isIOS) {
          final iosInfo = await deviceInfo.iosInfo;
          _isSimulator = !iosInfo.isPhysicalDevice;
        } else if (Platform.isAndroid) {
          final androidInfo = await deviceInfo.androidInfo;
          _isSimulator = !androidInfo.isPhysicalDevice;
        }
      } catch (e) {
        // Fallback to false if check fails
        _isSimulator = false;
      }
    }
    
    _initialized = true;
  }
}
