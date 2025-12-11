import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/activity_model.dart';
import '../widgets/artist_header.dart';
import '../widgets/local_artists_row_widget.dart';
import '../widgets/local_galleries_widget.dart';
import '../widgets/upcoming_events_row_widget.dart';
import '../widgets/artist_subscription_cta_widget.dart';
import '../services/earnings_service.dart';
import '../services/analytics_service.dart';
import '../models/earnings_model.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  State<ArtistDashboardScreen> createState() => _ArtistDashboardScreenState();
}

class _ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  final _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  // Services
  final EarningsService _earningsService = EarningsService();
  final AnalyticsService _analyticsService = AnalyticsService();

  bool _isLoading = true;
  String? _error;
  EarningsModel? _earnings;
  Map<String, dynamic> _analytics = {};
  List<ActivityModel> _recentActivities = [];

  @override
  void initState() {
    super.initState();
    _loadArtistData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadArtistData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load real data from services
      final earnings = await _earningsService.getArtistEarnings();
      final analytics = await _loadAnalyticsData();

      // Load recent activities from various sources
      final activities = await _loadRecentActivities();

      if (mounted) {
        setState(() {
          _earnings = earnings;
          _analytics = analytics;
          _recentActivities = activities;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> _loadAnalyticsData() async {
    try {
      final userId = _analyticsService.getCurrentUserId();
      if (userId == null) return {};

      // Get artwork count and other analytics
      final artworkCount = await _getArtworkCount(userId);
      final profileViews = await _getProfileViews(userId);

      return {
        'artworkCount': artworkCount,
        'profileViews': profileViews,
        'totalSales': _earnings?.totalEarnings ?? 0.0,
      };
    } catch (e) {
      return {};
    }
  }

  Future<int> _getArtworkCount(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artwork')
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getProfileViews(String userId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artistProfileViews')
          .where('artistId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<ActivityModel>> _loadRecentActivities() async {
    final activities = <ActivityModel>[];

    try {
      final userId = _analyticsService.getCurrentUserId();
      if (userId == null) return activities;

      // Load recent artwork sales
      final salesActivities = await _loadSalesActivities(userId);
      activities.addAll(salesActivities);

      // Load recent commission requests
      final commissionActivities = await _loadCommissionActivities(userId);
      activities.addAll(commissionActivities);

      // Load recent gift activities
      final giftActivities = await _loadGiftActivities(userId);
      activities.addAll(giftActivities);

      // Sort by most recent and take top 5
      activities.sort((a, b) => b.timeAgo.compareTo(a.timeAgo));
      return activities.take(5).toList();
    } catch (e) {
      return activities;
    }
  }

  Future<List<ActivityModel>> _loadSalesActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('artwork_sales')
          .where('artistId', isEqualTo: userId)
          .orderBy('soldAt', descending: true)
          .limit(3)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final artworkTitle = data['artworkTitle'] as String? ?? 'Artwork';
        final soldAt = (data['soldAt'] as Timestamp?)?.toDate();

        activities.add(ActivityModel(
          type: ActivityType.sale,
          title: 'Artwork Sold',
          description: '"$artworkTitle" was sold',
          timeAgo: soldAt != null ? _formatTimeAgo(soldAt) : 'Recently',
        ));
      }
    } catch (e) {
      // Handle error silently
    }

    return activities;
  }

  Future<List<ActivityModel>> _loadCommissionActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('commission_requests')
          .where('artistId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(3)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

        activities.add(ActivityModel(
          type: ActivityType.commission,
          title: 'Commission Request',
          description: 'New commission inquiry received',
          timeAgo: createdAt != null ? _formatTimeAgo(createdAt) : 'Recently',
        ));
      }
    } catch (e) {
      // Handle error silently
    }

    return activities;
  }

  Future<List<ActivityModel>> _loadGiftActivities(String userId) async {
    final activities = <ActivityModel>[];

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('gift_purchases')
          .where('recipientArtistId', isEqualTo: userId)
          .orderBy('purchasedAt', descending: true)
          .limit(2)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final purchasedAt = (data['purchasedAt'] as Timestamp?)?.toDate();
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        activities.add(ActivityModel(
          type: ActivityType.gift,
          title: 'Gift Received',
          description: 'Received a gift of \$${amount.toStringAsFixed(2)}',
          timeAgo:
              purchasedAt != null ? _formatTimeAgo(purchasedAt) : 'Recently',
        ));
      }
    } catch (e) {
      // Handle error silently
    }

    return activities;
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    final updatedColor = color.withValues(alpha: color.a);
    return Card(
      elevation: 2,
      shadowColor: updatedColor.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: updatedColor,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: updatedColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistMarketingSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('art_walk_artist_marketing'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.campaign,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('art_walk_promote_your_art'.tr(),
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text('art_walk_create_ads_featuring_your_artwork_to_reach_more_art_lovers'.tr(),
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue.shade700,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/ads/create'),
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text('ads_create_local_ad_text_create_ad'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Premium feature: Create engaging ads with your artwork',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ArtistSubscriptionCTAWidget(
          onSubscribePressed: () =>
              Navigator.pushNamed(context, '/subscription/artist'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: 1, // Artist Dashboard tab in bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: const ArtistHeader(
        title: 'Artist Dashboard',
        showBackButton: false,
        showSearch: false,
        showDeveloper: true,
      ),
      drawer: const core.ArtbeatDrawer(),
      child: _buildDashboardContent(),
    );
  }

  Widget _buildDashboardContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text('art_walk_error_loading_dashboard'.tr(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadArtistData,
              child: Text('admin_admin_settings_text_retry'.tr()),
            ),
          ],
        ),
      );
    }

    final surfaceColor = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            surfaceColor,
            surfaceColor.withValues(alpha: 0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Stats Overview Section
                  Text('art_walk_overview'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 4 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildStatCard(
                        'Total Earnings',
                        '\$${_earnings?.totalEarnings.toStringAsFixed(2) ?? '0.00'}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'Available Balance',
                        '\$${_earnings?.availableBalance.toStringAsFixed(2) ?? '0.00'}',
                        Icons.account_balance_wallet,
                        Colors.teal,
                      ),
                      _buildStatCard(
                        'Total Artworks',
                        _analytics['artworkCount']?.toString() ?? '0',
                        Icons.palette,
                        Colors.blue,
                      ),
                      _buildStatCard(
                        'Profile Views',
                        _analytics['profileViews']?.toString() ?? '0',
                        Icons.visibility,
                        Colors.indigo,
                      ),
                      _buildStatCard(
                        'Gift Earnings',
                        '\$${_earnings?.giftEarnings.toStringAsFixed(2) ?? '0.00'}',
                        Icons.card_giftcard,
                        Colors.purple,
                      ),
                      _buildStatCard(
                        'Commission Earnings',
                        '\$${_earnings?.commissionEarnings.toStringAsFixed(2) ?? '0.00'}',
                        Icons.work,
                        Colors.amber,
                      ),
                      _buildStatCard(
                        'Sponsorships',
                        '\$${_earnings?.sponsorshipEarnings.toStringAsFixed(2) ?? '0.00'}',
                        Icons.handshake,
                        Colors.orange,
                      ),
                      _buildStatCard(
                        'Pending Balance',
                        '\$${_earnings?.pendingBalance.toStringAsFixed(2) ?? '0.00'}',
                        Icons.pending,
                        Colors.red,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Quick Actions Section - Moved to top
                  _buildQuickActionsSection(context),
                  const SizedBox(height: 24),

                  // Local Artists Section
                  Text('art_walk_local_artists'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  LocalArtistsRowWidget(
                    zipCode:
                        '10001', // Default NYC zip code - should be user's location
                    onSeeAllPressed: () =>
                        Navigator.pushNamed(context, '/artist/browse'),
                  ),
                  const SizedBox(height: 24),

                  // Local Galleries Section
                  Text('art_walk_local_galleries___museums'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  LocalGalleriesWidget(
                    zipCode:
                        '10001', // Default NYC zip code - should be user's location
                    onSeeAllPressed: () =>
                        Navigator.pushNamed(context, '/galleries/browse'),
                  ),
                  const SizedBox(height: 24),

                  // Upcoming Events Section
                  Text('art_walk_upcoming_events'.tr(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  UpcomingEventsRowWidget(
                    zipCode:
                        '10001', // Default NYC zip code - should be user's location
                    onSeeAllPressed: () =>
                        Navigator.pushNamed(context, '/events/browse'),
                  ),
                  const SizedBox(height: 24),

                  // Artist Marketing Section
                  _buildArtistMarketingSection(context),
                  const SizedBox(height: 24),

                  // Recent Activity Section
                  if (_recentActivities.isNotEmpty) ...[
                    Text('art_walk_recent_activity'.tr(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _recentActivities.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final activity = _recentActivities[index];
                        final activityColor = activity.type.color;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: activityColor.withValues(
                              alpha: 0.2,
                            ),
                            child: Icon(
                              activity.type.icon,
                              color: activityColor,
                            ),
                          ),
                          title: Text(activity.title),
                          subtitle: Text(activity.description),
                          trailing: Text(
                            activity.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/artist/activity');
                        },
                        child: Text('artist_artist_dashboard_text_view_all_activity'.tr()),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('art_walk_quick_actions'.tr(),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Add Post',
                subtitle: 'Share updates with your community',
                icon: Icons.post_add,
                gradient: const LinearGradient(
                  colors: [Colors.purple, Colors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _showCreatePostOptions(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Upload Artwork',
                subtitle: 'Add new artwork to your portfolio',
                icon: Icons.add_photo_alternate,
                gradient: const LinearGradient(
                  colors: [Colors.blue, Colors.cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/artwork/upload'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Create Event',
                subtitle: 'Host exhibitions and gatherings',
                icon: Icons.event,
                gradient: const LinearGradient(
                  colors: [Colors.orange, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/events/create'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'View Analytics',
                subtitle: 'Track your performance',
                icon: Icons.analytics,
                gradient: const LinearGradient(
                  colors: [Colors.green, Colors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/artist/analytics'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Commission Wizard',
                subtitle: 'Set up commission settings',
                icon: Icons.auto_awesome,
                gradient: const LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => _navigateToCommissionWizard(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildThemedActionButton(
                context,
                title: 'Commission Hub',
                subtitle: 'Manage your commissions',
                icon: Icons.work_outline,
                gradient: const LinearGradient(
                  colors: [Colors.indigo, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                onTap: () => Navigator.pushNamed(context, '/commission/hub'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCreatePostOptions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.8,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.post_add,
                      color: Colors.purple,
                      size: 28,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('art_walk_create_post'.tr(),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text('art_walk_share_updates_with_your_community'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Create options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildPostOption(
                      context,
                      title: 'Text Post',
                      subtitle: 'Share your thoughts and updates',
                      icon: Icons.text_fields,
                      color: Colors.purple,
                      onTap: () => _createTextPost(context),
                    ),
                    const SizedBox(height: 12),
                    _buildPostOption(
                      context,
                      title: 'Artwork Post',
                      subtitle: 'Showcase your latest creation',
                      icon: Icons.palette,
                      color: Colors.blue,
                      onTap: () => _createArtworkPost(context),
                    ),
                    const SizedBox(height: 12),
                    _buildPostOption(
                      context,
                      title: 'Event Post',
                      subtitle: 'Announce upcoming events',
                      icon: Icons.event,
                      color: Colors.orange,
                      onTap: () => _createEventPost(context),
                    ),
                    const SizedBox(height: 12),
                    _buildPostOption(
                      context,
                      title: 'Photo Post',
                      subtitle: 'Share photos from your studio',
                      icon: Icons.photo_camera,
                      color: Colors.green,
                      onTap: () => _createPhotoPost(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[200]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _createTextPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  void _createArtworkPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  void _createEventPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  void _createPhotoPost(BuildContext context) {
    Navigator.pop(context);
    // Navigate to general post creation screen
    Navigator.pushNamed(context, '/community/create');
  }

  Widget _buildThemedActionButton(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    required VoidCallback onTap,
  }) {
    return Container(
      height: 140, // Increased from 120 to prevent overflow
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const Spacer(),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14, // Slightly smaller font
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2), // Reduced from 4
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11, // Slightly smaller font
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToCommissionWizard(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const community.CommissionSetupWizardScreen(
          mode: community.SetupMode.firstTime,
        ),
      ),
    );
  }
}
