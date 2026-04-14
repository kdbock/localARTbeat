import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../route_utils.dart';

typedef AdminAccessChecker = Future<bool> Function();

class AdminRouteHandler {
  const AdminRouteHandler({AdminAccessChecker? adminAccessChecker})
    : _adminAccessChecker = adminAccessChecker ?? _defaultAdminAccessChecker;

  final AdminAccessChecker _adminAccessChecker;

  Route<dynamic>? handleRoute(RouteSettings settings) {
    final adminRoute = admin.AdminRoutes.generateRoute(settings);
    if (adminRoute != null) {
      return _createGuardedRoute(
        settings: settings,
        childBuilder: (context) =>
            _buildResolvedRouteWidget(adminRoute, context),
      );
    }

    switch (settings.name) {
      case core.AppRoutes.adminCoupons:
        return _createGuardedRoute(
          settings: settings,
          childBuilder: (_) => const core.CouponManagementScreen(),
        );

      case core.AppRoutes.adminCouponManagement:
      case core.AppRoutes.adminUsers:
      case core.AppRoutes.adminModeration:
      case core.AppRoutes.artworkModeration:
      case core.AppRoutes.adminAdManagement:
      case core.AppRoutes.adminAdReview:
      case core.AppRoutes.adminAdTest:
      case core.AppRoutes.adminMessaging:
      case '/admin/artwork':
      case '/admin/enhanced-dashboard':
      case '/admin/financial-analytics':
      case '/admin/content-management-suite':
      case '/admin/advanced-content-management':
      case '/admin/moderation/events':
      case '/admin/moderation/art-walks':
      case '/admin/moderation/content':
      case '/admin/moderation/artworks':
      case '/admin/moderation/community':
      case '/admin/upload-tools':
        return _createGuardedRoute(
          settings: settings,
          childBuilder: (_) => const admin.ModernUnifiedAdminDashboard(),
        );

      default:
        return _createGuardedRoute(
          settings: settings,
          childBuilder: (context) => RouteUtils.createComingSoonRoute(
            'Admin feature',
          ).builder(context),
        );
    }
  }

  Route<dynamic> _createGuardedRoute({
    required RouteSettings settings,
    required WidgetBuilder childBuilder,
  }) => MaterialPageRoute(
    builder: (context) => _AdminRouteAccessGate(
      adminAccessChecker: _adminAccessChecker,
      childBuilder: childBuilder,
    ),
    settings: settings,
  );

  static Widget _buildResolvedRouteWidget(
    Route<dynamic> resolvedRoute,
    BuildContext context,
  ) {
    if (resolvedRoute is MaterialPageRoute<dynamic>) {
      return resolvedRoute.builder(context);
    }
    if (resolvedRoute is PageRouteBuilder<dynamic>) {
      return resolvedRoute.pageBuilder(
        context,
        const AlwaysStoppedAnimation<double>(1),
        const AlwaysStoppedAnimation<double>(1),
      );
    }
    return const admin.ModernUnifiedAdminDashboard();
  }

  static Future<bool> _defaultAdminAccessChecker() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    if (!userDoc.exists) return false;

    final data = userDoc.data() ?? <String, dynamic>{};
    final userType = (data['userType'] as String? ?? '').trim().toLowerCase();
    return userType == 'admin';
  }
}

class _AdminRouteAccessGate extends StatelessWidget {
  const _AdminRouteAccessGate({
    required this.adminAccessChecker,
    required this.childBuilder,
  });

  final AdminAccessChecker adminAccessChecker;
  final WidgetBuilder childBuilder;

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: adminAccessChecker(),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      if (snapshot.data ?? false) {
        return childBuilder(context);
      }

      return const _AdminAccessDeniedScreen();
    },
  );
}

class _AdminAccessDeniedScreen extends StatelessWidget {
  const _AdminAccessDeniedScreen();

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: Text('Admin access required')));
}
