import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show EnhancedUniversalHeader, ArtbeatColors, ArtbeatGradientBackground;
import 'package:geolocator/geolocator.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/chat_service.dart';
import '../services/voice_recording_service.dart';
import '../widgets/voice_recorder_widget.dart';
import '../widgets/voice_message_bubble.dart';
import '../widgets/smart_replies_widget.dart';
import '../widgets/message_interactions.dart';

class ChatScreen extends StatefulWidget {
  final ChatModel chat;

  const ChatScreen({super.key, required this.chat});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isTyping = false;
  bool _isAttachmentMenuOpen = false;
  bool _showSmartReplies = false;
  MessageModel? _replyingToMessage;
  late AnimationController _animationController;

  // For typing indicator animation
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  Future<String> get _chatName async {
    final chatService = context.read<ChatService>();
    if (widget.chat.isGroup) {
      return widget.chat.groupName ?? 'Group Chat';
    }

    // Handle edge cases for participant IDs
    if (widget.chat.participantIds.isEmpty) {
      return 'Unknown User';
    }

    if (widget.chat.participantIds.length == 1) {
      // Only one participant, might be the current user
      final name = await chatService.getUserDisplayName(
        widget.chat.participantIds.first,
      );
      return name ?? 'Unknown User';
    }

    final otherParticipantId = widget.chat.participantIds.firstWhere(
      (id) => id != chatService.currentUserId,
      orElse: () => widget.chat.participantIds.first,
    );
    final name = await chatService.getUserDisplayName(otherParticipantId);
    return name ?? 'Unknown User';
  }

  Future<String?> get _chatImage async {
    final chatService = context.read<ChatService>();
    if (widget.chat.isGroup) {
      return widget.chat.groupImage;
    }

    // Handle edge cases for participant IDs
    if (widget.chat.participantIds.isEmpty) {
      return null;
    }

    if (widget.chat.participantIds.length == 1) {
      // Only one participant, might be the current user
      return chatService.getUserPhotoUrl(widget.chat.participantIds.first);
    }

    final otherParticipantId = widget.chat.participantIds.firstWhere(
      (id) => id != chatService.currentUserId,
      orElse: () => widget.chat.participantIds.first,
    );
    return chatService.getUserPhotoUrl(otherParticipantId);
  }

  @override
  void initState() {
    super.initState();
    _setupTypingListener();

    // Initialize animation controllers
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _typingAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _typingAnimation = CurvedAnimation(
      parent: _typingAnimationController,
      curve: Curves.easeInOut,
    );

    // Mark messages as read when opening the chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatService = Provider.of<ChatService>(context, listen: false);
      chatService.markChatAsRead(widget.chat.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    _typingAnimationController.dispose();
    _clearTypingStatus();
    super.dispose();
  }

  void _setupTypingListener() {
    _messageController.addListener(() {
      final isCurrentlyTyping = _messageController.text.isNotEmpty;
      if (isCurrentlyTyping != _isTyping) {
        setState(() => _isTyping = isCurrentlyTyping);
        _updateTypingStatus(isCurrentlyTyping);
      }
    });
  }

  void _clearTypingStatus() {
    if (_isTyping) {
      _updateTypingStatus(false);
    }
  }

  void _updateTypingStatus(bool isTyping) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    final userId = chatService.currentUserId;
    chatService.updateTypingStatus(widget.chat.id, userId, isTyping);
  }

  Future<void> _handleSendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      if (_replyingToMessage != null) {
        await chatService.sendReplyMessage(
          widget.chat.id,
          text,
          _replyingToMessage!.id,
        );
        setState(() {
          _replyingToMessage = null;
        });
      } else {
        await chatService.sendMessage(widget.chat.id, text);
      }
      _messageController.clear();
      setState(() {
        _showSmartReplies = false;
      });

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_chat_error_failed_to_send'.tr()),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  void _onSmartReplySelected(String reply) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    chatService.sendMessage(widget.chat.id, reply);
    setState(() {
      _showSmartReplies = false;
    });
    _scrollToBottom();
  }

  void _onReplyToMessage(MessageModel message) {
    setState(() {
      _replyingToMessage = message;
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleImagePick() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );
    if (image == null) return;

    // ignore: use_build_context_synchronously
    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      // Show loading indicator
      _showSendingMediaIndicator();

      await chatService.sendImage(widget.chat.id, image.path);

      // Hide attachment menu if open
      if (_isAttachmentMenuOpen) {
        setState(() {
          _isAttachmentMenuOpen = false;
        });
        _animationController.reverse();
      }

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_chat_error_failed_to_send_2'.tr()),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleCameraPick() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.camera,
    );
    if (image == null) return;

    // ignore: use_build_context_synchronously
    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      // Show loading indicator
      _showSendingMediaIndicator();

      await chatService.sendImage(widget.chat.id, image.path);

      // Hide attachment menu if open
      if (_isAttachmentMenuOpen) {
        setState(() {
          _isAttachmentMenuOpen = false;
        });
        _animationController.reverse();
      }

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_chat_error_failed_to_send_2'.tr()),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  Future<void> _startAudioRecording() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FutureBuilder<VoiceRecordingService>(
        future: _initializeVoiceService(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text('messaging_chat_text_initializing_voice_recorder'.tr()),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to initialize voice recorder: ${snapshot.error}',
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('artwork_close_button'.tr()),
                  ),
                ],
              ),
            );
          }

          return ChangeNotifierProvider.value(
            value: snapshot.data!,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: VoiceRecorderWidget(
                onVoiceRecorded: (voiceFilePath, duration) {
                  Navigator.pop(context);
                  _handleVoiceMessage(voiceFilePath, duration);
                },
                onCancel: () {
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<VoiceRecordingService> _initializeVoiceService() async {
    final service = VoiceRecordingService();
    await service.initialize();
    return service;
  }

  Future<void> _handleVoiceMessage(
    String voiceFilePath,
    Duration duration,
  ) async {
    final chatService = Provider.of<ChatService>(context, listen: false);
    try {
      // Show sending indicator
      _showSendingMediaIndicator();

      await chatService.sendVoiceMessage(
        widget.chat.id,
        voiceFilePath,
        duration,
      );

      // Hide attachment menu if open
      if (_isAttachmentMenuOpen) {
        setState(() {
          _isAttachmentMenuOpen = false;
        });
        _animationController.reverse();
      }

      // Scroll to bottom after sending
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_chat_error_failed_to_send_7'.tr()),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  void _showEmojiPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => Container(
        height: 300,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Select Emoji',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 6,
                children:
                    [
                          '😀',
                          '😁',
                          '😂',
                          '🤣',
                          '😊',
                          '😇',
                          '😍',
                          '🤩',
                          '😘',
                          '😗',
                          '😋',
                          '😎',
                          '🤔',
                          '🤨',
                          '😐',
                          '😑',
                          '😶',
                          '🙄',
                          '😏',
                          '😣',
                          '😥',
                          '😮',
                          '🤐',
                          '😯',
                          '😴',
                          '😪',
                          '😵',
                          '🤯',
                          '🥰',
                          '🤪',
                          '👍',
                          '👎',
                          '👌',
                          '✌️',
                          '🤞',
                          '🤟',
                          '🤘',
                          '🤙',
                          '👈',
                          '👉',
                          '👆',
                          '👇',
                          '❤️',
                          '💔',
                          '💕',
                          '💖',
                          '💗',
                          '💙',
                          '💚',
                          '💛',
                          '🧡',
                          '💜',
                          '🖤',
                          '💯',
                          '🔥',
                          '⭐',
                          '🌟',
                          '💫',
                          '✨',
                          '🎉',
                        ]
                        .map(
                          (emoji) => GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                              _insertEmoji(emoji);
                            },
                            child: Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: ArtbeatColors.backgroundSecondary
                                    .withValues(alpha: 0.1),
                              ),
                              child: Center(
                                child: Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _insertEmoji(String emoji) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;

    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      emoji,
    );

    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(
      offset: selection.start + emoji.length,
    );
  }

  void _showSendingMediaIndicator() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Text('messaging_chat_text_sending_media'.tr()),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.black87,
      ),
    );
  }

  void _toggleAttachmentMenu() {
    setState(() {
      _isAttachmentMenuOpen = !_isAttachmentMenuOpen;
    });

    if (_isAttachmentMenuOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 4),
        child: ArtbeatGradientBackground(
          addShadow: true,
          child: FutureBuilder<String>(
            future: _chatName,
            builder: (context, snapshot) {
              final title = snapshot.hasError
                  ? 'Chat'
                  : snapshot.data ?? 'Loading...';
              return EnhancedUniversalHeader(
                title: title,
                showLogo: false,
                backgroundColor: Colors.transparent,
                // Removed foregroundColor to use deep purple default
                elevation: 0,
                showBackButton: true,
                onBackPressed: () => Navigator.pop(context),
                actions: [
                  FutureBuilder<String?>(
                    future: _chatImage,
                    builder: (context, imageSnapshot) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/messaging/chat-info',
                            arguments: {'chat': widget.chat},
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 18,
                            backgroundColor: ArtbeatColors.primaryPurple,
                            backgroundImage:
                                imageSnapshot.data != null &&
                                    imageSnapshot.data!.isNotEmpty
                                ? NetworkImage(imageSnapshot.data!)
                                : null,
                            child:
                                imageSnapshot.data == null ||
                                    imageSnapshot.data!.isEmpty
                                ? Text(
                                    title.isNotEmpty
                                        ? title[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: chatService.getMessagesStream(widget.chat.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 56,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading messages',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () => setState(() {}),
                              icon: const Icon(Icons.refresh),
                              label: Text('error_try_again'.tr()),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.error,
                                foregroundColor: theme.colorScheme.onError,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (!snapshot.hasData) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ArtbeatColors.primaryPurple,
                                ),
                                strokeWidth: 3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Loading messages...',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final messages = snapshot.data!;

                    // Show smart replies when there are messages from others
                    final currentUserId = chatService.currentUserId;
                    final hasMessagesFromOthers = messages.any(
                      (msg) => msg.senderId != currentUserId,
                    );
                    if (hasMessagesFromOthers && !_showSmartReplies) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _showSmartReplies = true;
                          });
                        }
                      });
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: ArtbeatColors.primaryPurple.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.chat_bubble_outline,
                                size: 48,
                                color: ArtbeatColors.primaryPurple,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No messages yet',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ArtbeatColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 40,
                              ),
                              child: Text(
                                'Start the conversation by sending a message below',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: ArtbeatColors.textSecondary,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final messageModel = messages[index];
                        final isCurrentUser =
                            messageModel.senderId == chatService.currentUserId;

                        // Check if we should show the date header
                        final showDateHeader =
                            index == messages.length - 1 ||
                            !_isSameDay(
                              messages[index].timestamp,
                              messages[index + 1].timestamp,
                            );

                        return Column(
                          children: [
                            if (showDateHeader)
                              _buildDateHeader(messageModel.timestamp),

                            // Show voice message bubble for voice messages
                            if (messageModel.type == MessageType.voice)
                              VoiceMessageBubble(
                                message: messageModel,
                                isCurrentUser: isCurrentUser,
                              )
                            else
                              InteractiveMessageBubble(
                                message: messageModel,
                                chat: widget.chat,
                                currentUserId: chatService.currentUserId,
                                chatService: chatService,
                                onReply: () => _onReplyToMessage(messageModel),
                              ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              // Typing indicator
              StreamBuilder<Map<String, bool>>(
                stream: chatService.getTypingStatusStream(widget.chat.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  final typingUsers = snapshot.data!.entries
                      .where(
                        (entry) =>
                            entry.key != chatService.currentUserId &&
                            entry.value,
                      )
                      .map((entry) => entry.key)
                      .toList();

                  if (typingUsers.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return FutureBuilder<String>(
                    future: _getTypingUserName(typingUsers.first, chatService),
                    builder: (context, nameSnapshot) {
                      final name = nameSnapshot.data ?? 'Someone';

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Text(
                              '$name is typing',
                              style: const TextStyle(
                                color: ArtbeatColors.textSecondary,
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTypingDots(),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),

              // Message input area
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Attachment menu
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: _isAttachmentMenuOpen ? 100 : 0,
                      child: SingleChildScrollView(
                        physics: const NeverScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAttachmentOption(
                                icon: Icons.image,
                                label: 'Gallery',
                                color: ArtbeatColors.primaryPurple,
                                onTap: _handleImagePick,
                              ),
                              _buildAttachmentOption(
                                icon: Icons.camera_alt,
                                label: 'Camera',
                                color: ArtbeatColors.primaryGreen,
                                onTap: _handleCameraPick,
                              ),
                              _buildAttachmentOption(
                                icon: Icons.mic,
                                label: 'Audio',
                                color: ArtbeatColors.secondaryTeal,
                                onTap: () async {
                                  // Close attachment menu first
                                  setState(() {
                                    _isAttachmentMenuOpen = false;
                                  });
                                  _animationController.reverse();

                                  // Then start audio recording
                                  await _startAudioRecording();
                                },
                              ),
                              _buildAttachmentOption(
                                icon: Icons.location_on,
                                label: 'Location',
                                color: ArtbeatColors.accentYellow,
                                onTap: () async {
                                  Navigator.pop(context);
                                  try {
                                    // Request location permission and get current position
                                    final position =
                                        await Geolocator.getCurrentPosition(
                                          locationSettings:
                                              const LocationSettings(
                                                accuracy: LocationAccuracy.high,
                                              ),
                                        );
                                    final latitude = position.latitude;
                                    final longitude = position.longitude;

                                    // Send location as a message (reuse sendMessage, but with type/location)
                                    final chatService = Provider.of<ChatService>(
                                      // ignore: use_build_context_synchronously
                                      context,
                                      listen: false,
                                    );
                                    final message = MessageModel(
                                      id: DateTime.now().millisecondsSinceEpoch
                                          .toString(),
                                      senderId: chatService.currentUserId,
                                      content: 'Location: $latitude,$longitude',
                                      timestamp: DateTime.now(),
                                      type: MessageType.location,
                                      metadata: {
                                        'latitude': latitude,
                                        'longitude': longitude,
                                      },
                                    );
                                    await chatService.sendMessage(
                                      widget.chat.id,
                                      message.content,
                                    );
                                  } catch (e) {
                                    // ignore: use_build_context_synchronously
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to share location: ${e.toString()}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Smart replies
                    SmartRepliesWidget(
                      chatId: widget.chat.id,
                      onReplySelected: _onSmartReplySelected,
                      enabled: _showSmartReplies,
                    ),

                    // Reply preview
                    if (_replyingToMessage != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: const Border(
                            left: BorderSide(
                              color: ArtbeatColors.primaryPurple,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Replying to',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ArtbeatColors.primaryPurple,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _replyingToMessage!.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              onPressed: () {
                                setState(() {
                                  _replyingToMessage = null;
                                });
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                    // Input field and buttons
                    Row(
                      children: [
                        IconButton(
                          icon: AnimatedIcon(
                            icon: AnimatedIcons.menu_close,
                            progress: _animationController,
                            color: ArtbeatColors.primaryPurple,
                          ),
                          onPressed: _toggleAttachmentMenu,
                        ),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: ArtbeatColors.primaryPurple.withValues(
                                  alpha: 0.2,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _messageController,
                                    decoration: InputDecoration(
                                      hintText: 'Type a message...',
                                      hintStyle: TextStyle(
                                        color: Colors.grey.shade500,
                                      ),
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 12,
                                          ),
                                    ),
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (_) => _handleSendMessage(),
                                    maxLines: 4,
                                    minLines: 1,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.emoji_emotions_outlined,
                                  ),
                                  color: ArtbeatColors.primaryPurple,
                                  onPressed: () {
                                    _showEmojiPicker();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: ArtbeatColors.primaryPurple,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ArtbeatColors.primaryPurple.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.send),
                            color: Colors.white,
                            onPressed: _handleSendMessage,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateHeader(DateTime timestamp) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              _formatDate(timestamp),
              style: const TextStyle(
                color: ArtbeatColors.primaryPurple,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Colors.grey, thickness: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTypingDots() {
    return SizedBox(
      width: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _typingAnimation,
            builder: (context, child) {
              final delay = index * 0.2;
              final value =
                  (_typingAnimation.value - delay).clamp(0.0, 1.0) / 0.6;
              return Transform.translate(
                offset: Offset(0, -3 * value),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: ArtbeatColors.primaryPurple,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) {
      return 'Today';
    } else if (dateToCheck == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<String> _getTypingUserName(
    String userId,
    ChatService chatService,
  ) async {
    final name = await chatService.getUserDisplayName(userId);
    return name ?? 'Someone';
  }
}
