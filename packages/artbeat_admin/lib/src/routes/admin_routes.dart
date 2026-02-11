import 'package:artbeat_admin/src/screens/moderation/admin_flagging_queue_screen.dart';
import 'package:flutter/material.dart';
import '../screens/admin_login_screen.dart';
import '../screens/modern_unified_admin_dashboard.dart';
import '../screens/admin_user_detail_screen.dart';
import '../screens/admin_audit_logs_screen.dart';
import '../screens/admin_settings_screen.dart';
import '../screens/admin_security_center_screen.dart';
import '../screens/admin_system_health_screen.dart';
import '../screens/admin_payment_screen.dart';
import '../screens/modern_unified_admin_upload_tools_screen.dart';
import '../screens/events_coming_soon_screen.dart';
import '../screens/moderation/event_moderation_dashboard_screen.dart';
import '../screens/moderation/admin_artwork_moderation_screen.dart';
import '../screens/moderation/admin_community_moderation_screen.dart';
import '../screens/moderation/admin_art_walk_moderation_screen.dart';
import '../screens/moderation/admin_content_moderation_screen.dart';
import '../screens/admin_platform_curation_screen.dart';
import '../models/user_admin_model.dart';
import 'package:easy_localization/easy_localization.dart';

/// Admin routing configuration for the ARTbeat admin system
///
/// Streamlined admin routes - consolidated from 15+ screens to 4 main sections:
/// 1. Unified Dashboard (replaces dashboard, analytics, enhanced dashboard)
/// 2. User Detail (modal/overlay for user details)
/// 3. Essential System Screens (settings, security, data, alerts, help)
/// 4. Migration (temporary utility)
class AdminRoutes {
  // Main unified dashboard - replaces all dashboard and analytics screens
  static const String dashboard = '/admin/dashboard';
  static const String enhancedDashboard =
      '/admin/dashboard'; // Redirect to unified
  static const String financialAnalytics =
      '/admin/dashboard'; // Redirect to unified
  static const String userManagement =
      '/admin/dashboard'; // Redirect to unified
  static const String advancedUserManagement =
      '/admin/dashboard'; // Redirect to unified
  static const String contentReview = '/admin/dashboard'; // Redirect to unified
  static const String enhancedContentReview =
      '/admin/dashboard'; // Redirect to unified
  static const String advancedContentManagement =
      '/admin/dashboard'; // Redirect to unified
  static const String contentManagementSuite =
      '/admin/dashboard'; // Redirect to unified
  static const String analytics = '/admin/dashboard'; // Redirect to unified
  static const String adManagement = '/admin/dashboard'; // Redirect to unified
  static const String adsManagement = '/admin/dashboard'; // Redirect to unified
  static const String eventsManagement =
      '/admin/dashboard'; // Redirect to unified
  static const String legacyCommunityModeration =
      '/admin/dashboard'; // Redirect to unified
  static const String communityModerationRedir =
      '/admin/dashboard'; // Redirect to unified
  static const String couponManagement =
      '/admin/dashboard'; // Redirect to unified

  // Moderation routes (Specific deep-dives)
  static const String eventModeration = '/admin/moderation/events';
  static const String artworkModeration = '/admin/moderation/artworks';
  static const String communityModeration = '/admin/moderation/community';
  static const String artWalkModeration = '/admin/moderation/art-walks';
  static const String contentModeration = '/admin/moderation/content';
  static const String flaggingQueue = '/admin/moderation/flagging-queue';
  static const String platformCuration = '/admin/curation';

  // User detail screen (modal/overlay)
  static const String userDetail = '/admin/user-detail';

  // Essential system screens (kept separate for specific functionality)
  static const String adminSettings = '/admin/settings';
  static const String securityCenter = '/admin/security';
  static const String systemMonitoring = '/admin/monitoring';
  static const String auditLogs = '/admin/audit-logs';
  static const String paymentManagement = '/admin/payments';
  static const String dataUpload = '/admin/upload-tools';
  static const String login = '/admin/login';

  /// Generate routes for the admin system
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case eventModeration:
      case '/admin/event-moderation-dashboard':
        return MaterialPageRoute<void>(
          builder: (_) => const EventModerationDashboardScreen(),
          settings: settings,
        );
      case artworkModeration:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminArtworkModerationScreen(),
          settings: settings,
        );
      case communityModeration:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminCommunityModerationScreen(),
          settings: settings,
        );
      case artWalkModeration:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminArtWalkModerationScreen(),
          settings: settings,
        );
      case contentModeration:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminContentModerationScreen(),
          settings: settings,
        );
      case flaggingQueue:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminFlaggingQueueScreen(),
          settings: settings,
        );
      case platformCuration:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminPlatformCurationScreen(),
          settings: settings,
        );
      case '/admin/events-coming-soon':
        return MaterialPageRoute<void>(
          builder: (_) => const EventsComingSoonScreen(),
          settings: settings,
        );
      // All main admin functionality now routes to the modern unified dashboard
      case dashboard:
        return MaterialPageRoute<void>(
          builder: (_) => const ModernUnifiedAdminDashboard(),
          settings: settings,
        );

      case userDetail:
        final user = settings.arguments as UserAdminModel?;
        if (user == null) {
          return _errorRoute('User data is required');
        }
        return MaterialPageRoute<void>(
          builder: (_) => AdminUserDetailScreen(user: user),
          settings: settings,
        );

      case adminSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminSettingsScreen(),
          settings: settings,
        );

      case securityCenter:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminSecurityCenterScreen(),
          settings: settings,
        );

      case systemMonitoring:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminSystemHealthScreen(),
          settings: settings,
        );
      case auditLogs:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminAuditLogsScreen(),
          settings: settings,
        );

      case paymentManagement:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminPaymentScreen(),
          settings: settings,
        );
      case dataUpload:
      case '/dev': // Redirect old dev routes to new upload tools
        return MaterialPageRoute<void>(
          builder: (_) => const ModernUnifiedAdminUploadToolsScreen(),
          settings: settings,
        );

      case login:
        return MaterialPageRoute<void>(
          builder: (_) => const AdminLoginScreen(),
          settings: settings,
        );

      default:
        // Return null for unrecognized admin routes so main app can handle them
        return null;
    }
  }

  /// Create an error route
  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(
          title: Text('admin_routes_error_title'.tr()),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'admin_routes_navigation_error'.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(_).pop(),
                child: Text('admin_routes_go_back'.tr()),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Get all available admin routes
  static List<AdminRoute> getAllRoutes() {
    return [
      const AdminRoute(
        name: 'Dashboard',
        route: dashboard,
        icon: Icons.dashboard,
        description: 'Main admin dashboard with overview metrics',
        category: AdminRouteCategory.overview,
      ),
      const AdminRoute(
        name: 'Enhanced Dashboard',
        route: enhancedDashboard,
        icon: Icons.dashboard_customize,
        description: 'Advanced dashboard with comprehensive analytics',
        category: AdminRouteCategory.overview,
      ),
      const AdminRoute(
        name: 'Financial Analytics',
        route: financialAnalytics,
        icon: Icons.attach_money,
        description: 'Revenue, subscriptions, and financial metrics',
        category: AdminRouteCategory.analytics,
      ),
      const AdminRoute(
        name: 'User Management',
        route: userManagement,
        icon: Icons.people,
        description: 'Basic user management and administration',
        category: AdminRouteCategory.users,
      ),
      const AdminRoute(
        name: 'Advanced User Management',
        route: advancedUserManagement,
        icon: Icons.manage_accounts,
        description: 'Advanced user segmentation and analytics',
        category: AdminRouteCategory.users,
      ),
      const AdminRoute(
        name: 'Content Review',
        route: contentReview,
        icon: Icons.rate_review,
        description: 'Basic content moderation and review',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Enhanced Content Review',
        route: enhancedContentReview,
        icon: Icons.admin_panel_settings,
        description:
            'Advanced content moderation with bulk operations and filtering',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Advanced Content Management',
        route: advancedContentManagement,
        icon: Icons.content_copy,
        description: 'AI-powered content management and analytics',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Analytics',
        route: analytics,
        icon: Icons.analytics,
        description: 'Comprehensive platform analytics',
        category: AdminRouteCategory.analytics,
      ),
      const AdminRoute(
        name: 'Settings',
        route: adminSettings,
        icon: Icons.settings,
        description: 'Admin system configuration and settings',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'Ad Management',
        route: adManagement,
        icon: Icons.campaign,
        description: 'Manage advertisements and sponsored content',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Security Center',
        route: securityCenter,
        icon: Icons.security,
        description: 'Security monitoring and threat detection',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'System Monitoring',
        route: systemMonitoring,
        icon: Icons.monitor,
        description: 'Real-time system monitoring and performance metrics',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'Audit Logs',
        route: auditLogs,
        icon: Icons.history_edu_rounded,
        description: 'Detailed log of all administrative actions',
        category: AdminRouteCategory.system,
      ),
      const AdminRoute(
        name: 'Event Moderation',
        route: eventModeration,
        icon: Icons.event_note_rounded,
        description: 'Review and manage community events',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Art Walk Moderation',
        route: artWalkModeration,
        icon: Icons.route_rounded,
        description: 'Moderate user-created art walks',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Content Moderation',
        route: contentModeration,
        icon: Icons.camera_rounded,
        description: 'Review artwork captures and content reports',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Flagging Queue',
        route: flaggingQueue,
        icon: Icons.report_problem_rounded,
        description: 'Triage user reports and flagged content',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Data Upload Tools',
        route: dataUpload,
        icon: Icons.upload_file_rounded,
        description: 'Administrative tools for bulk data uploads',
        category: AdminRouteCategory.system,
      ),
    ];
  }

  /// Get routes by category
  static List<AdminRoute> getRoutesByCategory(AdminRouteCategory category) {
    return getAllRoutes().where((route) => route.category == category).toList();
  }

  /// Get quick access routes (most commonly used)
  static List<AdminRoute> getQuickAccessRoutes() {
    return [
      const AdminRoute(
        name: 'Enhanced Dashboard',
        route: enhancedDashboard,
        icon: Icons.dashboard_customize,
        description: 'Advanced dashboard with comprehensive analytics',
        category: AdminRouteCategory.overview,
      ),
      const AdminRoute(
        name: 'Financial Analytics',
        route: financialAnalytics,
        icon: Icons.attach_money,
        description: 'Revenue, subscriptions, and financial metrics',
        category: AdminRouteCategory.analytics,
      ),
      const AdminRoute(
        name: 'Advanced User Management',
        route: advancedUserManagement,
        icon: Icons.manage_accounts,
        description: 'Advanced user segmentation and analytics',
        category: AdminRouteCategory.users,
      ),
      const AdminRoute(
        name: 'Advanced Content Management',
        route: advancedContentManagement,
        icon: Icons.content_copy,
        description: 'AI-powered content management and analytics',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Event Moderation',
        route: eventModeration,
        icon: Icons.event_note_rounded,
        description: 'Review and manage community events',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Artwork Moderation',
        route: artworkModeration,
        icon: Icons.brush_rounded,
        description: 'Moderate community-uploaded artworks',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Community Moderation',
        route: communityModeration,
        icon: Icons.forum_rounded,
        description: 'Moderate flagged posts and comments',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Art Walk Moderation',
        route: artWalkModeration,
        icon: Icons.route_rounded,
        description: 'Moderate user-created art walks',
        category: AdminRouteCategory.content,
      ),
      const AdminRoute(
        name: 'Content Moderation',
        route: contentModeration,
        icon: Icons.camera_rounded,
        description: 'Review artwork captures and content reports',
        category: AdminRouteCategory.content,
      ),
    ];
  }
}

/// Admin route model
class AdminRoute {
  final String name;
  final String route;
  final IconData icon;
  final String description;
  final AdminRouteCategory category;
  final bool requiresPermission;
  final List<String> permissions;

  const AdminRoute({
    required this.name,
    required this.route,
    required this.icon,
    required this.description,
    required this.category,
    this.requiresPermission = false,
    this.permissions = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'route': route,
      'description': description,
      'category': category.name,
      'requiresPermission': requiresPermission,
      'permissions': permissions,
    };
  }
}

/// Admin route categories
enum AdminRouteCategory {
  overview,
  users,
  content,
  analytics,
  financial,
  system,
}

/// Extension for admin route category display names
extension AdminRouteCategoryExtension on AdminRouteCategory {
  String get displayName {
    switch (this) {
      case AdminRouteCategory.overview:
        return 'Overview';
      case AdminRouteCategory.users:
        return 'User Management';
      case AdminRouteCategory.content:
        return 'Content Management';
      case AdminRouteCategory.analytics:
        return 'Analytics';
      case AdminRouteCategory.financial:
        return 'Financial';
      case AdminRouteCategory.system:
        return 'System';
    }
  }

  IconData get icon {
    switch (this) {
      case AdminRouteCategory.overview:
        return Icons.dashboard;
      case AdminRouteCategory.users:
        return Icons.people;
      case AdminRouteCategory.content:
        return Icons.content_copy;
      case AdminRouteCategory.analytics:
        return Icons.analytics;
      case AdminRouteCategory.financial:
        return Icons.attach_money;
      case AdminRouteCategory.system:
        return Icons.settings;
    }
  }
}

/// Admin navigation helper
class AdminNavigation {
  /// Navigate to a specific admin route
  static Future<void> navigateTo(
    BuildContext context,
    String route, {
    Object? arguments,
    bool replace = false,
  }) async {
    if (replace) {
      await Navigator.of(context)
          .pushReplacementNamed(route, arguments: arguments);
    } else {
      await Navigator.of(context).pushNamed(route, arguments: arguments);
    }
  }

  /// Navigate to user detail screen
  static Future<void> navigateToUserDetail(
    BuildContext context,
    UserAdminModel user,
  ) async {
    await Navigator.of(context).pushNamed(
      AdminRoutes.userDetail,
      arguments: user,
    );
  }

  /// Navigate back to dashboard
  static void navigateBackToDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AdminRoutes.enhancedDashboard,
      (route) => false,
    );
  }

  /// Check if current route is admin route
  static bool isAdminRoute(String? routeName) {
    if (routeName == null) return false;
    return routeName.startsWith('/admin/');
  }

  /// Get current admin route category
  static AdminRouteCategory? getCurrentCategory(String? routeName) {
    if (routeName == null) return null;

    final routes = AdminRoutes.getAllRoutes();
    final currentRoute = routes.firstWhere(
      (route) => route.route == routeName,
      orElse: () => routes.first,
    );

    return currentRoute.category;
  }
}
