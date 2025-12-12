import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final chatService = Provider.of<ChatService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search messages...',
            border: InputBorder.none,
          ),
          onChanged: (val) => setState(() => _query = val),
        ),
      ),
      body: StreamBuilder<List<MessageModel>>(
        stream: chatService.getMessagesStream(widget.chatId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'messaging_chat_search_message_no_messages_found'.tr(),
              ),
            );
          }
          final filtered = snapshot.data!
              .where(
                (m) => m.content.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();
          if (filtered.isEmpty) {
            return Center(
              child: Text('messaging_chat_search_text_no_results'.tr()),
            );
          }
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) => ListTile(
              title: Text(filtered[index].content),
              subtitle: Text(filtered[index].senderId),
              trailing: Text(
                filtered[index].timestamp.toLocal().toString().substring(0, 16),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
          );
        },
      ),
    );
  }
}
