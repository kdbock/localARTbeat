import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/chat_service.dart';
import '../models/message_model.dart';

/// Screen for displaying starred messages
class StarredMessagesScreen extends StatefulWidget {
  const StarredMessagesScreen({super.key});

  @override
  State<StarredMessagesScreen> createState() => _StarredMessagesScreenState();
}

class _StarredMessagesScreenState extends State<StarredMessagesScreen> {
  final ChatService _chatService = ChatService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('messaging_starred_messages_message_starred_messages'.tr()),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<MessageModel>>(
        stream: _chatService.getStarredMessagesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading starred messages',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final starredMessages = snapshot.data ?? [];

          if (starredMessages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_border, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No starred messages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Long press on any message and tap the star icon to add it here',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: starredMessages.length,
            itemBuilder: (context, index) {
              final message = starredMessages[index];
              return _StarredMessageTile(
                message: message,
                onTap: () => _navigateToMessage(message),
                onUnstar: () => _unstarMessage(message),
              );
            },
          );
        },
      ),
    );
  }

  void _navigateToMessage(MessageModel message) {
    // In a real implementation, you'd need to find which chat contains this message
    // For now, we'll show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'messaging_starred_messages_message_navigate_to_message'.tr(),
        ),
      ),
    );
  }

  Future<void> _unstarMessage(MessageModel message) async {
    try {
      // Note: This requires implementing getChatIdForMessage in ChatService
      // or storing chatId in message metadata
      // await _chatService.toggleMessageStar(chatId, message.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'messaging_starred_messages_message_message_unstarred'.tr(),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('messaging_starred_messages_error_error_e'.tr()),
        ),
      );
    }
  }
}

class _StarredMessageTile extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onTap;
  final VoidCallback onUnstar;

  const _StarredMessageTile({
    required this.message,
    required this.onTap,
    required this.onUnstar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.amber,
          child: Icon(Icons.star, color: Colors.white, size: 20),
        ),
        title: Text(
          message.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              _getMessageTypeLabel(message.type),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.blue[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _formatTimestamp(message.timestamp),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'unstar',
              child: Row(
                children: [
                  const Icon(Icons.star_border),
                  const SizedBox(width: 8),
                  Text('messaging_starred_messages_text_remove_star'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'navigate',
              child: Row(
                children: [
                  const Icon(Icons.open_in_new),
                  const SizedBox(width: 8),
                  Text('messaging_starred_messages_message_go_to_message'.tr()),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            switch (value) {
              case 'unstar':
                onUnstar();
                break;
              case 'navigate':
                onTap();
                break;
            }
          },
        ),
        onTap: onTap,
      ),
    );
  }

  String _getMessageTypeLabel(MessageType type) {
    switch (type) {
      case MessageType.text:
        return 'Text Message';
      case MessageType.image:
        return 'Image';
      case MessageType.voice:
        return 'Voice Message';
      case MessageType.video:
        return 'Video';
      case MessageType.file:
        return 'File';
      case MessageType.location:
        return 'Location';
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} year${(difference.inDays / 365).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} month${(difference.inDays / 30).floor() == 1 ? '' : 's'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
