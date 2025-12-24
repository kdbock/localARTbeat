import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';

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

  void _openTermsAndConditionsScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => const TermsAndConditionsScreen(),
      ),
    );
  }

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedProfileMenu(),
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
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                            child: _StampFadeIn(
                              intro: _intro,
                              delay: 0.0,
                              child: _TopHudBar(
                                title: "CAPTURE",
                                subtitle: "Scout → Snap → Upload to the map",
                                onMenu: () => Scaffold.of(context).openDrawer(),
                                onSearch: () => _showSearchModal(context),
                                onProfile: () => _showProfileMenu(context),
                              ),
                            ),
                          ),
                        ),

                        // Hero / Quest banner
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                            child: _StampFadeIn(
                              intro: _intro,
                              delay: 0.08,
                              child: _QuestHeroCard(
                                username: _currentUser?.username,
                                onStart: _openTermsAndConditionsScreen,
                                loop: _loop,
                              ),
                            ),
                          ),
                        ),

                        // HUD stats
                        if (_currentUser != null)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                              child: _StampFadeIn(
                                intro: _intro,
                                delay: 0.14,
                                child: _ImpactHud(
                                  totalCaptures: _totalUserCaptures,
                                  totalViews: _totalCommunityViews,
                                  loop: _loop,
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
                                title: "YOUR RECENT LOOT",
                                subtitle: "Tap to review your last drops",
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
                                return _QuestCaptureTile(capture: capture);
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
                                title: "INSPIRATION RUN",
                                subtitle: "See what other hunters are finding",
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
                                  return _QuestCommunityCard(capture: capture);
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
        colors: const [
          const Color(0xFF07060F),
          const Color(0xFF0A1330),
          const Color(0xFF071C18),
        ],
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
        colors: const [Colors.transparent, const Color.fromRGBO(0, 0, 0, 0.55)],
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
                    text: "PRIMARY QUEST",
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

  const _ImpactHud({
    required this.totalCaptures,
    required this.totalViews,
    required this.loop,
  });

  @override
  Widget build(BuildContext context) {
    // Fake “level” and “xp” vibe derived from stats (presentation only)
    final level = (1 + (totalCaptures / 5).floor()).clamp(1, 99);
    final xp = (totalViews % 1000).clamp(0, 1000);
    final xpProgress = ((xp / 1000.0)).clamp(0.05, 0.98);

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
                  "LV $level",
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
          "XP",
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
  const _QuestCaptureTile({required this.capture});

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
            // bottom fade
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: const [
                    Colors.transparent,
                    const Color.fromRGBO(0, 0, 0, 0.78),
                  ],
                ),
              ),
            ),
            // status chip + title
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
    );
  }
}

class _QuestCommunityCard extends StatelessWidget {
  final CaptureModel capture;
  const _QuestCommunityCard({required this.capture});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: _Glass(
        radius: 22,
        padding: EdgeInsets.zero,
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
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: const [
                      Colors.transparent,
                      const Color.fromRGBO(0, 0, 0, 0.80),
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
                    _TagChip(text: "SPOTTED", color: const Color(0xFF22D3EE)),
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
                      capture.artistName ?? 'Unknown Artist',
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
