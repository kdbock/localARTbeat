import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/login_prompt_dialog.dart';

/// Helper utility for managing authentication requirements in widgets
class AuthHelper {
  /// Check if user is currently authenticated
  static bool get isAuthenticated => FirebaseAuth.instance.currentUser != null;

  /// Get current user
  static User? get currentUser => FirebaseAuth.instance.currentUser;

  /// Check if user is authenticated, show prompt if not
  /// Returns true if user is authenticated or if they should proceed anyway
  static Future<bool> requireAuth(
    BuildContext context, {
    String? featureName,
  }) async {
    if (isAuthenticated) {
      return true;
    }

    final result = await LoginPromptDialog.show(
      context,
      featureName: featureName,
    );

    // If dialog was dismissed or user chose to browse, return false
    return result == true;
  }

  /// Execute an action only if user is authenticated
  /// Shows login prompt if not authenticated
  static Future<T?> executeIfAuthenticated<T>(
    BuildContext context, {
    required Future<T> Function() action,
    String? featureName,
  }) async {
    final isAuth = await requireAuth(context, featureName: featureName);
    if (!isAuth) {
      return null;
    }
    return action();
  }

  /// Execute an action with authentication, or return a default value
  static Future<T> executeOrDefault<T>(
    BuildContext context, {
    required Future<T> Function() action,
    required T defaultValue,
    String? featureName,
  }) async {
    final isAuth = await requireAuth(context, featureName: featureName);
    if (!isAuth) {
      return defaultValue;
    }
    return action();
  }

  /// Show login prompt without checking authentication first
  /// Useful for explicit "Sign in" buttons
  static Future<void> showLoginPrompt(BuildContext context) async {
    await LoginPromptDialog.show(context);
  }
}
