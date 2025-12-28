import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Helper class to handle Google Maps errors, especially in emulators
class GoogleMapsErrorHandler {
  /// Check if running on an emulator
  static Future<bool> isEmulator() async {
    try {
      if (Platform.isAndroid) {
        final deviceInfo = DeviceInfoPlugin();
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.isPhysicalDevice == false ||
            androidInfo.model.contains('sdk') ||
            androidInfo.model.contains('emulator');
      } else if (Platform.isIOS) {
        final deviceInfo = DeviceInfoPlugin();
        final iosInfo = await deviceInfo.iosInfo;
        return !iosInfo.isPhysicalDevice;
      }
      return false;
    } catch (e) {
      AppLogger.error('⚠️ Error checking if device is emulator: $e');
      return false;
    }
  }

  /// Optimized map style for emulators (reduced POI and transit visibility)
  static const String _emulatorMapStyle = '''
  [
    {
      "featureType": "poi",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "transit",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "road",
      "elementType": "labels",
      "stylers": [{"visibility": "simplified"}]
    }
  ]
  ''';

  /// Get map style for emulator optimization
  /// Use this with GoogleMap.style parameter for better performance
  static String getEmulatorMapStyle() {
    return _emulatorMapStyle;
  }

  /// Apply emulator camera optimizations to Google Map
  static Future<void> optimizeMapCameraForEmulator(
    GoogleMapController controller,
  ) async {
    try {
      // Set a lower zoom level for better emulator performance
      await controller.moveCamera(CameraUpdate.zoomTo(10));

      AppLogger.info('✅ Applied emulator camera optimizations to map');
    } catch (e) {
      AppLogger.error('❌ Failed to optimize map camera for emulator: $e');
    }
  }

  /// Handle map loading timeout
  static Future<void> handleMapTimeout(
    BuildContext context, {
    VoidCallback? onRetry,
  }) async {
    final isRunningOnEmulator = await isEmulator();

    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isRunningOnEmulator
              ? 'Map tile loading timeout. Emulator performance may be limited.'
              : 'Map loading timed out. Check your internet connection.',
        ),
        duration: const Duration(seconds: 5),
        action: onRetry == null
            ? null
            : SnackBarAction(
                label: 'Retry',
                onPressed: onRetry,
              ),
      ),
    );
  }

  /// Get optimized map options for emulators
  static GoogleMapOptions getOptimizedMapOptions() {
    return GoogleMapOptions(
      compassEnabled: false,
      mapToolbarEnabled: false,
      tiltGesturesEnabled: false,
      zoomControlsEnabled: false,
    );
  }
}

/// Container for GoogleMap options
class GoogleMapOptions {
  final bool compassEnabled;
  final bool mapToolbarEnabled;
  final bool tiltGesturesEnabled;
  final bool zoomControlsEnabled;

  GoogleMapOptions({
    this.compassEnabled = true,
    this.mapToolbarEnabled = true,
    this.tiltGesturesEnabled = true,
    this.zoomControlsEnabled = true,
  });
}
