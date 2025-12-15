import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGuard {
  /// Check if user is currently authenticated
  bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  /// Checks if the user is authenticated and returns appropriate route
  /// If not authenticated, shows a login prompt dialog instead of blocking
  static Route<dynamic>? guardRoute({
    required RouteSettings settings,
    required Widget Function() authenticatedBuilder,
    required Widget Function()? unauthenticatedBuilder,
    String? redirectRoute,
    String? featureName,
  }) {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User is authenticated, return the requested route
      return MaterialPageRoute(
        builder: (_) => authenticatedBuilder(),
        settings: settings,
      );
    } else {
      // User is not authenticated - return wrapper that shows dialog
      if (unauthenticatedBuilder != null) {
        return MaterialPageRoute(
          builder: (_) => unauthenticatedBuilder(),
          settings: settings,
        );
      } else {
        // Return a route that shows auth prompt when user tries to interact
        return MaterialPageRoute(
          builder: (context) =>
              _AuthPromptWrapper(featureName: featureName ?? 'this feature'),
          settings: RouteSettings(name: redirectRoute ?? '/auth-required'),
        );
      }
    }
  }

  /// Check if user has specific role/permission
  static bool hasRole(String role) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // This would typically check custom claims or user document
    // For now, return basic authentication status
    return user.emailVerified;
  }

  /// Check if user is an artist
  static bool isArtist() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    // This would check if user has artist role in Firestore
    // For now, return true if user is authenticated
    return true;
  }

  /// Show login prompt dialog - returns true if user should proceed
  static Future<bool> showLoginPrompt(
    BuildContext context, {
    String? featureName,
  }) async {
    final result = await core.LoginPromptDialog.show(
      context,
      featureName: featureName,
    );
    return result ?? false;
  }
}

/// Wrapper widget that shows auth prompt dialog immediately
class _AuthPromptWrapper extends StatefulWidget {

  const _AuthPromptWrapper({required this.featureName});
  final String featureName;

  @override
  State<_AuthPromptWrapper> createState() => _AuthPromptWrapperState();
}

class _AuthPromptWrapperState extends State<_AuthPromptWrapper> {
  @override
  void initState() {
    super.initState();
    // Show dialog after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrompt();
    });
  }

  Future<void> _showPrompt() async {
    await core.LoginPromptDialog.show(context, featureName: widget.featureName);
    // After dialog closes, go back
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: CircularProgressIndicator()));
}

/// Widget to show when authentication is required
class AuthRequiredScreen extends StatelessWidget {
  const AuthRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const core.EnhancedUniversalHeader(
      title: 'Authentication Required',
      showLogo: false,
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Authentication Required',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Please sign in to access this feature',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/auth');
            },
            child: const Text('Sign In'),
          ),
        ],
      ),
    ),
  );
}
