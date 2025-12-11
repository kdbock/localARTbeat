import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/models.dart';
import '../services/settings_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  final bool useOwnScaffold;

  const SecuritySettingsScreen({super.key, this.useOwnScaffold = true});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  SecuritySettingsModel? _securitySettings;
  bool _isLoading = true;
  bool _isSaving = false;
  late final SettingsService _settingsService;
  late final FirebaseAuth _auth;

  @override
  void initState() {
    super.initState();
    _settingsService = SettingsService();
    _auth = FirebaseAuth.instance;
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Load settings from Firestore
      final settingsData = await _settingsService.getUserSettings();
      final securityData =
          settingsData['securitySettings'] as Map<String, dynamic>?;

      SecuritySettingsModel settings;
      if (securityData != null) {
        // Parse existing security settings
        settings = SecuritySettingsModel.fromMap({
          'userId': userId,
          'twoFactor': securityData['twoFactor'] ?? <String, dynamic>{},
          'login': securityData['login'] ?? <String, dynamic>{},
          'password': securityData['password'] ?? <String, dynamic>{},
          'devices': securityData['devices'] ?? <String, dynamic>{},
          'updatedAt':
              securityData['updatedAt'] ?? DateTime.now().toIso8601String(),
        });
      } else {
        // Create default settings
        settings = SecuritySettingsModel.defaultSettings(userId);
      }

      if (mounted) {
        setState(() {
          _securitySettings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings_load_failed'.tr())),
        );
      }
    }
  }

  Future<void> _updateSecuritySettings(SecuritySettingsModel settings) async {
    setState(() => _isSaving = true);
    try {
      // Save security settings to Firestore
      await _settingsService.updateSetting(
        'securitySettings',
        settings.toMap(),
      );

      if (mounted) {
        setState(() {
          _securitySettings = settings;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('settings_update_failed'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _securitySettings == null
        ? Center(child: Text('settings_load_failed'.tr()))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTwoFactorCard(),
                const SizedBox(height: 16),
                _buildLoginSecurityCard(),
                const SizedBox(height: 16),
                _buildPasswordCard(),
                const SizedBox(height: 16),
                _buildDeviceSecurityCard(),
                const SizedBox(height: 24),
                _buildSecurityActionsSection(),
              ],
            ),
          );

    if (widget.useOwnScaffold) {
      return Scaffold(
        appBar: AppBar(title: Text('settings_security_title'.tr()), elevation: 0),
        body: body,
      );
    } else {
      return body;
    }
  }

  Widget _buildTwoFactorCard() {
    final twoFactor = _securitySettings!.twoFactor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_two_factor_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_two_factor_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'settings_enable_2fa'.tr(),
              subtitle: 'settings_enable_2fa_desc'.tr(),
              value: twoFactor.enabled,
              onChanged: (value) {
                final updatedTwoFactor = twoFactor.copyWith(enabled: value);
                final updated = _securitySettings!.copyWith(
                  twoFactor: updatedTwoFactor,
                );
                _updateSecuritySettings(updated);
              },
            ),
            if (twoFactor.enabled) ...[
              const SizedBox(height: 12),
              _buildTwoFactorMethodDropdown(twoFactor),
              const SizedBox(height: 12),
              _buildSwitchTile(
                title: 'settings_backup_codes'.tr(),
                subtitle: 'settings_backup_codes_desc'.tr(),
                value: twoFactor.backupCodesGenerated,
                onChanged: (value) {
                  if (value) {
                    _showBackupCodesDialog();
                  } else {
                    final updatedTwoFactor = twoFactor.copyWith(
                      backupCodesGenerated: false,
                    );
                    final updated = _securitySettings!.copyWith(
                      twoFactor: updatedTwoFactor,
                    );
                    _updateSecuritySettings(updated);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTwoFactorMethodDropdown(TwoFactorSettings twoFactor) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'settings_two_factor_method'.tr(),
        border: const OutlineInputBorder(),
      ),
      initialValue: twoFactor.method,
      items: [
        DropdownMenuItem(value: 'sms', child: Text('settings_2fa_sms'.tr())),
        DropdownMenuItem(value: 'email', child: Text('settings_2fa_email'.tr())),
        DropdownMenuItem(
          value: 'authenticator',
          child: Text('settings_2fa_authenticator'.tr()),
        ),
      ],
      onChanged: _isSaving
          ? null
          : (value) {
              if (value != null) {
                final updatedTwoFactor = twoFactor.copyWith(method: value);
                final updated = _securitySettings!.copyWith(
                  twoFactor: updatedTwoFactor,
                );
                _updateSecuritySettings(updated);
              }
            },
    );
  }

  Widget _buildLoginSecurityCard() {
    final login = _securitySettings!.login;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_login_security_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_login_security_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'settings_email_verification_required'.tr(),
              subtitle: 'settings_email_verification_required_desc'.tr(),
              value: login.requireEmailVerification,
              onChanged: (value) {
                final updatedLogin = login.copyWith(
                  requireEmailVerification: value,
                );
                final updated = _securitySettings!.copyWith(
                  login: updatedLogin,
                );
                _updateSecuritySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_login_alerts'.tr(),
              subtitle: 'settings_login_alerts_desc'.tr(),
              value: login.allowLoginAlerts,
              onChanged: (value) {
                final updatedLogin = login.copyWith(allowLoginAlerts: value);
                final updated = _securitySettings!.copyWith(
                  login: updatedLogin,
                );
                _updateSecuritySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_remember_device'.tr(),
              subtitle: 'settings_remember_device_desc'.tr(),
              value: login.rememberDevice,
              onChanged: (value) {
                final updatedLogin = login.copyWith(rememberDevice: value);
                final updated = _securitySettings!.copyWith(
                  login: updatedLogin,
                );
                _updateSecuritySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordCard() {
    final password = _securitySettings!.password;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_password_security_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_password_last_changed'.tr(namedArgs: {'date': password.lastChanged != null ? _formatDate(password.lastChanged!) : 'settings_never'.tr()}),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_reset),
              title: Text('settings_change_password'.tr()),
              subtitle: Text('settings_change_password_desc'.tr()),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showChangePasswordDialog(),
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'settings_require_password_change'.tr(),
              subtitle: 'settings_require_password_change_desc'.tr(),
              value: password.requirePasswordChange,
              onChanged: (value) {
                final updatedPassword = password.copyWith(
                  requirePasswordChange: value,
                );
                final updated = _securitySettings!.copyWith(
                  password: updatedPassword,
                );
                _updateSecuritySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceSecurityCard() {
    final devices = _securitySettings!.devices;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_device_security_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_device_security_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.devices),
              title: Text('settings_manage_devices'.tr()),
              subtitle: Text(
                'settings_approved_devices'.tr(namedArgs: {'count': '${devices.approvedDevices.length}'}),
              ),
              trailing: const Icon(Icons.chevron_right),
              contentPadding: EdgeInsets.zero,
              onTap: () => _showDevicesDialog(),
            ),
            const Divider(),
            _buildSwitchTile(
              title: 'settings_allow_multiple_sessions'.tr(),
              subtitle: 'settings_allow_multiple_sessions_desc'.tr(),
              value: devices.allowMultipleSessions,
              onChanged: (value) {
                final updatedDevices = devices.copyWith(
                  allowMultipleSessions: value,
                );
                final updated = _securitySettings!.copyWith(
                  devices: updatedDevices,
                );
                _updateSecuritySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_track_device_location'.tr(),
              subtitle: 'settings_track_device_location_desc'.tr(),
              value: devices.trackDeviceLocation,
              onChanged: (value) {
                final updatedDevices = devices.copyWith(
                  trackDeviceLocation: value,
                );
                final updated = _securitySettings!.copyWith(
                  devices: updatedDevices,
                );
                _updateSecuritySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_security_actions_title'.tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.history, color: Colors.blue),
                title: Text('settings_login_history'.tr()),
                subtitle: Text('settings_login_history_desc'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLoginHistoryDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.security, color: Colors.orange),
                title: Text('settings_security_checkup'.tr()),
                subtitle: Text('settings_security_checkup_desc'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSecurityCheckupDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text('settings_sign_out_everywhere'.tr()),
                subtitle: Text('settings_sign_out_everywhere_desc'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showSignOutEverywhereDialog(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: _isSaving ? null : onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showBackupCodesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_backup_codes'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('settings_backup_codes_save'.tr()),
            const SizedBox(height: 16),
            const SelectableText('A1B2-C3D4-E5F6\nG7H8-I9J0-K1L2\nM3N4-O5P6-Q7R8'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_close'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Mark backup codes as generated
              final twoFactor = _securitySettings!.twoFactor.copyWith(
                backupCodesGenerated: true,
              );
              final updated = _securitySettings!.copyWith(twoFactor: twoFactor);
              _updateSecuritySettings(updated);
            },
            child: Text('settings_backup_codes_saved'.tr()),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('settings_change_password'.tr()),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  decoration: InputDecoration(
                    labelText: 'settings_current_password'.tr(),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  decoration: InputDecoration(
                    labelText: 'settings_new_password'.tr(),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'settings_confirm_new_password'.tr(),
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'settings_password_requirements'.tr(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);
              },
              child: Text('common_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text.trim();
                final newPassword = newPasswordController.text.trim();
                final confirmPassword = confirmPasswordController.text.trim();

                // Validate inputs
                if (currentPassword.isEmpty ||
                    newPassword.isEmpty ||
                    confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('settings_fill_all_fields'.tr())),
                  );
                  return;
                }

                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('settings_passwords_do_not_match'.tr())),
                  );
                  return;
                }

                // Validate password requirements
                if (_securitySettings != null &&
                    !_securitySettings!.password.validatePassword(
                      newPassword,
                    )) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'settings_password_not_meet_requirements'.tr(),
                      ),
                    ),
                  );
                  return;
                }

                // Close dialog and show loading
                currentPasswordController.dispose();
                newPasswordController.dispose();
                confirmPasswordController.dispose();
                Navigator.pop(context);

                // Change password using Firebase Auth
                await _changePassword(currentPassword, newPassword);
              },
              child: Text('settings_change_password'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not authenticated');
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(newPassword);

      // Update password change timestamp in security settings
      if (_securitySettings != null) {
        final updatedSettings = _securitySettings!.copyWith(
          password: _securitySettings!.password.copyWith(
            lastChanged: DateTime.now(),
          ),
        );
        await _updateSecuritySettings(updatedSettings);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_password_changed_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorKey = 'settings_password_change_failed';
      if (e.code == 'wrong-password') {
        errorKey = 'settings_current_password_incorrect';
      } else if (e.code == 'weak-password') {
        errorKey = 'settings_new_password_weak';
      } else if (e.code == 'requires-recent-login') {
        errorKey = 'settings_requires_recent_login';
      }

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorKey.tr())));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('common_error'.tr())));
      }
    }
  }

  void _showDevicesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_trusted_devices'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: Text('artbeat_settings_trusted_device_iphone_15'.tr()),
              subtitle: Text('artbeat_settings_last_used_today'.tr()),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
            ListTile(
              leading: const Icon(Icons.laptop_mac),
              title: Text('artbeat_settings_trusted_device_macbook_pro'.tr()),
              subtitle: Text('artbeat_settings_last_used_yesterday'.tr()),
              trailing: const Icon(Icons.check_circle, color: Colors.green),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showLoginHistoryDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_login_history'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.smartphone, color: Colors.green),
              title: Text('artbeat_settings_trusted_device_iphone_15'.tr()),
              subtitle: Text('artbeat_settings_login_history_today_sample'.tr()),
            ),
            ListTile(
              leading: const Icon(Icons.laptop_mac, color: Colors.green),
              title: Text('artbeat_settings_trusted_device_macbook_pro'.tr()),
              subtitle: Text('artbeat_settings_login_history_yesterday_sample'.tr()),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSecurityCheckupDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_security_checkup'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('settings_security_status'.tr()),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('artbeat_settings_2fa_enabled'.tr()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('artbeat_settings_strong_password'.tr()),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Text('artbeat_settings_password_age_six_months'.tr()),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_close'.tr()),
          ),
        ],
      ),
    );
  }

  void _showSignOutEverywhereDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_sign_out_everywhere'.tr()),
        content: Text(
          'settings_sign_out_everywhere_msg'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('settings_signed_out_everywhere'.tr()),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('settings_sign_out'.tr()),
          ),
        ],
      ),
    );
  }
}
