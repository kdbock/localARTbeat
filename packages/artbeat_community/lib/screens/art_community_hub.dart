import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../models/art_models.dart';
import '../models/post_model.dart';
import '../services/art_community_service.dart';
import '../src/services/moderation_service.dart';
import '../widgets/enhanced_post_card.dart';
import '../widgets/activity_card.dart';
import '../widgets/mini_artist_card.dart';
import '../widgets/comments_modal.dart';
import '../widgets/commission_artists_browser.dart';
import '../widgets/fullscreen_image_viewer.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'artist_onboarding_screen.dart';
import 'artist_feed_screen.dart';
import 'feed/comments_screen.dart';
import 'feed/create_post_screen.dart';
import 'package:artbeat_artist/src/services/community_service.dart'
    as artist_community;
import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'feed/trending_content_screen.dart';
import 'feed/group_feed_screen.dart';
import 'feed/social_engagement_demo_screen.dart';
import 'posts/user_posts_screen.dart';
import 'settings/quiet_mode_screen.dart';
import '../models/direct_commission_model.dart';
import '../services/direct_commission_service.dart';

// Mixin for shared post loading logic
mixin PostLoadingMixin<T extends StatefulWidget> on State<T> {
  List<PostModel> posts = [];
  List<PostModel> filteredPosts = [];
  bool isLoading = true;
  final ModerationService moderationService = ModerationService();

  Future<void> loadPosts(
    ArtCommunityService communityService, {
    int limit = 20,
  }) async {
    setState(() => isLoading = true);

    try {
      AppLogger.info('📱 Loading posts from community service...');

      final loadedPosts = await communityService.getFeed(limit: limit);

      AppLogger.info('📱 Loaded ${loadedPosts.length} posts');

      // Filter out posts from blocked users
      List<PostModel> filtered = loadedPosts;
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        try {
          final blockedUserIds = await moderationService.getBlockedUsers(
            currentUser.uid,
          );

          if (blockedUserIds.isNotEmpty) {
            filtered = loadedPosts
                .where((post) => !blockedUserIds.contains(post.userId))
                .toList();
            AppLogger.info(
              '📱 Filtered out ${loadedPosts.length - filtered.length} posts from blocked users',
            );
          }
        } catch (e) {
          AppLogger.error('📱 Error filtering blocked users: $e');
        }
      }

      if (mounted) {
        setState(() {
          posts = filtered;
          filteredPosts = filtered;
          isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('📱 Error loading posts: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading posts: $e')));
      }
    }
  }

  void filterPosts(String searchQuery) {
    setState(() {
      if (searchQuery.isEmpty) {
        filteredPosts = posts;
      } else {
        filteredPosts = posts.where((post) {
          final content = post.content.toLowerCase();
          final authorName = post.userName.toLowerCase();
          final location = post.location.toLowerCase();

          return content.contains(searchQuery) ||
              authorName.contains(searchQuery) ||
              location.contains(searchQuery);
        }).toList();
      }
    });
  }
}

// Tab-specific version of commissions content (without MainLayout)
class CommissionsTab extends StatefulWidget {
  const CommissionsTab({super.key});

  @override
  State<CommissionsTab> createState() => _CommissionsTabState();
}

class _CommissionsTabState extends State<CommissionsTab>
    with SingleTickerProviderStateMixin {
  final DirectCommissionService _commissionService = DirectCommissionService();
  late final TabController _tabController;
  List<DirectCommissionModel> _commissions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        return;
      }

      final commissions = await _commissionService.getCommissionsByUser(
        user.uid,
      );
      setState(() {
        _commissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading commissions: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tabs for filtering commissions
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
        // Commission list
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Active commissions (in progress, accepted, quoted)
                    _buildCommissionList(
                      _commissions
                          .where(
                            (c) =>
                                c.status == CommissionStatus.inProgress ||
                                c.status == CommissionStatus.accepted ||
                                c.status == CommissionStatus.quoted,
                          )
                          .toList(),
                    ),
                    // Pending commissions
                    _buildCommissionList(
                      _commissions
                          .where((c) => c.status == CommissionStatus.pending)
                          .toList(),
                    ),
                    // Completed commissions
                    _buildCommissionList(
                      _commissions
                          .where(
                            (c) =>
                                c.status == CommissionStatus.completed ||
                                c.status == CommissionStatus.delivered,
                          )
                          .toList(),
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildCommissionList(List<DirectCommissionModel> commissions) {
    if (commissions.isEmpty) {
      return const Center(child: Text('No commissions found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: commissions.length,
      itemBuilder: (context, index) {
        final commission = commissions[index];
        return Card(
          child: ListTile(
            title: Text(commission.title),
            subtitle: Text(
              'Status: ${commission.status.displayName} • \$${commission.totalPrice.toStringAsFixed(2)}',
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {
              _showCommissionDetails(commission);
            },
          ),
        );
      },
    );
  }

  void _showCommissionDetails(DirectCommissionModel commission) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commission Details',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _buildDetailRow('Commission ID', commission.id),
              _buildDetailRow('Title', commission.title),
              _buildDetailRow('Client', commission.clientName),
              _buildDetailRow('Artist', commission.artistName),
              _buildDetailRow('Type', commission.type.displayName),
              _buildDetailRow(
                'Total Price',
                '\$${commission.totalPrice.toStringAsFixed(2)}',
              ),
              _buildDetailRow('Status', commission.status.displayName),
              _buildDetailRow('Requested', commission.requestedAt.toString()),
              if (commission.deadline != null)
                _buildDetailRow('Deadline', commission.deadline.toString()),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

/// New simplified community hub with gallery-style design
class ArtCommunityHub extends StatefulWidget {
  const ArtCommunityHub({super.key});

  @override
  State<ArtCommunityHub> createState() => _ArtCommunityHubState();
}

class _ArtCommunityHubState extends State<ArtCommunityHub>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late ArtCommunityService _communityService;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _communityService = ArtCommunityService();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _communityService.dispose();
    super.dispose();
  }

  void _checkAuthStatus() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      AppLogger.info('🔐 User is authenticated: ${user.uid} (${user.email})');
    } else {
      AppLogger.error('🔐 User is NOT authenticated');
    }
  }

  void _showSearchDialog() {
    final currentTab = _tabController.index;
    final tabName = currentTab == 0
        ? 'Feed'
        : currentTab == 1
        ? 'Artists'
        : 'Topics';

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: ArtbeatColors.backgroundDark,
              title: Text(
                'Search $tabName',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      hintStyle: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(Icons.search, color: Colors.white),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Searching in: $tabName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchQuery = '';
                    Navigator.of(context).pop();
                    // Trigger search update in current tab
                    setState(() {});
                  },
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: ArtbeatColors.primary),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Trigger search update in current tab
                    setState(() {});
                  },
                  child: const Text(
                    'Search',
                    style: TextStyle(color: ArtbeatColors.primary),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: ArtbeatColors.backgroundDark,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.people,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Art Community',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Explore, create, connect',
                    style: TextStyle(fontSize: 14, color: Colors.white70),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Main Feeds Section
                  _buildDrawerSection('Main Feeds'),
                  _buildDrawerItem(
                    icon: Icons.feed,
                    title: 'Community Feed',
                    subtitle: 'Latest posts from artists',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(0);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.trending_up,
                    title: 'Trending Content',
                    subtitle: 'Popular and trending posts',
                    onTap: () => _navigateToScreen(
                      'feed/trending_content_screen.dart',
                      'TrendingContentScreen',
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.group,
                    title: 'Artist Community',
                    subtitle: 'Connect with fellow artists',
                    onTap: () => _navigateToScreen(
                      'feed/artist_community_feed_screen.dart',
                      'ArtistCommunityFeedScreen',
                    ),
                  ),

                  // Create & Post Section
                  _buildDrawerSection('Create & Share'),
                  _buildDrawerItem(
                    icon: Icons.add_circle,
                    title: 'Create Post',
                    subtitle: 'Share your art with the community',
                    onTap: () => _navigateToScreen(
                      'feed/create_post_screen.dart',
                      'CreatePostScreen',
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.group_add,
                    title: 'Create Group Post',
                    subtitle: 'Post to artist groups',
                    onTap: () => _navigateToScreen(
                      'feed/create_group_post_screen.dart',
                      'CreateGroupPostScreen',
                    ),
                  ),

                  // Artists Section
                  _buildDrawerSection('Artists'),
                  _buildDrawerItem(
                    icon: Icons.palette,
                    title: 'Artists Gallery',
                    subtitle: 'Discover amazing artists',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(1);
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_add,
                    title: 'Artist Onboarding',
                    subtitle: 'Join the artist community',
                    onTap: () => _navigateToScreen(
                      'artist_onboarding_screen.dart',
                      'ArtistOnboardingScreen',
                    ),
                  ),

                  // Commissions Section
                  _buildDrawerSection('Commissions'),
                  _buildDrawerItem(
                    icon: Icons.art_track,
                    title: 'Commission Hub',
                    subtitle: 'Browse commissions & requests',
                    onTap: () => _navigateToScreen(
                      'commissions/commission_hub_screen.dart',
                      'CommissionHubScreen',
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.handshake,
                    title: 'Commission Artists',
                    subtitle: 'Find artists accepting work',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(1); // Go to Artists tab
                    },
                  ),

                  // Topics & Discovery
                  _buildDrawerSection('Discover'),
                  _buildDrawerItem(
                    icon: Icons.topic,
                    title: 'Topics',
                    subtitle: 'Browse by art categories',
                    onTap: () {
                      Navigator.pop(context);
                      _tabController.animateTo(2);
                    },
                  ),

                  // Personal Section
                  _buildDrawerSection('My Content'),
                  _buildDrawerItem(
                    icon: Icons.person,
                    title: 'My Posts',
                    subtitle: 'View your posts and activity',
                    onTap: () => _navigateToScreen(
                      'posts/user_posts_screen.dart',
                      'UserPostsScreen',
                    ),
                  ),

                  // Settings & Tools
                  _buildDrawerSection('Tools'),
                  _buildDrawerItem(
                    icon: Icons.settings,
                    title: 'Quiet Mode',
                    subtitle: 'Manage notifications',
                    onTap: () => _navigateToScreen(
                      'settings/quiet_mode_screen.dart',
                      'QuietModeScreen',
                    ),
                  ),
                  _buildDrawerItem(
                    icon: Icons.analytics,
                    title: 'Social Engagement',
                    subtitle: 'View engagement analytics',
                    onTap: () => _navigateToScreen(
                      'feed/social_engagement_demo_screen.dart',
                      'SocialEngagementDemoScreen',
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                  Text(
                    'ARTbeat Community',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Version 2.0.5',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: ArtbeatColors.primaryGreen,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: ArtbeatColors.primaryPurple, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.6),
          fontSize: 12,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  void _navigateToScreen(String screenPath, String screenClassName) {
    Navigator.pop(context); // Close drawer

    // Navigate to the appropriate screen based on the class name
    Widget? screen;
    switch (screenClassName) {
      case 'TrendingContentScreen':
        screen = const TrendingContentScreen();
        break;
      case 'UserPostsScreen':
        screen = const UserPostsScreen();
        break;
      case 'QuietModeScreen':
        screen = const QuietModeScreen();
        break;
      case 'SocialEngagementDemoScreen':
        screen = const SocialEngagementDemoScreen();
        break;
      case 'ArtistOnboardingScreen':
        screen = const ArtistOnboardingScreen();
        break;
      case 'CreatePostScreen':
        // This is already handled by the FAB, but we can navigate here too
        screen = const CreatePostScreen();
        break;
      case 'CreateGroupPostScreen':
        // This requires parameters, so show a dialog to select group type
        _showGroupPostDialog();
        return;
      case 'ArtistCommunityFeedScreen':
        // This requires an artist parameter, so show artist selection
        _showArtistSelectionDialog();
        return;
      default:
        // Show placeholder for screens not yet implemented
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$screenClassName navigation not yet implemented'),
            duration: const Duration(seconds: 2),
          ),
        );
        return;
    }

    Navigator.push<Widget>(
      context,
      MaterialPageRoute<Widget>(builder: (context) => screen!),
    );
  }

  void _showGroupPostDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Group Post'),
        content: const Text(
          'Select the type of group post you want to create:',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to regular create post screen for group posts
              Navigator.push<void>(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const CreatePostScreen(),
                ),
              );
            },
            child: const Text('Group Post'),
          ),
        ],
      ),
    );
  }

  void _showArtistSelectionDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Artist'),
        content: const Text(
          'Artist selection will be implemented soon. For now, this feature requires selecting a specific artist.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 48 + 4),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.people,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Art Community',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Connect with artists',
                        style: TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
            leading: Builder(
              builder: (context) => Container(
                margin: const EdgeInsets.only(left: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () => Scaffold.of(context).openDrawer(),
                  icon: const Icon(Icons.menu, color: Colors.white),
                ),
              ),
            ),
            actions: [
              // Debug auth button
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user == null) {
                      // Sign in anonymously for testing
                      try {
                        await FirebaseAuth.instance.signInAnonymously();
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Signed in anonymously for testing'),
                          ),
                        );
                      } catch (e) {
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sign in failed: $e')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Already signed in: ${user.uid}'),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.person, color: Colors.white),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: _showSearchDialog,
                  icon: const Icon(Icons.search, color: Colors.white),
                ),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.7),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w400,
                fontSize: 16,
              ),
              tabs: const [
                Tab(text: 'Feed', icon: Icon(Icons.feed, size: 20)),
                Tab(text: 'Artists', icon: Icon(Icons.palette, size: 20)),
                Tab(text: 'Groups', icon: Icon(Icons.group, size: 20)),
              ],
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
              Colors.white,
            ],
          ),
        ),
        child: TabBarView(
          controller: _tabController,
          children: [
            CommunityFeedTab(
              communityService: _communityService,
              searchQuery: _searchQuery,
            ),
            ArtistsGalleryTab(
              communityService: _communityService,
              searchQuery: _searchQuery,
            ),
            GroupsTab(
              communityService: _communityService,
              searchQuery: _searchQuery,
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: ArtbeatColors.primaryPurple.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () {
            // Navigate to enhanced create post screen
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const CreatePostScreen(),
              ),
            ).then((result) {
              setState(() {});
            });
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Feed tab - Gallery of all posts
class CommunityFeedTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const CommunityFeedTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<CommunityFeedTab> createState() => _CommunityFeedTabState();
}

class _CommunityFeedTabState extends State<CommunityFeedTab>
    with PostLoadingMixin {
  List<art_walk.SocialActivity> _activities = [];
  bool _showActivities = true; // Filter toggle for activities
  List<dynamic> _feedItems = []; // Combined posts and activities

  @override
  void initState() {
    super.initState();
    loadPosts(widget.communityService);
    _loadActivities();
  }

  @override
  Future<void> loadPosts(
    ArtCommunityService communityService, {
    int limit = 20,
  }) async {
    await super.loadPosts(communityService, limit: limit);
    _combineFeedItems();
  }

  @override
  void didUpdateWidget(CommunityFeedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      filterPosts(widget.searchQuery.toLowerCase());
      _combineFeedItems();
    }
  }

  Future<void> _loadActivities() async {
    try {
      AppLogger.info('📱 Loading social activities...');

      final socialService = art_walk.SocialService();
      final user = FirebaseAuth.instance.currentUser;

      List<art_walk.SocialActivity> activities = [];

      if (user != null) {
        // First, try to load user's own activities (most reliable)
        AppLogger.info('📱 Loading user activities for ${user.uid}');
        final userActivities = await socialService.getUserActivities(
          userId: user.uid,
          limit: 10,
        );
        AppLogger.info('📱 Loaded ${userActivities.length} user activities');
        activities = userActivities;

        // If we have few activities, also try to load nearby activities
        if (activities.length < 5) {
          try {
            final userPosition = await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.medium,
              ),
            );

            final nearbyActivities = await socialService.getNearbyActivities(
              userPosition: userPosition,
              radiusKm: 80.0, // ~50 miles
              limit: 10,
            );

            AppLogger.info(
              '📱 Loaded ${nearbyActivities.length} nearby activities',
            );

            // Combine and deduplicate activities
            final activityIds = activities.map((a) => a.id).toSet();
            for (final activity in nearbyActivities) {
              if (!activityIds.contains(activity.id)) {
                activities.add(activity);
              }
            }
          } catch (e) {
            AppLogger.warning('Could not load nearby activities: $e');
          }
        }
      } else {
        AppLogger.warning('No user logged in, cannot load activities');
      }

      AppLogger.info('📱 Total activities loaded: ${activities.length}');

      // Filter out ALL RSS feeds - only keep genuine app activities
      final filteredActivities = activities.where((activity) {
        // Exclude any RSS feed activities
        // RSS feeds typically have 'type' field set to 'rss' or similar
        // Or check if the activity type indicates it's an RSS feed
        final activityType = activity.type.toString().toLowerCase();
        final isRssFeed =
            activityType.contains('rss') ||
            activityType.contains('feed') ||
            activityType.contains('news');

        // Also check message content for RSS indicators
        final message = activity.message.toLowerCase();
        final hasRssIndicators =
            message.contains('rss') ||
            message.contains('news feed') ||
            message.contains('political news') ||
            message.contains('news sports');

        // Keep only genuine app activities (art walks, etc)
        return !isRssFeed && !hasRssIndicators;
      }).toList();

      AppLogger.info(
        '📱 Filtered out ${activities.length - filteredActivities.length} RSS feed activities, ${filteredActivities.length} genuine activities remaining',
      );

      if (mounted) {
        setState(() {
          _activities = filteredActivities;
        });
        _combineFeedItems();
      }
    } catch (e) {
      AppLogger.error('📱 Error loading activities: $e');
    }
  }

  void _combineFeedItems() {
    final combinedItems = <dynamic>[];

    // Add posts
    combinedItems.addAll(filteredPosts);

    // Add activities if filter is enabled
    if (_showActivities) {
      combinedItems.addAll(_activities);
    }

    // Sort by timestamp (newest first)
    combinedItems.sort((a, b) {
      DateTime timeA, timeB;

      if (a is PostModel) {
        timeA = a.createdAt;
      } else if (a is art_walk.SocialActivity) {
        timeA = a.timestamp;
      } else {
        return 0;
      }

      if (b is PostModel) {
        timeB = b.createdAt;
      } else if (b is art_walk.SocialActivity) {
        timeB = b.timestamp;
      } else {
        return 0;
      }

      return timeB.compareTo(timeA); // Newest first
    });

    setState(() {
      _feedItems = combinedItems;
    });
  }

  void _toggleActivitiesFilter() {
    setState(() {
      _showActivities = !_showActivities;
      _combineFeedItems();
    });
  }

  void _handlePostTap(PostModel post) {
    _showPostDetailDialog(post);
  }

  void _showPostDetailDialog(PostModel post) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and close button
              Row(
                children: [
                  CircleAvatar(
                    backgroundImage: ImageUrlValidator.safeNetworkImage(
                      post.userPhotoUrl,
                    ),
                    child: !ImageUrlValidator.isValidImageUrl(post.userPhotoUrl)
                        ? Text(post.userName[0].toUpperCase())
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _formatPostTime(post.createdAt),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Post content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post text
                      Text(post.content, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),

                      // Images
                      if (post.imageUrls.isNotEmpty) ...[
                        SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: post.imageUrls.length,
                            itemBuilder: (context, index) => Container(
                              width: 200,
                              margin: const EdgeInsets.only(right: 8),
                              child: Image.network(
                                post.imageUrls[index],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Location
                      if (post.location.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              post.location,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ],

                      // Tags
                      if (post.tags.isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          children: post.tags
                              .map(
                                (tag) => Chip(
                                  label: Text('#$tag'),
                                  backgroundColor: Theme.of(
                                    context,
                                  ).primaryColor.withValues(alpha: 0.1),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Engagement stats
                      Row(
                        children: [
                          const Icon(
                            Icons.favorite,
                            size: 16,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 4),
                          Text('${post.likesCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.comment, size: 16),
                          const SizedBox(width: 4),
                          Text('${post.commentsCount}'),
                          const SizedBox(width: 16),
                          const Icon(Icons.share, size: 16),
                          const SizedBox(width: 4),
                          Text('${post.sharesCount}'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _handleLike(post);
                    },
                    icon: Icon(
                      post.isLikedByCurrentUser
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: post.isLikedByCurrentUser ? Colors.red : null,
                    ),
                    label: const Text('Like'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Navigate to comments screen
                      Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (context) => CommentsScreen(post: post),
                        ),
                      );
                    },
                    icon: const Icon(Icons.comment),
                    label: const Text('Comment'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Implement share functionality
                      _handleShare(post);
                    },
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPostTime(DateTime postTime) {
    final now = DateTime.now();
    final difference = now.difference(postTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  void _handleLike(PostModel post) async {
    try {
      AppLogger.info('🤍 User attempting to like post: ${post.id}');

      // Check authentication first
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        AppLogger.error('🤍 User not authenticated, cannot like post');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to like posts')),
        );
        return;
      }
      AppLogger.info('🤍 User authenticated: ${user.uid}');

      // Optimistically update UI
      final postIndex = posts.indexWhere((p) => p.id == post.id);
      if (postIndex != -1) {
        AppLogger.info('🤍 Found post at index $postIndex');
        setState(() {
          final currentLikeCount = posts[postIndex].engagementStats.likeCount;
          final isCurrentlyLiked = posts[postIndex].isLikedByCurrentUser;

          AppLogger.info(
            '🤍 Current like count: $currentLikeCount, Currently liked: $isCurrentlyLiked',
          );

          // Create new engagement stats with updated like count
          final newEngagementStats = EngagementStats(
            likeCount: isCurrentlyLiked
                ? currentLikeCount - 1
                : currentLikeCount + 1,
            commentCount: posts[postIndex].engagementStats.commentCount,
            shareCount: posts[postIndex].engagementStats.shareCount,
            lastUpdated: DateTime.now(),
          );

          // Update the post with new like state
          posts[postIndex] = posts[postIndex].copyWith(
            isLikedByCurrentUser: !isCurrentlyLiked,
            engagementStats: newEngagementStats,
          );

          AppLogger.info(
            '🤍 Updated UI optimistically - new like count: ${newEngagementStats.likeCount}, new liked state: ${!isCurrentlyLiked}',
          );
        });
      } else {
        AppLogger.error('🤍 Post not found in _posts list');
      }

      AppLogger.info('🤍 Making API call to toggle like...');
      // Make the actual API call
      final success = await widget.communityService.toggleLike(post.id);
      AppLogger.info('🤍 API call result: $success');

      if (!success) {
        AppLogger.warning('🤍 API call failed, reverting optimistic update');
        // Revert the optimistic update if the API call failed
        if (postIndex != -1) {
          setState(() {
            final currentLikeCount = posts[postIndex].engagementStats.likeCount;
            final isCurrentlyLiked = posts[postIndex].isLikedByCurrentUser;

            final revertedEngagementStats = EngagementStats(
              likeCount: isCurrentlyLiked
                  ? currentLikeCount - 1
                  : currentLikeCount + 1,
              commentCount: posts[postIndex].engagementStats.commentCount,
              shareCount: posts[postIndex].engagementStats.shareCount,
              lastUpdated: DateTime.now(),
            );

            posts[postIndex] = posts[postIndex].copyWith(
              isLikedByCurrentUser: !isCurrentlyLiked,
              engagementStats: revertedEngagementStats,
            );
          });
        }
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like. Please try again.'),
          ),
        );
      } else {
        AppLogger.info('🤍 Like successfully updated!');
      }
    } catch (e) {
      AppLogger.error('Error handling like: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error updating like. Please try again.')),
      );
    }
  }

  void _handleComment(PostModel post) {
    AppLogger.info('💬 User attempting to open comments for post: ${post.id}');

    // Check authentication first
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppLogger.error('💬 User not authenticated, cannot view comments');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to view and add comments'),
        ),
      );
      return;
    }
    AppLogger.info('💬 User authenticated: ${user.uid}');

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        AppLogger.info('💬 Comments modal builder called');
        return CommentsModal(
          post: post,
          communityService: widget.communityService,
          onCommentAdded: () => loadPosts(widget.communityService),
        );
      },
    );
  }

  void _handleShare(PostModel post) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to share posts')),
        );
        return;
      }

      // Create a new post that shares the original post
      String shareContent = 'Shared from ARTbeat Community\n\n';
      if (post.content.isNotEmpty) {
        shareContent += '"${post.content}"\n\n';
      }
      shareContent += 'Originally posted by ${post.userName}';

      if (post.location.isNotEmpty) {
        shareContent += ' • ${post.location}';
      }

      if (post.tags.isNotEmpty) {
        shareContent += '\n\n${post.tags.map((tag) => '#$tag').join(' ')}';
      }

      // Create the shared post
      final postId = await widget.communityService.createPost(
        content: shareContent,
        imageUrls: post.imageUrls, // Include the original images
        tags: post.tags,
        isArtistPost: false, // Shared posts are not automatically artist posts
      );

      if (postId != null) {
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Post shared successfully!')),
          );
        }

        // Refresh the feed to show the new shared post
        await loadPosts(widget.communityService);

        // Also increment the share count on the original post
        widget.communityService.incrementShareCount(post.id);
      } else {
        throw Exception('Failed to create shared post');
      }
    } catch (e) {
      AppLogger.error('Error sharing post: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share post. Please try again.'),
          ),
        );
      }
    }
  }

  void _showFullscreenImage(
    String imageUrl,
    int initialIndex,
    List<String> allImages,
  ) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (context) => FullscreenImageViewer(
        imageUrls: allImages,
        initialIndex: initialIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    if (_feedItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.palette_outlined,
                size: 64,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No posts or activities yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Be the first to share your creative work or complete an art walk!',
              style: TextStyle(color: ArtbeatColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            // Filter toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Show Activities'),
                Switch(
                  value: _showActivities,
                  onChanged: (value) => _toggleActivitiesFilter(),
                  activeThumbColor: ArtbeatColors.primaryPurple,
                ),
              ],
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await loadPosts(widget.communityService);
        await _loadActivities();
      },
      color: ArtbeatColors.primaryPurple,
      child: CustomScrollView(
        slivers: [
          // Filter toggle at the top
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Show Activities',
                    style: TextStyle(
                      fontSize: 14,
                      color: ArtbeatColors.textSecondary,
                    ),
                  ),
                  Switch(
                    value: _showActivities,
                    onChanged: (value) => _toggleActivitiesFilter(),
                    activeThumbColor: ArtbeatColors.primaryPurple,
                  ),
                ],
              ),
            ),
          ),

          // Combined feed list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index >= _feedItems.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ArtbeatColors.primaryPurple,
                        ),
                      ),
                    ),
                  );
                }

                final item = _feedItems[index];

                if (item is PostModel) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: EnhancedPostCard(
                      post: item,
                      onTap: () => _handlePostTap(item),
                      onLike: () => _handleLike(item),
                      onComment: () => _handleComment(item),
                      onShare: () => _handleShare(item),
                      onImageTap: (String imageUrl, int imgIndex) =>
                          _showFullscreenImage(
                            imageUrl,
                            imgIndex,
                            item.imageUrls,
                          ),
                      onBlockStatusChanged: () =>
                          loadPosts(widget.communityService),
                    ),
                  );
                } else if (item is art_walk.SocialActivity) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: ActivityCard(
                      activity: item,
                      onTap: () {
                        // Handle activity tap - could show details or navigate
                        AppLogger.info('Activity tapped: ${item.message}');
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              }, childCount: _feedItems.length),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Artists tab - Gallery of artist profiles
class ArtistsGalleryTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const ArtistsGalleryTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<ArtistsGalleryTab> createState() => _ArtistsGalleryTabState();
}

class _ArtistsGalleryTabState extends State<ArtistsGalleryTab> {
  List<ArtistProfile> _artists = [];
  List<ArtistProfile> _filteredArtists = [];
  bool _isLoading = true;
  late artist_community.CommunityService _artistCommunityService;

  @override
  void initState() {
    super.initState();
    _artistCommunityService = artist_community.CommunityService();
    _loadArtists();
  }

  @override
  void didUpdateWidget(ArtistsGalleryTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterArtists();
    }
  }

  Future<void> _loadArtists() async {
    setState(() => _isLoading = true);

    try {
      AppLogger.info('🎨 Loading artists...');
      // Fetch artists from Firestore
      final artists = await widget.communityService.fetchArtists(limit: 20);

      AppLogger.info('🎨 Loaded ${artists.length} artists');
      if (artists.isNotEmpty) {
        AppLogger.info(
          '🎨 First artist: ${artists.first.displayName}, avatar: ${artists.first.avatarUrl}, portfolio images: ${artists.first.portfolioImages.length}',
        );
      }

      if (mounted) {
        setState(() {
          _artists = artists;
          _filteredArtists = artists;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('🎨 Error loading artists: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading artists: $e')));
      }
    }
  }

  void _filterArtists() {
    setState(() {
      if (widget.searchQuery.isEmpty) {
        _filteredArtists = _artists;
      } else {
        _filteredArtists = _artists.where((artist) {
          final displayName = artist.displayName.toLowerCase();
          final bio = artist.bio.toLowerCase();

          return displayName.contains(widget.searchQuery) ||
              bio.contains(widget.searchQuery);
        }).toList();
      }
    });
  }

  void _handleArtistTap(ArtistProfile artist) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ArtistFeedScreen(
          artistId: artist.userId,
          artistName: artist.displayName,
        ),
      ),
    );
  }

  void _handleFollow(ArtistProfile artist, bool isFollowing) async {
    try {
      final success = isFollowing
          ? await _artistCommunityService.followArtist(artist.userId)
          : await _artistCommunityService.unfollowArtist(artist.userId);

      if (!success) {
        // Only show error message and revert on failure
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFollowing
                  ? 'Failed to follow artist'
                  : 'Failed to unfollow artist',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        // Revert optimistic update by refreshing - this will restore correct follow state and counts
        _loadArtists();
      }
      // On success, do nothing - the optimistic update in ArtistCard is sufficient
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error ${isFollowing ? 'following' : 'unfollowing'} artist: $e',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      // Revert optimistic update by refreshing - this will restore correct follow state and counts
      _loadArtists();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    if (_artists.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.people_outline,
                size: 64,
                color: ArtbeatColors.primaryPurple,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No artists yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Artists will appear here as they join the community',
              style: TextStyle(color: ArtbeatColors.textSecondary, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Call-to-action to become an artist
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    '🎨 Ready to showcase your art?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join our artist community and share your creative work with the world',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute<bool>(
                          builder: (context) => const ArtistOnboardingScreen(),
                        ),
                      );

                      if (result == true && mounted) {
                        // Refresh the artists list after successful onboarding
                        _loadArtists();
                        // ignore: use_build_context_synchronously
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Welcome to the artist community! 🎉',
                            ),
                            duration: Duration(seconds: 3),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.brush, color: Colors.white),
                    label: const Text(
                      'Become an Artist',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      foregroundColor: Colors.white,
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
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadArtists,
      color: ArtbeatColors.primaryPurple,
      child: CustomScrollView(
        slivers: [
          // Ad1 - Community & Social Zone
          const SliverToBoxAdapter(child: SizedBox.shrink()),

          // Commission Artists Browser
          SliverToBoxAdapter(
            child: CommissionArtistsBrowser(
              onCommissionRequest: () {
                // Refresh artists after commission request
                _loadArtists();
              },
            ),
          ),

          // Divider
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Divider(),
            ),
          ),

          // Section title
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'All Artists',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Artists grid - 2 columns with mini cards
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 columns
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75, // Taller than wide for mini cards
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final artist = _filteredArtists[index];

                // Insert ads every 6 artists (3 rows)
                if (index > 0 && index % 6 == 0) {
                  return Column(
                    children: [
                      // Ad placement
                      const SizedBox.shrink(),
                      const SizedBox(height: 8),
                      // Mini artist card
                      Expanded(
                        child: MiniArtistCard(
                          artist: artist,
                          onTap: () => _handleArtistTap(artist),
                          onFollow: (isFollowing) =>
                              _handleFollow(artist, isFollowing),
                        ),
                      ),
                    ],
                  );
                }

                return MiniArtistCard(
                  artist: artist,
                  onTap: () => _handleArtistTap(artist),
                  onFollow: (isFollowing) => _handleFollow(artist, isFollowing),
                );
              }, childCount: _filteredArtists.length),
            ),
          ),

          // Ad at the bottom
          const SliverToBoxAdapter(child: SizedBox.shrink()),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}

/// Groups tab - User-created group feeds
class GroupsTab extends StatefulWidget {
  final ArtCommunityService communityService;
  final String searchQuery;

  const GroupsTab({
    super.key,
    required this.communityService,
    this.searchQuery = '',
  });

  @override
  State<GroupsTab> createState() => _GroupsTabState();
}

class _GroupsTabState extends State<GroupsTab> {
  List<GroupModel> _groups = [];
  List<GroupModel> _filteredGroups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  @override
  void didUpdateWidget(GroupsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchQuery != widget.searchQuery) {
      _filterGroups();
    }
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    try {
      // Load groups from Firestore
      final groupsSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .orderBy('memberCount', descending: true)
          .limit(20)
          .get();

      final groups = groupsSnapshot.docs.map((DocumentSnapshot doc) {
        final data = doc.data() as Map<String, dynamic>;
        return GroupModel(
          id: doc.id,
          name: data['name'] as String? ?? 'Unknown',
          description: data['description'] as String? ?? '',
          iconUrl: data['iconUrl'] as String? ?? '',
          memberCount: data['memberCount'] as int? ?? 0,
          postCount: data['postCount'] as int? ?? 0,
          createdBy: data['createdBy'] as String? ?? '',
          color: data['color'] as String? ?? '#8B5CF6',
        );
      }).toList();

      if (mounted) {
        setState(() {
          _groups = groups;
          _filteredGroups = groups;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading groups: $e');
      if (mounted) {
        setState(() {
          _groups = [];
          _filteredGroups = [];
          _isLoading = false;
        });
      }
    }
  }

  void _filterGroups() {
    setState(() {
      if (widget.searchQuery.isEmpty) {
        _filteredGroups = _groups;
      } else {
        _filteredGroups = _groups
            .where(
              (group) =>
                  group.name.toLowerCase().contains(
                    widget.searchQuery.toLowerCase(),
                  ) ||
                  group.description.toLowerCase().contains(
                    widget.searchQuery.toLowerCase(),
                  ),
            )
            .toList();
      }
    });
  }

  void _handleGroupTap(GroupModel group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            GroupFeedScreen(groupId: group.id, groupName: group.name),
      ),
    );
  }

  void _showCreateGroupDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    ).then((_) => _loadGroups()); // Refresh groups after creation
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            ArtbeatColors.primaryPurple,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadGroups,
      color: ArtbeatColors.primaryPurple,
      child: CustomScrollView(
        slivers: [
          // Header with create button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Groups',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: ArtbeatColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Join communities and share your art',
                          style: TextStyle(
                            color: ArtbeatColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showCreateGroupDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Create Group'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ArtbeatColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Groups grid
          if (_filteredGroups.isEmpty) ...[
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: ArtbeatColors.primaryPurple.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.group_outlined,
                        size: 64,
                        color: ArtbeatColors.primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No groups found',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Be the first to create a group!',
                      style: TextStyle(
                        color: ArtbeatColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showCreateGroupDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Group'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ArtbeatColors.primaryPurple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final group = _filteredGroups[index];
                  return _buildGroupCard(group);
                }, childCount: _filteredGroups.length),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupCard(GroupModel group) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () => _handleGroupTap(group),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(
                  int.parse(group.color.replaceFirst('#', ''), radix: 16) +
                      0xFF000000,
                ).withValues(alpha: 0.1),
                Color(
                  int.parse(group.color.replaceFirst('#', ''), radix: 16) +
                      0xFF000000,
                ).withValues(alpha: 0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon/Image
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Color(
                    int.parse(group.color.replaceFirst('#', ''), radix: 16) +
                        0xFF000000,
                  ).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: group.iconUrl.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          group.iconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(
                                Icons.group,
                                color: ArtbeatColors.primaryPurple,
                              ),
                        ),
                      )
                    : Icon(
                        Icons.group,
                        size: 30,
                        color: Color(
                          int.parse(
                                group.color.replaceFirst('#', ''),
                                radix: 16,
                              ) +
                              0xFF000000,
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              // Group name
              Text(
                group.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Description
              if (group.description.isNotEmpty) ...[
                Text(
                  group.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: ArtbeatColors.textSecondary,
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],

              // Member and post counts
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${group.memberCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: ArtbeatColors.primaryPurple,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.people,
                    size: 12,
                    color: ArtbeatColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${group.postCount}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: ArtbeatColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.article,
                    size: 12,
                    color: ArtbeatColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Model for group data
class GroupModel {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final int memberCount;
  final int postCount;
  final String createdBy;
  final String color;

  const GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.memberCount,
    required this.postCount,
    required this.createdBy,
    required this.color,
  });

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unknown',
      description: map['description'] as String? ?? '',
      iconUrl: map['iconUrl'] as String? ?? '',
      memberCount: map['memberCount'] as int? ?? 0,
      postCount: map['postCount'] as int? ?? 0,
      createdBy: map['createdBy'] as String? ?? '',
      color: map['color'] as String? ?? '#8B5CF6',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconUrl': iconUrl,
      'memberCount': memberCount,
      'postCount': postCount,
      'createdBy': createdBy,
      'color': color,
    };
  }
}

/// Dialog for creating new groups
class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({super.key});

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createGroup() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to create a group')),
        );
        return;
      }

      // Create group document
      final groupRef = await FirebaseFirestore.instance
          .collection('groups')
          .add({
            'name': _nameController.text.trim(),
            'description': _descriptionController.text.trim(),
            'createdBy': user.uid,
            'memberCount': 1,
            'postCount': 0,
            'color': '#8B5CF6',
            'createdAt': FieldValue.serverTimestamp(),
          });

      // Add creator as first member
      await FirebaseFirestore.instance.collection('groupMembers').add({
        'groupId': groupRef.id,
        'userId': user.uid,
        'role': 'admin',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created successfully!')),
        );
      }
    } catch (e) {
      AppLogger.error('Error creating group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create group. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Group'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Group Name',
              hintText: 'Enter group name',
            ),
            maxLength: 50,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'Describe your group',
            ),
            maxLength: 200,
            maxLines: 3,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createGroup,
          style: ElevatedButton.styleFrom(
            backgroundColor: ArtbeatColors.primaryPurple,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}
