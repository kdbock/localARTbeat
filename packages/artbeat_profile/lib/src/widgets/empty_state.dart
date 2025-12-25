// 📁 lib/artbeat_profile/widgets/empty_state.dart
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.buttonLabel,
    this.onPressed,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor ?? ArtbeatColors.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: ArtbeatColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonLabel != null && onPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ArtbeatColors.primaryPurple,
                  foregroundColor: Colors.white,
                ),
                child: Text(buttonLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
