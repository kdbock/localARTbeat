import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import 'chat_screen.dart';
import 'contact_selection_screen.dart';

// ARTbeat brand colors
const Color artBeatPrimary = Color(0xFF0EEC96);
const Color artBeatText = Color(0xFF8C52FF);
const Color artBeatBackground = Color(0xFFF8FFFC);

class SimpleMessagingDashboardScreen extends StatefulWidget {
  const SimpleMessagingDashboardScreen({Key? key}) : super(key: key);

  @override
  State<SimpleMessagingDashboardScreen> createState() =>
      _SimpleMessagingDashboardScreenState();
}

class _SimpleMessagingDashboardScreenState
    extends State<SimpleMessagingDashboardScreen> {
  String _selectedFilter = 'All'; // Filter for user types

  // Enhanced dummy data with ARTbeat user types
  List<Map<String, dynamic>> onlineUsers = [
    {
      'name': 'Alice Chen',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'isOnline': true,
      'userType': 'Artist',
      'isVerified': true,
    },
    {
      'name': 'Bob Gallery',
      'avatar': 'https://i.pravatar.cc/150?img=2',
      'isOnline': true,
      'userType': 'Gallery',
      'isVerified': true,
    },
    {
      'name': 'Charlie Davis',
      'avatar': 'https://i.pravatar.cc/150?img=3',
      'isOnline': true,
      'userType': 'Collector',
      'isVerified': false,
    },
  ];

  List<Map<String, dynamic>> recentChats = [
    {
      'name': 'Alice Chen',
      'avatar': 'https://i.pravatar.cc/150?img=1',
      'lastMessage': 'Thanks for your interest in my latest piece!',
      'timestamp': '2 min ago',
      'unread': 2,
      'userType': 'Artist',
      'chatType': 'artwork_inquiry',
      'isVerified': true,
    },
  ];

  // Get filtered online users based on selected filter
  List<Map<String, dynamic>> get filteredOnlineUsers {
    if (_selectedFilter == 'All') return onlineUsers;
    return onlineUsers
        .where((user) => user['userType'] == _selectedFilter)
        .toList();
  }

  // Get color for user type indicator
  Color _getUserTypeColor(String userType) {
    switch (userType) {
      case 'Artist':
        return const Color(0xFFFF6B6B); // Red for artists
      case 'Gallery':
        return const Color(0xFF4ECDC4); // Teal for galleries
      case 'Collector':
        return const Color(0xFFFFE66D); // Yellow for collectors
      default:
        return Colors.grey;
    }
  }

  // Get color for chat type indicator
  Color _getChatTypeColor(String chatType) {
    switch (chatType) {
      case 'artwork_inquiry':
        return const Color(0xFF9B59B6); // Purple for artwork inquiries
      case 'commission':
        return const Color(0xFF3498DB); // Blue for commissions
      case 'purchase_inquiry':
        return const Color(0xFF27AE60); // Green for purchase inquiries
      default:
        return Colors.grey;
    }
  }

  // Get icon for chat type indicator
  IconData _getChatTypeIcon(String chatType) {
    switch (chatType) {
      case 'artwork_inquiry':
        return Icons.palette;
      case 'commission':
        return Icons.handshake;
      case 'purchase_inquiry':
        return Icons.shopping_cart;
      default:
        return Icons.chat;
    }
  }

  // Get label for chat type
  String _getChatTypeLabel(String chatType) {
    switch (chatType) {
      case 'artwork_inquiry':
        return 'Artwork';
      case 'commission':
        return 'Commission';
      case 'purchase_inquiry':
        return 'Purchase';
      default:
        return 'Chat';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: artBeatBackground,
      body: CustomScrollView(
        slivers: [
          // Header with filter chips
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: artBeatText,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Artist', 'Gallery', 'Collector']
                          .map(
                            (filter) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(filter),
                                selected: _selectedFilter == filter,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedFilter = filter;
                                  });
                                },
                                selectedColor: artBeatPrimary.withValues(
                                  alpha: 0.2,
                                ),
                                checkmarkColor: artBeatText,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                'Online (${filteredOnlineUsers.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: artBeatText,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filteredOnlineUsers.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final user = filteredOnlineUsers[index];
                  final String avatar = user['avatar'] as String;
                  final String name = user['name'] as String;
                  final bool isOnline = user['isOnline'] as bool;
                  final String userType = user['userType'] as String;
                  final bool isVerified = user['isVerified'] as bool? ?? false;

                  return SizedBox(
                    width: 40,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: isVerified
                                    ? Border.all(
                                        color: artBeatPrimary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: CircleAvatar(
                                radius: 14,
                                backgroundImage:
                                    ImageUrlValidator.safeNetworkImage(
                                      avatar,
                                    ) ??
                                    const AssetImage(
                                          'assets/default_profile.png',
                                        )
                                        as ImageProvider,
                              ),
                            ),
                            // Online indicator
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                            // User type indicator
                            Positioned(
                              left: 0,
                              top: 0,
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: _getUserTypeColor(userType),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Flexible(
                          child: Text(
                            name.split(' ').first, // First name only
                            style: const TextStyle(fontSize: 8),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Recent Chats',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: artBeatText,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final chat = recentChats[index];
              final String avatar = chat['avatar'] as String;
              final String name = chat['name'] as String;
              final String lastMessage = chat['lastMessage'] as String;
              final String timestamp = chat['timestamp'] as String;
              final int unread = chat['unread'] as int;
              final String userType = chat['userType'] as String;
              final String chatType = chat['chatType'] as String;
              final bool isVerified = chat['isVerified'] as bool? ?? false;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: artBeatPrimary.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: isVerified
                              ? Border.all(color: artBeatPrimary, width: 2)
                              : null,
                        ),
                        child: CircleAvatar(
                          backgroundImage:
                              ImageUrlValidator.safeNetworkImage(avatar) ??
                              const AssetImage('assets/default_profile.png')
                                  as ImageProvider,
                          radius: 20,
                        ),
                      ),
                      // Chat type indicator
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _getChatTypeColor(chatType),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1),
                          ),
                          child: Icon(
                            _getChatTypeIcon(chatType),
                            size: 8,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // User type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _getUserTypeColor(
                            userType,
                          ).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userType,
                          style: TextStyle(
                            fontSize: 10,
                            color: _getUserTypeColor(userType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: artBeatPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$unread',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timestamp,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getChatTypeLabel(chatType),
                        style: TextStyle(
                          fontSize: 8,
                          color: _getChatTypeColor(chatType),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _navigateToChatDetail(context, chat);
                  },
                ),
              );
            }, childCount: recentChats.length),
          ),
          // Add bottom padding to prevent overflow
          const SliverToBoxAdapter(
            child: SizedBox(height: 80), // Space for FAB
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: artBeatPrimary,
        foregroundColor: artBeatText,
        child: const Icon(Icons.add_comment),
        onPressed: () {
          _startNewChat(context);
        },
      ),
    );
  }

  /// Navigate to chat detail screen
  void _navigateToChatDetail(
    BuildContext context,
    Map<String, dynamic> chatData,
  ) {
    // Create a ChatModel from the dummy data
    // In a real implementation, this would come from the chat service
    final chat = ChatModel(
      id: 'chat_${chatData['name']?.toString().toLowerCase()}',
      participantIds: ['current_user', 'other_user'],
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedAt: DateTime.now(),
      unreadCounts: {'current_user': chatData['unread'] as int? ?? 0},
      isGroup: false,
      participants: [
        {
          'id': 'other_user',
          'displayName': chatData['name'] as String,
          'photoUrl': chatData['avatar'] as String,
        },
      ],
    );

    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => ChatScreen(chat: chat)),
    );
  }

  /// Start new chat by navigating to contact selection
  void _startNewChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const ContactSelectionScreen(),
      ),
    );
  }
}
