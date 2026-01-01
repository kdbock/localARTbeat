import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart' hide HudTopBar;
import 'package:artbeat_profile/widgets/widgets.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;

  const FollowingListScreen({super.key, required this.userId});

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

enum _FollowingFilter { all, artists, galleries, collectors }

class _FollowingListScreenState extends State<FollowingListScreen> {
  final UserService _userService = UserService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<UserModel> _following = [];
  bool _isLoading = true;
  _FollowingFilter _activeFilter = _FollowingFilter.all;

  bool get _isViewingOwnProfile => _currentUserId == widget.userId;

  List<UserModel> get _filteredFollowing {
    if (_activeFilter == _FollowingFilter.all) return _following;
    return _following.where((user) {
      final type = _resolveType(user);
      switch (_activeFilter) {
        case _FollowingFilter.artists:
          return type == UserType.artist;
        case _FollowingFilter.galleries:
          return type == UserType.gallery;
        case _FollowingFilter.collectors:
          return type == UserType.regular;
        case _FollowingFilter.all:
          return true;
      }
    }).toList();
  }

  int get _artistCount =>
      _following.where((user) => _resolveType(user) == UserType.artist).length;

  int get _galleryCount =>
      _following.where((user) => _resolveType(user) == UserType.gallery).length;

  int get _collectorCount =>
      _following.where((user) => _resolveType(user) == UserType.regular).length;

  int get _activeThisWeekCount => _following
      .where(
        (user) =>
            user.lastActive != null &&
            DateTime.now().difference(user.lastActive!).inDays < 7,
      )
      .length;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getFollowing(widget.userId);
      if (mounted) {
        setState(() => _following = users);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1B1D2A),
            content: Text(
              'profile_following_list_screen_error_error_loading_following'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmUnfollow(UserModel user) async {
    if (!_isViewingOwnProfile) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'profile_following_list_screen_text_unfollow_user'.tr(
                  namedArgs: {'followedUserUsername': user.username},
                ),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'profile_following_confirm_unfollow'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text(
                        'profile_following_list_screen_text_cancel'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: HudButton(
                      text: 'profile_following_unfollow_button'.tr(),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      await _unfollow(user);
    }
  }

  Future<void> _unfollow(UserModel user) async {
    try {
      await _userService.unfollowUser(user.id);
      if (mounted) {
        setState(() => _following.removeWhere((u) => u.id == user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF10121B),
            content: Text(
              'profile_following_list_screen_success_you_unfollowed_user'.tr(
                namedArgs: {'followedUserFullName': user.fullName},
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.3),
            content: Text(
              'profile_following_list_screen_error_error_unfollowing_user'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFollowing = _filteredFollowing;

    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                HudTopBar(
                  title: 'profile_following'.tr(),
                  actions: [
                    IconButton(
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      onPressed: _loadFollowing,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSummaryCard(),
                const SizedBox(height: 16),
                _buildFilterChips(),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _isLoading
                        ? _buildLoadingState()
                        : _buildFollowingContent(filteredFollowing),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GradientBadge(
            child: Text(
              'connections_pulse'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildPrimaryStat(
                  label: 'total_following'.tr(),
                  value: _following.length.toString(),
                  icon: Icons.groups_2,
                  accent: const Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPrimaryStat(
                  label: 'active_this_week'.tr(),
                  value: _activeThisWeekCount.toString(),
                  icon: Icons.bolt,
                  accent: const Color(0xFFFFC857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSecondaryStat('artists'.tr(), _artistCount),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryStat('galleries'.tr(), _galleryCount),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSecondaryStat('collectors'.tr(), _collectorCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryStat({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
            ),
            child: Icon(icon, color: accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryStat(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value.toString(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterPill(
            filter: _FollowingFilter.all,
            label: 'all'.tr(),
            icon: Icons.blur_on,
          ),
          _buildFilterPill(
            filter: _FollowingFilter.artists,
            label: 'artists'.tr(),
            icon: Icons.palette,
          ),
          _buildFilterPill(
            filter: _FollowingFilter.galleries,
            label: 'galleries'.tr(),
            icon: Icons.apartment,
          ),
          _buildFilterPill(
            filter: _FollowingFilter.collectors,
            label: 'collectors'.tr(),
            icon: Icons.favorite_border,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required _FollowingFilter filter,
    required String label,
    required IconData icon,
  }) {
    final selected = _activeFilter == filter;
    final count = _filterCount(filter);

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _setFilter(filter),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: selected
                  ? const Color(0xFF22D3EE).withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.03),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.24)
                    : Colors.white.withValues(alpha: 0.12),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingContent(List<UserModel> list) {
    if (list.isEmpty) {
      return RefreshIndicator(
        color: const Color(0xFF22D3EE),
        backgroundColor: Colors.black,
        onRefresh: _loadFollowing,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(top: 64, bottom: 72),
          children: [_buildEmptyState()],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF22D3EE),
      backgroundColor: Colors.black,
      onRefresh: _loadFollowing,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 32),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final user = list[index];
          final isViewer = user.id == _currentUserId;

          return GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            padding: EdgeInsets.zero,
            child: UserListTile(
              id: user.id,
              displayName: user.fullName,
              handle: user.username,
              avatarUrl: user.profileImageUrl,
              isVerified: user.isVerified,
              trailing: (!_isViewingOwnProfile || isViewer)
                  ? null
                  : FollowButton(
                      isFollowing: true,
                      onTap: () => _confirmUnfollow(user),
                    ),
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profile/view',
                  arguments: {'userId': user.id, 'isCurrentUser': isViewer},
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return GlassCard(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            child: const Icon(
              Icons.travel_explore,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'profile_following'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'profile_no_followers'.tr(),
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 16),
          HudButton(
            text: 'discover_creators'.tr(),
            onPressed: () => Navigator.of(context).pushNamed('/explore'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      key: ValueKey('following_loading'),
      child: CircularProgressIndicator(color: Color(0xFF22D3EE)),
    );
  }

  void _setFilter(_FollowingFilter filter) {
    if (_activeFilter == filter) return;
    setState(() => _activeFilter = filter);
  }

  int _filterCount(_FollowingFilter filter) {
    switch (filter) {
      case _FollowingFilter.artists:
        return _artistCount;
      case _FollowingFilter.galleries:
        return _galleryCount;
      case _FollowingFilter.collectors:
        return _collectorCount;
      case _FollowingFilter.all:
        return _following.length;
    }
  }

  UserType _resolveType(UserModel user) {
    final value = user.userType;
    if (value == null) return UserType.regular;
    return UserType.fromString(value);
  }
}
