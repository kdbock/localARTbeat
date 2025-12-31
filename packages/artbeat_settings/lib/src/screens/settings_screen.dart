import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_events/artbeat_events.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: _buildSettingsBody(context),
      ),
    );
  }

  Widget _buildSettingsBody(BuildContext context) {
    final categories = SettingsCategoryModel.getDefaultCategories();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
    final user = _auth.currentUser;

    return GlassCard(
      onTap: () => _navigateToProfile(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                ImageUrlValidator.safeNetworkImage(user?.photoURL) ??
                const AssetImage('assets/default_profile.png') as ImageProvider,
            child: !ImageUrlValidator.isValidImageUrl(user?.photoURL)
                ? const Icon(Icons.person, size: 30, color: Colors.white70)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'settings_your_account'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'settings_manage_profile'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildSettingsCategory(
    BuildContext context,
    SettingsCategoryModel category,
  ) {
    if (!category.isEnabled) return const SizedBox.shrink();

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      onTap: () => _navigateToCategory(context, category),
      child: Row(
        children: [
          Icon(
            _getIconForCategory(category.iconData),
            color: Colors.white70,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category.description.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white70),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_quick_actions'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.logout, color: Color(0xFFFF3D8D)),
                title: Text(
                  'settings_sign_out'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: () => _showLogoutDialog(context),
                minVerticalPadding: 12,
              ),
              Container(
                height: 1,
                color: Colors.white12,
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text(
                  'settings_delete_account'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                onTap: () => _showDeleteAccountDialog(context),
                minVerticalPadding: 12,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  IconData _getIconForCategory(String iconName) {
    switch (iconName) {
      case 'account_circle':
        return Icons.account_circle;
      case 'privacy_tip':
        return Icons.privacy_tip;
      case 'notifications':
        return Icons.notifications;
      case 'security':
        return Icons.security;
      case 'block':
        return Icons.block;
      default:
        return Icons.settings;
    }
  }

  void _navigateToCategory(
    BuildContext context,
    SettingsCategoryModel category,
  ) {
    Navigator.pushNamed(context, category.route);
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pushNamed(context, '/profile');
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        title: Text(
          'settings_sign_out'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'settings_confirm_signout'.tr(),
          style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'common_cancel'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _signOut();
            },
            child: Text(
              'settings_sign_out'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFFFF3D8D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        title: Text(
          'settings_delete_account'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'settings_confirm_delete'.tr(),
          style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'common_cancel'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  )
                : Text(
                    'common_delete'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        title: Text(
          'settings_reauth_required'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'settings_reauth_message'.tr(),
          style: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'common_ok'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
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
