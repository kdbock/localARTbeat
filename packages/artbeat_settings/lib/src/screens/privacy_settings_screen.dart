import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/models.dart';
import '../services/settings_service.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  final _settingsService = SettingsService();
  PrivacySettingsModel? _privacySettings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    try {
      final settings = await _settingsService.getPrivacySettings();
      if (mounted) {
        setState(() {
          _privacySettings = settings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        String errorMessage = 'settings_load_failed'.tr();

        if (e.toString().contains('not authenticated')) {
          errorMessage = 'Please log in again to access privacy settings';
        } else if (e.toString().contains('Permission denied')) {
          errorMessage =
              'Unable to load privacy settings - permission denied. Please check your privacy settings in Firestore.';
        } else if (e.toString().contains('Network')) {
          errorMessage =
              'Network error - please check your internet connection';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _updatePrivacySettings(PrivacySettingsModel settings) async {
    setState(() => _isSaving = true);
    try {
      await _settingsService.savePrivacySettings(settings);
      if (mounted) {
        setState(() {
          _privacySettings = settings;
          _isSaving = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings_updated'.tr())));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('settings_update_failed'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _privacySettings == null
        ? Center(child: Text('settings_load_failed'.tr()))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileVisibilityCard(),
                const SizedBox(height: 16),
                _buildContentPrivacyCard(),
                const SizedBox(height: 16),
                _buildDataPrivacyCard(),
                const SizedBox(height: 16),
                _buildLocationPrivacyCard(),
                const SizedBox(height: 16),
                _buildBlockedUsersCard(),
                const SizedBox(height: 24),
                _buildDataControlsSection(),
              ],
            ),
          );
  }

  Widget _buildProfileVisibilityCard() {
    final profile = _privacySettings!.profile;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_privacy_title'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_privacy_profile_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildVisibilityDropdown(profile),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'settings_show_last_seen'.tr(),
              subtitle: 'settings_show_last_seen_desc'.tr(),
              value: profile.showLastSeen,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(showLastSeen: value);
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_show_online_status'.tr(),
              subtitle: 'settings_show_online_status_desc'.tr(),
              value: profile.showOnlineStatus,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(
                  showOnlineStatus: value,
                );
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_allow_messages'.tr(),
              subtitle: 'settings_allow_messages_desc'.tr(),
              value: profile.allowMessages,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(allowMessages: value);
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_show_followers'.tr(),
              subtitle: 'settings_show_followers_desc'.tr(),
              value: profile.showFollowersCount,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(
                  showFollowersCount: value,
                );
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_show_following'.tr(),
              subtitle: 'settings_show_following_desc'.tr(),
              value: profile.showFollowingCount,
              onChanged: (value) {
                final updatedProfile = profile.copyWith(
                  showFollowingCount: value,
                );
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibilityDropdown(ProfilePrivacySettings profile) {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'settings_visibility'.tr(),
        border: const OutlineInputBorder(),
      ),
      initialValue: profile.visibility,
      items: [
        DropdownMenuItem(
          value: 'public',
          child: Text('settings_visibility_public'.tr()),
        ),
        DropdownMenuItem(
          value: 'friends',
          child: Text('settings_visibility_friends'.tr()),
        ),
        DropdownMenuItem(
          value: 'private',
          child: Text('settings_visibility_private'.tr()),
        ),
      ],
      onChanged: _isSaving
          ? null
          : (value) {
              if (value != null) {
                final updatedProfile = profile.copyWith(visibility: value);
                final updated = _privacySettings!.copyWith(
                  profile: updatedProfile,
                );
                _updatePrivacySettings(updated);
              }
            },
    );
  }

  Widget _buildContentPrivacyCard() {
    final content = _privacySettings!.content;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_content_privacy'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_content_privacy_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'settings_show_in_search'.tr(),
              subtitle: 'settings_show_in_search_desc'.tr(),
              value: content.showInSearch,
              onChanged: (value) {
                final updatedContent = content.copyWith(showInSearch: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_allow_comments'.tr(),
              subtitle: 'settings_allow_comments_desc'.tr(),
              value: content.allowComments,
              onChanged: (value) {
                final updatedContent = content.copyWith(allowComments: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_allow_sharing'.tr(),
              subtitle: 'settings_allow_sharing_desc'.tr(),
              value: content.allowSharing,
              onChanged: (value) {
                final updatedContent = content.copyWith(allowSharing: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_allow_likes'.tr(),
              subtitle: 'settings_allow_likes_desc'.tr(),
              value: content.allowLikes,
              onChanged: (value) {
                final updatedContent = content.copyWith(allowLikes: value);
                final updated = _privacySettings!.copyWith(
                  content: updatedContent,
                );
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataPrivacyCard() {
    final data = _privacySettings!.data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_data_privacy'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_data_privacy_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'settings_analytics'.tr(),
              subtitle: 'settings_analytics_desc'.tr(),
              value: data.allowAnalytics,
              onChanged: (value) {
                final updatedData = data.copyWith(allowAnalytics: value);
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_marketing'.tr(),
              subtitle: 'settings_marketing_desc'.tr(),
              value: data.allowMarketing,
              onChanged: (value) {
                final updatedData = data.copyWith(allowMarketing: value);
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_personalization'.tr(),
              subtitle: 'settings_personalization_desc'.tr(),
              value: data.allowPersonalization,
              onChanged: (value) {
                final updatedData = data.copyWith(allowPersonalization: value);
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_third_party'.tr(),
              subtitle: 'settings_third_party_desc'.tr(),
              value: data.allowThirdPartySharing,
              onChanged: (value) {
                final updatedData = data.copyWith(
                  allowThirdPartySharing: value,
                );
                final updated = _privacySettings!.copyWith(data: updatedData);
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationPrivacyCard() {
    final location = _privacySettings!.location;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_location_privacy'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_location_privacy_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            _buildSwitchTile(
              title: 'settings_location_sharing'.tr(),
              subtitle: 'settings_location_sharing_desc'.tr(),
              value: location.shareLocation,
              onChanged: (value) {
                final updatedLocation = location.copyWith(shareLocation: value);
                final updated = _privacySettings!.copyWith(
                  location: updatedLocation,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_location_profile'.tr(),
              subtitle: 'settings_location_profile_desc'.tr(),
              value: location.showLocationInProfile,
              onChanged: (value) {
                final updatedLocation = location.copyWith(
                  showLocationInProfile: value,
                );
                final updated = _privacySettings!.copyWith(
                  location: updatedLocation,
                );
                _updatePrivacySettings(updated);
              },
            ),
            _buildSwitchTile(
              title: 'settings_location_recommendations'.tr(),
              subtitle: 'settings_location_recommendations_desc'.tr(),
              value: location.allowLocationBasedRecommendations,
              onChanged: (value) {
                final updatedLocation = location.copyWith(
                  allowLocationBasedRecommendations: value,
                );
                final updated = _privacySettings!.copyWith(
                  location: updatedLocation,
                );
                _updatePrivacySettings(updated);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedUsersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'settings_blocked_users'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'settings_blocked_users_desc'.tr(),
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: Text('settings_manage_blocked_users'.tr()),
              subtitle: Text('settings_manage_blocked_users_desc'.tr()),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.of(context).pushNamed('/settings/blocked-users');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataControlsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings_data_controls'.tr(),
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.download, color: Colors.blue),
                title: Text('settings_download_data'.tr()),
                subtitle: Text('settings_download_data_desc'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDataDownloadDialog(),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: Text('settings_delete_data'.tr()),
                subtitle: Text('settings_delete_data_desc'.tr()),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDataDeletionDialog(),
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

  void _showDataDownloadDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_download_data'.tr()),
        content: Text('settings_download_data_dialog'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestDataDownload();
            },
            child: Text('settings_request_download'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDataDeletionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_delete_data'.tr()),
        content: Text('settings_delete_data_dialog'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _requestDataDeletion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('settings_delete_data_confirm'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _requestDataDownload() async {
    try {
      await _settingsService.requestDataDownload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_data_download_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_data_download_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestDataDeletion() async {
    try {
      await _settingsService.requestDataDeletion();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_data_deletion_success'.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('settings_data_deletion_failed'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
