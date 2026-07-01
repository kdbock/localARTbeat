import 'package:artbeat_auth/artbeat_auth.dart' as auth;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:artbeat_profile/artbeat_profile.dart' as profile;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class AuthProfileRouteHandler {
  const AuthProfileRouteHandler({
    required core_auth.AuthService authService,
  }) : _authService = authService;

  final core_auth.AuthService _authService;

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.login:
        return RouteUtils.createSimpleRoute(child: const auth.LoginScreen());

      case core.AppRoutes.register:
        return RouteUtils.createSimpleRoute(child: const auth.RegisterScreen());

      case core.AppRoutes.forgotPassword:
        return RouteUtils.createSimpleRoute(
          child: const auth.ForgotPasswordScreen(),
        );

      case core.AppRoutes.profileEdit:
        final currentUserId = _authService.currentUser?.uid ?? '';
        return RouteUtils.createMainNavRoute(
          child: profile.EditProfileScreen(userId: currentUserId),
        );

      default:
        return null;
    }
  }
}
