import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show UserService;
import '../widgets/settings_category_header.dart';
import '../widgets/settings_section_card.dart';
import '../widgets/settings_toggle_row.dart';
import '../widgets/hud_top_bar.dart';
import '../widgets/settings_list_item.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;

  bool isProfilePrivate = false;
  bool allowDataUsage = true;
  bool personalizedContent = true;
  bool _isDeleting = false;

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This will permanently delete your account and associated data. '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await _deleteAccount();
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showMessage('No user is currently signed in.', isError: true);
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await _userService.deleteAccount(user.uid);
      if (!mounted) return;
      _showMessage('Account deleted successfully.');
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (r) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'requires-recent-login') {
        _showReauthRequiredDialog();
      } else {
        _showMessage('Unable to delete account: ${e.message}', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to delete account: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _showReauthRequiredDialog() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Re-authentication Required'),
        content: const Text(
          'For security, please sign out and sign back in before deleting your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF07060F),
                  Color(0xFF0B1222),
                  Color(0xFF0A1B15),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                HudTopBar(
                  title: 'privacy_settings_title',
                  subtitle: 'privacy_settings_subtitle',
                  onBack: () => Navigator.of(context).maybePop(),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SettingsCategoryHeader(title: 'Privacy'),

                        SettingsSectionCard(
                          child: Column(
                            children: [
                              SettingsToggleRow(
                                title: 'Private Profile',
                                subtitle: 'Hide your profile from public feeds',
                                value: isProfilePrivate,
                                onChanged: (v) =>
                                    setState(() => isProfilePrivate = v),
                              ),
                              SettingsToggleRow(
                                title: 'Allow Data Usage',
                                subtitle:
                                    'Help us improve by sharing usage data',
                                value: allowDataUsage,
                                onChanged: (v) =>
                                    setState(() => allowDataUsage = v),
                              ),
                              SettingsToggleRow(
                                title: 'Personalized Content',
                                subtitle:
                                    'Improve recommendations based on activity',
                                value: personalizedContent,
                                onChanged: (v) =>
                                    setState(() => personalizedContent = v),
                              ),
                            ],
                          ),
                        ),

                        const SettingsCategoryHeader(title: 'Account'),

                        SettingsSectionCard(
                          child: SettingsListItem(
                            icon: Icons.delete_forever_rounded,
                            title: _isDeleting
                                ? 'Deleting Account...'
                                : 'Delete Account',
                            destructive: true,
                            onTap: _isDeleting
                                ? null
                                : _showDeleteAccountDialog,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
