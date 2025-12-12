import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart' as messaging;

class GroupCreationScreen extends StatefulWidget {
  const GroupCreationScreen({super.key});

  @override
  State<GroupCreationScreen> createState() => _GroupCreationScreenState();
}

class _GroupCreationScreenState extends State<GroupCreationScreen> {
  final _groupNameController = TextEditingController();
  final _selectedUsers = <messaging.UserModel>{};
  String _searchQuery = '';

  @override
  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chatService = Provider.of<ChatService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('messaging_chat_list_text_new_group'.tr()),
        actions: [
          if (_selectedUsers.isNotEmpty &&
              _groupNameController.text.trim().isNotEmpty)
            TextButton(
              onPressed: () async {
                final groupName = _groupNameController.text.trim();
                final selectedUserIds = _selectedUsers
                    .map((u) => u.id)
                    .toList();

                try {
                  final chat = await chatService.createGroupChat(
                    groupName: groupName,
                    participantIds: selectedUserIds,
                  );

                  if (!mounted) return;

                  Navigator.pushNamed(
                    // ignore: use_build_context_synchronously
                    context,
                    '/messaging/chat',
                    arguments: {'chat': chat},
                  );
                } catch (e) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'messaging_group_creation_error_failed_to_create'.tr(),
                      ),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              child: Text('core_coupon_create_button'.tr()),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _groupNameController,
              decoration: InputDecoration(
                hintText: 'Group name',
                prefixIcon: const Icon(Icons.group),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_selectedUsers.isNotEmpty)
            SizedBox(
              height: 90,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedUsers.length,
                itemBuilder: (context, index) {
                  final user = _selectedUsers.elementAt(index);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            ImageUtils.safeCircleAvatar(
                              imageUrl: user.photoUrl,
                              displayName: user.displayName,
                              radius: 30.0,
                            ),
                            Positioned(
                              right: -4,
                              top: -4,
                              child: IconButton(
                                icon: const Icon(Icons.remove_circle),
                                color: theme.colorScheme.error,
                                iconSize: 20,
                                onPressed: () {
                                  setState(() {
                                    _selectedUsers.remove(user);
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.displayName,
                          style: theme.textTheme.bodySmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search people...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: FutureBuilder(
              future: chatService.searchUsers(_searchQuery),
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading users',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  );
                }

                final users = snapshot.data ?? [];
                final availableUsers = users
                    .where((user) => !_selectedUsers.contains(user))
                    .toList();

                if (availableUsers.isEmpty) {
                  return Center(
                    child: Text(
                      'No users found',
                      style: theme.textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: availableUsers.length,
                  itemBuilder: (context, index) {
                    final user = availableUsers[index] as messaging.UserModel;
                    return ListTile(
                      leading: ImageUtils.safeCircleAvatar(
                        imageUrl: user.photoUrl,
                        displayName: user.displayName,
                        radius: 20.0,
                      ),
                      title: Text(user.displayName),
                      subtitle: Text(
                        user.isOnline
                            ? 'Online'
                            : 'Last seen: ${_formatLastSeen(user.lastSeen)}',
                      ),
                      onTap: () {
                        setState(() {
                          _selectedUsers.add(user);
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
