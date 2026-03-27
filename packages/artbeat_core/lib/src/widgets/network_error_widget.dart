import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NetworkErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String message;

  const NetworkErrorWidget({
    super.key,
    required this.onRetry,
    this.message = 'Network connection error',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Container(
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: const Color(
            0x1BDD3131,
          ), // 0.1 opacity for error color (example ARGB for Material error color)
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to connect to the server. Please check your connection and try again.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: Text('common_retry'.tr())),
          ],
        ),
      ),
    );
  }
}
