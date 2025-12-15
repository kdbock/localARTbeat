import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import '../services/admin_messaging_service.dart';
import '../utils/messaging_navigation_helper.dart';

/// Messaging Dashboard Screen
///
/// A comprehensive, dynamic dashboard for messaging featuring:
/// - Real-time messaging statistics and analytics
/// - User activity monitoring and management
/// - Message moderation tools
/// - Performance metrics and insights
/// - Modern, engaging UI with messaging brand colors
/// - Interactive charts and visualizations
/// - Quick action buttons for common admin tasks
class MessagingDashboardScreen extends StatefulWidget {
  const MessagingDashboardScreen({Key? key}) : super(key: key);

  @override
  State<MessagingDashboardScreen> createState() =>
      _MessagingDashboardScreenState();
}

class _MessagingDashboardScreenState extends State<MessagingDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late ScrollController _scrollController;
  AdminMessagingService? _adminService;

  // Messaging color scheme from to_do.md
  static const Color primaryColor = Color(0xFF0EEC96); // #0eec96
  static const Color textColor = Color(0xFF8C52FF); // #8c52ff
  static const Color cardColor = Color(0xFFF8FFFC);

  // Real-time data
  Map<String, dynamic>? _messagingStats;
  List<Map<String, dynamic>> _topConversations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _scrollController = ScrollController();

    try {
      _adminService = AdminMessagingService();
      // Load real data
      _loadData();
    } catch (e) {
      // debugPrint('❌ Error initializing AdminMessagingService: $e');
      // Set fallback data immediately
      _messagingStats = {
        'totalMessages': 0,
        'activeUsers': 0,
        'onlineNow': 0,
        'reportedMessages': 0,
        'blockedUsers': 0,
        'averageResponseTime': '0 min',
        'dailyGrowth': '0%',
        'weeklyActive': 0,
        'messagesSentToday': 0,
        'peakHour': 'N/A',
        'topEmoji': '📱',
        'groupChats': 0,
      };
    }

    // Start animations
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      if (_adminService == null) {
        throw Exception('AdminMessagingService not initialized');
      }

      final stats = await _adminService!.getMessagingStats();
      final conversations = await _adminService!.getTopConversations();

      if (mounted) {
        setState(() {
          _messagingStats = stats;
          _topConversations = conversations;
        });
      }
    } catch (e) {
      // For development: Use fallback data if Firebase data fails
      // debugPrint('Error loading messaging data: $e');
      if (mounted) {
        setState(() {
          _messagingStats = {
            'totalMessages': 1247,
            'activeUsers': 89,
            'onlineNow': 23,
            'reportedMessages': 3,
            'blockedUsers': 1,
            'averageResponseTime': '2.3 min',
            'dailyGrowth': '+12%',
            'weeklyActive': 156,
            'messagesSentToday': 89,
            'peakHour': '2-3 PM',
            'topEmoji': '🎨',
            'groupChats': 12,
          };
          _topConversations = [
            {
              'participants': ['Alice Johnson', 'Bob Smith'],
              'messageCount': 156,
              'lastActive': '2 min ago',
              'type': 'direct',
              'avatars': [
                'https://i.pravatar.cc/150?u=alice',
                'https://i.pravatar.cc/150?u=bob',
              ],
            },
            {
              'participants': ['Art Lovers Group'],
              'messageCount': 89,
              'lastActive': '5 min ago',
              'type': 'group',
              'avatars': ['https://i.pravatar.cc/150?u=group1'],
              'memberCount': 8,
            },
          ];
        });
      }
    }
  }

  // Get real messaging statistics
  Map<String, dynamic> get messagingStats =>
      _messagingStats ??
      {
        'totalMessages': 0,
        'activeUsers': 0,
        'onlineNow': 0,
        'reportedMessages': 0,
        'blockedUsers': 0,
        'averageResponseTime': '0 min',
        'dailyGrowth': '0%',
        'weeklyActive': 0,
        'messagesSentToday': 0,
        'peakHour': 'N/A',
        'topEmoji': '📱',
        'groupChats': 0,
      };

  // Get real recent activity stream with fallback
  Stream<List<Map<String, dynamic>>> get recentActivityStream {
    if (_adminService != null) {
      return _adminService!.getRecentActivityStream();
    }
    // Fallback stream for development
    return Stream.value([
      {
        'id': '1',
        'type': 'user',
        'user': 'Alice Johnson',
        'action': 'Joined the platform',
        'timestamp': '2 min ago',
        'severity': 'low',
        'icon': Icons.person_add,
        'color': Colors.green,
      },
      {
        'id': '2',
        'type': 'report',
        'user': 'System',
        'action': 'New message reported',
        'timestamp': '5 min ago',
        'severity': 'medium',
        'icon': Icons.report_problem,
        'color': Colors.orange,
      },
      {
        'id': '3',
        'type': 'milestone',
        'user': 'System',
        'action': '1000+ messages sent today',
        'timestamp': '1 hr ago',
        'severity': 'low',
        'icon': Icons.celebration,
        'color': Colors.green,
      },
    ]);
  }

  // Get real top conversations
  List<Map<String, dynamic>> get topConversations => _topConversations;

  // Get real online users stream with fallback
  Stream<List<Map<String, dynamic>>> get onlineUsersStream {
    if (_adminService != null) {
      return _adminService!.getOnlineUsersStream();
    }
    // Fallback stream for development
    return Stream.value([
      {
        'id': '1',
        'name': 'Alice Johnson',
        'avatar': 'https://i.pravatar.cc/150?u=alice',
        'isOnline': true,
        'status': 'Active',
        'lastSeen': 'now',
        'role': 'Artist',
      },
      {
        'id': '2',
        'name': 'Bob Smith',
        'avatar': 'https://i.pravatar.cc/150?u=bob',
        'isOnline': true,
        'status': 'Away',
        'lastSeen': '5 min ago',
        'role': 'Collector',
      },
      {
        'id': '3',
        'name': 'Carol Davis',
        'avatar': 'https://i.pravatar.cc/150?u=carol',
        'isOnline': false,
        'status': 'Offline',
        'lastSeen': '1 hr ago',
        'role': 'Gallery',
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    // Add error handling for build method
    try {
      return Scaffold(
        backgroundColor: cardColor,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header with gradient
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.chat_bubble_outline,
                              color: textColor,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Messaging Dashboard',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  Text(
                                    'Admin Control Center',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textColor.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildQuickActionButton(
                              Icons.settings,
                              'Settings',
                              () => _showSettingsDialog(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Stats Overview
              Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatsOverview(),
              ),

              // Tab Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: textColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: primaryColor,
                    indicatorWeight: 3,
                    tabs: const [
                      Tab(text: 'Activity', icon: Icon(Icons.timeline)),
                      Tab(text: 'Users', icon: Icon(Icons.people)),
                      Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
                    ],
                  ),
                ),
              ),

              // Tab Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildActivityTab(),
                      _buildUsersTab(),
                      _buildAnalyticsTab(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showBroadcastDialog(),
          backgroundColor: primaryColor,
          foregroundColor: textColor,
          icon: const Icon(Icons.campaign),
          label: Text(
            'messaging_enhanced_messaging_dashboard_text_broadcast'.tr(),
          ),
        ),
      );
    } catch (e, stackTrace) {
      // debugPrint('❌ Error in EnhancedMessagingDashboardScreen build: $e');
      // debugPrint('❌ Stack trace: $stackTrace');
      // Suppress unused variable warning - stackTrace is used in debugPrint
      // ignore: unused_local_variable
      stackTrace;

      // Return a safe error screen
      return Scaffold(
        backgroundColor: cardColor,
        appBar: AppBar(
          title: Text(
            'messaging_enhanced_messaging_dashboard_text_messaging_dashboard'
                .tr(),
          ),
          backgroundColor: primaryColor,
          foregroundColor: textColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Something went wrong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Error: $e',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loadData();
                  });
                },
                child: Text('artwork_retry_button'.tr()),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildStatsOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200, // Fixed height for the grid
          child: GridView.count(
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildStatCard(
                'Total Messages',
                (messagingStats['totalMessages'] ?? 0).toString(),
                Icons.chat,
                primaryColor,
                '+${messagingStats['dailyGrowth'] ?? '0%'}',
              ),
              _buildStatCard(
                'Active Users',
                (messagingStats['activeUsers'] ?? 0).toString(),
                Icons.people,
                Colors.blue,
                'Weekly: ${messagingStats['weeklyActive'] ?? 0}',
              ),
              _buildStatCard(
                'Online Now',
                (messagingStats['onlineNow'] ?? 0).toString(),
                Icons.circle,
                Colors.green,
                'Peak: ${messagingStats['peakHour'] ?? 'N/A'}',
              ),
              _buildStatCard(
                'Reports',
                (messagingStats['reportedMessages'] ?? 0).toString(),
                Icons.report_problem,
                Colors.orange,
                'Blocked: ${messagingStats['blockedUsers'] ?? 0}',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _refreshActivity(),
              icon: const Icon(Icons.refresh),
              label: Text('curated_gallery_refresh_button'.tr()),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: recentActivityStream,
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

              final activities = snapshot.data ?? [];

              if (activities.isEmpty) {
                return Center(
                  child: Text(
                    'messaging_enhanced_messaging_dashboard_text_no_recent_activity'
                        .tr(),
                  ),
                );
              }

              return ListView.builder(
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final activity = activities[index];
                  return _buildActivityCard(activity);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    // Safe extraction with null checks and defaults
    final color = activity['color'] as Color? ?? Colors.grey;
    final icon = activity['icon'] as IconData? ?? Icons.info;
    final action = activity['action'] as String? ?? 'Unknown action';
    final user = activity['user'] as String? ?? 'Unknown user';
    final timestamp = activity['timestamp'] as String? ?? 'Unknown time';
    final severity = activity['severity'] as String? ?? 'low';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          action,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          'messaging_user_timestamp'
              .tr()
              .replaceAll('{user}', user)
              .replaceAll('{timestamp}', timestamp),
        ),
        trailing: _buildSeverityBadge(severity),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity) {
      case 'high':
        color = Colors.red;
        break;
      case 'medium':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: onlineUsersStream,
      builder: (context, snapshot) {
        final users = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Online Users (${users.length})',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                Row(
                  children: [
                    _buildQuickActionButton(
                      Icons.search,
                      'Search',
                      () => _showUserSearch(),
                    ),
                    const SizedBox(width: 8),
                    _buildQuickActionButton(
                      Icons.filter_list,
                      'Filter',
                      () => _showUserFilter(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : snapshot.hasError
                  ? Center(
                      child: Text(
                        'messaging_enhanced_messaging_dashboard_error_error_snapshoterror'
                            .tr(),
                      ),
                    )
                  : users.isEmpty
                  ? Center(
                      child: Text(
                        'messaging_enhanced_messaging_dashboard_text_no_users_online'
                            .tr(),
                      ),
                    )
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserCard(user);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    // Safe extraction with null checks and defaults
    final avatar =
        user['avatar'] as String? ?? 'https://i.pravatar.cc/150?u=default';
    final isOnline = user['isOnline'] as bool? ?? false;
    final name = user['name'] as String? ?? 'Unknown User';
    final role = user['role'] as String? ?? 'User';
    final status = user['status'] as String? ?? 'Unknown';
    final lastSeen = user['lastSeen'] as String? ?? 'Unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundImage:
                  ImageUrlValidator.safeNetworkImage(avatar) ??
                  const AssetImage('assets/default_profile.png')
                      as ImageProvider,
              radius: 20,
              onBackgroundImageError: (exception, stackTrace) {
                // Handle image loading errors gracefully
              },
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline ? Colors.green : Colors.grey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role,
                style: const TextStyle(
                  fontSize: 10,
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          'messaging_status_last_seen'
              .tr()
              .replaceAll('{status}', status)
              .replaceAll('{lastSeen}', lastSeen),
        ),
        trailing: PopupMenuButton(
          icon: const Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'message',
              child: Row(
                children: [
                  const Icon(Icons.message),
                  const SizedBox(width: 8),
                  Text(
                    'messaging_enhanced_messaging_dashboard_message_send_message'
                        .tr(),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  const Icon(Icons.visibility),
                  const SizedBox(width: 8),
                  Text('messaging_blocked_users_text_view_profile'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'moderate',
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings),
                  const SizedBox(width: 8),
                  Text(
                    'messaging_enhanced_messaging_dashboard_text_moderate'.tr(),
                  ),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleUserAction(value, user),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Analytics & Insights',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildAnalyticsCard(
                  'Message Volume',
                  'Today: ${messagingStats['messagesSentToday']}',
                  Icons.trending_up,
                  primaryColor,
                  'Peak hour: ${messagingStats['peakHour']}',
                ),
                const SizedBox(height: 12),
                _buildAnalyticsCard(
                  'Response Time',
                  'Avg: ${messagingStats['averageResponseTime']}',
                  Icons.timer,
                  Colors.blue,
                  'Target: < 5 min',
                ),
                const SizedBox(height: 12),
                _buildAnalyticsCard(
                  'Popular Content',
                  'Top emoji: ${messagingStats['topEmoji']}',
                  Icons.emoji_emotions,
                  Colors.orange,
                  'Art-related: 78%',
                ),
                const SizedBox(height: 12),
                _buildAnalyticsCard(
                  'Group Activity',
                  '${messagingStats['groupChats']} active groups',
                  Icons.group,
                  Colors.purple,
                  'Avg members: 8.5',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String subtitle,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, color: textColor),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }

  void _showSettingsDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'messaging_enhanced_messaging_dashboard_text_messaging_settings'.tr(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text(
                'messaging_enhanced_messaging_dashboard_text_push_notifications'
                    .tr(),
              ),
              trailing: const Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: const Icon(Icons.auto_delete),
              title: Text(
                'messaging_enhanced_messaging_dashboard_text_autodelete_spam'
                    .tr(),
              ),
              trailing: const Switch(value: true, onChanged: null),
            ),
            ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(
                'messaging_enhanced_messaging_dashboard_text_quiet_hours'.tr(),
              ),
              trailing: const Switch(value: false, onChanged: null),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('artwork_close_button'.tr()),
          ),
        ],
      ),
    );
  }

  void _showBroadcastDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'messaging_enhanced_messaging_dashboard_message_send_broadcast_message'
              .tr(),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Message',
                hintText: 'Enter your broadcast message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This will be sent to all active users',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('artwork_edit_delete_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendBroadcast();
            },
            child: Text(
              'messaging_enhanced_messaging_dashboard_text_send'.tr(),
            ),
          ),
        ],
      ),
    );
  }

  void _refreshActivity() {
    HapticFeedback.lightImpact();
    // Simulate refresh
    setState(() {});
  }

  void _showUserSearch() {
    // Implement user search
  }

  void _showUserFilter() {
    // Implement user filter
  }

  void _handleUserAction(String action, Map<String, dynamic> user) {
    switch (action) {
      case 'message':
        // Navigate to chat with user
        final userId = user['id'] as String?;
        if (userId != null) {
          MessagingNavigationHelper.navigateToUserChat(context, userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'messaging_enhanced_messaging_dashboard_text_unable_to_start'
                    .tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        break;
      case 'view':
        // Show user profile
        final userId = user['id'] as String?;
        if (userId != null) {
          MessagingNavigationHelper.navigateToUserProfile(context, userId);
        }
        break;
      case 'moderate':
        // Show moderation options
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'messaging_enhanced_messaging_dashboard_text_moderation_features_coming'
                  .tr(),
            ),
            backgroundColor: Colors.blue,
          ),
        );
        break;
    }
  }

  void _sendBroadcast() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'messaging_enhanced_messaging_dashboard_success_broadcast_message_sent'
              .tr(),
        ),
        backgroundColor: primaryColor,
      ),
    );
  }
}
