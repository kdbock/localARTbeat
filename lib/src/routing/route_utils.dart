import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Route handler interface for modular routing
abstract class RouteHandler {
  Route<dynamic>? handleRoute(RouteSettings settings);
  bool canHandle(String routeName);
}

/// Utility methods for common route patterns
class RouteUtils {
  /// Creates a standard MaterialPageRoute with MainLayout
  static MaterialPageRoute<T> createMainLayoutRoute<T>({
    required Widget child,
    int currentIndex = -1,
    PreferredSizeWidget? appBar,
    PreferredSizeWidget? Function(BuildContext)? appBarBuilder,
    Widget? drawer,
  }) => MaterialPageRoute<T>(
    builder: (context) => core.MainLayout(
      currentIndex: currentIndex,
      appBar: appBarBuilder?.call(context) ?? appBar,
      drawer: drawer,
      child: child,
    ),
  );

  /// Creates a main navigation route with the ArtbeatDrawer
  static MaterialPageRoute<T> createMainNavRoute<T>({
    required Widget child,
    int currentIndex = -1,
    PreferredSizeWidget? appBar,
    GlobalKey? bottomNavKey,
    List<GlobalKey>? bottomNavItemKeys,
  }) => MaterialPageRoute<T>(
    builder: (_) => core.MainLayout(
      currentIndex: currentIndex,
      appBar: appBar,
      drawer: const core.ArtbeatDrawer(),
      bottomNavKey: bottomNavKey,
      bottomNavItemKeys: bottomNavItemKeys,
      child: child,
    ),
  );

  /// Creates a simple MaterialPageRoute without MainLayout
  static MaterialPageRoute<T> createSimpleRoute<T>({required Widget child}) =>
      MaterialPageRoute<T>(builder: (_) => child);

  /// Creates a route with authentication requirement
  static MaterialPageRoute<T> createAuthRequiredRoute<T>({
    required Widget Function() authenticatedBuilder,
    Widget Function()? unauthenticatedBuilder,
  }) => MaterialPageRoute<T>(
    builder: (_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return authenticatedBuilder();
      } else {
        return unauthenticatedBuilder?.call() ??
            const core.MainLayout(
              currentIndex: -1,
              child: core.AuthRequiredScreen(),
            );
      }
    },
  );

  /// Creates a standard app bar
  static PreferredSizeWidget createAppBar(
    String title, {
    bool showBackButton = true,
    bool showLogo = false,
    bool showDeveloperTools = false,
  }) => core.EnhancedUniversalHeader(
    title: title,
    showLogo: showLogo,
    showBackButton: showBackButton,
    showDeveloperTools: showDeveloperTools,
  );

  /// Extracts arguments safely from route settings
  static T? getArgument<T>(RouteSettings settings, String key) {
    final args = settings.arguments as Map<String, dynamic>?;
    return args?[key] as T?;
  }

  /// Creates a not found route
  static MaterialPageRoute<void> createNotFoundRoute([String? feature]) =>
      MaterialPageRoute<void>(
        builder: (_) => core.MainLayout(
          currentIndex: -1,
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Page Not Found',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    feature != null
                        ? 'The $feature page could not be found.'
                        : 'The requested page could not be found.',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Creates a coming soon placeholder route
  static MaterialPageRoute<void> createComingSoonRoute(String feature) =>
      MaterialPageRoute<void>(
        builder: (_) => core.MainLayout(
          currentIndex: -1,
          appBar: createAppBar(feature),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.construction, size: 64, color: Colors.orange),
                const SizedBox(height: 16),
                Text(
                  '$feature Coming Soon',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This feature is under development.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      );

  /// Creates an error route with custom message
  static MaterialPageRoute<void> createErrorRoute(String message) =>
      MaterialPageRoute<void>(
        builder: (_) => core.MainLayout(
          currentIndex: -1,
          child: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Error',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

  /// Safely creates a route with error handling
  static Route<dynamic> createSafeRoute(
    String routeName,
    Widget Function() builder,
  ) {
    try {
      return MaterialPageRoute(builder: (_) => builder());
    } on Exception catch (e) {
      core.AppLogger.error('❌ Error creating route $routeName: $e');
      return createErrorRoute('Error loading $routeName');
    }
  }

  /// Extracts username from Firebase user with fallbacks
  static String extractUsernameFromFirebaseUser(User firebaseUser) {
    // First try displayName
    if (firebaseUser.displayName != null &&
        firebaseUser.displayName!.isNotEmpty) {
      return firebaseUser.displayName!;
    }

    // Then try email prefix
    if (firebaseUser.email != null && firebaseUser.email!.isNotEmpty) {
      final emailPrefix = firebaseUser.email!.split('@').first;
      if (emailPrefix.isNotEmpty) {
        return emailPrefix;
      }
    }

    // Fallback to user ID prefix
    return 'user_${firebaseUser.uid.substring(0, 8)}';
  }

  /// Creates a user model from Firebase user
  static core.UserModel createUserModelFromFirebase(User firebaseUser) =>
      core.UserModel(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        username: extractUsernameFromFirebaseUser(firebaseUser),
        fullName: firebaseUser.displayName ?? '',
        createdAt: DateTime.now(),
      );
}
