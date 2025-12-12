import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/message_model.dart';
import '../models/message_thread_model.dart';
import '../models/chat_model.dart';
import '../models/message.dart';
import '../services/chat_service.dart';
import '../widgets/message_bubble.dart';
import '../utils/message_converter.dart';

class MessageThreadViewScreen extends StatefulWidget {
  final ChatModel chat;
  final String threadId;

  const MessageThreadViewScreen({
    super.key,
    required this.chat,
    required this.threadId,
  });

  @override
  State<MessageThreadViewScreen> createState() =>
      _MessageThreadViewScreenState();
}

class _MessageThreadViewScreenState extends State<MessageThreadViewScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late ChatService _chatService;
  List<MessageModel> _threadMessages = [];
  MessageThreadModel? _thread;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _chatService = context.read<ChatService>();
    _loadThread();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() => _isLoading = true);

    try {
      final thread = await _chatService.getMessageThread(
        widget.chat.id,
        widget.threadId,
      );
      final messages = await _chatService.getThreadMessages(
        widget.chat.id,
        widget.threadId,
      );

      setState(() {
        _thread = thread;
        _threadMessages = messages;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading thread: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendReply() async {
    final replyText = _messageController.text.trim();
    if (replyText.isEmpty) return;

    try {
      await _chatService.sendReplyMessage(
        widget.chat.id,
        replyText,
        widget.threadId,
      );

      _messageController.clear();
      await _loadThread(); // Refresh thread

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      AppLogger.error('Error sending reply: $e');
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            'messaging_message_thread_view_error_failed_to_send'.tr(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _thread != null ? '${_thread!.replyCount} replies' : 'Thread',
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Expanded(child: _buildMessagesList()),
                  _buildMessageInput(),
                ],
              ),
      ),
    );
  }

  Widget _buildMessagesList() {
    if (_threadMessages.isEmpty) {
      return Center(
        child: Text(
          'messaging_message_thread_view_message_no_messages_in'.tr(),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _threadMessages.length,
      itemBuilder: (context, index) {
        final message = _threadMessages[index];
        final isFirstInThread = index == 0;
        final isCurrentUser = message.senderId == _chatService.currentUserId;

        return Column(
          children: [
            if (isFirstInThread)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border(
                    left: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                      width: 3,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Original Message',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<Message>(
                      future: message.toMessageAsync(
                        widget.chat.id,
                        chat: widget.chat,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return MessageBubble(
                            message: snapshot.data!,
                            isCurrentUser: isCurrentUser,
                            chatId: widget.chat.id,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              )
            else
              Container(
                margin: const EdgeInsets.only(left: 32, bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 2,
                      height: 40,
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      margin: const EdgeInsets.only(right: 16),
                    ),
                    Expanded(
                      child: FutureBuilder<Message>(
                        future: message.toMessageAsync(
                          widget.chat.id,
                          chat: widget.chat,
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            return MessageBubble(
                              message: snapshot.data!,
                              isCurrentUser: isCurrentUser,
                              chatId: widget.chat.id,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Reply to thread...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendReply(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendReply,
            icon: Icon(
              Icons.send,
              color: Theme.of(context).colorScheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              padding: const EdgeInsets.all(12),
            ),
          ),
        ],
      ),
    );
  }
}
