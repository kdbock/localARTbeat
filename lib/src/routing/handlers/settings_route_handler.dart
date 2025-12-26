import 'package:artbeat_settings/artbeat_settings.dart';
import 'package:flutter/material.dart';

import 'package:artbeat_core/src/routing/app_routes.dart';

class SettingsRouteHandler {
  static Widget handleSettingsRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case AppRoutes.accountSettings:
        return const AccountSettingsScreen();
      case AppRoutes.notificationSettings:
        return const NotificationSettingsScreen();
      case AppRoutes.privacySettings:
        return const PrivacySettingsScreen();
      case AppRoutes.securitySettings:
        return const SecuritySettingsScreen();
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}
