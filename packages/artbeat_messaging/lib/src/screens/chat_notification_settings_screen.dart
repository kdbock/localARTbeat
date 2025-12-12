import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatNotificationSettingsScreen extends StatefulWidget {
  final String chatId;
  const ChatNotificationSettingsScreen({Key? key, required this.chatId})
    : super(key: key);

  @override
  State<ChatNotificationSettingsScreen> createState() =>
      _ChatNotificationSettingsScreenState();
}

class _ChatNotificationSettingsScreenState
    extends State<ChatNotificationSettingsScreen> {
  bool _muted = false;
  bool _showPreviews = true;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    final doc = await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('notificationSettings')
        .doc(userId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _muted = (data['muted'] as bool?) ?? false;
        _showPreviews = (data['showPreviews'] as bool?) ?? true;
      });
    }
  }

  Future<void> _saveSettings() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore
        .collection('chats')
        .doc(widget.chatId)
        .collection('notificationSettings')
        .doc(userId)
        .set({
          'muted': _muted,
          'showPreviews': _showPreviews,
        }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'messaging_chat_notification_settings_text_notification_settings'
              .tr(),
        ),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: Text(
              'messaging_chat_notification_settings_text_mute_notifications'
                  .tr(),
            ),
            value: _muted,
            onChanged: (val) async {
              setState(() => _muted = val);
              await _saveSettings();
            },
          ),
          SwitchListTile(
            title: Text(
              'messaging_chat_notification_settings_message_show_message_previews'
                  .tr(),
            ),
            value: _showPreviews,
            onChanged: (val) async {
              setState(() => _showPreviews = val);
              await _saveSettings();
            },
          ),
        ],
      ),
    );
  }
}
