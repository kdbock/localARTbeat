import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';

class ChatSettingsScreen extends StatefulWidget {
  final ChatModel chat;
  const ChatSettingsScreen({super.key, required this.chat});

  @override
  State<ChatSettingsScreen> createState() => _ChatSettingsScreenState();
}

class _ChatSettingsScreenState extends State<ChatSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _mediaAutoDownload = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled =
          prefs.getBool('chat_notifications_enabled') ?? true;
      _mediaAutoDownload = prefs.getBool('chat_media_auto_download') ?? true;
    });
  }

  Future<void> _updateNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_notifications_enabled', value);
  }

  Future<void> _updateAutoDownloadSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('chat_media_auto_download', value);
  }

  String _selectedTheme = 'system';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const EnhancedUniversalHeader(
        title: 'Chat Settings',
        showLogo: false,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text('messaging_chat_settings_text_chat_notifications'.tr()),
            subtitle: Text(
              'messaging_chat_settings_message_get_notified_about'.tr(),
            ),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (value) async {
                setState(() {
                  _notificationsEnabled = value;
                });
                await _updateNotificationSetting(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: Text('messaging_chat_settings_text_autodownload_media'.tr()),
            subtitle: Text(
              'messaging_chat_settings_text_automatically_download_photos'.tr(),
            ),
            trailing: Switch(
              value: _mediaAutoDownload,
              onChanged: (value) async {
                setState(() {
                  _mediaAutoDownload = value;
                });
                await _updateAutoDownloadSetting(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.palette),
            title: Text('messaging_chat_settings_text_chat_theme'.tr()),
            subtitle: Text(
              _selectedTheme.substring(0, 1).toUpperCase() +
                  _selectedTheme.substring(1),
            ),
            onTap: () {
              final MenuController controller = MenuController();
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('messaging_chat_settings_text_select_theme'.tr()),
                  content: MenuAnchor(
                    controller: controller,
                    menuChildren: [
                      RadioMenuButton<String>(
                        value: 'system',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTheme = value;
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: Text('messaging_chat_settings_text_system'.tr()),
                      ),
                      RadioMenuButton<String>(
                        value: 'light',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTheme = value;
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: Text('messaging_chat_settings_text_light'.tr()),
                      ),
                      RadioMenuButton<String>(
                        value: 'dark',
                        groupValue: _selectedTheme,
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedTheme = value;
                            });
                            Navigator.pop(context);
                          }
                        },
                        child: Text('messaging_chat_settings_text_dark'.tr()),
                      ),
                    ],
                    child: const SizedBox.shrink(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: Text('messaging_chat_settings_text_clear_chat_history'.tr()),
            onTap: () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(
                    'messaging_chat_settings_text_clear_chat_history'.tr(),
                  ),
                  content: const Text(
                    'Are you sure you want to clear all chat history? This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('artwork_edit_delete_cancel'.tr()),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        try {
                          final chatService = Provider.of<ChatService>(
                            context,
                            listen: false,
                          );
                          await chatService.clearChatHistory(widget.chat.id);
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'messaging_chat_settings_text_chat_history_cleared'
                                      .tr(),
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            // ignore: use_build_context_synchronously
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'messaging_chat_settings_error_failed_to_clear'
                                      .tr(),
                                ),
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        'Clear',
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: Text('messaging_artistic_messaging_text_blocked_users'.tr()),
            onTap: () {
              Navigator.pushNamed(context, '/messaging/blocked-users');
            },
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Changes to these settings will apply to all your chats.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
