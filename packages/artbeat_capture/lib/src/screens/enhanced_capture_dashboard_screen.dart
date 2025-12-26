import 'dart:math' as math;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/src/screens/profile_menu_screen.dart';

/// Quest-style Capture Dashboard (Local ARTbeat)
/// - Same services/data/routes as your original
/// - Completely different presentation: gaming/quest hub vibe
class EnhancedCaptureDashboardScreen extends StatefulWidget {
  const EnhancedCaptureDashboardScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedCaptureDashboardScreen> createState() =>
      _EnhancedCaptureDashboardScreenState();
}

class _EnhancedCaptureDashboardScreenState
    extends State<EnhancedCaptureDashboardScreen>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = true;

  // Data
  List<CaptureModel> _recentCaptures = [];
  List<CaptureModel> _communityCaptures = [];
  UserModel? _currentUser;
  int _totalUserCaptures = 0;
  int _totalCommunityViews = 0;

  int get _todayCaptureCount {
    final now = DateTime.now();
    return _recentCaptures.where((capture) {
      final created = capture.createdAt;
      return created.year == now.year &&
          created.month == now.month &&
          created.day == now.day;
    }).length;
  }

  int get _uniqueNeighborhoodDrops {
    final now = DateTime.now();
    final todaysLocations = _recentCaptures
        .where((capture) {
          final created = capture.createdAt;
          return created.year == now.year &&
              created.month == now.month &&
              created.day == now.day;
        })
        .map(
          (capture) =>
              (capture.locationName ?? capture.location?.toString())?.trim(),
        );
    return todaysLocations
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toSet()
        .length;
  }

  int get _communityArtistCount =>
      _communityCaptures.map((capture) => capture.userId).toSet().length;

  int get _communityEngagementScore => _communityCaptures.fold(
    0,
    (total, capture) =>
        total +
        capture.engagementStats.likeCount +
        capture.engagementStats.shareCount +
        capture.engagementStats.commentCount,
  );

  String get _trendingCommunityLocation {
    final counts = <String, int>{};
    for (final capture in _communityCaptures) {
      final key = (capture.locationName ?? capture.artType ?? '').trim();
      if (key.isEmpty) {
        continue;
      }
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      return 'Your city';
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key;
  }

  // Services
  final CaptureService _captureService = CaptureService();
  final UserService _userService = UserService();

  // Animations
  late final AnimationController _loop; // ambient world loop
  late final AnimationController _intro; // entrance

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final user = await _userService.getCurrentUserModel();

      List<CaptureModel> recentCaptures = [];
      List<CaptureModel> communityCaptures = [];
      int totalUserCaptures = 0;
      int totalCommunityViews = 0;

      if (user != null) {
        recentCaptures = await _captureService.getUserCaptures(
          userId: user.id,
          limit: 6,
        );
        totalUserCaptures = await _captureService.getUserCaptureCount(user.id);
        totalCommunityViews = await _captureService.getUserCaptureViews(
          user.id,
        );
      }

      communityCaptures = await _captureService.getAllCaptures(limit: 8);

      if (!mounted) return;
      setState(() {
        _currentUser = user;
        _recentCaptures = recentCaptures;
        _communityCaptures = communityCaptures;
        _totalUserCaptures = totalUserCaptures;
        _totalCommunityViews = totalCommunityViews;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async => _loadData();

  void _startCaptureFlow() {
    Navigator.pushNamed(context, '/capture/camera');
  }

  void _navigateToCaptureDetail(String captureId) {
    Navigator.pushNamed(
      context,
      '/capture/detail',
      arguments: {'captureId': captureId},
    );
  }

  List<_CaptureMissionModel> _buildMissionData(BuildContext context) {
    return [
      _CaptureMissionModel(
        title: 'capture_dashboard_mission_daily_drop_title'.tr(),
        description: 'capture_dashboard_mission_daily_drop_desc'.tr(),
        xpReward: 75,
        icon: Icons.camera_enhance_rounded,
        accent: const Color(0xFF34D399),
        current: math.min(_todayCaptureCount, 3),
        target: 3,
        onTap: _startCaptureFlow,
      ),
      _CaptureMissionModel(
        title: 'capture_dashboard_mission_community_scout_title'.tr(),
        description: 'capture_dashboard_mission_community_scout_desc'.tr(),
        xpReward: 40,
        icon: Icons.feedback_outlined,
        accent: const Color(0xFF22D3EE),
        current: math.min(_communityCaptures.length, 5),
        target: 5,
        onTap: () => Navigator.pushNamed(context, '/capture/popular'),
      ),
      _CaptureMissionModel(
        title: 'capture_dashboard_mission_map_block_title'.tr(),
        description: 'capture_dashboard_mission_map_block_desc'.tr(),
        xpReward: 120,
        icon: Icons.map_outlined,
        accent: const Color(0xFFFFC857),
        current: math.min(_uniqueNeighborhoodDrops, 2),
        target: 2,
        onTap: () => Navigator.pushNamed(context, '/capture/nearby'),
      ),
    ];
  }

  List<_QuickActionData> _buildQuickActions(BuildContext context) {
    return [
      _QuickActionData(
        label: 'capture_dashboard_quick_capture_now_title'.tr(),
        subtitle: 'capture_dashboard_quick_capture_now_subtitle'.tr(),
        icon: Icons.camera_alt_rounded,
        accent: const Color(0xFF34D399),
        onTap: _startCaptureFlow,
      ),
      _QuickActionData(
        label: 'capture_dashboard_quick_my_drops_title'.tr(),
        subtitle: 'capture_dashboard_quick_my_drops_subtitle'.tr(),
        icon: Icons.inventory_2_rounded,
        accent: const Color(0xFF22D3EE),
        onTap: () => Navigator.pushNamed(context, '/capture/my-captures'),
      ),
      _QuickActionData(
        label: 'capture_dashboard_quick_community_heat_title'.tr(),
        subtitle: 'capture_dashboard_quick_community_heat_subtitle'.tr(),
        icon: Icons.local_fire_department_rounded,
        accent: const Color(0xFFFF6B6B),
        onTap: () => Navigator.pushNamed(context, '/capture/popular'),
      ),
      _QuickActionData(
        label: 'capture_dashboard_quick_guidelines_title'.tr(),
        subtitle: 'capture_dashboard_quick_guidelines_subtitle'.tr(),
        icon: Icons.policy_rounded,
        accent: const Color(0xFFFFC857),
        onTap: _openTermsAndConditionsScreen,
      ),
    ];
  }

  void _openTermsAndConditionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (context) => const ProfileMenuScreen()),
    );
  }

  void _showSearchModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: ArtbeatColors.primaryGreen,
                      size: 24,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'capture_dashboard_search_captures'.tr(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            'capture_dashboard_find_art'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildSearchOption(
                      icon: Icons.camera_alt,
                      title: 'capture_dashboard_search_captures'.tr(),
                      subtitle: 'capture_dashboard_search_captures_subtitle'
                          .tr(),
                      color: ArtbeatColors.primaryGreen,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/capture/search');
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.location_on,
                      title: 'capture_dashboard_nearby_art'.tr(),
                      subtitle: 'capture_dashboard_nearby_art_subtitle'.tr(),
                      color: ArtbeatColors.primaryPurple,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/capture/nearby');
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.trending_up,
                      title: 'capture_dashboard_popular_captures'.tr(),
                      subtitle: 'capture_dashboard_popular_captures_subtitle'
                          .tr(),
                      color: ArtbeatColors.secondaryTeal,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/capture/popular');
                      },
                    ),
                    _buildSearchOption(
                      icon: Icons.person_search,
                      title: 'capture_dashboard_find_artists'.tr(),
                      subtitle: 'capture_dashboard_find_artists_subtitle'.tr(),
                      color: ArtbeatColors.accentYellow,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, '/artist/search');
                      },
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

  Widget _buildSearchOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI ---

  @override
  Widget build(BuildContext context) {
    final missionData = _buildMissionData(context);
    final quickActions = _buildQuickActions(context);
    final userLevel = _currentUser?.level;
    final userXp = _currentUser?.experiencePoints;

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      drawer: const CaptureDrawer(),
      body: Stack(
        children: [
          // Ambient animated background (no heavy overlay blocks)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, __) => CustomPaint(
                painter: _QuestAmbientPainter(t: _loop.value),
                size: Size.infinite,
              ),
            ),
          ),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF22D3EE),
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refreshData,
                    color: const Color(0xFF22D3EE),
                    backgroundColor: const Color(0xFF0C0A16),
                    child: CustomScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        // Wrap _TopHudBar in a Builder to provide context under Scaffold
                        SliverToBoxAdapter(
                          child: Builder(
                            builder: (context) => _TopHudBar(
                              title: 'capture_dashboard_title'.tr(),
                              subtitle: 'capture_dashboard_subtitle'.tr(),
                              onMenu: () => Scaffold.of(context).openDrawer(),
                              onSearch: () => _showSearchModal(context),
                              onProfile: () => _showProfileMenu(context),
                            ),
                          ),
                        ),
                        // Quest tracker section
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                            child: _StampFadeIn(
                              intro: _intro,
                              delay: 0.2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SectionHeader(
                                    title:
                                        'capture_dashboard_section_quest_tracker_title'
                                            .tr(),
                                    subtitle:
                                        'capture_dashboard_section_quest_tracker_subtitle'
                                            .tr(),
                                    accent: const Color(0xFF34D399),
                                  ),
                                  const SizedBox(height: 12),
                                  _CaptureMissionList(missions: missionData),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (_communityCaptures.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                              child: _StampFadeIn(
                                intro: _intro,
                                delay: 0.22,
                                child: _CommunityPulse(
                                  activeHunters: _communityArtistCount,
                                  newDrops: _communityCaptures.length,
                                  xpPulse: _communityEngagementScore,
                                  trendingLocation: _trendingCommunityLocation,
                                  onExplore: () => Navigator.pushNamed(
                                    context,
                                    '/capture/popular',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        // Recent (loot grid)
                        if (_recentCaptures.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                18,
                                14,
                                10,
                              ),
                              child: _SectionHeader(
                                title:
                                    'capture_dashboard_section_recent_loot_title'
                                        .tr(),
                                subtitle:
                                    'capture_dashboard_section_recent_loot_subtitle'
                                        .tr(),
                                accent: const Color(0xFF7C4DFF),
                              ),
                            ),
                          ),
                        if (_recentCaptures.isNotEmpty)
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            sliver: SliverGrid(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 1,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final capture = _recentCaptures[index];
                                return _QuestCaptureTile(
                                  capture: capture,
                                  onTap: () =>
                                      _navigateToCaptureDetail(capture.id),
                                );
                              }, childCount: _recentCaptures.length),
                            ),
                          ),
                        // Community inspiration
                        if (_communityCaptures.isNotEmpty)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                20,
                                14,
                                10,
                              ),
                              child: _SectionHeader(
                                title:
                                    'capture_dashboard_section_inspiration_title'
                                        .tr(),
                                subtitle:
                                    'capture_dashboard_section_inspiration_subtitle'
                                        .tr(),
                                accent: const Color(0xFF22D3EE),
                              ),
                            ),
                          ),
                        if (_communityCaptures.isNotEmpty)
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 220,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                ),
                                itemCount: _communityCaptures.length,
                                itemBuilder: (context, index) {
                                  final capture = _communityCaptures[index];
                                  return _QuestCommunityCard(
                                    capture: capture,
                                    onTap: () =>
                                        _navigateToCaptureDetail(capture.id),
                                  );
                                },
                              ),
                            ),
                          ),
                        // Keep your existing artist CTA
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(8, 18, 8, 0),
                            child: CompactArtistCTAWidget(),
                          ),
                        ),
                        const SliverToBoxAdapter(child: SizedBox(height: 110)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Background painter: subtle “art energy” blobs (gaming vibe)
/// =======================

class _QuestAmbientPainter extends CustomPainter {
  final double t;
  _QuestAmbientPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark gradient
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    _blob(canvas, size, const Color(0xFF22D3EE), 0.18, 0.20, 0.36, phase: 0.0);
    _blob(canvas, size, const Color(0xFF7C4DFF), 0.84, 0.22, 0.30, phase: 0.2);
    _blob(canvas, size, const Color(0xFFFF3D8D), 0.78, 0.76, 0.42, phase: 0.45);
    _blob(canvas, size, const Color(0xFF34D399), 0.16, 0.78, 0.34, phase: 0.62);

    // soft vignette (very subtle)
    final vignette = Paint()
      ..shader = const RadialGradient(
        radius: 1.15,
        colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.55)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  void _blob(
    Canvas canvas,
    Size size,
    Color color,
    double ax,
    double ay,
    double r, {
    required double phase,
  }) {
    final dx = math.sin((t + phase) * 2 * math.pi) * 0.03;
    final dy = math.cos((t + phase) * 2 * math.pi) * 0.03;

    final center = Offset(size.width * (ax + dx), size.height * (ay + dy));
    final radius = size.width * r;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _QuestAmbientPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// =======================
/// Top HUD
/// =======================

class _TopHudBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onMenu;
  final VoidCallback onSearch;
  final VoidCallback onProfile;

  const _TopHudBar({
    required this.title,
    required this.subtitle,
    required this.onMenu,
    required this.onSearch,
    required this.onProfile,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onMenu,
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSearch,
            icon: const Icon(Icons.search_rounded, color: Colors.white),
          ),
          IconButton(
            onPressed: onProfile,
            icon: const Icon(Icons.person_rounded, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Hero quest card
/// =======================

class _QuestHeroCard extends StatelessWidget {
  final String? username;
  final VoidCallback onStart;
  final AnimationController loop;

  const _QuestHeroCard({
    required this.username,
    required this.onStart,
    required this.loop,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, __) {
        final t = loop.value;
        final pulse = 0.70 + 0.30 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));

        return _Glass(
          radius: 22,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _TagChip(
                    text: 'capture_dashboard_tag_primary_quest'.tr(),
                    color: const Color(0xFFFFC857),
                  ),
                  const Spacer(),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF22D3EE).withValues(alpha: 0.9),
                          const Color(0xFF7C4DFF).withValues(alpha: 0.75),
                          const Color(0xFFFF3D8D).withValues(alpha: 0.70),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF22D3EE,
                          ).withValues(alpha: 0.14 * pulse),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Text(
                username == null
                    ? 'capture_dashboard_ready_capture'.tr()
                    : "${'capture_dashboard_ready_capture'.tr()}, $username",
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'capture_dashboard_discover_document'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),

              _QuestPrimaryButton(
                label: 'capture_dashboard_start_capture'.tr(),
                icon: Icons.assignment_turned_in_rounded,
                onTap: onStart,
                loop: loop,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final AnimationController loop;

  const _QuestPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.loop,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, __) {
        final t = loop.value;
        final sweep = (t * 1.15) % 1.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF34D399,
                          ).withValues(alpha: 0.22),
                          blurRadius: 18,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: Colors.white.withValues(alpha: 0.16),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.22),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Spotlight sweep (animated highlight)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.55,
                    child: Transform.translate(
                      offset: Offset((sweep * 2 - 1) * 240, 0),
                      child: Transform.rotate(
                        angle: -0.55,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Colors.white.withValues(alpha: 0.22),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// =======================
/// Impact HUD
/// =======================

class _ImpactHud extends StatelessWidget {
  final int totalCaptures;
  final int totalViews;
  final AnimationController loop;
  final int? userLevel;
  final int? userXp;
  final int communityPulse;

  const _ImpactHud({
    required this.totalCaptures,
    required this.totalViews,
    required this.loop,
    this.userLevel,
    this.userXp,
    this.communityPulse = 0,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLevel = (userLevel ?? (1 + (totalCaptures / 5).floor()))
        .clamp(1, 99);
    final xpValue = userXp ?? totalViews;
    final xpProgress = ((xpValue % 1000) / 1000).clamp(0.05, 0.98);

    return _Glass(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              _HudPill(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC857), Color(0xFFFF3D8D)],
                ),
                child: Text(
                  "LV $resolvedLevel",
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.black.withValues(alpha: 0.86),
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: _XpBar(progress: xpProgress)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'capture_dashboard_stat_captures'.tr(),
                  value: totalCaptures.toString(),
                  accent: const Color(0xFF34D399),
                  icon: Icons.camera_alt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'capture_dashboard_stat_community_views'.tr(),
                  value: totalViews.toString(),
                  accent: const Color(0xFF7C4DFF),
                  icon: Icons.visibility_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'capture_dashboard_stat_community_xp_label'.tr(),
                  value: communityPulse.toString(),
                  accent: const Color(0xFFFFC857),
                  icon: Icons.bolt_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'capture_dashboard_stat_total_xp_label'.tr(),
                  value: xpValue.toString(),
                  accent: const Color(0xFF22D3EE),
                  icon: Icons.auto_graph_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _XpBar extends StatelessWidget {
  final double progress;
  const _XpBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'capture_dashboard_label_xp'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 10,
            color: Colors.white.withValues(alpha: 0.08),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF22D3EE),
                      Color(0xFF7C4DFF),
                      Color(0xFFFF3D8D),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  const _MiniStat({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: accent.withValues(alpha: 0.16),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.92),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Section header
/// =======================

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color accent;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// =======================
/// Capture tiles + community cards
/// =======================

class _QuestCaptureTile extends StatelessWidget {
  final CaptureModel capture;
  final VoidCallback onTap;
  const _QuestCaptureTile({required this.capture, required this.onTap});

  Color _statusColor(CaptureStatus status) {
    switch (status) {
      case CaptureStatus.approved:
        return const Color(0xFF34D399);
      case CaptureStatus.pending:
        return const Color(0xFFFFC857);
      case CaptureStatus.rejected:
        return const Color(0xFFFF3D8D);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(capture.status);

    return _Glass(
      radius: 20,
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                SecureNetworkImage(
                  imageUrl: capture.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: Container(
                    color: const Color.fromRGBO(255, 255, 255, 0.06),
                    child: const Icon(
                      Icons.broken_image_rounded,
                      color: Colors.white54,
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color.fromRGBO(0, 0, 0, 0.78),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 10,
                  right: 10,
                  bottom: 10,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((capture.title ?? '').isNotEmpty)
                        Text(
                          capture.title!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: [
                            BoxShadow(
                              color: statusColor.withValues(alpha: 0.20),
                              blurRadius: 14,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Text(
                          capture.status.value.toUpperCase(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black.withValues(alpha: 0.88),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuestCommunityCard extends StatelessWidget {
  final CaptureModel capture;
  final VoidCallback onTap;
  const _QuestCommunityCard({required this.capture, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: _Glass(
        radius: 22,
        padding: EdgeInsets.zero,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  SecureNetworkImage(
                    imageUrl: capture.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: const Color.fromRGBO(255, 255, 255, 0.06),
                      child: const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color.fromRGBO(0, 0, 0, 0.80),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TagChip(
                          text: 'capture_dashboard_tag_spotted'.tr(),
                          color: const Color(0xFF22D3EE),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          capture.title ??
                              'capture_dashboard_community_capture'.tr(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          capture.artistName ??
                              'capture_dashboard_unknown_artist'.tr(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.70),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaptureMissionModel {
  final String title;
  final String description;
  final int xpReward;
  final IconData icon;
  final Color accent;
  final int current;
  final int target;
  final VoidCallback onTap;

  const _CaptureMissionModel({
    required this.title,
    required this.description,
    required this.xpReward,
    required this.icon,
    required this.accent,
    required this.current,
    required this.target,
    required this.onTap,
  });

  double get progress {
    if (target <= 0) {
      return 1;
    }
    return (current / target).clamp(0.0, 1.0);
  }
}

class _CaptureMissionList extends StatelessWidget {
  final List<_CaptureMissionModel> missions;
  const _CaptureMissionList({required this.missions});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: missions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) =>
            _CaptureMissionCard(mission: missions[index]),
      ),
    );
  }
}

class _CaptureMissionCard extends StatelessWidget {
  final _CaptureMissionModel mission;
  const _CaptureMissionCard({required this.mission});

  @override
  Widget build(BuildContext context) {
    final progress = mission.progress;

    return SizedBox(
      width: 240,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: mission.onTap,
          borderRadius: BorderRadius.circular(22),
          child: _Glass(
            radius: 22,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: mission.accent.withValues(alpha: 0.20),
                        border: Border.all(
                          color: mission.accent.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(mission.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.title,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '+${mission.xpReward} XP',
                          style: GoogleFonts.spaceGrotesk(
                            color: mission.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  mission.description,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 8,
                          color: Colors.white.withValues(alpha: 0.08),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    mission.accent,
                                    mission.accent.withValues(alpha: 0.5),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${mission.current}/${mission.target}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.82),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionData {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  const _QuickActionData({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });
}

class _CaptureQuickActions extends StatelessWidget {
  final List<_QuickActionData> actions;
  const _CaptureQuickActions({required this.actions});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final width = size.width < 380 ? size.width - 40 : (size.width - 40) / 2;

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions
          .map((action) => _QuickActionChip(data: action, width: width))
          .toList(),
    );
  }
}

class _QuickActionChip extends StatelessWidget {
  final _QuickActionData data;
  final double width;

  const _QuickActionChip({required this.data, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: data.onTap,
          borderRadius: BorderRadius.circular(18),
          child: _Glass(
            radius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: data.accent.withValues(alpha: 0.18),
                    border: Border.all(
                      color: data.accent.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Icon(data.icon, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.label,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_outward_rounded,
                  color: Colors.white54,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CommunityPulse extends StatelessWidget {
  final int activeHunters;
  final int newDrops;
  final int xpPulse;
  final String trendingLocation;
  final VoidCallback onExplore;

  const _CommunityPulse({
    required this.activeHunters,
    required this.newDrops,
    required this.xpPulse,
    required this.trendingLocation,
    required this.onExplore,
  });

  @override
  Widget build(BuildContext context) {
    return _Glass(
      radius: 22,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'capture_dashboard_label_community_pulse'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: onExplore,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: Text(
                  'capture_dashboard_button_explore'.tr(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _CommunityStat(
                  label: 'capture_dashboard_stat_active_hunters'.tr(),
                  value: activeHunters.toString(),
                  icon: Icons.people_alt_rounded,
                  accent: const Color(0xFF22D3EE),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CommunityStat(
                  label: 'capture_dashboard_stat_new_drops'.tr(),
                  value: newDrops.toString(),
                  icon: Icons.camera_roll_rounded,
                  accent: const Color(0xFF34D399),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _CommunityStat(
                  label: 'capture_dashboard_stat_xp_shared'.tr(),
                  value: xpPulse.toString(),
                  icon: Icons.bolt_rounded,
                  accent: const Color(0xFFFFC857),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF7C4DFF)],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                  child: const Icon(
                    Icons.place_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'capture_dashboard_label_trending_location'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        trendingLocation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _CommunityStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.04),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: accent.withValues(alpha: 0.20),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Shared UI atoms
/// =======================

class _Glass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _Glass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(255, 255, 255, 0.06),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HudPill extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;

  const _HudPill({required this.child, required this.gradient});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: gradient,
      ),
      child: child,
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color color;
  const _TagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [color, Colors.white.withValues(alpha: 0.30)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.20),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black.withValues(alpha: 0.85),
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _StampFadeIn extends StatelessWidget {
  final AnimationController intro;
  final double delay;
  final Widget child;

  const _StampFadeIn({
    required this.intro,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: intro,
      curve: Interval(
        delay,
        (delay + 0.55).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
    final slide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: intro,
            curve: Interval(
              delay,
              (delay + 0.75).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
