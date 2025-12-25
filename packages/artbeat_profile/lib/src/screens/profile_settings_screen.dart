import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool isPrivate = false;
  bool notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
      ),
      child: Scaffold(
        body: WorldBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SectionHeader(title: 'Privacy'),

                GlassCard(
                  child: Column(
                    children: [
                      ToggleTile(
                        title: 'Private Profile',
                        subtitle: 'Only followers can see your content',
                        value: isPrivate,
                        onChanged: (bool val) {
                          setState(() => isPrivate = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const SectionHeader(title: 'Notifications'),

                GlassCard(
                  child: Column(
                    children: [
                      ToggleTile(
                        title: 'Enable Notifications',
                        subtitle: 'Get updates on activity and features',
                        value: notificationsEnabled,
                        onChanged: (bool val) {
                          setState(() => notificationsEnabled = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                const SectionHeader(title: 'Account'),

                GlassCard(
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.lock, color: Colors.white),
                        title: const Text('Change Password'),
                        onTap: () {
                          // Navigate to password change
                        },
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.white,
                        ),
                        title: const Text('Delete Account'),
                        textColor: Colors.red,
                        onTap: () {
                          // Confirm deletion
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
