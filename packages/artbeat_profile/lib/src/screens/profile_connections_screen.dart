import 'dart:ui';

import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/profile_connection_model.dart';
import '../services/profile_connection_service.dart';

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
  String? _errorMessage;
  List<ProfileConnectionModel> _mutualConnections = [];
  List<ProfileConnectionModel> _friendSuggestions = [];
  List<core.UserModel> _followers = [];
  List<core.UserModel> _following = [];

  core.UserService get _userService =>
      Provider.of<core.UserService>(context, listen: false);

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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _userService.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'profile_connections_sign_in_required'.tr();
        });
        return;
      }

      final results = await Future.wait<dynamic>([
        _connectionService.getMutualConnections(user.uid, user.uid),
        _connectionService.getFriendSuggestions(user.uid),
        _userService.getFollowers(user.uid),
        _userService.getFollowing(user.uid),
      ]);

      if (!mounted) return;

      setState(() {
        _mutualConnections = List<ProfileConnectionModel>.from(
          results[0] as List,
        );
        _friendSuggestions = List<ProfileConnectionModel>.from(
          results[1] as List,
        );
        _followers = List<core.UserModel>.from(results[2] as List);
        _following = List<core.UserModel>.from(results[3] as List);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading connections';
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading connections: $e')));
    }
  }

  Future<void> _handleFollowAction(String targetUserId) async {
    final currentUserId = _userService.currentUserId;
    if (currentUserId == null || targetUserId.isEmpty) return;

    final isFollowing = await _userService.isFollowing(targetUserId);
    if (isFollowing) {
      await _userService.unfollowUser(targetUserId);
    } else {
      await _userService.followUser(targetUserId);
    }
    if (mounted) await _loadConnections();
  }

  Future<void> _dismissSuggestion(ProfileConnectionModel connection) async {
    final userId = _userService.currentUserId;
    if (userId == null) return;
    await _connectionService.dismissConnection(
      userId,
      connection.connectedUserId,
    );
    if (mounted) await _loadConnections();
  }

  void _openProfile(String userId) {
    if (userId.isEmpty) return;
    Navigator.of(context).pushNamed(
      '/profile/view',
      arguments: {
        'userId': userId,
        'isCurrentUser': userId == _userService.currentUserId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      child: Scaffold(
        backgroundColor: const Color(0xFF07060F),
        body: Stack(
          children: [
            _buildWorldBackground(),
            SafeArea(
              child: Column(
                children: [
                  _buildHudBar(context),
                  const SizedBox(height: 12),
                  _buildTabBar(),
                  const SizedBox(height: 12),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF22D3EE),
                              ),
                            )
                          : _errorMessage != null
                          ? _buildErrorState()
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildMutualConnections(),
                                _buildFriendSuggestions(),
                                _buildFollowersList(),
                                _buildFollowingList(),
                              ],
                            ),
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

  Widget _buildWorldBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF07060F), Color(0xFF0C1326), Color(0xFF041015)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.tealAccent.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -60,
            left: -30,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.deepPurpleAccent.withValues(alpha: 0.08),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHudBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  color: Colors.white,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                Expanded(
                  child: Text(
                    'profile_connections_title'.tr(),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                  onPressed: _loadConnections,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          dividerColor: Colors.transparent,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF22D3EE).withValues(alpha: 0.18),
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 18),
          labelStyle: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Mutuals'),
            Tab(text: 'Suggestions'),
            Tab(text: 'Followers'),
            Tab(text: 'Following'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 48),
          const SizedBox(height: 12),
          Text(
            _errorMessage ?? 'Something went wrong',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: _loadConnections, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildMutualConnections() {
    return _buildConnectionList(
      items: _mutualConnections,
      emptyTitle: 'profile_connections_no_mutuals_title'.tr(),
      emptySubtitle: 'profile_connections_no_mutuals_subtitle'.tr(),
    );
  }

  Widget _buildFriendSuggestions() {
    return _buildConnectionList(
      items: _friendSuggestions,
      emptyTitle: 'profile_connections_no_suggestions_title'.tr(),
      emptySubtitle: 'profile_connections_no_suggestions_subtitle'.tr(),
      builder: (connection) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionTile(connection),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () =>
                      _handleFollowAction(connection.connectedUserId),
                  child: const Text('Connect'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.24)),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => _dismissSuggestion(connection),
                  child: const Text('Skip'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersList() {
    return _buildUserList(
      users: _followers,
      emptyTitle: 'profile_connections_no_followers_title'.tr(),
      emptySubtitle: 'profile_connections_no_followers_subtitle'.tr(),
    );
  }

  Widget _buildFollowingList() {
    return _buildUserList(
      users: _following,
      emptyTitle: 'profile_connections_no_following_title'.tr(),
      emptySubtitle: 'profile_connections_no_following_subtitle'.tr(),
    );
  }

  Widget _buildConnectionList({
    required List<ProfileConnectionModel> items,
    required String emptyTitle,
    required String emptySubtitle,
    Widget Function(ProfileConnectionModel connection)? builder,
  }) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: Icons.public,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final item = items[index];
        if (builder != null) {
          return builder(item);
        }
        return _buildConnectionTile(item);
      },
    );
  }

  Widget _buildConnectionTile(ProfileConnectionModel connection) {
    return InkWell(
      onTap: () => _openProfile(connection.connectedUserId),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.04),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _buildAvatar(
              connection.connectedUserAvatar,
              connection.connectedUserName,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    connection.connectedUserName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    connection.connectionReasonText,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  if (connection.mutualFollowersCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _buildPill(
                        '${connection.mutualFollowersCount} mutual',
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
      ),
    );
  }

  Widget _buildUserList({
    required List<core.UserModel> users,
    required String emptyTitle,
    required String emptySubtitle,
  }) {
    if (users.isEmpty) {
      return _buildEmptyState(
        icon: Icons.groups_2,
        title: emptyTitle,
        subtitle: emptySubtitle,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: users.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final user = users[index];
        return InkWell(
          onTap: () => _openProfile(user.id),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              children: [
                _buildAvatar(user.profileImageUrl, user.fullName),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white54),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String? imageUrl, String fallbackName) {
    final imageProvider = core.ImageUrlValidator.safeNetworkImage(imageUrl);
    return CircleAvatar(
      radius: 30,
      backgroundColor: Colors.white10,
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              fallbackName.isNotEmpty ? fallbackName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }

  Widget _buildPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white30, size: 48),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 240,
            child: Text(
              subtitle,
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: _loadConnections,
            child: Text('profile_connections_refresh'.tr()),
          ),
        ],
      ),
    );
  }
}
