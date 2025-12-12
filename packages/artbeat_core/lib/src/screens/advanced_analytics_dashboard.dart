import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/logger.dart';
import 'package:easy_localization/easy_localization.dart';

/// Advanced analytics dashboard providing cross-package insights
class AdvancedAnalyticsDashboard extends StatefulWidget {
  const AdvancedAnalyticsDashboard({super.key});

  @override
  State<AdvancedAnalyticsDashboard> createState() =>
      _AdvancedAnalyticsDashboardState();
}

class _AdvancedAnalyticsDashboardState extends State<AdvancedAnalyticsDashboard>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _analyticsData = {};
  String _selectedTimeRange = '7d';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() => _isLoading = true);

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final endDate = DateTime.now();
      final startDate = _getStartDateForRange(_selectedTimeRange);

      // Load analytics from all packages
      final futures = await Future.wait([
        _loadArtWalkAnalytics(userId, startDate, endDate),
        _loadArtworkAnalytics(userId, startDate, endDate),
        _loadCommunityAnalytics(userId, startDate, endDate),
        _loadCaptureAnalytics(userId, startDate, endDate),
        _loadProfileAnalytics(userId, startDate, endDate),
        _loadEngagementAnalytics(userId, startDate, endDate),
      ]);

      setState(() {
        _analyticsData = {
          'artWalk': futures[0],
          'artwork': futures[1],
          'community': futures[2],
          'capture': futures[3],
          'profile': futures[4],
          'engagement': futures[5],
          'summary': _generateSummary(futures),
        };
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  DateTime _getStartDateForRange(String range) {
    final now = DateTime.now();
    switch (range) {
      case '1d':
        return now.subtract(const Duration(days: 1));
      case '7d':
        return now.subtract(const Duration(days: 7));
      case '30d':
        return now.subtract(const Duration(days: 30));
      case '90d':
        return now.subtract(const Duration(days: 90));
      default:
        return now.subtract(const Duration(days: 7));
    }
  }

  Future<Map<String, dynamic>> _loadArtWalkAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final walksQuery = await _firestore
          .collection('artWalks')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      final completedWalks = walksQuery.docs.where((doc) {
        final data = doc.data();
        return data['status'] == 'completed';
      }).length;

      final totalDistance = walksQuery.docs.fold<double>(0.0, (sum, doc) {
        final data = doc.data();
        final distance = data['distance'];
        return sum + (distance != null ? (distance as num).toDouble() : 0.0);
      });

      return {
        'totalWalks': walksQuery.docs.length,
        'completedWalks': completedWalks,
        'totalDistance': totalDistance,
        'averageDistance': walksQuery.docs.isNotEmpty
            ? totalDistance / walksQuery.docs.length
            : 0.0,
        'completionRate': walksQuery.docs.isNotEmpty
            ? (completedWalks / walksQuery.docs.length * 100)
            : 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _loadArtworkAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final artworksQuery = await _firestore
          .collection('artworks')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      final totalViews = artworksQuery.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + (data['views'] as int? ?? 0);
      });

      final totalLikes = artworksQuery.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + (data['likes'] as int? ?? 0);
      });

      return {
        'totalArtworks': artworksQuery.docs.length,
        'totalViews': totalViews,
        'totalLikes': totalLikes,
        'averageViews': artworksQuery.docs.isNotEmpty
            ? totalViews / artworksQuery.docs.length
            : 0.0,
        'averageLikes': artworksQuery.docs.isNotEmpty
            ? totalLikes / artworksQuery.docs.length
            : 0.0,
        'engagementRate': totalViews > 0
            ? (totalLikes / totalViews * 100)
            : 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _loadCommunityAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final postsQuery = await _firestore
          .collection('community_posts')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      final commentsQuery = await _firestore
          .collection('comments')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      return {
        'totalPosts': postsQuery.docs.length,
        'totalComments': commentsQuery.docs.length,
        'totalInteractions': postsQuery.docs.length + commentsQuery.docs.length,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _loadCaptureAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final capturesQuery = await _firestore
          .collection('captures')
          .where('userId', isEqualTo: userId)
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      final photoCount = capturesQuery.docs.where((doc) {
        final data = doc.data();
        return data['type'] == 'photo';
      }).length;

      final videoCount = capturesQuery.docs.where((doc) {
        final data = doc.data();
        return data['type'] == 'video';
      }).length;

      return {
        'totalCaptures': capturesQuery.docs.length,
        'photoCount': photoCount,
        'videoCount': videoCount,
        'photoPercentage': capturesQuery.docs.isNotEmpty
            ? (photoCount / capturesQuery.docs.length * 100)
            : 0.0,
        'videoPercentage': capturesQuery.docs.isNotEmpty
            ? (videoCount / capturesQuery.docs.length * 100)
            : 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _loadProfileAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final profileDoc = await _firestore.collection('users').doc(userId).get();
      final profileData = profileDoc.data() ?? {};

      final followersCount = profileData['followersCount'] as int? ?? 0;
      final followingCount = profileData['followingCount'] as int? ?? 0;
      final profileViews = profileData['profileViews'] as int? ?? 0;

      return {
        'followersCount': followersCount,
        'followingCount': followingCount,
        'profileViews': profileViews,
        'followRatio': followingCount > 0
            ? (followersCount / followingCount)
            : 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _loadEngagementAnalytics(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final engagementQuery = await _firestore
          .collection('user_engagement')
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: startDate)
          .where('timestamp', isLessThanOrEqualTo: endDate)
          .get();

      final sessionCount = engagementQuery.docs.length;
      final totalDuration = engagementQuery.docs.fold<int>(0, (sum, doc) {
        final data = doc.data();
        return sum + (data['duration'] as int? ?? 0);
      });

      return {
        'sessionCount': sessionCount,
        'totalDuration': totalDuration,
        'averageSessionDuration': sessionCount > 0
            ? (totalDuration / sessionCount)
            : 0.0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Map<String, dynamic> _generateSummary(List<Map<String, dynamic>> data) {
    final artWalk = data[0];
    final artwork = data[1];
    final community = data[2];
    final capture = data[3];
    // Remove unused variables
    // final profile = data[4];
    // final engagement = data[5];

    return {
      'totalActivity':
          (artWalk['totalWalks'] ?? 0) +
          (artwork['totalArtworks'] ?? 0) +
          (community['totalInteractions'] ?? 0) +
          (capture['totalCaptures'] ?? 0),
      'engagementScore': _calculateEngagementScore(data),
      'mostActiveArea': _getMostActiveArea(data),
      'growthTrend':
          'positive', // This would be calculated based on historical data
    };
  }

  double _calculateEngagementScore(List<Map<String, dynamic>> data) {
    // Simple engagement score calculation
    final artwork = data[1];
    final community = data[2];
    final profile = data[4];

    final artworkScore =
        ((artwork['engagementRate'] ?? 0.0) as num).toDouble() * 0.4;
    final communityScore =
        ((community['totalInteractions'] ?? 0) as num).toDouble() * 0.3;
    final profileScore =
        ((profile['followRatio'] ?? 0.0) as num).toDouble() * 0.3;

    return artworkScore + communityScore + profileScore;
  }

  String _getMostActiveArea(List<Map<String, dynamic>> data) {
    final activities = {
      'Art Walk': (data[0]['totalWalks'] ?? 0) as int,
      'Artwork': (data[1]['totalArtworks'] ?? 0) as int,
      'Community': (data[2]['totalInteractions'] ?? 0) as int,
      'Capture': (data[3]['totalCaptures'] ?? 0) as int,
    };

    return activities.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('core_analytics_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Art Walk'),
            Tab(text: 'Artwork'),
            Tab(text: 'Community'),
            Tab(text: 'Capture'),
            Tab(text: 'Profile'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            initialValue: _selectedTimeRange,
            onSelected: (value) {
              setState(() => _selectedTimeRange = value);
              _loadAnalyticsData();
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: '1d',
                child: Text('core_analytics_last24h'.tr()),
              ),
              PopupMenuItem(
                value: '7d',
                child: Text('core_analytics_last7d'.tr()),
              ),
              PopupMenuItem(
                value: '30d',
                child: Text('core_analytics_last30d'.tr()),
              ),
              PopupMenuItem(
                value: '90d',
                child: Text('core_analytics_last90d'.tr()),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildArtWalkTab(),
                _buildArtworkTab(),
                _buildCommunityTab(),
                _buildCaptureTab(),
                _buildProfileTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = _analyticsData['summary'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity Summary',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Summary cards
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Activity',
                  summary['totalActivity']?.toString() ?? '0',
                  Icons.analytics,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Engagement Score',
                  (summary['engagementScore'] as num?)?.toStringAsFixed(1) ??
                      '0.0',
                  Icons.trending_up,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Most Active Area',
                  summary['mostActiveArea']?.toString() ?? 'None',
                  Icons.star,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildSummaryCard(
                  'Growth Trend',
                  summary['growthTrend']?.toString() ?? 'Stable',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Quick insights
          const Text(
            'Quick Insights',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildInsightCard(
            'Your most active area is ${summary['mostActiveArea'] ?? 'Unknown'}',
            'Focus on this area to maximize engagement',
            Icons.lightbulb,
          ),

          _buildInsightCard(
            'Engagement score: ${(summary['engagementScore'] as num?)?.toStringAsFixed(1) ?? '0.0'}',
            'Try posting more content to increase engagement',
            Icons.trending_up,
          ),
        ],
      ),
    );
  }

  Widget _buildArtWalkTab() {
    final data = _analyticsData['artWalk'] as Map<String, dynamic>? ?? {};

    if (data.containsKey('error')) {
      return Center(child: Text('Error: ${data['error']}'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Art Walk Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Walks',
                  data['totalWalks']?.toString() ?? '0',
                  Icons.directions_walk,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Completed',
                  data['completedWalks']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Distance',
                  '${(data['totalDistance'] as num?)?.toStringAsFixed(1) ?? '0.0'} km',
                  Icons.straighten,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Completion Rate',
                  '${(data['completionRate'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.percent,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkTab() {
    final data = _analyticsData['artwork'] as Map<String, dynamic>? ?? {};

    if (data.containsKey('error')) {
      return Center(child: Text('Error: ${data['error']}'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Artwork Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Artworks',
                  data['totalArtworks']?.toString() ?? '0',
                  Icons.palette,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Views',
                  data['totalViews']?.toString() ?? '0',
                  Icons.visibility,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Likes',
                  data['totalLikes']?.toString() ?? '0',
                  Icons.favorite,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Engagement Rate',
                  '${(data['engagementRate'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityTab() {
    final data = _analyticsData['community'] as Map<String, dynamic>? ?? {};

    if (data.containsKey('error')) {
      return Center(child: Text('Error: ${data['error']}'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Community Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Posts',
                  data['totalPosts']?.toString() ?? '0',
                  Icons.post_add,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Total Comments',
                  data['totalComments']?.toString() ?? '0',
                  Icons.comment,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildMetricCard(
            'Total Interactions',
            data['totalInteractions']?.toString() ?? '0',
            Icons.people,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureTab() {
    final data = _analyticsData['capture'] as Map<String, dynamic>? ?? {};

    if (data.containsKey('error')) {
      return Center(child: Text('Error: ${data['error']}'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Capture Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Total Captures',
                  data['totalCaptures']?.toString() ?? '0',
                  Icons.camera_alt,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Photos',
                  data['photoCount']?.toString() ?? '0',
                  Icons.photo,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Videos',
                  data['videoCount']?.toString() ?? '0',
                  Icons.videocam,
                  Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Photo %',
                  '${(data['photoPercentage'] as num?)?.toStringAsFixed(1) ?? '0.0'}%',
                  Icons.pie_chart,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    final data = _analyticsData['profile'] as Map<String, dynamic>? ?? {};

    if (data.containsKey('error')) {
      return Center(child: Text('Error: ${data['error']}'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Analytics',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Followers',
                  data['followersCount']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Following',
                  data['followingCount']?.toString() ?? '0',
                  Icons.person_add,
                  Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Profile Views',
                  data['profileViews']?.toString() ?? '0',
                  Icons.visibility,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'Follow Ratio',
                  (data['followRatio'] as num?)?.toStringAsFixed(2) ?? '0.00',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(String title, String subtitle, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
