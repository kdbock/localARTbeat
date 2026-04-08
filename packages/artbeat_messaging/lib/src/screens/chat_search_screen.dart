import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show GlassCard, HudTopBar, MainLayout, WorldBackground;
import '../models/message_model.dart';
import '../services/chat_service.dart';

class ChatSearchScreen extends StatefulWidget {
  final String chatId;
  const ChatSearchScreen({Key? key, required this.chatId}) : super(key: key);

  @override
  State<ChatSearchScreen> createState() => _ChatSearchScreenState();
}

class _ChatSearchScreenState extends State<ChatSearchScreen> {
  String _query = '';
  final TextEditingController _queryController = TextEditingController();

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    return MainLayout(
      currentIndex: -1,
      appBar: HudTopBar(
        title: 'messaging_search_title'.tr(),
        subtitle: '',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
      ),
      child: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              GlassCard(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _queryController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        cursorColor: const Color(0xFF22D3EE),
                        decoration: const InputDecoration(
                          hintText: 'Search messages...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                        onChanged: (val) => setState(() => _query = val.trim()),
                      ),
                    ),
                    if (_queryController.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _queryController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<MessageModel>>(
                  stream: chatService.getMessagesStream(widget.chatId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'messaging_chat_search_message_no_messages_found'
                              .tr(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    final filtered = snapshot.data!
                        .where(
                          (m) => m.content.toLowerCase().contains(
                            _query.toLowerCase(),
                          ),
                        )
                        .toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'messaging_chat_search_text_no_results'.tr(),
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final message = filtered[index];
                        return GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.content,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      message.senderId,
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                message.timestamp
                                    .toLocal()
                                    .toString()
                                    .substring(0, 16),
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
