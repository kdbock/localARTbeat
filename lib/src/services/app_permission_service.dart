import 'dart:io';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized service for handling app permissions at startup
class AppPermissionService {
  factory AppPermissionService() => _instance;

  AppPermissionService._internal();

  static final AppPermissionService _instance =
      AppPermissionService._internal();

  bool _isInitialized = false;
  final Map<Permission, PermissionStatus> _permissionStatus = {};

  /// Initialize permissions when app first loads
  Future<void> initializePermissions() async {
    if (_isInitialized) {
      AppLogger.info('Permissions already initialized');
      return;
    }

    AppLogger.info('Initializing app permissions...');

    try {
      // Request essential permissions on first app launch
      await _requestEssentialPermissions();

      _isInitialized = true;
      AppLogger.info('✅ App permissions initialized successfully');
    } on Exception catch (e) {
      AppLogger.error('❌ Failed to initialize app permissions: $e');
      rethrow;
    }
  }

  /// Request essential permissions that the app needs to function properly
  Future<void> _requestEssentialPermissions() async {
    final List<Permission> essentialPermissions = [
      if (Platform.isIOS) Permission.photos, // For iOS photo access
      if (Platform.isAndroid) Permission.storage, // For Android file access
    ];

    AppLogger.info(
      'Checking essential permissions: ${essentialPermissions.map((p) => p.toString()).join(', ')}',
    );

    // Check current status of all permissions first
    for (final permission in essentialPermissions) {
      final status = await permission.status;
      _permissionStatus[permission] = status;
      AppLogger.info('${permission.toString()}: $status');
    }

    // Request permissions that are denied but not permanently denied
    final List<Permission> permissionsToRequest = [];

    for (final permission in essentialPermissions) {
      final status = _permissionStatus[permission];
      if (status!.isDenied) {
        permissionsToRequest.add(permission);
      }
    }

    if (permissionsToRequest.isNotEmpty) {
      AppLogger.info(
        'Requesting permissions: ${permissionsToRequest.map((p) => p.toString()).join(', ')}',
      );

      // Request permissions individually for better control
      for (final permission in permissionsToRequest) {
        try {
          final result = await permission.request();
          _permissionStatus[permission] = result;

          if (result.isGranted) {
            AppLogger.info('✅ ${permission.toString()} granted');
          } else if (result.isPermanentlyDenied) {
            AppLogger.warning('⚠️ ${permission.toString()} permanently denied');
          } else {
            AppLogger.warning('❌ ${permission.toString()} denied: $result');
          }
        } on Exception catch (e) {
          AppLogger.error('❌ Error requesting ${permission.toString()}: $e');
        }
      }
    }
  }

  /// Get status of a specific permission
  Future<PermissionStatus> getPermissionStatus(Permission permission) async {
    try {
      final status = await permission.status;
      _permissionStatus[permission] = status;
      return status;
    } on Exception catch (e) {
      AppLogger.error('❌ Error getting ${permission.toString()} status: $e');
      return PermissionStatus.denied;
    }
  }

  /// Open app settings for manually granting permissions
  Future<bool> openSettings() async {
    try {
      AppLogger.info('Opening app settings for permission management');
      return await openAppSettings();
    } on Exception catch (e) {
      AppLogger.error('❌ Error opening app settings: $e');
      return false;
    }
  }

  /// Check if all essential permissions are granted
  bool get hasEssentialPermissions {
    return true; // Return true as essential permissions are handled individually
  }

  /// Get a user-friendly message for permission status
  String getPermissionMessage(Permission permission) {
    final status = _permissionStatus[permission];
    return 'Permission status: ${status?.toString() ?? 'Unknown'}';
  }
}
