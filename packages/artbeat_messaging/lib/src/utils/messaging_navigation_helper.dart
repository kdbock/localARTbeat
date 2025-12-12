import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class MessagingNavigationHelper {
  /// Navigates to a chat by chat ID
  static Future<void> navigateToChatById(
    BuildContext context,
    String chatId,
  ) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final chat = await chatService.getChatById(chatId);

      if (chat != null && context.mounted) {
        Navigator.pushNamed(
          context,
          '/messaging/chat',
          arguments: {'chat': chat},
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_error_chat_not_found'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'messaging_error_opening_chat'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigates to a chat with a specific user
  static Future<void> navigateToUserChat(
    BuildContext context,
    String userId,
  ) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final chat = await chatService.createOrGetChat(userId);

      if (context.mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/messaging/chat',
          arguments: {'chat': chat},
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'messaging_error_creating_chat'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Navigates to user profile by user ID
  static Future<void> navigateToUserProfile(
    BuildContext context,
    String userId,
  ) async {
    try {
      final chatService = Provider.of<ChatService>(context, listen: false);
      final user = await chatService.getUser(userId);

      if (user != null && context.mounted) {
        Navigator.pushNamed(
          context,
          '/messaging/user',
          arguments: {'userId': userId},
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_error_user_not_found'.tr()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'messaging_error_loading_user'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Opens messaging with a specific user (creates chat if needed)
  static Future<void> openMessagingForUser(
    BuildContext context,
    String userId,
  ) async {
    await navigateToUserChat(context, userId);
  }

  /// Opens messaging main screen
  static void openMessaging(BuildContext context) {
    Navigator.pushNamed(context, '/messaging');
  }

  /// Opens new message screen
  static void openNewMessage(BuildContext context) {
    Navigator.pushNamed(context, '/messaging/new');
  }

  /// Opens group creation screen
  static void openGroupCreation(BuildContext context) {
    Navigator.pushNamed(context, '/messaging/group/new');
  }

  /// Opens messaging settings
  static void openMessagingSettings(BuildContext context) {
    Navigator.pushNamed(context, '/messaging/settings');
  }

  /// Opens blocked users screen
  static void openBlockedUsers(BuildContext context) {
    Navigator.pushNamed(context, '/messaging/blocked-users');
  }

  /// Opens chat info screen
  static void openChatInfo(BuildContext context, ChatModel chat) {
    Navigator.pushNamed(
      context,
      '/messaging/chat-info',
      arguments: {'chat': chat},
    );
  }

  /// Handles deep link navigation
  static Future<void> handleDeepLink(
    BuildContext context,
    String deepLink,
  ) async {
    final uri = Uri.parse(deepLink);

    switch (uri.pathSegments.first) {
      case 'messaging':
        if (uri.pathSegments.length == 1) {
          openMessaging(context);
        } else {
          switch (uri.pathSegments[1]) {
            case 'chat':
              if (uri.pathSegments.length > 2) {
                await navigateToChatById(context, uri.pathSegments[2]);
              }
              break;
            case 'user':
              if (uri.pathSegments.length > 2) {
                await navigateToUserProfile(context, uri.pathSegments[2]);
              }
              break;
            case 'new':
              openNewMessage(context);
              break;
            case 'settings':
              openMessagingSettings(context);
              break;
            case 'blocked':
              openBlockedUsers(context);
              break;
            case 'group':
              if (uri.pathSegments.length > 2 && uri.pathSegments[2] == 'new') {
                openGroupCreation(context);
              }
              break;
          }
        }
        break;
      default:
        // Handle unknown deep links
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('messaging_error_unknown_deep_link'.tr()),
              backgroundColor: Colors.orange,
            ),
          );
        }
    }
  }
}
