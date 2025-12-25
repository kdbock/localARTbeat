import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

import '../../widgets/dashboard/dashboard_browse_section.dart';

/// Local ARTbeat - Explore Dashboard (Feed + Tabs)
/// - Same modern visual language as the AnimatedDashboardScreen
/// - Restores the "deleted" dashboard content into structured tabs
class ArtbeatDashboardScreen extends StatefulWidget {
  const ArtbeatDashboardScreen({super.key});

  @override
  State<ArtbeatDashboardScreen> createState() => _ArtbeatDashboardScreenState();
}

class _ArtbeatDashboardScreenState extends State<ArtbeatDashboardScreen>
    with TickerProviderStateMixin, RouteAware {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();

  late final TabController _tabController;
  // World background animation (matching animated dashboard)
  late final AnimationController _loopController;
  // Subtle animations (matching “animated dashboard” vibe)
  late final AnimationController _fadeController;
  late final Animation<double> _fade;

  // Celebration overlay
  late final AnimationController _celebrationController;
  bool _showCelebration = false;
  String? _celebrationMessage;

  // UI state
  int _scrollDepth = 0;

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 28,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.white.withOpacity(0.70),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'error_something_wrong'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.92),
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withOpacity(0.70),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh),
                      label: Text('error_try_again'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C4DFF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                      ),
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

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 3, vsync: this);

    _loopController = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _fadeController.forward();

      try {
        final vm = Provider.of<DashboardViewModel>(context, listen: false);
        await vm.initialize();
        _checkForCelebrations(vm);
      } catch (e, stack) {
        AppLogger.error('❌ Dashboard init error: $e');
        AppLogger.error('❌ Stack trace: $stack');
      }
    });
  }

  void _onScroll() {
    final scrollPercent = (_scrollController.offset / 1000).clamp(0.0, 1.0);
    final newDepth = (scrollPercent * 10).round();
    if (newDepth != _scrollDepth) {
      setState(() => _scrollDepth = newDepth);
    }
  }

  @override
  void didPopNext() {
    super.didPopNext();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final vm = Provider.of<DashboardViewModel>(context, listen: false);
        await vm.refreshUserData();
      } catch (e) {
        AppLogger.error('❌ Error refreshing user data: $e');
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    _loopController.dispose();
    _fadeController.dispose();
    _celebrationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<DashboardViewModel>(context);

    String _getErrorMessage(DashboardViewModel vm) {
      if (vm.eventsError != null) {
        return 'dashboard_error_unable_load_events'.tr();
      }
      if (vm.artworkError != null) {
        return 'dashboard_error_unable_load_artwork'.tr();
      }
      if (vm.artistsError != null) {
        return 'dashboard_error_unable_load_artists'.tr();
      }
      return 'dashboard_error_something_wrong_retry'.tr();
    }

    return Scaffold(
      key: _scaffoldKey,
      drawer: const ArtbeatDrawer(),
      backgroundColor: const Color(0xFF07060F),
      body: _hasErrors(vm)
          ? _buildErrorState(_getErrorMessage(vm), () => vm.refresh())
          : Stack(
              children: [
                // World background (matching animated dashboard)
                Positioned.fill(
                  child: AnimatedBuilder(
                    animation: _loopController,
                    builder: (_, __) => CustomPaint(
                      painter: _ExploreWorldPainter(t: _loopController.value),
                      size: Size.infinite,
                    ),
                  ),
                ),

                // Vignette to focus content
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 1.15,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.65),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                FadeTransition(
                  opacity: _fade,
                  child: RefreshIndicator(
                    onRefresh: () => vm.refresh(),
                    color: const Color(0xFF22D3EE),
                    child: NestedScrollView(
                      controller: _scrollController,
                      headerSliverBuilder: (context, innerBoxIsScrolled) {
                        return [
                          _buildSliverHeader(context, vm),
                          _buildPinnedTabs(context),
                        ];
                      },
                      body: TabBarView(
                        controller: _tabController,
                        children: [
                          _ForYouTab(
                            vm: vm,
                            scrollDepth: _scrollDepth,
                            onOpenProfileMenu: () => _showProfileMenu(context),
                            onOpenDrawer: _openDrawer,
                            onNavigateToArtWalk: () =>
                                _navigateToArtWalk(context),
                          ),
                          _ExploreTab(vm: vm),
                          _CommunityTab(vm: vm),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showCelebration) _buildCelebrationOverlay(),
              ],
            ),
    );
  }

  // ---------- Header (Animated-dashboard style) ----------
  Widget _buildSliverHeader(BuildContext context, DashboardViewModel vm) {
    final isCompact = MediaQuery.sizeOf(context).width < 380;
    final user = vm.currentUser;
    final locationLabel = (user?.location.trim().isNotEmpty ?? false)
        ? user!.location
        : 'art_walk_art_walk_dashboard_text_your_location'.tr();

    return SliverAppBar(
      pinned: false,
      floating: false,
      expandedHeight: 400,
      toolbarHeight: 80.0,
      backgroundColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(color: Colors.transparent),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final showSearchInput = constraints.maxHeight > 140;
                final showLocationPill = constraints.maxHeight > 260;
                final showQuickStats = constraints.maxHeight > 320;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        _glassIconButton(icon: Icons.menu, onTap: _openDrawer),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/dashboard'),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "Local ",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white.withValues(
                                              alpha: 0.90,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "ART",
                                          style: GoogleFonts.dmSerifDisplay(
                                            color: const Color(0xFFFFC857),
                                            fontSize: 18,
                                            fontWeight: FontWeight.w400,
                                            letterSpacing: -0.2,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "beat",
                                          style: GoogleFonts.spaceGrotesk(
                                            color: Colors.white.withValues(
                                              alpha: 0.90,
                                            ),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (!isCompact || !showSearchInput) ...[
                          _glassIconButton(
                            icon: Icons.search,
                            onTap: () =>
                                Navigator.pushNamed(context, '/search'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (!isCompact) ...[
                          _glassIconButton(
                            icon: Icons.message,
                            onTap: () =>
                                Navigator.pushNamed(context, '/messaging'),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _notificationButton(vm),
                        const SizedBox(width: 8),
                        _glassIconButton(
                          icon: Icons.account_circle,
                          onTap: () => _showProfileMenu(context),
                        ),
                      ],
                    ),
                    if (showSearchInput) ...[
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/search'),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 0,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 18,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.search,
                                    color: Colors.white.withValues(alpha: 0.70),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'dashboard_search_placeholder'.tr(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withValues(
                                          alpha: 0.70,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.tune,
                                    color: Colors.white.withValues(alpha: 0.70),
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                    ],
                    if (showLocationPill) ...[
                      const SizedBox(height: 14),
                      _LocationPill(
                        label: locationLabel,
                        isLoading: vm.isLoadingLocation,
                        onTap: () =>
                            Navigator.pushNamed(context, '/art-walk/map'),
                      ),
                    ],
                    if (showQuickStats) ...[
                      const SizedBox(height: 10),
                      _QuickStatsRow(
                        vm: vm,
                        onAchieveTap: () =>
                            Navigator.pushNamed(context, '/achievements'),
                        onArtistsTap: () =>
                            Navigator.pushNamed(context, '/artist/browse'),
                        onEventsTap: () =>
                            Navigator.pushNamed(context, '/events/discover'),
                        onCapturesTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  const InstantDiscoveryRadarScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinnedTabs(BuildContext context) {
    const outerVPad = 8.0;
    const innerPad = 4.0;

    // This matches the actual painted height so SliverGeometry stays valid.
    // kTextTabBarHeight is 48.0.
    const headerHeight =
        kTextTabBarHeight + (outerVPad * 2) + (innerPad * 2); // 72.0

    Widget tabPill(IconData icon, String label) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }

    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabHeaderDelegate(
        minExtent: headerHeight,
        maxExtent: headerHeight,
        child: Container(
          color: Colors.transparent, // Transparent for world background
          padding: const EdgeInsets.fromLTRB(16, outerVPad, 16, outerVPad),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.all(innerPad),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.10),
                      blurRadius: 38,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF7C4DFF),
                        Color(0xFF22D3EE),
                        Color(0xFF34D399),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withValues(alpha: 0.70),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  labelStyle: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  tabs: [
                    Tab(
                      child: tabPill(
                        Icons.auto_awesome,
                        'dashboard_tab_for_you'.tr(),
                      ),
                    ),
                    Tab(
                      child: tabPill(
                        Icons.explore,
                        'dashboard_tab_explore'.tr(),
                      ),
                    ),
                    Tab(
                      child: tabPill(
                        Icons.people,
                        'dashboard_tab_community'.tr(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Helpers ----------
  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        // tighter but still accessible
        constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        padding: EdgeInsets.zero,
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        tooltip: icon.toString(),
      ),
    );
  }

  Widget _notificationButton(DashboardViewModel vm) {
    final has = _hasNotifications(vm);
    final count = _getNotificationCount(vm);

    return Stack(
      children: [
        _glassIconButton(
          icon: Icons.notifications,
          onTap: () => _navigateToNotifications(context),
        ),
        if (has)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 16),
              child: Text(
                count > 9 ? '9+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  bool _hasErrors(DashboardViewModel vm) {
    return (vm.eventsError != null && vm.events.isEmpty) ||
        (vm.artworkError != null && vm.artwork.isEmpty);
  }

  String _getErrorMessage(DashboardViewModel vm) {
    if (vm.eventsError != null)
      return 'dashboard_error_unable_load_events'.tr();
    if (vm.artworkError != null)
      return 'dashboard_error_unable_load_artwork'.tr();
    if (vm.artistsError != null)
      return 'dashboard_error_unable_load_artists'.tr();
    return 'dashboard_error_something_wrong_retry'.tr();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  void _showProfileMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const EnhancedProfileMenu(),
    );
  }

  Future<void> _navigateToArtWalk(BuildContext context) async {
    final result = await Navigator.pushNamed(context, '/art-walk/dashboard');
    if (result == true && context.mounted) {
      final vm = Provider.of<DashboardViewModel>(context, listen: false);
      await vm.refresh();
    }
  }

  void _navigateToNotifications(BuildContext context) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('🔔 Notification button tapped! Route: /notifications');
    }
    try {
      Navigator.pushNamed(context, '/notifications');
    } catch (error) {
      AppLogger.error('Notification navigation error: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'error_navigation'.tr(namedArgs: {'error': error.toString()}),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  bool _hasNotifications(DashboardViewModel vm) {
    return (vm.achievements.isNotEmpty) ||
        (vm.currentStreak >= 7) ||
        (vm.activities.isNotEmpty);
  }

  int _getNotificationCount(DashboardViewModel vm) {
    int count = 0;
    if (vm.achievements.isNotEmpty) count += vm.achievements.length;
    if (vm.currentStreak >= 7) count += 1;
    return count.clamp(0, 99);
  }

  void _checkForCelebrations(DashboardViewModel vm) {
    if (vm.currentStreak >= 7 && !_showCelebration) {
      _triggerCelebration('dashboard_celebration_7_day_streak'.tr());
    } else if (vm.totalDiscoveries > 0 && vm.totalDiscoveries % 10 == 0) {
      _triggerCelebration(
        'dashboard_celebration_discoveries'.tr(
          namedArgs: {'count': vm.totalDiscoveries.toString()},
        ),
      );
    }
  }

  void _triggerCelebration(String message) {
    setState(() {
      _showCelebration = true;
      _celebrationMessage = message;
    });
    _celebrationController.forward(from: 0).then((_) {
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        setState(() => _showCelebration = false);
      });
    });
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationController,
      builder: (context, _) {
        final v = Curves.easeOut.transform(_celebrationController.value);
        return Positioned.fill(
          child: Container(
            color: Colors.black.withValues(alpha: 0.72 * v),
            child: Center(
              child: Transform.scale(
                scale: 0.9 + 0.1 * v,
                child: Container(
                  margin: const EdgeInsets.all(28),
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 22,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipRect(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.celebration,
                          size: 56,
                          color: ArtbeatColors.primaryPurple,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _celebrationMessage ??
                              'dashboard_achievement_unlocked'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ArtbeatColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 1: For You (restores hero + activity + engagement + browse/captures)
// -----------------------------------------------------------------------------
class _ForYouTab extends StatelessWidget {
  const _ForYouTab({
    required this.vm,
    required this.scrollDepth,
    required this.onOpenProfileMenu,
    required this.onOpenDrawer,
    required this.onNavigateToArtWalk,
  });

  final DashboardViewModel vm;
  final int scrollDepth;
  final VoidCallback onOpenProfileMenu;
  final VoidCallback onOpenDrawer;
  final VoidCallback onNavigateToArtWalk;

  @override
  Widget build(BuildContext context) {
    final List<CaptureModel> savedCaptures =
        vm.currentUser?.captures ?? <CaptureModel>[];
    final List<ArtworkModel> spotlightArtworks = vm.artwork.take(5).toList();

    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.10),
                      blurRadius: 38,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: DashboardHeroSection(
                  viewModel: vm,
                  onFindArtTap: onNavigateToArtWalk,
                ),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _SmartFiltersBar(
              onFilterSelected: (query) => Navigator.pushNamed(
                context,
                '/search',
                arguments: {'query': query},
              ),
            ),
          ),
        ),
        if (spotlightArtworks.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 0, 0),
              child: _SpotlightCarousel(
                artworks: spotlightArtworks,
                onArtworkTap: (artwork) => Navigator.pushNamed(
                  context,
                  '/artwork/detail',
                  arguments: {'artworkId': artwork.id},
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            transform: Matrix4.translationValues(0, scrollDepth * -1.6, 0),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: LiveActivityFeed(
                activities: vm.activities,
                onTap: () => Navigator.pushNamed(context, '/community/feed'),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _ArtWalkSpotlight(
              challenge: vm.todaysChallenge,
              onDetailTap: onNavigateToArtWalk,
            ),
          ),
        ),
        if (!vm.isAuthenticated) SliverToBoxAdapter(child: _AnonymousBanner()),
        if (vm.isAuthenticated && vm.currentUser != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    height: 500,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                        BoxShadow(
                          color: const Color(
                            0xFF22D3EE,
                          ).withValues(alpha: 0.10),
                          blurRadius: 38,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: IntegratedEngagementWidget(
                      user: vm.currentUser!,
                      currentStreak: vm.currentStreak,
                      totalDiscoveries: vm.totalDiscoveries,
                      weeklyProgress: vm.weeklyProgress,
                      weeklyGoal: 7,
                      achievements: vm.achievements,
                      activities: vm.activities,
                      onProfileTap: onOpenProfileMenu,
                      onAchievementsTap: () =>
                          Navigator.pushNamed(context, '/achievements'),
                      onWeeklyGoalsTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => const WeeklyGoalsScreen(),
                        ),
                      ),
                      onLeaderboardTap: () =>
                          Navigator.pushNamed(context, '/leaderboard'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: DashboardBrowseSection(viewModel: vm),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
            child: DashboardCapturesSection(viewModel: vm),
          ),
        ),
        if (savedCaptures.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SavedCollectionsGrid(
                captures: savedCaptures.take(4).toList(),
                onCaptureTap: (capture) => Navigator.pushNamed(
                  context,
                  '/capture/detail',
                  arguments: {'captureId': capture.id},
                ),
              ),
            ),
          ),
        if (!vm.isAuthenticated)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(top: 8),
              child: DashboardAppExplanation(),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _AnonymousBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_add, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'dashboard_anonymous_title'.tr(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'dashboard_anonymous_message'.tr(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/auth'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ArtbeatColors.primaryPurple,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'dashboard_anonymous_button'.tr(),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 2: Explore (artists + artwork + browse)
// -----------------------------------------------------------------------------
class _ExploreTab extends StatelessWidget {
  const _ExploreTab({required this.vm});
  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        if (vm.artists.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DashboardArtistsSection(viewModel: vm),
            ),
          ),
        if (vm.artwork.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: DashboardArtworkSection(viewModel: vm),
            ),
          ),

        // Always include browse gateway
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: DashboardBrowseSection(viewModel: vm),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// TAB 3: Community (community + events + artist CTA)
// -----------------------------------------------------------------------------
class _CommunityTab extends StatelessWidget {
  const _CommunityTab({required this.vm});
  final DashboardViewModel vm;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        SliverToBoxAdapter(child: DashboardCommunitySection(viewModel: vm)),
        if (vm.events.isNotEmpty)
          SliverToBoxAdapter(child: DashboardEventsSection(viewModel: vm)),

        // Conversion zone (from deleted)
        SliverToBoxAdapter(child: DashboardArtistCtaSection(viewModel: vm)),

        const SliverToBoxAdapter(child: SizedBox(height: 110)),
      ],
    );
  }
}

class _LocationPill extends StatelessWidget {
  const _LocationPill({
    required this.label,
    required this.isLoading,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.near_me, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chevron_right, color: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  const _QuickStatsRow({
    required this.vm,
    required this.onAchieveTap,
    required this.onArtistsTap,
    required this.onEventsTap,
    required this.onCapturesTap,
  });

  final DashboardViewModel vm;
  final VoidCallback onAchieveTap;
  final VoidCallback onArtistsTap;
  final VoidCallback onEventsTap;
  final VoidCallback onCapturesTap;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _QuickStatData(
        label: 'art_walk_dashboard_stat_streak'.tr(),
        value: '${vm.currentStreak}d',
        detail: '${vm.weeklyProgress}/7',
        color: const Color(0xFF7C4DFF),
        onTap: onAchieveTap,
      ),
      _QuickStatData(
        label: 'art_walk_dashboard_stat_discoveries'.tr(),
        value: '${vm.totalDiscoveries}',
        detail: 'art_walk_art_walk_dashboard_text_local_scene'.tr(),
        color: const Color(0xFF22D3EE),
        onTap: onCapturesTap,
      ),
      _QuickStatData(
        label: 'explore_featured_artists'.tr(),
        value: vm.artists.length.toString(),
        detail: 'explore_artists_subtitle'.tr(),
        color: const Color(0xFFFF3D8D),
        onTap: onArtistsTap,
      ),
      _QuickStatData(
        label: 'explore_upcoming_events'.tr(),
        value: vm.events.length.toString(),
        detail: 'explore_upcoming_events_subtitle'.tr(),
        color: const Color(0xFF34D399),
        onTap: onEventsTap,
      ),
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) => _PulseCard(data: stats[index]),
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemCount: stats.length,
      ),
    );
  }
}

class _PulseCard extends StatelessWidget {
  const _PulseCard({required this.data});

  final _QuickStatData data;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [data.color, data.color.withValues(alpha: 0.6)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: data.color.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.value,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                data.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.detail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickStatData {
  const _QuickStatData({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;
  final VoidCallback? onTap;
}

class _SmartFiltersBar extends StatefulWidget {
  const _SmartFiltersBar({required this.onFilterSelected});

  final ValueChanged<String> onFilterSelected;

  @override
  State<_SmartFiltersBar> createState() => _SmartFiltersBarState();
}

class _SmartFiltersBarState extends State<_SmartFiltersBar> {
  int _selectedIndex = 0;

  final List<_SmartFilterChipData> _filters = const [
    _SmartFilterChipData(
      icon: Icons.auto_awesome,
      labelKey: 'explore_featured_artists',
      query: 'artists',
      color: Color(0xFFFF3D8D),
    ),
    _SmartFilterChipData(
      icon: Icons.palette,
      labelKey: 'explore_featured_artwork',
      query: 'artwork',
      color: Color(0xFF7C4DFF),
    ),
    _SmartFilterChipData(
      icon: Icons.groups,
      labelKey: 'explore_community_highlights',
      query: 'community',
      color: Color(0xFF22D3EE),
    ),
    _SmartFilterChipData(
      icon: Icons.event,
      labelKey: 'explore_upcoming_events',
      query: 'events',
      color: Color(0xFF34D399),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final data = _filters[index];
          final selected = index == _selectedIndex;
          return GestureDetector(
            onTap: () {
              setState(() => _selectedIndex = index);
              widget.onFilterSelected(data.query);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? data.color.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? data.color.withValues(alpha: 0.6)
                      : Colors.white.withValues(alpha: 0.12),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(data.icon, size: 16, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    data.labelKey.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _filters.length,
      ),
    );
  }
}

class _SmartFilterChipData {
  const _SmartFilterChipData({
    required this.icon,
    required this.labelKey,
    required this.query,
    required this.color,
  });

  final IconData icon;
  final String labelKey;
  final String query;
  final Color color;
}

class _SpotlightCarousel extends StatefulWidget {
  const _SpotlightCarousel({
    required this.artworks,
    required this.onArtworkTap,
  });

  final List<ArtworkModel> artworks;
  final ValueChanged<ArtworkModel> onArtworkTap;

  @override
  State<_SpotlightCarousel> createState() => _SpotlightCarouselState();
}

class _SpotlightCarouselState extends State<_SpotlightCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: 0.82,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'explore_featured_artwork'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'explore_featured_artwork_subtitle'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.artworks.length,
            itemBuilder: (context, index) {
              final artwork = widget.artworks[index];
              return Padding(
                padding: EdgeInsets.only(
                  right: index == widget.artworks.length - 1 ? 0 : 16,
                ),
                child: GestureDetector(
                  onTap: () => widget.onArtworkTap(artwork),
                  child: _SpotlightCard(artwork: artwork),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SpotlightCard extends StatelessWidget {
  const _SpotlightCard({required this.artwork});

  final ArtworkModel artwork;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        fit: StackFit.expand,
        children: [
          SecureNetworkImage(imageUrl: artwork.imageUrl, fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artwork.artistName,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    artwork.medium.isNotEmpty
                        ? artwork.medium
                        : 'artwork_filter_medium'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 11,
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
}

class _SavedCollectionsGrid extends StatelessWidget {
  const _SavedCollectionsGrid({
    required this.captures,
    required this.onCaptureTap,
  });

  final List<CaptureModel> captures;
  final ValueChanged<CaptureModel> onCaptureTap;

  @override
  Widget build(BuildContext context) {
    final preview = captures.take(4).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'drawer_favorites'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'artwork_saved_searches'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.2,
          ),
          itemCount: preview.length,
          itemBuilder: (context, index) {
            final capture = preview[index];
            return GestureDetector(
              onTap: () => onCaptureTap(capture),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    SecureNetworkImage(
                      imageUrl: capture.imageUrl,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.8),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            capture.title?.isNotEmpty == true
                                ? capture.title!
                                : 'explore_featured_artwork'.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            capture.locationName ??
                                capture.artistName ??
                                'art_walk_art_walk_dashboard_text_browse_artwork'
                                    .tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ArtWalkSpotlight extends StatelessWidget {
  const _ArtWalkSpotlight({required this.challenge, required this.onDetailTap});

  final ChallengeModel? challenge;
  final VoidCallback onDetailTap;

  @override
  Widget build(BuildContext context) {
    final progress = challenge != null && challenge!.targetCount > 0
        ? (challenge!.currentCount / challenge!.targetCount).clamp(0.0, 1.0)
        : 0.0;
    final title = challenge?.title.isNotEmpty == true
        ? challenge!.title
        : 'art_walk_dashboard_discovery_title'.tr();
    final description = challenge?.description.isNotEmpty == true
        ? challenge!.description
        : 'art_walk_art_walk_dashboard_text_art_events_and'.tr();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'art_walk_dashboard_greeting_subtitle'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF22D3EE)),
              ),
              const SizedBox(height: 10),
              Text(
                '${challenge?.currentCount ?? 0}/${challenge?.targetCount ?? 0} • ${challenge?.rewardXP ?? 0} XP',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: onDetailTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF22D3EE),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text('art_walk_drawer_saved_walks'.tr()),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/art-walk/list'),
                    style: TextButton.styleFrom(foregroundColor: Colors.white),
                    child: Text(
                      'art_walk_art_walk_dashboard_text_trending'.tr(),
                    ),
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

// -----------------------------------------------------------------------------
// Pinned header delegate
// -----------------------------------------------------------------------------
class _TabHeaderDelegate extends SliverPersistentHeaderDelegate {
  _TabHeaderDelegate({
    required this.minExtent,
    required this.maxExtent,
    required this.child,
  });

  @override
  final double minExtent;

  @override
  final double maxExtent;

  final Widget child;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _TabHeaderDelegate oldDelegate) {
    return oldDelegate.minExtent != minExtent ||
        oldDelegate.maxExtent != maxExtent ||
        oldDelegate.child != child;
  }
}

// -----------------------------------------------------------------------------
// World background painter (matching animated dashboard)
// -----------------------------------------------------------------------------
class _ExploreWorldPainter extends CustomPainter {
  final double t;
  _ExploreWorldPainter({required this.t});

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

    // Ambient blobs
    _blob(canvas, size, const Color(0xFFFF3D8D), 0.18, 0.18, 0.34, phase: 0.0);
    _blob(canvas, size, const Color(0xFF7C4DFF), 0.82, 0.20, 0.28, phase: 0.2);
    _blob(canvas, size, const Color(0xFFFFC857), 0.74, 0.78, 0.38, phase: 0.45);
    _blob(canvas, size, const Color(0xFF34D399), 0.16, 0.78, 0.34, phase: 0.62);
    _blob(canvas, size, const Color(0xFF22D3EE), 0.54, 0.56, 0.44, phase: 0.78);

    // Radar rings
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final maxR = size.width * 0.62;

    for (int i = 1; i <= 4; i++) {
      final r = maxR * (i / 4.0);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.045);
      canvas.drawCircle(center, r, p);
    }

    // Sweeping radar arc
    final angle = t * 2 * math.pi;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * 0.95),
      angle - 0.55,
      0.75,
      false,
      arcPaint,
    );

    // Quest path (marching dots)
    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.70)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.54,
        size.width * 0.52,
        size.height * 0.82,
        size.width * 0.88,
        size.height * 0.60,
      );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawPath(path, linePaint);

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final m = metrics.first;
      final len = m.length;
      final baseOffset = (t * 1.3) % 1.0 * len;

      for (int i = 0; i < 28; i++) {
        final d = (baseOffset + i * (len / 28)) % len;
        final pos = m.getTangentForOffset(d)?.position;
        if (pos == null) continue;

        final isNode = i % 7 == 0;
        final dotPaint = Paint()
          ..color = (isNode ? const Color(0xFFFFC857) : Colors.white)
              .withValues(alpha: isNode ? 0.14 : 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(pos, isNode ? 4.0 : 2.1, dotPaint);

        if (isNode) {
          // node ring
          final local = ((t + i * 0.09) % 1.0);
          final sweep = (0.2 + 0.7 * (local * local * (3 - 2 * local))).clamp(
            0.0,
            1.0,
          );
          final ringPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFFF3D8D).withValues(alpha: 0.08);

          canvas.drawArc(
            Rect.fromCircle(center: pos, radius: 12),
            local * 2 * math.pi,
            2 * math.pi * sweep,
            false,
            ringPaint,
          );
        }
      }
    }
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
    final dx = math.sin((t + phase) * 2 * math.pi) * 0.035;
    final dy = math.cos((t + phase) * 2 * math.pi) * 0.035;

    final center = Offset(size.width * (ax + dx), size.height * (ay + dy));
    final radius = size.width * r;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _ExploreWorldPainter oldDelegate) =>
      oldDelegate.t != t;
}
