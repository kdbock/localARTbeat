import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';

/// Enhanced navigation service with error handling and analytics
class NavigationService {
  factory NavigationService() => _instance;
  NavigationService._internal();
  static final NavigationService _instance = NavigationService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final DefensibilityTelemetryService _defensibilityTelemetry =
      DefensibilityTelemetryService();

  /// Safe navigation with error handling and analytics
  Future<bool> navigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) async {
    try {
      // Log navigation event
      await _analytics.logEvent(
        name: 'navigation_attempt',
        parameters: {
          'route_name': routeName,
          'has_arguments': arguments != null ? 1 : 0,
          'replace': replace ? 1 : 0,
          'clear_stack': clearStack ? 1 : 0,
        },
      );

      // Perform navigation
      if (clearStack) {
        // ignore: use_build_context_synchronously
        await Navigator.of(context).pushNamedAndRemoveUntil(
          routeName,
          (route) => false,
          arguments: arguments,
        );
      } else if (replace) {
        await Navigator.of(
          // ignore: use_build_context_synchronously
          context,
        ).pushReplacementNamed(routeName, arguments: arguments);
      } else {
        // ignore: use_build_context_synchronously
        await Navigator.of(context).pushNamed(routeName, arguments: arguments);
      }

      // Log successful navigation
      await _analytics.logEvent(
        name: 'navigation_success',
        parameters: {'route_name': routeName},
      );

      await _trackDefensibilityRouteSignals(routeName);

      return true;
    } on Exception catch (error, stackTrace) {
      // Log navigation error
      await _analytics.logEvent(
        name: 'navigation_error',
        parameters: {'route_name': routeName, 'error': error.toString()},
      );

      // Show error to user
      // ignore: use_build_context_synchronously
      _showNavigationError(context, routeName, error);

      // Log to console for debugging
      AppLogger.error('Navigation error to $routeName: $error');
      AppLogger.info('Stack trace: $stackTrace');

      return false;
    }
  }

  Future<void> _trackDefensibilityRouteSignals(String routeName) async {
    final surface = _surfaceForRoute(routeName);
    if (surface == null) return;

    await _defensibilityTelemetry.trackEvent(
      DefensibilityEvent.feedItemOpen,
      surface: surface,
      extra: {'route_name': routeName},
    );

    if (routeName == '/dashboard' || routeName == '/artist/dashboard') {
      await _defensibilityTelemetry.trackEvent(
        DefensibilityEvent.activationMilestoneReached,
        surface: surface,
        extra: {'milestone': 'dashboard_reached'},
      );
    }
  }

  String? _surfaceForRoute(String routeName) {
    switch (routeName) {
      case '/dashboard':
        return 'dashboard';
      case '/community/dashboard':
        return 'community_feed';
      case '/artist/dashboard':
        return 'artist_dashboard';
      case '/artwork/featured':
        return 'artwork_featured';
      case '/events':
        return 'events';
      default:
        return null;
    }
  }

  /// Show navigation error dialog
  void _showNavigationError(
    BuildContext context,
    String routeName,
    dynamic error,
  ) {
    if (!context.mounted) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Navigation Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Failed to navigate to: $routeName'),
            const SizedBox(height: 8),
            Text(
              'Error: ${error.toString()}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(
                context,
              ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
            },
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  /// Check if route exists
  bool doesRouteExist(String routeName) {
    final validRoutes = [
      '/dashboard',
      '/search',
      '/artist/search',
      '/trending',
      '/local',
      '/auth',
      '/art-walk/my-walks',
      '/events',
      '/artist/onboarding',
      '/art-walk/dashboard',
      '/capture/dashboard',
      '/community/dashboard',
      '/artwork/featured',
      '/artist/dashboard',
      '/art-walk/map',
      '/art-walk/create',
      '/art-walk/list',
      '/art-walk/detail',
      '/artist/public-profile',
      '/artist/artwork-detail',
      '/profile',
      '/achievements',
      '/login',
      '/register',
    ];

    return validRoutes.contains(routeName);
  }

  /// Navigate with validation
  Future<bool> safeNavigateTo(
    BuildContext context,
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) async {
    // Pre-flight checks
    if (!context.mounted) {
      AppLogger.info('Navigation cancelled: context not mounted');
      return false;
    }

    if (!doesRouteExist(routeName)) {
      AppLogger.info('Navigation cancelled: route $routeName does not exist');
      _showNavigationError(context, routeName, 'Route does not exist');
      return false;
    }

    return navigateTo(
      context,
      routeName,
      arguments: arguments,
      replace: replace,
      clearStack: clearStack,
    );
  }
}

/// Extension to add safe navigation to BuildContext
extension SafeNavigation on BuildContext {
  NavigationService get nav => NavigationService();

  Future<bool> safeNavigate(
    String routeName, {
    Object? arguments,
    bool replace = false,
    bool clearStack = false,
  }) => NavigationService().safeNavigateTo(
    this,
    routeName,
    arguments: arguments,
    replace: replace,
    clearStack: clearStack,
  );
}
