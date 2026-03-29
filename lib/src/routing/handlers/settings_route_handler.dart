import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:artbeat_settings/artbeat_settings.dart' as settings_pkg;
import 'package:flutter/material.dart';

import '../../guards/auth_guard.dart';
import '../route_utils.dart';

class SettingsRouteHandler {
  const SettingsRouteHandler({required core_auth.AuthService authService})
    : _authService = authService;

  final core_auth.AuthService _authService;

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.settings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Settings', showDeveloperTools: true),
          child: const settings_pkg.SettingsScreen(),
        );

      case core.AppRoutes.settingsAccount:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Account Settings'),
          child: const settings_pkg.AccountSettingsScreen(
            useOwnScaffold: false,
          ),
        );

      case core.AppRoutes.settingsNotifications:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Notification Settings'),
          child: const settings_pkg.NotificationSettingsScreen(),
        );

      case core.AppRoutes.settingsPrivacy:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Privacy Settings'),
          child: const settings_pkg.PrivacySettingsScreen(),
        );

      case core.AppRoutes.securitySettings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Security Settings'),
          child: const settings_pkg.SecuritySettingsScreen(
            useOwnScaffold: false,
          ),
        );

      case core.AppRoutes.settingsLanguage:
        return RouteUtils.createSimpleRoute(
          child: const settings_pkg.LanguageSettingsScreen(),
        );

      case core.AppRoutes.settingsTheme:
        return RouteUtils.createSimpleRoute(
          child: const settings_pkg.ThemeSettingsScreen(),
        );

      case core.AppRoutes.paymentSettings:
        return RouteUtils.createMainLayoutRoute(
          appBar: RouteUtils.createAppBar('Payment Settings'),
          child: const artist.PaymentMethodsScreen(),
        );

      case '/settings/become-artist':
        return AuthGuard.guardRoute(
          settings: settings,
          authenticatedBuilder: () {
            final currentUser = _authService.currentUser;
            if (currentUser == null) {
              return const core.MainLayout(
                currentIndex: -1,
                child: core.AuthRequiredScreen(),
              );
            }

            final user = RouteUtils.createUserModelFromFirebase(currentUser);
            return core.MainLayout(
              currentIndex: -1,
              child: settings_pkg.BecomeArtistScreen(user: user),
            );
          },
          unauthenticatedBuilder: () => const core.MainLayout(
            currentIndex: -1,
            child: core.AuthRequiredScreen(),
          ),
        );

      default:
        if (settings.name == '/settings/blocked-users') {
          return RouteUtils.createMainLayoutRoute(
            appBar: RouteUtils.createAppBar('Blocked Users'),
            child: const settings_pkg.BlockedUsersScreen(useOwnScaffold: false),
          );
        }

        final feature = settings.name!.split('/').last;
        return RouteUtils.createComingSoonRoute(
          '${feature[0].toUpperCase()}${feature.substring(1)} Settings',
        );
    }
  }
}
