import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/studio_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/widgets.dart';

class _StudioChatPalette {
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0xB3FFFFFF);
  static const Color textTertiary = Color(0x73FFFFFF);
  static const Color accentPurple = Color(0xFF7C4DFF);
  static const Color accentTeal = Color(0xFF22D3EE);
  static const Color accentGreen = Color(0xFF34D399);

  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      accentPurple,
      accentTeal,
      accentGreen,
    ],
  );
}

class StudioChatScreen extends StatefulWidget {
  final String studioId;
  final StudioModel? studio;

  const StudioChatScreen({super.key, required this.studioId, this.studio});

  @override
  _StudioChatScreenState createState() => _StudioChatScreenState();
}

class _StudioChatScreenState extends State<StudioChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _timestampFormatter = DateFormat('MMM d • HH:mm');

  StreamSubscription<QuerySnapshot>? _onlineSubscription;

  StudioModel? _studio;
  bool _isLoading = true;
  Map<String, bool> _onlineUsers = {};

  @override
  void initState() {
    super.initState();
    _loadStudioDetails();
    _setupOnlineStatus();
  }

  @override
  void dispose() {
    _onlineSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadStudioDetails() async {
    if (widget.studio != null) {
      setState(() {
        _studio = widget.studio;
        _isLoading = false;
      });
      return;
    }

    try {
      final studios = await _firestoreService.getStudios();
      final studio = studios.firstWhere((s) => s.id == widget.studioId);
      if (!mounted) return;
      setState(() {
        _studio = studio;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_studio_chat.error_loading_studio'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  void _setupOnlineStatus() {
    final user = _auth.currentUser;
    if (user == null) return;

    final studioDoc = _firestore.collection('studios').doc(widget.studioId);
    studioDoc.collection('online_users').doc(user.uid).set({
          'online': true,
          'lastSeen': FieldValue.serverTimestamp(),
        });

    _onlineSubscription = studioDoc
        .collection('online_users')
        .snapshots()
        .listen((snapshot) {
      final onlineUsers = <String, bool>{};
      for (final doc in snapshot.docs) {
        onlineUsers[doc.id] = (doc.data()['online'] as bool?) ?? false;
      }
      if (mounted) {
        setState(() => _onlineUsers = onlineUsers);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('studios')
          .doc(widget.studioId)
          .collection('messages')
          .add({
        'text': text,
        'senderId': user.uid,
        'senderName':
            user.displayName ?? 'community_studio_chat.unknown_sender'.tr(),
        'timestamp': FieldValue.serverTimestamp(),
        'messageType': 'text',
      });
      _messageController.clear();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'community_studio_chat.error_sending_message'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final studioName = _studio?.name.trim().isNotEmpty == true
        ? _studio!.name
        : 'community_studio_chat.generic_studio'.tr();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'community_studio_chat.app_bar'
            .tr(namedArgs: {'studio': studioName}),
        glassBackground: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FittedBox(child: _buildOnlineBadge()),
          ),
        ], subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? _buildLoadingState()
              : _buildChatBody(context, studioName),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(
          _StudioChatPalette.accentTeal,
        ),
      ),
    );
  }

  Widget _buildChatBody(BuildContext context, String studioName) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          if (_studio != null) _buildStudioHero(studioName),
          if (_studio != null) const SizedBox(height: 16),
          Expanded(child: _buildMessagesCard()),
          const SizedBox(height: 16),
          _buildComposer(context),
          SizedBox(height: bottomInset + 8),
        ],
      ),
    );
  }

  Widget _buildOnlineBadge() {
    final onlineCount =
        _onlineUsers.values.where((isOnline) => isOnline).length.toString();

    return GradientBadge(
      text: 'community_studio_chat.online_count'
          .tr(namedArgs: {'count': onlineCount}),
      icon: Icons.bolt_rounded,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  Widget _buildStudioHero(String studioName) {
    final memberCount = _studio?.memberList.length ?? 0;
    final description = _studio?.description.trim().isNotEmpty == true
        ? _studio!.description.trim()
        : 'community_studio_chat.description_fallback'.tr();
    final privacyType = (_studio?.privacyType.toLowerCase() ?? 'public') ==
            'private'
        ? 'community_studio_chat.privacy_private'
        : 'community_studio_chat.privacy_public';

    return GlassCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildStudioMonogram(studioName),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      studioName,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: _StudioChatPalette.textPrimary,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'community_studio_chat.members_label'.tr(
                        namedArgs: {'count': memberCount.toString()},
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _StudioChatPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _StudioChatPalette.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GradientBadge(
                text: 'community_studio_chat.live_badge'.tr(),
                icon: Icons.wifi_tethering,
              ),
              GradientBadge(
                text: privacyType.tr(),
                icon: (_studio?.privacyType.toLowerCase() ?? 'public') ==
                        'private'
                    ? Icons.lock
                    : Icons.explore,
              ),
              GradientBadge(
                text: 'community_studio_chat.online_count'.tr(
                  namedArgs: {
                    'count': _onlineUsers.values
                        .where((isOnline) => isOnline)
                        .length
                        .toString(),
                  },
                ),
                icon: Icons.bolt,
              ),
            ],
          ),
          if (_studio?.tags.isNotEmpty == true) ...[
            const SizedBox(height: 16),
            Text(
              'community_studio_chat.tags_label'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _StudioChatPalette.textTertiary,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _studio!.tags.take(6).map((tag) {
                return GradientBadge(
                  text: '#$tag',
                  icon: Icons.tag,
                  fontSize: 10,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStudioMonogram(String studioName) {
    final letter = studioName.trim().isNotEmpty
        ? studioName.trim()[0].toUpperCase()
        : 'A';

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _StudioChatPalette.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: _StudioChatPalette.accentPurple.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMessagesCard() {
    return GlassCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      child: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('studios')
            .doc(widget.studioId)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildSectionLoadingState();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final messages = snapshot.data!.docs;

          return ListView.builder(
            controller: _scrollController,
            reverse: true,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _buildMessageBubble(messages[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionLoadingState() {
    return const SizedBox(
      height: 200,
      child: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            _StudioChatPalette.accentPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'community_studio_chat.empty_title'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: _StudioChatPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'community_studio_chat.empty_subtitle'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _StudioChatPalette.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(QueryDocumentSnapshot<Object?> messageDoc) {
    final data = messageDoc.data() as Map<String, dynamic>? ?? {};
    final isCurrentUser = data['senderId'] == _auth.currentUser?.uid;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final senderName = (data['senderName'] as String?)?.trim();
    final resolvedSender = senderName?.isNotEmpty == true
        ? senderName!
        : 'community_studio_chat.unknown_sender'.tr();

    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
      bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
    );

    return Align(
      alignment:
          isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsetsDirectional.only(
          top: 8,
          bottom: 8,
          start: isCurrentUser ? 64 : 0,
          end: isCurrentUser ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: isCurrentUser ? _StudioChatPalette.primaryGradient : null,
          color: isCurrentUser ? null : Colors.white.withValues(alpha: 0.08),
          borderRadius: borderRadius,
          border: Border.all(
            color: isCurrentUser
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: isCurrentUser
              ? [
                  BoxShadow(
                    color:
                        _StudioChatPalette.accentPurple.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser) ...[
              Text(
                resolvedSender,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _StudioChatPalette.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              (data['text'] as String?) ?? '',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isCurrentUser ? Colors.white : _StudioChatPalette.textPrimary,
                height: 1.4,
              ),
            ),
            if (timestamp != null) ...[
              const SizedBox(height: 8),
              Text(
                _formatTimestamp(timestamp),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isCurrentUser
                      ? Colors.white.withValues(alpha: 0.8)
                      : _StudioChatPalette.textTertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: GlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: GlassTextField(
                controller: _messageController,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                hintText: 'community_studio_chat.input_hint'.tr(),
                onSubmitted: (_) => _sendMessage(),
                decoration: GlassInputDecoration.glass(
                  hintText: 'community_studio_chat.input_hint'.tr(),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _messageController,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty;
                return GradientCTAButton(
                  width: 128,
                  height: 52,
                  text: 'community_studio_chat.send_cta'.tr(),
                  icon: Icons.send_rounded,
                  onPressed: canSend ? _sendMessage : null,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      final formatted = _timestampFormatter.format(timestamp);
      return 'community_studio_chat.full_timestamp'
          .tr(namedArgs: {'date': formatted});
    }

    if (difference.inHours > 0) {
      return 'community_studio_chat.hours_ago'
          .tr(namedArgs: {'hours': difference.inHours.toString()});
    }

    if (difference.inMinutes > 0) {
      return 'community_studio_chat.minutes_ago'
          .tr(namedArgs: {'minutes': difference.inMinutes.toString()});
    }

    return 'community_studio_chat.just_now'.tr();
  }
}
