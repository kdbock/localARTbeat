import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'logger.dart';

/// Utility class for handling permissions consistently across the app
class PermissionUtils {
  static const String _locationSafetyDisclosureKey =
      'location_safety_disclosure_ack_v1';

  /// Show a one-time safety notice before first location permission request.
  static Future<bool> showLocationSafetyDisclosureIfNeeded(
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadyAcknowledged =
          prefs.getBool(_locationSafetyDisclosureKey) ?? false;
      if (alreadyAcknowledged) return true;

      if (!context.mounted) return false;
      final acknowledged = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          title: Text('permission_location_safety_notice_title'.tr()),
          content: Text(
            'permission_location_safety_notice_body'.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('permission_not_now'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('permission_i_understand'.tr()),
            ),
          ],
        ),
      );

      if (acknowledged == true) {
        await prefs.setBool(_locationSafetyDisclosureKey, true);
        return true;
      }
      return false;
    } catch (e) {
      AppLogger.error('Error showing location safety disclosure: $e');
      return false;
    }
  }

  /// Safety-first location permission flow: disclosure then OS permission.
  static Future<bool> requestLocationPermissionWithSafety(
    BuildContext context,
  ) async {
    final canProceed = await showLocationSafetyDisclosureIfNeeded(context);
    if (!canProceed) return false;
    if (!context.mounted) return false;
    return requestLocationPermission(context);
  }

  /// Request photo library permission with proper error handling
  static Future<bool> requestPhotoPermission(BuildContext context) async {
    try {
      // Check current permission status
      PermissionStatus status = await Permission.photos.status;

      // If permission is denied, request it
      if (status.isDenied) {
        status = await Permission.photos.request();
      }

      // Handle permanently denied permission
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('permission_required_title'.tr()),
              content: Text(
                'permission_photo_permanently_denied'.tr(),
              ),
              actions: [
                TextButton(
                  child: Text('common_cancel'.tr()),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: Text('permission_open_settings'.tr()),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }

      // Check if permission is granted (including limited access on iOS)
      if (status.isGranted || status.isLimited) {
        return true;
      }

      // Permission denied
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('permission_photo_required'.tr()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      AppLogger.error('Error requesting photo permission: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'permission_request_failed'.tr(namedArgs: {'error': '$e'}),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Request camera permission with proper error handling
  static Future<bool> requestCameraPermission(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.camera.status;

      if (status.isDenied) {
        status = await Permission.camera.request();
      }

      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
              title: Text('permission_required_title'.tr()),
              content: Text(
                'permission_camera_permanently_denied'.tr(),
              ),
              actions: [
                TextButton(
                  child: Text('common_cancel'.tr()),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: Text('permission_open_settings'.tr()),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
          }
        }
        return false;
      }

      if (status.isGranted) {
        return true;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('permission_camera_required'.tr()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      AppLogger.error('Error requesting camera permission: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'permission_request_failed'.tr(namedArgs: {'error': '$e'}),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Request location permission with proper error handling
  static Future<bool> requestLocationPermission(BuildContext context) async {
    try {
      // Use geolocator for more reliable system-level status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        return true;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          return true;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (context.mounted) {
          final shouldOpenSettings = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) => AlertDialog(
              title: Text('permission_required_title'.tr()),
              content: Text(
                'permission_location_permanently_denied'.tr(),
              ),
              actions: [
                TextButton(
                  child: Text('common_cancel'.tr()),
                  onPressed: () => Navigator.pop(context, false),
                ),
                TextButton(
                  child: Text('permission_open_settings'.tr()),
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            ),
          );

          if (shouldOpenSettings == true) {
            await openAppSettings();
            return false;
          }
        }
        return false;
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('permission_location_required'.tr()),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    } catch (e) {
      AppLogger.error('Error requesting location permission: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'permission_request_failed'.tr(namedArgs: {'error': '$e'}),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  /// Check if photo permission is granted without requesting
  static Future<bool> hasPhotoPermission() async {
    final status = await Permission.photos.status;
    return status.isGranted || status.isLimited;
  }

  /// Check if camera permission is granted without requesting
  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Check if location permission is granted without requesting
  static Future<bool> hasLocationPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
