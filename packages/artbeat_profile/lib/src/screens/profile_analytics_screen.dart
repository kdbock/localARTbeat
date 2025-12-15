import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/profile_analytics_model.dart';
import '../services/profile_analytics_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileAnalyticsScreen extends StatefulWidget {
  const ProfileAnalyticsScreen({super.key});

  @override
  State<ProfileAnalyticsScreen> createState() => _ProfileAnalyticsScreenState();
}

class _ProfileAnalyticsScreenState extends State<ProfileAnalyticsScreen> {
  final ProfileAnalyticsService _analyticsService = ProfileAnalyticsService();

  bool _isLoading = true;
  ProfileAnalyticsModel? _analytics;
  Map<String, dynamic> _engagementMetrics = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    try {
      final user = Provider.of<UserService>(context, listen: false).currentUser;
      if (user != null) {
        final [analytics, metrics] = await Future.wait([
          _analyticsService.getProfileAnalytics(user.uid),
          _analyticsService.getEngagementMetrics(user.uid),
        ]);

        setState(() {
          _analytics = analytics as ProfileAnalyticsModel?;
          _engagementMetrics = metrics as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading analytics: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile_analytics_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
          ? _buildNoDataWidget()
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewSection(),
                    const SizedBox(height: 24),
                    _buildEngagementSection(),
                    const SizedBox(height: 24),
                    _buildViewsSection(),
                    const SizedBox(height: 24),
                    _buildTopViewersSection(),
                    const SizedBox(height: 24),
                    _buildTrendsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildNoDataWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No Analytics Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your profile analytics will appear here once you start gaining activity.',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: Text('profile_analytics_refresh'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            _buildMetricCard(
              'Profile Views',
              _analytics!.profileViews.toString(),
              Icons.visibility,
              Colors.blue,
            ),
            _buildMetricCard(
              'Followers',
              _analytics!.totalFollowers.toString(),
              Icons.people,
              Colors.green,
            ),
            _buildMetricCard(
              'Following',
              _analytics!.totalFollowing.toString(),
              Icons.person_add,
              Colors.orange,
            ),
            _buildMetricCard(
              'Posts',
              _analytics!.totalPosts.toString(),
              Icons.post_add,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEngagementSection() {
    final engagementRate = _engagementMetrics['engagementRate'] ?? 0.0;
    final totalEngagements = _engagementMetrics['totalEngagements'] ?? 0;
    final growthTrend = _engagementMetrics['growthTrend'] ?? 'stable';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Engagement',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildEngagementMetric(
                      'Engagement Rate',
                      '${engagementRate.toStringAsFixed(1)}%',
                      Icons.trending_up,
                    ),
                    _buildEngagementMetric(
                      'Total Engagements',
                      totalEngagements.toString(),
                      Icons.favorite,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildTrendIndicator(growthTrend.toString()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildSmallMetricCard(
              'Likes',
              _analytics!.totalLikes,
              Icons.favorite,
              Colors.red,
            ),
            _buildSmallMetricCard(
              'Comments',
              _analytics!.totalComments,
              Icons.comment,
              Colors.blue,
            ),
            _buildSmallMetricCard(
              'Shares',
              _analytics!.totalShares,
              Icons.share,
              Colors.green,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildViewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Views',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_analytics!.topDailyViews.isNotEmpty) ...[
                  ..._analytics!.topDailyViews
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_formatDate(entry.key))),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  '${entry.value} views',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ] else
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No daily view data available yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopViewersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Profile Viewers',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _analytics!.topViewers.isNotEmpty
                ? Column(
                    children: _analytics!.topViewers
                        .take(5)
                        .map(
                          (viewerId) => FutureBuilder<Map<String, dynamic>?>(
                            future: _getUserInfo(viewerId),
                            builder: (context, snapshot) {
                              final userInfo = snapshot.data;
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage:
                                      ImageUrlValidator.safeNetworkImage(
                                        userInfo?['photoURL']?.toString(),
                                      ),
                                  child:
                                      !ImageUrlValidator.isValidImageUrl(
                                        userInfo?['photoURL']?.toString(),
                                      )
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                title: Text(
                                  userInfo?['displayName']?.toString() ??
                                      'Unknown User',
                                ),
                                subtitle: Text('profile_analytics_viewer'.tr()),
                                trailing: const Icon(
                                  Icons.visibility,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        )
                        .toList(),
                  )
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'No viewer data available yet',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrendsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Trends',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildTrendItem(
                  'Average Views per Day',
                  ((_engagementMetrics['avgViewsPerDay'] as num?)?.toDouble() ??
                          0.0)
                      .toStringAsFixed(1),
                  Icons.trending_up,
                ),
                const Divider(),
                _buildTrendItem(
                  'Peak Engagement Day',
                  _formatDate(
                    (_engagementMetrics['peakEngagementDay'] ?? '').toString(),
                  ),
                  Icons.star,
                ),
                const Divider(),
                _buildTrendItem(
                  'Growth Trend',
                  _getTrendText(
                    (_engagementMetrics['growthTrend'] ?? 'stable').toString(),
                  ),
                  _getTrendIcon(
                    (_engagementMetrics['growthTrend'] ?? 'stable').toString(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallMetricCard(
    String title,
    int value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetric(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendIndicator(String trend) {
    Color color;
    IconData icon;
    String text;

    switch (trend) {
      case 'growing':
        color = Colors.green;
        icon = Icons.trending_up;
        text = 'Growing';
        break;
      case 'declining':
        color = Colors.red;
        icon = Icons.trending_down;
        text = 'Declining';
        break;
      default:
        color = Colors.grey;
        icon = Icons.trending_flat;
        text = 'Stable';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color.fromRGBO(
          (color.r * 255).round(),
          (color.g * 255).round(),
          (color.b * 255).round(),
          0.1,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color.fromRGBO(
            (color.r * 255).round(),
            (color.g * 255).round(),
            (color.b * 255).round(),
            0.3,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendItem(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    if (dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateString;
    }
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'growing':
        return 'Growing';
      case 'declining':
        return 'Declining';
      default:
        return 'Stable';
    }
  }

  IconData _getTrendIcon(String trend) {
    switch (trend) {
      case 'growing':
        return Icons.trending_up;
      case 'declining':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    // In a real implementation, you'd fetch user data from Firestore
    // For now, return placeholder data
    return {'displayName': 'User $userId', 'photoURL': null};
  }
}
