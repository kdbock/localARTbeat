import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';

class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Developer Menu',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
                SizedBox(height: 8),
                Text(
                  'Screen Navigation & Tools',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildAdminSection(context),
          const SizedBox(height: 8),
          _buildDebugSection(context),
          const SizedBox(height: 8),
          _buildFeedbackSection(context),
          const SizedBox(height: 8),
          _buildBackupSection(context),
        ],
      ),
    ),
  );

  Widget _buildAdminSection(BuildContext context) => ExpansionTile(
    title: const Text('Admin Command Center'),
    initiallyExpanded: true,
    children: [
      ListTile(
        leading: const Icon(Icons.dashboard_rounded, color: Colors.blue),
        title: const Text('Unified Admin Dashboard'),
        subtitle: const Text('Central hub for all administration'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/dashboard');
        },
      ),
      ListTile(
        leading: const Icon(Icons.settings_rounded, color: Colors.grey),
        title: const Text('System Settings'),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/admin/settings');
        },
      ),
    ],
  );

  Widget _buildFeedbackSection(BuildContext context) => ExpansionTile(
    title: const Text('Feedback System'),
    children: [
      ListTile(
        leading: const Icon(Icons.feedback),
        title: const Text('Submit Feedback'),
        subtitle: const Text('Test the feedback form'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => const FeedbackForm()),
          );
        },
      ),
      ListTile(
        leading: const Icon(Icons.info),
        title: const Text('System Info'),
        subtitle: const Text('Learn about the feedback system'),
        onTap: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const FeedbackSystemInfoScreen(),
            ),
          );
        },
      ),
    ],
  );

  Widget _buildBackupSection(BuildContext context) => ExpansionTile(
    title: const Text('Backup Management'),
    children: [
      ListTile(
        title: const Text('View Backups'),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup viewer coming soon')),
          );
        },
      ),
      ListTile(
        title: const Text('Create Backup'),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup creation coming soon')),
          );
        },
      ),
      ListTile(
        title: const Text('Restore Backup'),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Backup restoration coming soon')),
          );
        },
      ),
    ],
  );

  Widget _buildDebugSection(BuildContext context) => ExpansionTile(
    title: const Text('Debug Tools'),
    children: [
      ListTile(
        title: const Text('Fix Profile Image'),
        subtitle: const Text('Update profile image URL'),
        onTap: () {
          Navigator.pushNamed(context, '/debug/profile-fix');
        },
      ),
    ],
  );
}
