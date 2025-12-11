import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtbeatColors;
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final VoidCallback onTap;
  final String? heroTagPrefix;
  final VoidCallback? onArchive;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.onTap,
    this.heroTagPrefix,
    this.onArchive,
  });

  void _navigateToChat(BuildContext context) {
    Navigator.pushNamed(context, '/messaging/chat', arguments: {'chat': chat});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.jm();

    return Hero(
      tag: '${heroTagPrefix ?? 'chat'}_${chat.id}',
      child: Dismissible(
        key: Key('chat_${chat.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: ArtbeatColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.archive_outlined, color: Colors.white, size: 28),
              SizedBox(height: 4),
              Text(
                'messaging_button_archive'.tr(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (direction) async {
          return _showArchiveConfirmation(context);
        },
        onDismissed: (direction) {
          if (onArchive != null) {
            onArchive!();
          }
        },
        child: Card(
          elevation: chat.unreadCount > 0 ? 3 : 1,
          shadowColor: chat.unreadCount > 0
              ? ArtbeatColors.primaryPurple.withValues(alpha: 0.3)
              : Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: chat.unreadCount > 0
                  ? ArtbeatColors.primaryPurple.withValues(alpha: 0.2)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => _navigateToChat(context),
            borderRadius: BorderRadius.circular(16),
            child: _buildListTile(context, theme, dateFormat),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showArchiveConfirmation(BuildContext context) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('messaging_archive_chat_title'.tr()),
          content: Text(
            chat.isGroup
                ? 'messaging_archive_group_confirm'.tr().replaceAll('{groupName}', chat.groupName ?? 'this group')
                : 'messaging_archive_chat_confirm'.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('messaging_button_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: ArtbeatColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('messaging_button_archive'.tr()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildListTile(
    BuildContext context,
    ThemeData theme,
    DateFormat dateFormat,
  ) {
    final chatService = Provider.of<ChatService>(context, listen: false);

    return FutureBuilder<String?>(
      future: _getChatName(chatService),
      builder: (context, snapshot) {
        final chatName = snapshot.data ?? 'Loading...';
        final hasUnread = chat.unreadCount > 0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Row(
            children: [
              const SizedBox(width: 12),
              _buildAvatar(context, chatName, hasUnread),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chatName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: hasUnread
                                  ? ArtbeatColors.textPrimary
                                  : ArtbeatColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (chat.lastMessage != null)
                          Text(
                            dateFormat.format(
                              chat.lastMessage?.timestamp ?? DateTime.now(),
                            ),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: hasUnread
                                  ? ArtbeatColors.primaryPurple
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            chat.lastMessage?.content ?? 'No messages yet',
                            style: TextStyle(
                              color: hasUnread
                                  ? ArtbeatColors.textPrimary
                                  : Colors.grey.shade600,
                              fontSize: 14,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: ArtbeatColors.primaryPurple,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: ArtbeatColors.primaryPurple.withValues(
                                    alpha: 0.3,
                                  ),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              chat.unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context, String chatName, bool hasUnread) {
    return FutureBuilder<String?>(
      future: _getChatImage(context),
      builder: (context, snapshot) {
        final imageUrl = snapshot.data;

        return Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: hasUnread
                        ? ArtbeatColors.primaryPurple.withValues(alpha: 0.3)
                        : Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                backgroundColor: _getAvatarColor(chatName),
                radius: 28,
                backgroundImage: imageUrl != null && imageUrl.isNotEmpty
                    ? NetworkImage(imageUrl)
                    : null,
                child: imageUrl == null || imageUrl.isEmpty
                    ? Text(
                        _getInitials(chatName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
            ),
            if (chat.isGroup)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 12),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      ArtbeatColors.primaryPurple,
      ArtbeatColors.primaryGreen,
      ArtbeatColors.secondaryTeal,
      ArtbeatColors.accentYellow,
      ArtbeatColors.error,
      ArtbeatColors.info,
      ArtbeatColors.warning,
    ];

    // Generate a consistent color based on the name
    final index = name.isNotEmpty
        ? name.codeUnits.reduce((a, b) => a + b) % colors.length
        : 0;

    return colors[index];
  }

  Future<String> _getChatName(ChatService chatService) async {
    if (chat.isGroup) {
      return chat.groupName ?? 'Group Chat';
    }
    final currentUserId = chatService.currentUserIdSafe;
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => chat.participantIds.first,
    );

    // First try to get from chat participants
    final String? name = chat.getParticipantDisplayName(otherParticipantId);
    if (name != null && name != 'Unknown User') {
      return name;
    }

    // If not found or is "Unknown User", fetch from ChatService
    return await chatService.getUserDisplayName(otherParticipantId) ??
        'Unknown User';
  }

  Future<String?> _getChatImage(BuildContext context) async {
    final chatService = Provider.of<ChatService>(context, listen: false);

    if (chat.isGroup) {
      return chat.groupImage;
    }

    final currentUserId = chatService.currentUserIdSafe;
    final otherParticipantId = chat.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => chat.participantIds.first,
    );

    // First try to get from chat participants
    final String? photoUrl = chat.getParticipantPhotoUrl(otherParticipantId);
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return photoUrl;
    }

    // If not found, fetch from ChatService
    return chatService.getUserPhotoUrl(otherParticipantId);
  }

  String _getInitials(String name) {
    if (chat.isGroup) {
      return chat.groupName?.isNotEmpty == true
          ? chat.groupName![0].toUpperCase()
          : 'G';
    }

    if (name.isEmpty) return '?';

    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }
}
