import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../models/message_reaction_model.dart';
import '../services/message_reaction_service.dart';
import 'custom_emoji_picker.dart';

/// Widget for displaying message reactions and handling user interactions
class MessageReactionsWidget extends StatefulWidget {
  final String messageId;
  final String chatId;
  final bool showAddReaction;
  final VoidCallback? onReactionAdded;

  const MessageReactionsWidget({
    super.key,
    required this.messageId,
    required this.chatId,
    this.showAddReaction = true,
    this.onReactionAdded,
  });

  @override
  State<MessageReactionsWidget> createState() => _MessageReactionsWidgetState();
}

class _MessageReactionsWidgetState extends State<MessageReactionsWidget> {
  late MessageReactionService _reactionService;

  @override
  void initState() {
    super.initState();
    _reactionService = context.read<MessageReactionService>();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MessageReactionsSummary>(
      stream: _reactionService.streamMessageReactionsSummary(
        messageId: widget.messageId,
        chatId: widget.chatId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.hasReactions) {
          return widget.showAddReaction
              ? _buildAddReactionButton()
              : const SizedBox.shrink();
        }

        final summary = snapshot.data!;
        return _buildReactionsDisplay(summary);
      },
    );
  }

  Widget _buildReactionsDisplay(MessageReactionsSummary summary) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          // Display existing reactions
          ...summary.reactionCounts.entries.map((entry) {
            final reactionType = entry.key;
            final count = entry.value;
            final emoji = ReactionTypes.getEmoji(reactionType);

            return _buildReactionChip(
              emoji: emoji,
              count: count,
              reactionType: reactionType,
              isSelected: _isCurrentUserReacted(summary, reactionType),
            );
          }),

          // Add reaction button
          if (widget.showAddReaction) _buildAddReactionButton(),
        ],
      ),
    );
  }

  Widget _buildReactionChip({
    required String emoji,
    required int count,
    required String reactionType,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () => _toggleReaction(reactionType),
      onLongPress: () => _showReactionDetails(reactionType),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddReactionButton() {
    return GestureDetector(
      onTap: _showReactionPicker,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.add_reaction_outlined,
          size: 16,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  bool _isCurrentUserReacted(
    MessageReactionsSummary summary,
    String reactionType,
  ) {
    try {
      final userId = _reactionService.currentUserId;
      return summary.hasUserReacted(userId, reactionType);
    } catch (e) {
      return false;
    }
  }

  void _toggleReaction(String reactionType) async {
    try {
      await _reactionService.toggleReaction(
        messageId: widget.messageId,
        chatId: widget.chatId,
        reactionType: reactionType,
      );

      widget.onReactionAdded?.call();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('messaging_error_toggle_reaction'.tr().replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  void _showReactionPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ReactionPickerBottomSheet(
        messageId: widget.messageId,
        chatId: widget.chatId,
        onReactionSelected: (reactionType) {
          Navigator.pop(context);
          _toggleReaction(reactionType);
        },
      ),
    );
  }

  void _showReactionDetails(String reactionType) async {
    final summary = await _reactionService.getMessageReactionsSummary(
      messageId: widget.messageId,
      chatId: widget.chatId,
    );

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (context) => _ReactionDetailsBottomSheet(
        reactionType: reactionType,
        reactions: summary.getReactions(reactionType),
        emoji: ReactionTypes.getEmoji(reactionType),
      ),
    );
  }
}

/// Bottom sheet for selecting reactions
class _ReactionPickerBottomSheet extends StatelessWidget {
  final String messageId;
  final String chatId;
  final void Function(String) onReactionSelected;

  const _ReactionPickerBottomSheet({
    required this.messageId,
    required this.chatId,
    required this.onReactionSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Choose a reaction',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          // Quick reactions grid
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: ReactionTypes.allTypes
                .where((type) => type != ReactionTypes.emoji)
                .map((reactionType) {
                  final emoji = ReactionTypes.getEmoji(reactionType);
                  return GestureDetector(
                    onTap: () => onReactionSelected(reactionType),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                })
                .toList(),
          ),

          const SizedBox(height: 20),

          // Custom emoji button
          GestureDetector(
            onTap: () {
              Navigator.pop(context); // Close current bottom sheet
              _showCustomEmojiPicker(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_emotions_outlined),
                  const SizedBox(width: 8),
                  Text('messaging_reactions_more_emojis'.tr()),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _showCustomEmojiPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CustomEmojiPicker(
        onEmojiSelected: (emoji) {
          Navigator.pop(context);
          onReactionSelected(emoji);
        },
        onClose: () => Navigator.pop(context),
      ),
    );
  }
}

/// Bottom sheet showing who reacted with a specific reaction
class _ReactionDetailsBottomSheet extends StatelessWidget {
  final String reactionType;
  final List<MessageReactionModel> reactions;
  final String emoji;

  const _ReactionDetailsBottomSheet({
    required this.reactionType,
    required this.reactions,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(
                '${reactions.length} ${reactions.length == 1 ? 'person' : 'people'}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Users list
          if (reactions.isEmpty)
            Text('messaging_reactions_no_reactions_yet'.tr())
          else
            ...reactions.map(
              (reaction) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: reaction.userAvatar.isNotEmpty
                          ? NetworkImage(reaction.userAvatar)
                          : null,
                      child: reaction.userAvatar.isEmpty
                          ? const Icon(Icons.person, size: 20)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        reaction.userName.isNotEmpty
                            ? reaction.userName
                            : 'Unknown User',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    Text(
                      _formatReactionTime(reaction.createdAt),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  String _formatReactionTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
