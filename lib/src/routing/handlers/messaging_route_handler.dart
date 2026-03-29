import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class MessagingRouteHandler {
  const MessagingRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.messaging:
        return RouteUtils.createSimpleRoute(
          child: const messaging.ArtisticMessagingScreen(),
        );

      case core.AppRoutes.messagingInbox:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.MessagingDashboardScreen(),
        );

      case core.AppRoutes.messagingNew:
        return RouteUtils.createMainLayoutRoute(
          child: const messaging.ContactSelectionScreen(),
        );

      case core.AppRoutes.messagingChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        if (chat != null) {
          return RouteUtils.createMainLayoutRoute(
            child: messaging.ChatScreen(chat: chat),
          );
        }
        return RouteUtils.createNotFoundRoute('Chat not found');

      case core.AppRoutes.messagingUserChat:
        final args = settings.arguments as Map<String, dynamic>?;
        final userId = args?['userId'] as String?;
        if (userId != null && userId.isNotEmpty) {
          return RouteUtils.createMainLayoutRoute(
            child: _UserChatLoader(userId: userId),
          );
        }
        return RouteUtils.createNotFoundRoute('User chat not found');

      case core.AppRoutes.messagingThread:
        final args = settings.arguments as Map<String, dynamic>?;
        final chat = args?['chat'] as messaging.ChatModel?;
        final threadId = args?['threadId'] as String?;
        if (chat != null && threadId != null) {
          return RouteUtils.createMainLayoutRoute(
            child: messaging.MessageThreadViewScreen(
              chat: chat,
              threadId: threadId,
            ),
          );
        }
        return RouteUtils.createNotFoundRoute('Thread not found');

      default:
        return RouteUtils.createNotFoundRoute('Messaging feature');
    }
  }
}

class _UserChatLoader extends StatefulWidget {
  const _UserChatLoader({required this.userId});
  final String userId;

  @override
  State<_UserChatLoader> createState() => _UserChatLoaderState();
}

class _UserChatLoaderState extends State<_UserChatLoader> {
  @override
  void initState() {
    super.initState();
    _navigateToChat();
  }

  Future<void> _navigateToChat() async {
    try {
      await messaging.MessagingNavigationHelper.navigateToUserChat(
        context,
        widget.userId,
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating chat: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}
