import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/user_model.dart' as messaging;
import '../services/chat_service.dart';
import 'user_profile_screen.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<messaging.UserModel> _blockedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() => _isLoading = true);

    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final blockedUsers = await chatService.getBlockedUsers();

      setState(() {
        _blockedUsers = blockedUsers.cast<messaging.UserModel>();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_blocked_users_error_error_loading_blocked'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _blockedUsers.isEmpty
        ? _buildEmptyState()
        : _buildBlockedUsersList();
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
          const Text(
            'No blocked users',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Users you block will appear here. They won\'t be able to message you or see your activity.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedUsersList() {
    return RefreshIndicator(
      onRefresh: _loadBlockedUsers,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _blockedUsers.length,
        itemBuilder: (context, index) {
          final user = _blockedUsers[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: ImageUtils.safeCircleAvatar(
                imageUrl: user.photoUrl,
                displayName: user.displayName,
                radius: 20.0,
                backgroundColor: ArtbeatColors.primaryPurple,
              ),
              title: Text(
                user.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user.username != null && user.username!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username!}',
                      style: const TextStyle(
                        color: ArtbeatColors.primaryPurple,
                        fontSize: 12,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Blocked on ${_formatBlockedDate(user.blockedAt ?? DateTime.now())}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () => _viewProfile(user),
                    tooltip: 'View Profile',
                  ),
                  IconButton(
                    icon: const Icon(Icons.block_outlined),
                    onPressed: () => _unblockUser(user),
                    tooltip: 'Unblock',
                  ),
                ],
              ),
              onTap: () => _showUserOptions(user),
            ),
          );
        },
      ),
    );
  }

  void _viewProfile(messaging.UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => UserProfileScreen(user: user),
      ),
    );
  }

  void _unblockUser(messaging.UserModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('messaging_blocked_users_text_unblock_user'.tr()),
        content: Text(
          'Are you sure you want to unblock ${user.displayName}? They will be able to message you again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('artwork_edit_delete_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performUnblock(user);
            },
            child: Text('messaging_blocked_users_text_unblock'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performUnblock(messaging.UserModel user) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      await chatService.unblockUser(user.id);

      setState(() {
        _blockedUsers.removeWhere((u) => u.id == user.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_user_unblocked'.tr().replaceAll('{user}', user.displayName)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_blocked_users_error_error_unblocking_user'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showUserOptions(messaging.UserModel user) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.person),
            title: Text('messaging_blocked_users_text_view_profile'.tr()),
            onTap: () {
              Navigator.pop(context);
              _viewProfile(user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.block_outlined),
            title: Text('messaging_blocked_users_text_unblock'.tr()),
            onTap: () {
              Navigator.pop(context);
              _unblockUser(user);
            },
          ),
          ListTile(
            leading: const Icon(Icons.report),
            title: Text('messaging_blocked_users_text_report_user'.tr()),
            onTap: () {
              Navigator.pop(context);
              _reportUser(user);
            },
          ),
        ],
      ),
    );
  }

  void _reportUser(messaging.UserModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('messaging_blocked_users_text_report_user'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('messaging_blocked_users_label_report_userdisplayname_for'.tr()),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                hintText: 'Reason for reporting (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('artwork_edit_delete_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final chatService = Provider.of<ChatService>(
                  context,
                  listen: false,
                );
                await chatService.reportUser(user.id, 'Blocked user report');
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('messaging_blocked_users_success_user_reported_successfully'.tr()),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                // ignore: use_build_context_synchronously
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('messaging_blocked_users_error_failed_to_report'.tr()),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text('messaging_blocked_users_text_report'.tr()),
          ),
        ],
      ),
    );
  }

  String _formatBlockedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
