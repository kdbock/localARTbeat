import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/blocked_user_model.dart';
import '../services/integrated_settings_service.dart';

class BlockedUsersScreen extends StatefulWidget {
  final bool useOwnScaffold;

  const BlockedUsersScreen({super.key, this.useOwnScaffold = true});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final IntegratedSettingsService _settingsService =
      IntegratedSettingsService();
  List<BlockedUserModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      final blockedUsers = await _settingsService.getBlockedUsers();
      if (mounted) {
        setState(() {
          _blockedUsers = blockedUsers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'settings_blocked_users_error_load'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _blockedUsers.isEmpty
        ? _buildEmptyState()
        : _buildBlockedUsersList();

    if (!widget.useOwnScaffold) {
      // Return just the body if wrapped in MainLayout
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('settings_blocked_users_title'.tr()),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true,
      ),
      body: body,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.block,
              size: 64,
              color: ArtbeatColors.primaryPurple,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'settings_blocked_users_empty_title'.tr(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'settings_blocked_users_empty_desc'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _blockedUsers.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildListHeader();
          }

          final user = _blockedUsers[index - 1];
          return _buildBlockedUserCard(user);
        },
      ),
    );
  }

  Widget _buildListHeader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: ArtbeatColors.primaryPurple,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                _blockedUsers.length == 1
                    ? 'settings_blocked_users_count_one'.tr()
                    : 'settings_blocked_users_count_multiple'.tr(
                        namedArgs: {'count': _blockedUsers.length.toString()},
                      ),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: ArtbeatColors.primaryPurple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'settings_blocked_users_cannot_message'.tr(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUserCard(BlockedUserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
          backgroundImage: ImageUrlValidator.safeNetworkImage(
            user.blockedUserProfileImage,
          ),
          child:
              !ImageUrlValidator.isValidImageUrl(user.blockedUserProfileImage)
              ? Text(
                  user.blockedUserName.isNotEmpty
                      ? user.blockedUserName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: ArtbeatColors.primaryPurple,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          user.blockedUserName.isNotEmpty
              ? user.blockedUserName
              : 'settings_blocked_users_unknown_user'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.reason.isNotEmpty)
              Text(
                'settings_blocked_users_reason'.tr(
                  namedArgs: {'reason': user.reason},
                ),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            Text(
              'settings_blocked_users_blocked_date'.tr(
                namedArgs: {'date': _formatDate(user.blockedAt)},
              ),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _showUnblockDialog(user),
          child: Text(
            'settings_blocked_users_unblock_button'.tr(),
            style: const TextStyle(color: ArtbeatColors.primaryPurple),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 30) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _showUnblockDialog(BlockedUserModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('settings_blocked_users_unblock_title'.tr()),
        content: Text(
          'settings_blocked_users_unblock_confirm'.tr(
            namedArgs: {'name': user.blockedUserName},
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('settings_blocked_users_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _unblockUser(user);
            },
            child: Text(
              'settings_blocked_users_unblock_button'.tr(),
              style: const TextStyle(color: ArtbeatColors.primaryPurple),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _unblockUser(BlockedUserModel user) async {
    try {
      await _settingsService.unblockUser(user.blockedUserId);

      if (mounted) {
        setState(() {
          _blockedUsers.removeWhere(
            (blockedUser) => blockedUser.blockedUserId == user.blockedUserId,
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'settings_blocked_users_unblocked_success'.tr(
                namedArgs: {'name': user.blockedUserName},
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'settings_blocked_users_error_unblock'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
