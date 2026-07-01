import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'feedback_form.dart';
import '../services/onboarding_service.dart';

/// Debug-only developer menu for local app diagnostics.
class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Local Debug Tools',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('Submit Feedback'),
              onTap: () {
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 250), () {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const FeedbackForm(),
                    ),
                  );
                });
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text('Reset Onboarding'),
              subtitle: const Text('Show dashboard tour on next refresh'),
              onTap: () async {
                await context.read<OnboardingService>().resetOnboarding();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Onboarding reset! Refresh dashboard to see the tour.',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
