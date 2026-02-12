import 'package:flutter/material.dart';
import 'package:artbeat_admin/artbeat_admin.dart';
import 'feedback_form.dart';
import '../services/onboarding_service.dart';

/// Developer menu with admin upload screens only
/// Refactored to use unified admin tools from artbeat_admin
class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<dynamic>(builder: (context) => screen));
  }

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
              onTap: () => _navigateToScreen(
                context,
                const ModernUnifiedAdminUploadToolsScreen(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Developer Feedback Admin'),
              onTap: () => _navigateToScreen(
                context,
                const ModernUnifiedAdminUploadToolsScreen(), // Feedback moderation integrated here
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
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Unified Admin Dashboard'),
              onTap: () => _navigateToScreen(
                context,
                const ModernUnifiedAdminDashboard(),
              ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.restart_alt, color: Colors.orange),
              title: const Text('Reset Onboarding'),
              subtitle: const Text('Show dashboard tour on next refresh'),
              onTap: () async {
                await OnboardingService().resetOnboarding();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Onboarding reset! Refresh dashboard to see the tour.'),
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
