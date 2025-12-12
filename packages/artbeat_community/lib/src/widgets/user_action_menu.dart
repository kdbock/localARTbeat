import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../services/moderation_service.dart';
import 'report_dialog.dart';

/// Menu for user content actions including report and block
class UserActionMenu extends StatefulWidget {
  final String userId;
  final String contentId;
  final String contentType;
  final String? userName;
  final VoidCallback? onReportSubmitted;
  final VoidCallback? onBlockStatusChanged;

  const UserActionMenu({
    super.key,
    required this.userId,
    required this.contentId,
    required this.contentType,
    this.userName,
    this.onReportSubmitted,
    this.onBlockStatusChanged,
  });

  @override
  State<UserActionMenu> createState() => _UserActionMenuState();
}

class _UserActionMenuState extends State<UserActionMenu> {
  final ModerationService _moderationService = ModerationService();
  bool _isBlocked = false;
  final currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _checkIfBlocked();
  }

  Future<void> _checkIfBlocked() async {
    if (currentUser == null) return;

    final isBlocked = await _moderationService.isUserBlocked(
      blockingUserId: currentUser!.uid,
      checkedUserId: widget.userId,
    );

    if (mounted) {
      setState(() => _isBlocked = isBlocked);
    }
  }

  void _handleBlockUserSelection() {
    // Handle block/unblock immediately within PopupMenuButton callback
    // This prevents navigation context issues
    _showBlockConfirmationDialog();
  }

  Future<void> _showBlockConfirmationDialog() async {
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_user_action_sign_in_required'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Prevent users from blocking themselves
    if (currentUser!.uid == widget.userId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('art_walk_user_action_cannot_block_self'.tr()),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show confirmation dialog immediately - no navigation operations
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _isBlocked
              ? 'art_walk_user_action_unblock_title'.tr()
              : 'art_walk_user_action_block_title'.tr(),
        ),
        content: Text(
          _isBlocked
              ? 'art_walk_user_action_unblock_confirmation'.tr().replaceAll(
                  '{userName}',
                  widget.userName ?? 'this user',
                )
              : 'art_walk_user_action_block_confirmation'.tr().replaceAll(
                  '{userName}',
                  widget.userName ?? 'this user',
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text('art_walk_report_dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              _isBlocked
                  ? 'art_walk_user_action_unblock'.tr()
                  : 'art_walk_user_action_block'.tr(),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      _performBlockOperation();
    }
  }

  Future<void> _performBlockOperation() async {
    // Show loading indicator
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (loadingContext) => Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text('art_walk_user_action_processing'.tr()),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final action = _isBlocked ? 'unblock' : 'block';
      AppLogger.info(
        '🔄 UserActionMenu: Attempting to $action user ${widget.userId}',
      );

      final success = _isBlocked
          ? await _moderationService.unblockUser(
              blockingUserId: currentUser!.uid,
              blockedUserId: widget.userId,
            )
          : await _moderationService.blockUser(
              blockingUserId: currentUser!.uid,
              blockedUserId: widget.userId,
            );

      AppLogger.info('📊 UserActionMenu: $action operation success: $success');

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      if (mounted) {
        if (success) {
          // Store the action before updating state for correct message
          final wasBlocked = _isBlocked;
          setState(() => _isBlocked = !_isBlocked);

          // Notify parent of block status change
          widget.onBlockStatusChanged?.call();

          // Use post frame callback to ensure UI updates happen after current frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              // Show success message
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    wasBlocked
                        ? 'art_walk_user_action_unblock_success'.tr()
                        : 'art_walk_user_action_block_success'.tr(),
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('art_walk_user_action_block_failed'.tr()),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
          });
        }
      }
    } catch (e) {
      AppLogger.error('❌ UserActionMenu: Exception during block/unblock: $e');

      // Close loading dialog on error
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_user_action_error'.tr().replaceAll(
                  '{error}',
                  e.toString(),
                ),
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      });
    }
  }

  void _showReportDialog() {
    Navigator.pop(context); // Close the menu first
    showDialog<void>(
      context: context,
      builder: (context) => ReportDialog(
        reportedUserId: widget.userId,
        contentId: widget.contentId,
        contentType: widget.contentType,
        reportingUserId: currentUser?.uid,
        onReportSubmitted: widget.onReportSubmitted,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        if (value == 'report') {
          _showReportDialog();
        } else if (value == 'block') {
          _handleBlockUserSelection();
        }
      },
      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
        PopupMenuItem<String>(
          value: 'report',
          child: ListTile(
            leading: const Icon(Icons.flag),
            title: Text('art_walk_user_action_report'.tr()),
          ),
        ),
        PopupMenuItem<String>(
          value: 'block',
          child: ListTile(
            leading: Icon(_isBlocked ? Icons.person_add : Icons.block),
            title: Text(_isBlocked ? 'Unblock user' : 'Block user'),
          ),
        ),
      ],
      icon: const Icon(Icons.more_vert),
    );
  }
}
