import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class GroupChatScreen extends StatelessWidget {
  const GroupChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatModel>>(
      stream: ChatService().getChatStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'messaging_enhanced_messaging_dashboard_error_error_snapshoterror'
                  .tr(),
            ),
          );
        }

        final chats =
            snapshot.data?.where((chat) => chat.isGroup).toList() ?? [];

        if (chats.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.group_outlined, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'No Group Chats',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Start a group chat to collaborate with artists',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/messaging/group/new'),
                  icon: const Icon(Icons.add),
                  label: Text(
                    'messaging_group_chat_text_create_group_chat'.tr(),
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: chats.length,
          itemBuilder: (context, index) {
            final chat = chats[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    chat.groupImage != null && chat.groupImage!.isNotEmpty
                    ? NetworkImage(chat.groupImage!)
                    : null,
                child: chat.groupImage == null || chat.groupImage!.isEmpty
                    ? const Icon(Icons.group, size: 32)
                    : null,
              ),
              title: Text(chat.groupName ?? 'Unnamed Group'),
              subtitle: Text(chat.lastMessage?.content ?? 'No messages yet'),
              trailing: chat.unreadCount > 0
                  ? Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${chat.unreadCount}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    )
                  : null,
              onTap: () => Navigator.pushNamed(
                context,
                '/messaging/chat',
                arguments: {'chat': chat},
              ),
            );
          },
        );
      },
    );
  }
}
