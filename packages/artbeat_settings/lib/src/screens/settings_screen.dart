import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/models.dart';
import '../widgets/language_selector.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    return _buildSettingsBody(context);
  }

  Widget _buildSettingsBody(BuildContext context) {
    final categories = SettingsCategoryModel.getDefaultCategories();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User profile summary
        _buildProfileSummary(context),
        const SizedBox(height: 24),

        // Language selector
        const LanguageSelector(),
        const SizedBox(height: 24),

        // Settings categories
        ...categories.map(
          (category) => _buildSettingsCategory(context, category),
        ),

        const SizedBox(height: 24),

        // Quick actions
        _buildQuickActions(context),
      ],
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: const AssetImage('assets/default_profile.png'),
              child: Container(),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'settings_your_account'.tr(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'settings_manage_profile'.tr(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCategory(
    BuildContext context,
    SettingsCategoryModel category,
  ) {
    if (!category.isEnabled) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: _getIconForCategory(category.iconData),
        title: Text(
          category.title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          category.description,
          style: const TextStyle(color: Colors.black54),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _navigateToCategory(context, category),
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_quick_actions'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(
                  'settings_sign_out'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => _showLogoutDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'settings_delete_account'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
                onTap: () => _showDeleteAccountDialog(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Icon _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'account_circle':
        return const Icon(Icons.account_circle);
      case 'privacy_tip':
        return const Icon(Icons.privacy_tip);
      case 'notifications':
        return const Icon(Icons.notifications);
      case 'security':
        return const Icon(Icons.security);
      case 'block':
        return const Icon(Icons.block);
      default:
        return const Icon(Icons.settings);
    }
  }

  void _navigateToCategory(
    BuildContext context,
    SettingsCategoryModel category,
  ) {
    Navigator.pushNamed(context, category.route);
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_sign_out'.tr()),
        content: Text('settings_confirm_signout'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _signOut();
            },
            child: Text('settings_sign_out'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_delete_account'.tr()),
        content: Text('settings_confirm_delete'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common_cancel'.tr()),
          ),
          TextButton(
            onPressed: _isDeleting
                ? null
                : () {
                    Navigator.of(context).pop();
                    _deleteAccount();
                  },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: _isDeleting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text('common_delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();

      if (mounted) {
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('${'settings_signout_failed'.tr()}: $e');
      }
    }
  }

  Future<void> _deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) {
      _showErrorMessage('settings_no_user_signed_in'.tr());
      return;
    }

    setState(() => _isDeleting = true);

    try {
      await _userService.deleteAccount(user.uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_account_deleted'.tr()),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        String errorMessage = 'settings_signout_failed'.tr();

        if (e.code == 'requires-recent-login') {
          errorMessage = 'settings_reauth_message'.tr();
          _showReauthenticationDialog();
        } else {
          errorMessage = '${'settings_signout_failed'.tr()}: ${e.message}';
          _showErrorMessage(errorMessage);
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('${'settings_signout_failed'.tr()}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  void _showReauthenticationDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_reauth_required'.tr()),
        content: Text('settings_reauth_message'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('common_ok'.tr()),
          ),
        ],
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
