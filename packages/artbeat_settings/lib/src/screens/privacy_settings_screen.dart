import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show LegalConfig, UserService;
import '../services/integrated_settings_service.dart';
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
  final _settingsService = IntegratedSettingsService();

  bool isProfilePrivate = false;
  bool allowDataUsage = true;
  bool personalizedContent = true;
  bool _isDeleting = false;
  bool _isRequestingDownload = false;
  bool _isRequestingDeletion = false;

  @override
  void dispose() {
    _settingsService.dispose();
    super.dispose();
  }

  Future<void> _showDeleteAccountDialog() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This permanently deletes your account access. Most user-facing '
          'data is removed within ${LegalConfig.accountDeletionPrimaryDays} '
          'days, backups are purged within ${LegalConfig.backupPurgeDays} '
          'days, and legal/financial records may be retained up to '
          '${LegalConfig.financialRetentionYears} years where required by law. '
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

  Future<void> _requestDataDownload() async {
    if (_isRequestingDownload) return;
    setState(() => _isRequestingDownload = true);
    try {
      await _settingsService.requestDataDownload();
      if (!mounted) return;
      _showMessage(
        'Data export request submitted. We will acknowledge within 72 hours.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to submit data export request: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRequestingDownload = false);
    }
  }

  Future<void> _requestDataDeletion() async {
    if (_isRequestingDeletion) return;
    setState(() => _isRequestingDeletion = true);
    try {
      await _settingsService.requestDataDeletion();
      if (!mounted) return;
      _showMessage(
        'Data deletion request submitted. We will acknowledge within '
        '${LegalConfig.dataRequestAckHours} hours and complete eligible '
        'deletion within ${LegalConfig.dataRequestFulfillmentDays} days.',
      );
    } catch (e) {
      if (!mounted) return;
      _showMessage('Unable to submit data deletion request: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isRequestingDeletion = false);
    }
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

                        const SettingsCategoryHeader(title: 'Data Rights'),

                        SettingsSectionCard(
                          child: Column(
                            children: [
                              SettingsListItem(
                                icon: Icons.download_rounded,
                                title: _isRequestingDownload
                                    ? 'Submitting Data Export...'
                                    : 'Request Data Export',
                                subtitle:
                                    'Receive a copy of your account data.',
                                onTap: _isRequestingDownload
                                    ? null
                                    : _requestDataDownload,
                              ),
                              SettingsListItem(
                                icon: Icons.delete_outline_rounded,
                                title: _isRequestingDeletion
                                    ? 'Submitting Data Deletion...'
                                    : 'Request Data Deletion',
                                subtitle:
                                    'Submit a legal request to delete retained personal data.',
                                destructive: true,
                                onTap: _isRequestingDeletion
                                    ? null
                                    : _requestDataDeletion,
                              ),
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  12,
                                  16,
                                  8,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Recent Requests',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ),
                              ),
                              _buildRecentDataRequests(),
                            ],
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

  Widget _buildRecentDataRequests() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const ListTile(title: Text('Sign in to view request status'));
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('dataRequests')
          .where('userId', isEqualTo: userId)
          .limit(25)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = (snapshot.data?.docs ?? []).toList()
          ..sort((a, b) {
            final aTs = a.data()['requestedAt'];
            final bTs = b.data()['requestedAt'];
            final aMs = aTs is Timestamp ? aTs.millisecondsSinceEpoch : 0;
            final bMs = bTs is Timestamp ? bTs.millisecondsSinceEpoch : 0;
            return bMs.compareTo(aMs);
          });
        if (docs.isEmpty) {
          return const ListTile(
            title: Text('No requests submitted yet'),
            subtitle: Text('Requests appear here once submitted.'),
          );
        }

        return Column(
          children: docs.take(5).map((doc) {
            final data = doc.data();
            final type = (data['requestType'] ?? data['type'] ?? 'request')
                .toString();
            final status = (data['status'] ?? 'pending').toString();
            final requestedAt = data['requestedAt'];
            final requestedAtLabel = requestedAt is Timestamp
                ? requestedAt.toDate().toLocal().toString()
                : 'Processing timestamp pending';

            return ListTile(
              leading: Icon(
                type == 'download'
                    ? Icons.download_rounded
                    : Icons.delete_outline_rounded,
                color: Colors.white70,
              ),
              title: Text(
                type == 'download'
                    ? 'Data Export Request'
                    : 'Data Deletion Request',
                style: const TextStyle(color: Colors.white),
              ),
              subtitle: Text(
                'Status: $status\nRequested: $requestedAtLabel',
                style: const TextStyle(color: Colors.white70),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
