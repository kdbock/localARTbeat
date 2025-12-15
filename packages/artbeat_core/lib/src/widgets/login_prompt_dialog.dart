import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/artbeat_colors.dart';

/// Dialog that prompts users to login or create an account
class LoginPromptDialog extends StatelessWidget {
  final String? title;
  final String? message;
  final String? featureName;

  const LoginPromptDialog({
    super.key,
    this.title,
    this.message,
    this.featureName,
  });

  /// Show the login prompt dialog
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
    String? featureName,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LoginPromptDialog(
        title: title,
        message: message,
        featureName: featureName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTitle = title ?? 'auth_required_title'.tr();
    final effectiveMessage =
        message ??
        (featureName != null
            ? 'auth_required_feature_message'.tr(
                namedArgs: {'feature': featureName!},
              )
            : 'auth_required_message'.tr());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              effectiveTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Message
            Text(
              effectiveMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: ArtbeatColors.primaryPurple.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'auth_prompt_browse'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ArtbeatColors.primaryPurple,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(false);
                      // Navigate to login screen
                      Navigator.of(context).pushNamed('/auth');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: ArtbeatColors.primaryPurple,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'auth_prompt_login'.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Sign up option
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
                // Navigate to registration screen
                Navigator.of(context).pushNamed('/register');
              },
              child: RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  children: [
                    TextSpan(text: 'auth_prompt_no_account'.tr()),
                    const TextSpan(text: ' '),
                    const TextSpan(
                      text: 'Sign Up',
                      style: TextStyle(
                        color: ArtbeatColors.primaryGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper mixin for screens that need authentication checks
mixin AuthenticationRequired {
  /// Check if user is authenticated, show prompt if not
  Future<bool> requireAuthentication(
    BuildContext context, {
    String? featureName,
  }) async {
    // Import auth at usage time to avoid circular dependencies
    final auth = await _getFirebaseAuth();
    if (auth.currentUser != null) {
      return true;
    }

    final result = await LoginPromptDialog.show(
      // ignore: use_build_context_synchronously
      context,
      featureName: featureName,
    );

    return result == true;
  }

  Future<dynamic> _getFirebaseAuth() async {
    // Dynamic import to avoid build-time dependency
    final firebaseAuth = await Future.value(
      // This will be imported from firebase_auth at runtime
      () async {
        try {
          // Use reflection or dynamic import here
          return null; // Placeholder - will be implemented
        } catch (e) {
          return null;
        }
      }(),
    );
    return firebaseAuth;
  }
}
