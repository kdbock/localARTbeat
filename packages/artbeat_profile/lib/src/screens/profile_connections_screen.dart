import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/profile_connection_model.dart';
import '../services/profile_connection_service.dart';
import 'package:easy_localization/easy_localization.dart';

class ProfileConnectionsScreen extends StatefulWidget {
  const ProfileConnectionsScreen({super.key});

  @override
  State<ProfileConnectionsScreen> createState() =>
      _ProfileConnectionsScreenState();
}

class _ProfileConnectionsScreenState extends State<ProfileConnectionsScreen>
    with TickerProviderStateMixin {
  final ProfileConnectionService _connectionService =
      ProfileConnectionService();

  late TabController _tabController;
  bool _isLoading = true;
  List<ProfileConnectionModel> _mutualConnections = [];
  List<Map<String, dynamic>> _friendSuggestions = [];
  List<String> _followers = [];
  List<String> _following = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadConnections();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadConnections() async {
    try {
      final user = Provider.of<UserService>(context, listen: false).currentUser;
      if (user != null) {
        final [
          mutual,
          suggestions,
          followersData,
          followingData,
        ] = await Future.wait([
          _connectionService.getMutualConnections(user.uid, user.uid),
          _connectionService.getFriendSuggestions(user.uid),
          _getFollowers(user.uid),
          _getFollowing(user.uid),
        ]);

        setState(() {
          _mutualConnections = mutual as List<ProfileConnectionModel>;
          _friendSuggestions = suggestions as List<Map<String, dynamic>>;
          _followers = followersData as List<String>;
          _following = followingData as List<String>;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading connections: $e')),
        );
      }
    }
  }

  Future<List<String>> _getFollowers(String userId) async {
    // Placeholder - in real implementation, fetch from Firestore
    return [];
  }

  Future<List<String>> _getFollowing(String userId) async {
    // Placeholder - in real implementation, fetch from Firestore
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('profile_connections_title'.tr()),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mutual'),
            Tab(text: 'Suggestions'),
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
              _showSearchDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConnections,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildMutualConnectionsTab(),
                _buildSuggestionsTab(),
                _buildFollowersTab(),
                _buildFollowingTab(),
              ],
            ),
    );
  }

  Widget _buildMutualConnectionsTab() {
    if (_mutualConnections.isEmpty) {
      return _buildEmptyState(
        'No Mutual Connections',
        'You don\'t have any mutual connections yet. Connect with more artists to see mutual friends.',
        Icons.people_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mutualConnections.length,
        itemBuilder: (context, index) {
          final connection = _mutualConnections[index];
          return _buildConnectionCard(connection);
        },
      ),
    );
  }

  Widget _buildSuggestionsTab() {
    if (_friendSuggestions.isEmpty) {
      return _buildEmptyState(
        'No Suggestions Available',
        'We\'ll suggest new connections based on your activity and interests.',
        Icons.person_add_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _friendSuggestions.length,
        itemBuilder: (context, index) {
          final suggestion = _friendSuggestions[index];
          return _buildSuggestionCard(suggestion);
        },
      ),
    );
  }

  Widget _buildFollowersTab() {
    if (_followers.isEmpty) {
      return _buildEmptyState(
        'No Followers Yet',
        'Share your artwork to attract followers who appreciate your creativity.',
        Icons.favorite_outline,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _followers.length,
        itemBuilder: (context, index) {
          final followerId = _followers[index];
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserInfo(followerId),
            builder: (context, snapshot) {
              final userInfo = snapshot.data;
              return _buildUserCard(userInfo, followerId, isFollower: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildFollowingTab() {
    if (_following.isEmpty) {
      return _buildEmptyState(
        'Not Following Anyone',
        'Discover and follow artists whose work inspires you.',
        Icons.person_search_outlined,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadConnections,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _following.length,
        itemBuilder: (context, index) {
          final followingId = _following[index];
          return FutureBuilder<Map<String, dynamic>?>(
            future: _getUserInfo(followingId),
            builder: (context, snapshot) {
              final userInfo = snapshot.data;
              return _buildUserCard(userInfo, followingId, isFollowing: true);
            },
          );
        },
      ),
    );
  }

  Widget _buildConnectionCard(ProfileConnectionModel connection) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FutureBuilder<Map<String, dynamic>?>(
                  future: _getUserInfo(connection.connectedUserId),
                  builder: (context, snapshot) {
                    final userInfo = snapshot.data;
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: userInfo?['photoURL'] != null
                              ? NetworkImage(userInfo!['photoURL'].toString())
                              : null,
                          child: userInfo?['photoURL'] == null
                              ? const Icon(Icons.person, size: 25)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userInfo?['displayName']?.toString() ??
                                  'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            if (connection.connectionReason != null)
                              Text(
                                'Reason: ${connection.connectionReason?['reason'] ?? 'Similar interests'}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                _buildActionButton(connection.connectedUserId),
              ],
            ),
            if (connection.mutualFollowerIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '${connection.mutualFollowersCount} mutual connection${connection.mutualFollowersCount == 1 ? '' : 's'}',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: connection.mutualFollowerIds.take(5).length,
                  itemBuilder: (context, index) {
                    final friendId = connection.mutualFollowerIds[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FutureBuilder<Map<String, dynamic>?>(
                        future: _getUserInfo(friendId),
                        builder: (context, snapshot) {
                          final friendInfo = snapshot.data;
                          return CircleAvatar(
                            radius: 16,
                            backgroundImage: friendInfo?['photoURL'] != null
                                ? NetworkImage(
                                    friendInfo!['photoURL'].toString(),
                                  )
                                : null,
                            child: friendInfo?['photoURL'] == null
                                ? const Icon(Icons.person, size: 16)
                                : null,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionCard(Map<String, dynamic> suggestion) {
    final userId = suggestion['userId']?.toString() ?? '';
    final score = suggestion['score'] as double? ?? 0.0;
    final reasons = suggestion['reasons'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                FutureBuilder<Map<String, dynamic>?>(
                  future: _getUserInfo(userId),
                  builder: (context, snapshot) {
                    final userInfo = snapshot.data;
                    return Row(
                      children: [
                        CircleAvatar(
                          radius: 25,
                          backgroundImage: userInfo?['photoURL'] != null
                              ? NetworkImage(userInfo!['photoURL'].toString())
                              : null,
                          child: userInfo?['photoURL'] == null
                              ? const Icon(Icons.person, size: 25)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userInfo?['displayName']?.toString() ??
                                  'Unknown User',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Color.fromRGBO(
                                  (_getScoreColor(score).r * 255).round(),
                                  (_getScoreColor(score).g * 255).round(),
                                  (_getScoreColor(score).b * 255).round(),
                                  0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${(score * 100).toStringAsFixed(0)}% match',
                                style: TextStyle(
                                  color: _getScoreColor(score),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => _dismissSuggestion(userId),
                    ),
                    ElevatedButton(
                      onPressed: () => _sendConnectionRequest(userId),
                      child: Text('profile_connections_connect'.tr()),
                    ),
                  ],
                ),
              ],
            ),
            if (reasons.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: reasons
                    .map(
                      (reason) => Chip(
                        label: Text(
                          reason.toString(),
                          style: const TextStyle(fontSize: 11),
                        ),
                        backgroundColor: Colors.blue.shade50,
                        labelStyle: TextStyle(color: Colors.blue.shade700),
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(
    Map<String, dynamic>? userInfo,
    String userId, {
    bool isFollower = false,
    bool isFollowing = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: userInfo?['photoURL'] != null
              ? NetworkImage(userInfo!['photoURL'].toString())
              : null,
          child: userInfo?['photoURL'] == null
              ? const Icon(Icons.person)
              : null,
        ),
        title: Text(userInfo?['displayName']?.toString() ?? 'Unknown User'),
        subtitle: Text(userInfo?['bio']?.toString() ?? 'No bio available'),
        trailing: _buildActionButton(
          userId,
          isFollower: isFollower,
          isFollowing: isFollowing,
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String userId, {
    bool isFollower = false,
    bool isFollowing = false,
  }) {
    if (isFollowing) {
      return OutlinedButton(
        onPressed: () => _unfollowUser(userId),
        child: const Text('Unfollow'),
      );
    } else if (isFollower) {
      return ElevatedButton(
        onPressed: () => _followUser(userId),
        child: const Text('Follow Back'),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _sendConnectionRequest(userId),
        child: Text('profile_connections_connect'.tr()),
      );
    }
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadConnections,
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  void _showSearchDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Connections'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter name or username...',
            prefixIcon: Icon(Icons.search),
          ),
          onSubmitted: (query) {
            Navigator.pop(context);
            _performSearch(query);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _performSearch(String query) {
    // Implement search functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Searching for: $query')));
  }

  Future<void> _sendConnectionRequest(String userId) async {
    try {
      // Implement connection request logic
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('profile_connections_request_sent'.tr())),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error sending request: $e')));
    }
  }

  Future<void> _followUser(String userId) async {
    try {
      // Implement follow logic
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Now following user!')));
      _loadConnections(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error following user: $e')));
    }
  }

  Future<void> _unfollowUser(String userId) async {
    try {
      // Implement unfollow logic
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unfollowed user')));
      _loadConnections(); // Refresh data
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error unfollowing user: $e')));
    }
  }

  Future<void> _dismissSuggestion(String userId) async {
    try {
      setState(() {
        _friendSuggestions.removeWhere(
          (suggestion) => suggestion['userId'] == userId,
        );
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Suggestion dismissed')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error dismissing suggestion: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _getUserInfo(String userId) async {
    // In a real implementation, you'd fetch user data from Firestore
    // For now, return placeholder data
    return {
      'displayName': 'User ${userId.substring(0, 8)}...',
      'photoURL': null,
      'bio': 'Artist and creator',
    };
  }
}
