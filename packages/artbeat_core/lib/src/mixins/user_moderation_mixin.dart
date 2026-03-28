import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../utils/logger.dart';
import '../services/user_block_service.dart';

/// Mixin to add user blocking and reporting functionality to any widget
/// Provides common methods for blocking users and reporting content
mixin UserModerationMixin {
  /// Block a user - prevents seeing their content
  Future<void> blockUser(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    try {
      final blockService = UserBlockService();
      await blockService.blockUser(userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'user_moderation_blocked_user'.tr(namedArgs: {'user': userName}),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      AppLogger.info('✅ User blocked: $userId');
    } catch (e) {
      AppLogger.error('❌ Error blocking user: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'user_moderation_error_blocking'.tr(namedArgs: {'error': '$e'}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Unblock a user - allows seeing their content again
  Future<void> unblockUser(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    try {
      final blockService = UserBlockService();
      await blockService.unblockUser(userId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'user_moderation_unblocked_user'.tr(
                namedArgs: {'user': userName},
              ),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      AppLogger.info('✅ User unblocked: $userId');
    } catch (e) {
      AppLogger.error('❌ Error unblocking user: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'user_moderation_error_unblocking'.tr(namedArgs: {'error': '$e'}),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Show a menu with block/report options for a user
  void showUserModerationMenu(
    BuildContext context,
    String userId,
    String userName,
    VoidCallback? onReportPressed,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Block option
              ListTile(
                leading: const Icon(Icons.block, color: Colors.red),
                title: Text('user_moderation_menu_block_title'.tr()),
                subtitle: Text(
                  'user_moderation_menu_block_subtitle'.tr(
                    namedArgs: {'user': userName},
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  blockUser(context, userId, userName);
                },
              ),
              const Divider(),

              // Report option
              if (onReportPressed != null)
                ListTile(
                  leading: const Icon(Icons.flag, color: Colors.orange),
                  title: Text('user_moderation_menu_report_title'.tr()),
                  subtitle: Text('user_moderation_menu_report_subtitle'.tr()),
                  onTap: () {
                    Navigator.pop(context);
                    onReportPressed();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Show confirmation dialog before blocking
  Future<bool?> showBlockConfirmation(
    BuildContext context,
    String userName,
  ) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('user_moderation_confirm_title'.tr()),
        content: Text(
          'user_moderation_confirm_body'.tr(namedArgs: {'user': userName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('user_moderation_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('user_moderation_block_action'.tr()),
          ),
        ],
      ),
    );
  }

  /// Show a popup menu for user actions (block, report, etc.)
  /// Returns the selected action or null if dismissed
  Future<String?> showUserActionPopup(
    BuildContext context,
    String userId,
    String userName,
  ) async {
    return showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width - 200,
        0,
        0,
        0,
      ),
      items: [
        PopupMenuItem<String>(
          value: 'block',
          child: Row(
            children: [
              const Icon(Icons.block, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Text(
                'user_moderation_popup_block_user'.tr(
                  namedArgs: {'user': userName},
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'report',
          child: Row(
            children: [
              const Icon(Icons.flag, color: Colors.orange, size: 18),
              const SizedBox(width: 8),
              Text('user_moderation_popup_report'.tr()),
            ],
          ),
        ),
      ],
    );
  }
}
