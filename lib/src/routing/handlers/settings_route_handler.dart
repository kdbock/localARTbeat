import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_settings/artbeat_settings.dart';
import 'package:flutter/material.dart';

class SettingsRouteHandler {
  static Widget handleSettingsRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case core.AppRoutes.accountSettings:
        return const AccountSettingsScreen();
      case core.AppRoutes.notificationSettings:
        return const NotificationSettingsScreen();
      case core.AppRoutes.privacySettings:
        return const PrivacySettingsScreen();
      case core.AppRoutes.securitySettings:
        return const SecuritySettingsScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}
