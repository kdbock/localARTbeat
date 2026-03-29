import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'feedback_form.dart';
import '../services/onboarding_service.dart';
import '../routing/app_routes.dart';

/// Developer menu with admin upload screens only
/// Refactored to use unified admin tools from artbeat_admin
class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  @override
  Widget build(BuildContext context) {
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
                    'Unified Admin & Dev Tools',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file),
              title: const Text('Admin Upload Tools'),
              subtitle: const Text('Consolidated data management'),
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/admin/upload-tools'),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Developer Feedback Admin'),
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed('/admin/upload-tools'),
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
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Unified Admin Dashboard'),
              onTap: () => Navigator.of(
                context,
                rootNavigator: true,
              ).pushNamed(AppRoutes.adminDashboard),
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
