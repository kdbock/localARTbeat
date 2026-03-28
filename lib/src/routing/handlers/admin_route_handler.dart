import 'package:artbeat_admin/artbeat_admin.dart' as admin;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class AdminRouteHandler {
  const AdminRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    final adminRoute = admin.AdminRoutes.generateRoute(settings);
    if (adminRoute != null) {
      return adminRoute;
    }

    switch (settings.name) {
      case core.AppRoutes.adminCoupons:
        return RouteUtils.createMainLayoutRoute(
          child: const core.CouponManagementScreen(),
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
        return RouteUtils.createSimpleRoute(
          child: const admin.ModernUnifiedAdminDashboard(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Admin feature');
    }
  }
}
