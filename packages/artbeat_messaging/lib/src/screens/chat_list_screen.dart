import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show EnhancedUniversalHeader, ArtbeatColors, ArtbeatGradientBackground;
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import '../widgets/chat_list_tile.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight + 4),
          child: ArtbeatGradientBackground(
            addShadow: true,
            child: EnhancedUniversalHeader(
              title: 'Messages',
              showLogo: false,
              backgroundColor: Colors.transparent,
              // Removed foregroundColor to use deep purple default
              elevation: 0,
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => _showSearchDialog(context),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: () {
                    _showChatOptions(context);
                  },
                ),
              ],
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
          child: StreamBuilder<List<ChatModel>>(
            stream: chatService.getNonArchivedChatsStream(),
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
                        'Error loading chats',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () => chatService.refresh(),
                        icon: const Icon(Icons.refresh),
                        label: Text('error_try_again'.tr()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.error,
                          foregroundColor: theme.colorScheme.onError,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                        width: 60,
                        height: 60,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            ArtbeatColors.primaryPurple,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loading conversations...',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: ArtbeatColors.primaryPurple,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final chats = snapshot.data!;

              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.1,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: ArtbeatColors.primaryPurple,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No messages yet',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          'Start a conversation with fellow artists and connect with the creative community',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: ArtbeatColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => _navigateToNewChat(context),
                        icon: const Icon(Icons.add),
                        label: Text(
                          'messaging_chat_list_message_new_message'.tr(),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ArtbeatColors.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: ListView.builder(
                  key: ValueKey<int>(chats.length),
                  padding: const EdgeInsets.only(top: kToolbarHeight + 16),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: ChatListTile(
                        chat: chat,
                        onTap: () => _navigateToChat(context, chat),
                        heroTagPrefix: 'chat_main',
                        onArchive: () => _archiveChat(context, chat),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _navigateToNewChat(context),
          icon: const Icon(Icons.chat),
          label: Text('messaging_chat_list_text_new_chat'.tr()),
          backgroundColor: ArtbeatColors.primaryPurple,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  void _navigateToNewChat(BuildContext context) {
    Navigator.pushNamed(context, '/messaging/new');
  }

  void _navigateToChat(BuildContext context, ChatModel chat) {
    Navigator.pushNamed(context, '/messaging/chat', arguments: {'chat': chat});
  }

  Future<void> _archiveChat(BuildContext context, ChatModel chat) async {
    final chatService = Provider.of<ChatService>(context, listen: false);

    try {
      await chatService.archiveChat(chat.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              chat.isGroup
                  ? 'Group "${chat.groupName ?? 'chat'}" archived'
                  : 'Chat archived',
            ),
            backgroundColor: ArtbeatColors.primaryPurple,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () async {
                try {
                  await chatService.unarchiveChat(chat.id);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'messaging_chat_list_error_failed_to_restore'.tr(),
                        ),
                        backgroundColor: ArtbeatColors.error,
                      ),
                    );
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('messaging_chat_list_error_failed_to_archive'.tr()),
            backgroundColor: ArtbeatColors.error,
          ),
        );
      }
    }
  }

  void _showSearchDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => _ChatSearchDialog(),
    );
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.group_add),
              title: Text('messaging_chat_list_text_new_group'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/messaging/group/new');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('messaging_chat_list_text_chat_settings'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/messaging/settings');
              },
            ),
          ],
        );
      },
    );
  }
}

class _ChatSearchDialog extends StatefulWidget {
  @override
  _ChatSearchDialogState createState() => _ChatSearchDialogState();
}

class _ChatSearchDialogState extends State<_ChatSearchDialog> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Removed unused methods

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search chats...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_searchQuery.isNotEmpty)
              Flexible(
                child: Consumer<ChatService>(
                  builder: (context, chatService, child) {
                    return FutureBuilder<List<ChatModel>>(
                      future: chatService.searchChats(_searchQuery),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error searching chats',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          );
                        }

                        final results = snapshot.data ?? [];

                        if (results.isEmpty) {
                          return Center(
                            child: Text(
                              'No chats found',
                              style: theme.textTheme.bodyLarge,
                            ),
                          );
                        }

                        return ListView.builder(
                          shrinkWrap: true,
                          itemCount: results.length,
                          itemBuilder: (context, index) {
                            final chat = results[index];
                            return ChatListTile(
                              chat: chat,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/messaging/chat',
                                  arguments: {'chat': chat},
                                );
                              },
                              heroTagPrefix: 'chat_search',
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
