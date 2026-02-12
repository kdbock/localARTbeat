import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, HudTopBar, WorldBackground, GradientCTAButton;
import 'package:artbeat_capture/artbeat_capture.dart' hide GlassCard, HudTopBar;
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_art_walk/src/widgets/tour/discover_tour_overlay.dart';
import 'dart:async';

/// 🎨 ARTbeat ArtWalk Dashboard Screen
/// Clean, professional design aligned with ArtBeat design system
class DiscoverDashboardScreen extends StatefulWidget {
  const DiscoverDashboardScreen({super.key});

  @override
  State<DiscoverDashboardScreen> createState() =>
      _DiscoverDashboardScreenState();
}

class _DiscoverDashboardScreenState extends State<DiscoverDashboardScreen>
    with TickerProviderStateMixin {
  static const String _unknownLocationKey = '__unknown_location__';

  // Core state
  GoogleMapController? _mapController;
  Position? _currentPosition;
  List<CaptureModel> _localCaptures = [];
  List<AchievementModel> _artWalkAchievements = [];
  UserModel? _currentUser;
  bool _isDisposed = false;
  bool _hasDiscoveriesMade = false; // Track if discoveries were made
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool _isTourActive = false;

  // Tour GlobalKeys
  final GlobalKey _menuKey = GlobalKey();
  final GlobalKey _searchKey = GlobalKey();
  final GlobalKey _chatKey = GlobalKey();
  final GlobalKey _notificationsKey = GlobalKey();
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _radarKey = GlobalKey();
  final GlobalKey _kioskKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _goalsKey = GlobalKey();
  final GlobalKey _socialKey = GlobalKey();
  final GlobalKey _quickActionsKey = GlobalKey();
  final GlobalKey _achievementsKey = GlobalKey();
  final GlobalKey _hotspotsKey = GlobalKey();
  final GlobalKey _radarTitleKey = GlobalKey();

  // Gamification state
  int _currentStreak = 0;
  int _activeWalkersNearby = 0;
  ChallengeModel? _todaysChallenge;
  List<WeeklyGoalModel> _weeklyGoals = [];
  final int _level = 1;
  int _nearbyArtCount = 0;

  // Animation controller - single subtle animation
  late AnimationController _floatController;

  // Services
  late final AchievementService _achievementService;
  late final UserService _userService;
  late final CaptureService _captureService;
  late final InstantDiscoveryService _discoveryService;
  late final ChallengeService _challengeService;
  late final WeeklyGoalsService _weeklyGoalsService;
  late final RewardsService _rewardsService;

  // Notification monitoring
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _achievementService = context.read<AchievementService>();
    _userService = context.read<UserService>();
    _captureService = context.read<CaptureService>();
    _discoveryService = context.read<InstantDiscoveryService>();
    _challengeService = context.read<ChallengeService>();
    _weeklyGoalsService = context.read<WeeklyGoalsService>();
    _rewardsService = context.read<RewardsService>();
    _initializeAnimations();
    _loadAllData();
    _startNotificationMonitoring();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOnboarding();
    });
  }

  Future<void> _checkOnboarding() async {
    final isCompleted = await OnboardingService().isDiscoverOnboardingCompleted();
    if (!isCompleted && mounted) {
      // Small delay to ensure data is loaded and layout is stable
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        setState(() => _isTourActive = true);
      }
    }
  }

  void _initializeAnimations() {
    // Single subtle floating animation
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _notificationSubscription?.cancel();
    _mapController?.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _handleNavigation(int index) {
    switch (index) {
      case 0:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/dashboard', (route) => false);
        break;
      case 1:
        // Already on Art Walk, no navigation needed
        break;
      case 2:
        // Smart camera launch for capture button - checks terms acceptance
        Navigator.of(context).pushNamed('/capture/smart');
        break;
      case 3:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/community/dashboard', (route) => false);
        break;
      case 4:
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/events/discover', (route) => false);
        break;
      default:
        // Handle any other indices gracefully
        break;
    }
  }

  // ... existing code ...

  @override
  Widget build(BuildContext context) {
    final slivers = <Widget>[
      SliverToBoxAdapter(child: _buildHeroSection(key: _heroKey)),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildInstantDiscoveryRadar(key: _radarKey)),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildKioskLaneSection(key: _kioskKey)),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildStatsSection(key: _statsKey)),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildHeroDetailsSection()),
    ];

    if (_todaysChallenge != null) {
      slivers.addAll([
        const SliverToBoxAdapter(
          child: SizedBox(height: ArtWalkDesignSystem.paddingL),
        ),
        SliverToBoxAdapter(child: _buildDailyChallenge()),
      ]);
    }

    if (_weeklyGoals.isNotEmpty) {
      slivers.addAll([
        const SliverToBoxAdapter(
          child: SizedBox(height: ArtWalkDesignSystem.paddingL),
        ),
        SliverToBoxAdapter(child: _buildWeeklyGoals()),
      ]);
    }

    slivers.addAll([
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildLiveSocialFeed(key: _socialKey)),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildQuickActionGrid()),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildAchievementShowcase()),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingL),
      ),
      SliverToBoxAdapter(child: _buildNearbyArtClusters()),
      const SliverToBoxAdapter(
        child: SizedBox(height: ArtWalkDesignSystem.paddingXXL),
      ),
    ]);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.pop(context, _hasDiscoveriesMade);
        }
      },
      child: Stack(
        children: [
          ArtWalkWorldScaffold(
            scaffoldKey: _scaffoldKey,
            drawer: const ArtWalkDrawer(),
            title: 'art_walk_art_walk_dashboard_text_local_scene',
            translateTitle: true,
            showBackButton: false,
            appBar: ArtWalkHeader(
              menuKey: _menuKey,
              searchKey: _searchKey,
              chatKey: _chatKey,
              notificationsKey: _notificationsKey,
              title: 'art_walk_art_walk_dashboard_text_local_scene'.tr(),
              showBackButton: false,
              showSearch: true,
              showChat: true,
              onSearchPressed: () => Navigator.pushNamed(context, '/search'),
              onChatPressed: () =>
                  Navigator.pushNamed(context, '/messaging/inbox'),
              actions: [
                IconButton(
                  key: _notificationsKey,
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.white,
                  ),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/notifications'),
                  tooltip: 'Notifications',
                ),
              ],
            ),
            body: Stack(
              children: [
                Positioned.fill(child: _buildAuroraBackdrop()),
                SafeArea(
                  bottom: false,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: slivers,
                  ),
                ),
              ],
            ),
            bottomNavigationBar: EnhancedBottomNav(
              currentIndex: 1,
              onTap: _handleNavigation,
            ),
          ),
          if (_isTourActive)
            DiscoverTourOverlay(
              menuKey: _menuKey,
              searchKey: _searchKey,
              chatKey: _chatKey,
              notificationsKey: _notificationsKey,
              heroKey: _heroKey,
              radarKey: _radarKey,
              kioskKey: _kioskKey,
              statsKey: _statsKey,
              goalsKey: _goalsKey,
              socialKey: _socialKey,
              quickActionsKey: _quickActionsKey,
              achievementsKey: _achievementsKey,
              hotspotsKey: _hotspotsKey,
              radarTitleKey: _radarTitleKey,
              onFinish: () {
                setState(() => _isTourActive = false);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAuroraBackdrop() {
    return const IgnorePointer(
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-0.6, -0.8),
                  radius: 1.2,
                  colors: [Color(0x3322D3EE), Colors.transparent],
                ),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -80,
            child: SizedBox(
              width: 240,
              height: 240,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x3325D366), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -60,
            child: SizedBox(
              width: 260,
              height: 260,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x332947FF), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection({Key? key}) {
    final greeting = _getDynamicGreeting();
    final userName = _getExplorerName();

    return _glassCard(
      key: key,
      margin: const EdgeInsets.fromLTRB(
        ArtWalkDesignSystem.paddingL,
        ArtWalkDesignSystem.paddingL,
        ArtWalkDesignSystem.paddingL,
        0,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingL,
        vertical: ArtWalkDesignSystem.paddingL,
      ),
      radius: ArtWalkDesignSystem.radiusXXL,
      colors: const [Color(0x3D7C4DFF), Color(0x3322D3EE), Color(0x1A05060A)],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
            decoration: ArtWalkDesignSystem.glassDecoration(
              borderRadius: ArtWalkDesignSystem.radiusM,
              alpha: 0.12,
              borderAlpha: 0.22,
              shadowAlpha: 0.18,
            ),
            child: const Icon(Icons.map_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: ArtWalkDesignSystem.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName!',
                  style: AppTypography.screenTitle().copyWith(fontSize: 24),
                ),
                const SizedBox(height: ArtWalkDesignSystem.paddingS),
                Text(
                  'art_walk_dashboard_greeting_subtitle'.tr(),
                  style: AppTypography.body(
                    Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroDetailsSection() {
    return _glassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      radius: 28,
      colors: const [Color(0x19090E1F), Color(0x14283A74)],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroExperiencePanel(),
          const SizedBox(height: 16),
          _buildHeroTags(),
          const SizedBox(height: 16),
          _buildHeroMissionHighlight(),
          const SizedBox(height: 20),
          _buildHeroPrimaryCtas(),
        ],
      ),
    );
  }

  Widget _buildHeroExperiencePanel() {
    final xp = _currentUser?.experiencePoints ?? 0;
    final level = _currentUser?.level ?? _level;
    final progress = _rewardsService.getLevelProgress(xp, level);
    final xpRange = _rewardsService.getLevelXPRange(level);
    final isMaxLevel = level >= 10;
    final xpToNextLevel = isMaxLevel
        ? 0
        : (xpRange['max']! + 1 - xp).clamp(0, 999999).toInt();
    final levelTitle = _rewardsService.getLevelTitle(level);

    return Container(
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingM),
      decoration: ArtWalkDesignSystem.glassDecoration(
        borderRadius: ArtWalkDesignSystem.radiusXL,
        alpha: 0.18,
        borderAlpha: 0.14,
        shadowAlpha: 0.12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
                decoration: ArtWalkDesignSystem.iconContainerDecoration(
                  color: ArtWalkDesignSystem.primaryTeal,
                  borderRadius: ArtWalkDesignSystem.radiusM,
                  alpha: 0.18,
                ),
                child: const Icon(
                  Icons.stacked_bar_chart,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: ArtWalkDesignSystem.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_hero_xp_label'.tr(),
                      style: AppTypography.helper(
                        Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: ArtWalkDesignSystem.paddingXS),
                    Text(
                      'art_walk_dashboard_hero_level_title'.tr(
                        namedArgs: {
                          'level': level.toString(),
                          'title': levelTitle,
                        },
                      ),
                      style: AppTypography.body().copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          ClipRRect(
            borderRadius: BorderRadius.circular(
              ArtWalkDesignSystem.radiusM.toDouble(),
            ),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingS),
          Text(
            isMaxLevel
                ? 'art_walk_dashboard_hero_xp_max_level'.tr(
                    namedArgs: {'current': xp.toString()},
                  )
                : 'art_walk_dashboard_hero_xp_progress'.tr(
                    namedArgs: {
                      'current': xp.toString(),
                      'remaining': xpToNextLevel.toString(),
                    },
                  ),
            style: AppTypography.body(Colors.white.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTags() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildHeroTagChip(
          icon: Icons.local_fire_department,
          label: 'art_walk_dashboard_hero_tag_streak'.tr(
            namedArgs: {'count': _currentStreak.toString()},
          ),
        ),
        _buildHeroTagChip(
          icon: Icons.people_alt_rounded,
          label: 'art_walk_dashboard_hero_tag_walkers'.tr(
            namedArgs: {'count': _activeWalkersNearby.toString()},
          ),
        ),
        _buildHeroTagChip(
          icon: Icons.camera_alt_rounded,
          label: 'art_walk_dashboard_hero_tag_discoveries'.tr(
            namedArgs: {'count': _localCaptures.length.toString()},
          ),
        ),
      ],
    );
  }

  Widget _buildHeroTagChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingM,
        vertical: ArtWalkDesignSystem.paddingS,
      ),
      decoration: ArtWalkDesignSystem.glassDecoration(
        borderRadius: 30,
        alpha: 0.12,
        borderAlpha: 0.2,
        shadowAlpha: 0,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: ArtWalkDesignSystem.paddingS),
          Text(label, style: AppTypography.badge()),
        ],
      ),
    );
  }

  Widget _buildHeroMissionHighlight() {
    final challenge = _todaysChallenge;
    final rawTitle = challenge?.title ?? '';
    final rawDescription = challenge?.description ?? '';
    final title = rawTitle.trim().isNotEmpty
        ? rawTitle
        : 'art_walk_dashboard_hero_mission_fallback'.tr();
    final description = rawDescription.trim().isNotEmpty
        ? rawDescription
        : 'art_walk_dashboard_hero_mission_fallback_body'.tr();
    final rewardXp = challenge?.rewardXP ?? 0;

    return Container(
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingM),
      decoration: ArtWalkDesignSystem.glassDecoration(
        borderRadius: ArtWalkDesignSystem.radiusXL,
        alpha: 0.16,
        borderAlpha: 0.14,
        shadowAlpha: 0.08,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
                decoration: ArtWalkDesignSystem.iconContainerDecoration(
                  color: ArtWalkDesignSystem.primaryTeal,
                  borderRadius: ArtWalkDesignSystem.radiusM,
                  alpha: 0.2,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: ArtWalkDesignSystem.paddingM),
              Expanded(
                child: Text(
                  'art_walk_dashboard_hero_mission_title'.tr(),
                  style: AppTypography.body().copyWith(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const QuestHistoryScreen(),
                    ),
                  );
                },
                child: Text(
                  'art_walk_dashboard_hero_mission_cta'.tr(),
                  style: AppTypography.body(),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          Text(
            title,
            style: AppTypography.body().copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingS),
          Text(
            description,
            style: AppTypography.body(Colors.white.withValues(alpha: 0.75)),
          ),
          if (rewardXp > 0) ...[
            const SizedBox(height: ArtWalkDesignSystem.paddingM),
            Text(
              'art_walk_dashboard_hero_mission_reward'.tr(
                namedArgs: {'xp': rewardXp.toString()},
              ),
              style: AppTypography.body().copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeroPrimaryCtas() {
    return Row(
      children: [
        Expanded(
          child: GradientCTAButton(
            label: 'art_walk_dashboard_hero_cta_radar'.tr(),
            icon: Icons.radar,
            onPressed: _openInstantDiscovery,
          ),
        ),
        const SizedBox(width: ArtWalkDesignSystem.paddingM),
        Expanded(
          child: GlassSecondaryButton(
            label: 'art_walk_dashboard_hero_cta_community'.tr(),
            icon: Icons.handshake_rounded,
            onTap: () {
              Navigator.pushNamed(context, '/community/dashboard');
            },
          ),
        ),
      ],
    );
  }

  // Stats Section - Clean white cards
  Widget _buildStatsSection({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingL,
      ),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.local_fire_department,
            iconColor: ArtWalkDesignSystem.accentOrange,
            value: '$_currentStreak',
            label: 'art_walk_dashboard_stat_streak'.tr(),
          ),
          const SizedBox(width: ArtWalkDesignSystem.paddingM),
          _buildStatCard(
            icon: Icons.explore,
            iconColor: ArtWalkDesignSystem.primaryTeal,
            value:
                '${_currentUser?.engagementStats.captureCount ?? _currentUser?.captures.length ?? 0}',
            label: 'art_walk_dashboard_stat_discoveries'.tr(),
          ),
          const SizedBox(width: ArtWalkDesignSystem.paddingM),
          _buildStatCard(
            icon: Icons.star,
            iconColor: ArtbeatColors.primaryPurple,
            value: '${_currentUser?.level ?? 1}',
            label: 'art_walk_dashboard_stat_level'.tr(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: _glassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.symmetric(
          vertical: ArtWalkDesignSystem.paddingM,
          horizontal: ArtWalkDesignSystem.paddingS,
        ),
        radius: ArtWalkDesignSystem.radiusXL,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.04),
        ],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
              decoration: ArtWalkDesignSystem.iconContainerDecoration(
                color: iconColor,
                borderRadius: ArtWalkDesignSystem.radiusM,
                alpha: 0.2,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingS),
            Text(value, style: AppTypography.screenTitle()),
            Text(
              label,
              style: AppTypography.helper(ArtWalkDesignSystem.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Daily Challenge - Enhanced card design
  Widget _buildDailyChallenge() {
    return Column(
      children: [
        DailyQuestCard(
          challenge: _todaysChallenge,
          showTimeRemaining: true,
          showRewardPreview: true,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (context) => const QuestHistoryScreen(),
              ),
            );
          },
        ),
        // View all quests button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) => const QuestHistoryScreen(),
                ),
              );
            },
            icon: const Icon(Icons.history),
            label: Text(
              'art_walk_artbeat_artwalk_dashboard_text_view_quest_history'.tr(),
            ),
            style: TextButton.styleFrom(
              foregroundColor: ArtbeatColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  // Weekly Goals Section
  Widget _buildWeeklyGoals({Key? key}) {
    return WeeklyGoalsCard(
      key: key,
      goals: _weeklyGoals,
      titleKey: _goalsKey,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const WeeklyGoalsScreen(),
          ),
        );
      },
    );
  }

  // Instant Discovery Radar - Clean featured section with map background
  Widget _buildInstantDiscoveryRadar({Key? key}) {
    return _glassCard(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.zero,
      radius: 30,
      colors: const [Color(0x19090E1F), Color(0x1910152B)],
      child: SizedBox(
        height: 540,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              if (_currentPosition != null)
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 15,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  tiltGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  onMapCreated: (controller) {},
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        ArtbeatColors.primaryPurple,
                        ArtbeatColors.primaryBlue,
                      ],
                    ),
                  ),
                ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.radar,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'art_walk_dashboard_discovery_title'.tr(),
                                key: _radarTitleKey,
                                style: AppTypography.body().copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'art_walk_dashboard_discovery_subtitle'.tr(),
                                style: AppTypography.body(
                                  Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 85,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '$_nearbyArtCount',
                                    style: AppTypography.screenTitle().copyWith(
                                      fontSize: 32,
                                    ),
                                  ),
                                  Text(
                                    'art_walk_dashboard_discovery_nearby'.tr(),
                                    style: AppTypography.helper(
                                      Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _getRadarStatusMessage(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _nearbyArtCount == 0
                                ? 'art_walk_dashboard_radar_move_around'.tr()
                                : 'art_walk_dashboard_radar_tap_explore'.tr(),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Sponsor Banner
                    if (_currentPosition != null)
                      SponsorBanner(
                        placementKey: SponsorshipPlacements.discoverRadarBanner,
                        userLocation: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        padding: EdgeInsets.zero,
                        showPlaceholder: true,
                        onPlaceholderTap: () => Navigator.pushNamed(
                          context,
                          '/discover-sponsorship',
                        ),
                      ),
                    const SizedBox(height: ArtWalkDesignSystem.paddingL),
                    GradientCTAButton(
                      label: 'art_walk_dashboard_discovery_button'.tr(),
                      icon: Icons.radar,
                      onPressed: _openInstantDiscovery,
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

  Widget _buildKioskLaneSection({Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: ArtWalkDesignSystem.accentOrange,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'dashboard_kiosk_lane_title'.tr(),
                style: ArtWalkDesignSystem.cardTitleStyle,
              ),
            ],
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingS),
          SizedBox(
            height: 96,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('artistProfiles')
                  .where(
                    'kioskLaneUntil',
                    isGreaterThan: Timestamp.fromDate(DateTime.now()),
                  )
                  .orderBy('kioskLaneUntil', descending: true)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'dashboard_kiosk_lane_empty'.tr(),
                      style: ArtWalkDesignSystem.cardSubtitleStyle,
                    ),
                  );
                }

                final artists = snapshot.data!.docs
                    .map((doc) => ArtistProfileModel.fromFirestore(doc))
                    .toList();

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artists.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: ArtWalkDesignSystem.paddingS),
                  itemBuilder: (context, index) =>
                      _buildKioskLaneChip(context, artists[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKioskLaneChip(BuildContext context, ArtistProfileModel artist) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/artist/public-profile',
        arguments: {'artistId': artist.userId},
      ),
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: ArtWalkDesignSystem.glassDecoration(
          borderRadius: ArtWalkDesignSystem.radiusM,
        ),
        child: Row(
          children: [
            BoostPulseRing(
              enabled: artist.hasActiveBoost || artist.hasKioskLane,
              ringPadding: 3,
              ringWidth: 2,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  artist.profileImageUrl,
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                child:
                    !ImageUrlValidator.isValidImageUrl(artist.profileImageUrl)
                    ? Text(
                        artist.displayName.isNotEmpty
                            ? artist.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                artist.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: ArtWalkDesignSystem.cardSubtitleStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Social Feed - Clean community section
  Widget _buildLiveSocialFeed({Key? key}) {
    return _glassCard(
      key: key,
      margin: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingL,
      ),
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
                decoration: ArtWalkDesignSystem.iconContainerDecoration(
                  color: ArtWalkDesignSystem.primaryTeal,
                  borderRadius: ArtWalkDesignSystem.radiusM,
                  alpha: 0.18,
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: ArtWalkDesignSystem.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_community_title'.tr(),
                      style: AppTypography.body().copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_community_subtitle'.tr(),
                      style: AppTypography.body(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: ArtWalkDesignSystem.paddingS,
                  vertical: ArtWalkDesignSystem.paddingXS,
                ),
                decoration: ArtWalkDesignSystem.iconContainerDecoration(
                  color: ArtWalkDesignSystem.primaryTeal,
                  borderRadius: ArtWalkDesignSystem.radiusM,
                  alpha: 0.2,
                ),
                child: Text(
                  'art_walk_dashboard_community_online'.tr(
                    namedArgs: {'count': _activeWalkersNearby.toString()},
                  ),
                  style: AppTypography.badge(Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          SocialActivityFeed(userPosition: _currentPosition, maxItems: 2),
        ],
      ),
    );
  }

  // Quick Action Grid - Clean action cards
  Widget _buildQuickActionGrid() {
    return _glassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingL,
      ),
      padding: const EdgeInsets.fromLTRB(
        ArtWalkDesignSystem.paddingL,
        ArtWalkDesignSystem.paddingM,
        ArtWalkDesignSystem.paddingL,
        ArtWalkDesignSystem.paddingXL,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
                decoration: ArtWalkDesignSystem.iconContainerDecoration(
                  color: ArtWalkDesignSystem.primaryTeal,
                  borderRadius: ArtWalkDesignSystem.radiusM,
                  alpha: 0.18,
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: ArtWalkDesignSystem.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_quick_actions_title'.tr(),
                      key: _quickActionsKey,
                      style: AppTypography.body().copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_quick_actions_subtitle'.tr(),
                      style: AppTypography.body(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: ArtWalkDesignSystem.paddingM,
            mainAxisSpacing: ArtWalkDesignSystem.paddingM,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(
                'art_walk_dashboard_action_create_walk'.tr(),
                Icons.add_location_rounded,
                ArtWalkDesignSystem.accentOrange,
                () => Navigator.pushNamed(context, '/art-walk/create'),
              ),
              _buildActionCard(
                'art_walk_dashboard_action_browse_art'.tr(),
                Icons.palette_rounded,
                ArtbeatColors.primaryPurple,
                () => Navigator.pushNamed(context, '/artwork/browse'),
              ),
              _buildActionCard(
                'art_walk_dashboard_action_my_walks'.tr(),
                Icons.map_rounded,
                ArtWalkDesignSystem.primaryTeal,
                () => Navigator.pushNamed(context, '/art-walk/list'),
              ),
              _buildActionCard(
                'art_walk_dashboard_action_achievements'.tr(),
                Icons.emoji_events_rounded,
                ArtWalkDesignSystem.primaryTealLight,
                () => Navigator.pushNamed(context, '/achievements'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: ArtWalkDesignSystem.buildGlassCard(
        margin: EdgeInsets.zero,
        padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingM),
        borderRadius: ArtWalkDesignSystem.radiusXL,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
              decoration: ArtWalkDesignSystem.iconContainerDecoration(
                color: color,
                borderRadius: ArtWalkDesignSystem.radiusM,
                alpha: 0.18,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingS),
            Text(
              title,
              style: AppTypography.body().copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Achievement Showcase - Clean achievement display
  Widget _buildAchievementShowcase() {
    return _glassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingL,
      ),
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
                decoration: ArtWalkDesignSystem.iconContainerDecoration(
                  color: ArtWalkDesignSystem.accentOrange,
                  borderRadius: ArtWalkDesignSystem.radiusM,
                  alpha: 0.18,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: ArtWalkDesignSystem.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_achievements_title'.tr(),
                      key: _achievementsKey,
                      style: AppTypography.body().copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_achievements_subtitle'.tr(),
                      style: AppTypography.body(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          if (_artWalkAchievements.isEmpty)
            _buildEmptyAchievementsState()
          else
            _buildAchievementsGrid(),
        ],
      ),
    );
  }

  // Nearby Art Clusters - Clean location display
  Widget _buildNearbyArtClusters() {
    return _glassCard(
      margin: const EdgeInsets.symmetric(
        horizontal: ArtWalkDesignSystem.paddingL,
      ),
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
                decoration: ArtWalkDesignSystem.iconContainerDecoration(
                  color: ArtbeatColors.primaryPurple,
                  borderRadius: ArtWalkDesignSystem.radiusM,
                  alpha: 0.2,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: ArtWalkDesignSystem.paddingM),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_nearby_title'.tr(),
                      key: _hotspotsKey,
                      style: AppTypography.body().copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_nearby_subtitle'.tr(),
                      style: AppTypography.body(
                        Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingM),
          if (_localCaptures.isEmpty)
            _buildEmptyClustersState()
          else
            _buildClustersGrid(),
        ],
      ),
    );
  }

  Widget _glassCard({
    Key? key,
    required Widget child,
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
    double radius = ArtWalkDesignSystem.radiusXXL,
    List<Color>? colors,
  }) {
    final decoratedChild = colors != null
        ? DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: colors,
              ),
            ),
            child: child,
          )
        : child;

    return Container(
      key: key,
      margin: margin,
      child: GlassCard(
        padding: padding,
        borderRadius: radius,
        fillColor: colors != null ? Colors.transparent : null,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 24,
          offset: const Offset(0, 16),
        ),
        child: decoratedChild,
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          width: 52,
          height: 52,
          decoration: ArtWalkDesignSystem.glassDecoration(
            borderRadius: 20,
            alpha: 0.18,
            borderAlpha: 0.22,
            shadowAlpha: 0.18,
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );

    return tooltip != null ? Tooltip(message: tooltip, child: button) : button;
  }

  // 🎯 Helper methods for dynamic content

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'art_walk_dashboard_greeting_morning'.tr();
    if (hour < 17) return 'art_walk_dashboard_greeting_afternoon'.tr();
    return 'art_walk_dashboard_greeting_evening'.tr();
  }

  String _getExplorerName() {
    final fullName = _currentUser?.fullName ?? '';
    if (fullName.trim().isNotEmpty) {
      return fullName.trim().split(' ').first;
    }
    final username = _currentUser?.username ?? '';
    if (username.trim().isNotEmpty) {
      return username.trim();
    }
    return 'art_walk_dashboard_default_explorer_name'.tr();
  }

  String _getRadarStatusMessage() {
    if (_nearbyArtCount == 0) return 'art_walk_dashboard_radar_scanning'.tr();
    if (_nearbyArtCount == 1)
      return 'art_walk_dashboard_radar_one_artwork'.tr();
    if (_nearbyArtCount < 5)
      return 'art_walk_dashboard_radar_multiple_artworks'.tr(
        namedArgs: {'count': _nearbyArtCount.toString()},
      );
    return 'art_walk_dashboard_radar_hotspot'.tr(
      namedArgs: {'count': _nearbyArtCount.toString()},
    );
  }

  Widget _buildEmptyAchievementsState() {
    return Container(
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingXL),
      decoration: ArtWalkDesignSystem.glassDecoration(
        borderRadius: ArtWalkDesignSystem.radiusXL,
        alpha: 0.1,
        borderAlpha: 0.12,
        shadowAlpha: 0,
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: ArtWalkDesignSystem.accentOrange.withValues(alpha: 0.6),
            size: 48,
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingS),
          Text(
            'art_walk_dashboard_empty_achievements'.tr(),
            style: AppTypography.body().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingXS),
          Text(
            'art_walk_dashboard_empty_achievements_subtitle'.tr(),
            style: AppTypography.helper(Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: ArtWalkDesignSystem.paddingS,
      mainAxisSpacing: ArtWalkDesignSystem.paddingS,
      childAspectRatio: 0.8,
      children: _artWalkAchievements.take(6).map((achievement) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/achievements'),
          child: ArtWalkDesignSystem.buildGlassCard(
            padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingS),
            borderRadius: ArtWalkDesignSystem.radiusM,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ArtWalkDesignSystem.buttonGradient,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: ArtWalkDesignSystem.paddingXS),
                Text(
                  achievement.title,
                  style: AppTypography.body().copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyClustersState() {
    return Container(
      padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingXL),
      decoration: ArtWalkDesignSystem.glassDecoration(
        borderRadius: ArtWalkDesignSystem.radiusXL,
        alpha: 0.1,
        borderAlpha: 0.12,
        shadowAlpha: 0,
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_searching,
            color: ArtbeatColors.primaryPurple.withValues(alpha: 0.6),
            size: 48,
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingS),
          Text(
            'art_walk_dashboard_empty_clusters'.tr(),
            style: AppTypography.body().copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ArtWalkDesignSystem.paddingXS),
          Text(
            'art_walk_dashboard_empty_clusters_subtitle'.tr(),
            style: AppTypography.helper(Colors.white.withValues(alpha: 0.7)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildClustersGrid() {
    final clusters = _groupCapturesByLocation();
    return Column(
      children: clusters.entries.take(3).map((entry) {
        final locationName = entry.key;
        final captures = entry.value;
        final displayName = locationName == _unknownLocationKey
            ? 'art_walk_dashboard_location_unknown'.tr()
            : locationName;

        return GestureDetector(
          onTap: () => _navigateToLocation(displayName, captures),
          child: ArtWalkDesignSystem.buildGlassCard(
            margin: const EdgeInsets.only(bottom: ArtWalkDesignSystem.paddingS),
            padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingM),
            borderRadius: ArtWalkDesignSystem.radiusXL,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: ArtWalkDesignSystem.buttonGradient,
                  ),
                  child: Center(
                    child: Text(
                      '${captures.length}',
                      style: AppTypography.body().copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: ArtWalkDesignSystem.paddingM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: AppTypography.body().copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'art_walk_dashboard_clusters_artwork_count'.plural(
                          captures.length,
                          namedArgs: {'count': captures.length.toString()},
                        ),
                        style: AppTypography.helper(
                          Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _glassIconButton(
                  icon: Icons.arrow_forward,
                  onTap: () => _navigateToLocation(displayName, captures),
                  tooltip: 'art_walk_dashboard_nearby_title'.tr(),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ... existing methods for data loading, navigation, etc. ...

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadCurrentUser(),
      _loadUserLocationAndSetMap(),
      _loadLocalCaptures(),
      _loadArtWalkAchievements(),
      _loadEngagementData(),
    ]);

    // Load nearby art count after position is available
    await _loadNearbyArtCount();
  }

  Future<void> _loadNearbyArtCount() async {
    try {
      if (_currentPosition != null) {
        final nearbyArt = await _discoveryService.getNearbyArt(
          _currentPosition!,
          radiusMeters: 500,
        );
        if (!_isDisposed && mounted) {
          setState(() => _nearbyArtCount = nearbyArt.length);
        }
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (!_isDisposed && mounted) {
        setState(() => _currentUser = user);
      }
    } catch (e) {
      // debugPrint('Error loading current user: $e');
    }
  }

  Future<void> _loadUserLocationAndSetMap() async {
    try {
      // First try to get location from stored ZIP code
      if (_currentUser?.zipCode != null && _currentUser!.zipCode!.isNotEmpty) {
        final coordinates = await LocationUtils.getCoordinatesFromZipCode(
          _currentUser!.zipCode!,
        );
        if (coordinates != null && mounted) {
          _updateMapPosition(coordinates.latitude, coordinates.longitude);
          return;
        }
      }

      // Then try to get current location
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      if (!_isDisposed && mounted) {
        _updateMapPosition(position.latitude, position.longitude);
      }
    } catch (e) {
      // debugPrint('Error getting location: $e');
      // Default to Asheville, NC
      _updateMapPosition(35.5951, -82.5515);
    }
  }

  void _updateMapPosition(double latitude, double longitude) {
    setState(() {
      _currentPosition = Position(
        latitude: latitude,
        longitude: longitude,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        heading: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
        altitudeAccuracy: 0.0,
        headingAccuracy: 0.0,
      );
    });
  }

  Future<void> _loadLocalCaptures() async {
    try {
      final captures = await _captureService.getAllCaptures();
      if (!_isDisposed && mounted) {
        setState(() => _localCaptures = captures);
      }
    } catch (e) {
      // debugPrint('Error loading captures: $e');
    }
  }

  Future<void> _loadArtWalkAchievements() async {
    try {
      final achievements = await _achievementService.getUserAchievements();
      if (!_isDisposed && mounted) {
        setState(() => _artWalkAchievements = achievements);
      }
    } catch (e) {
      // debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> _loadEngagementData() async {
    try {
      // Load daily challenge
      final challenge = await _challengeService.getTodaysChallenge();

      // Load weekly goals
      final weeklyGoals = await _weeklyGoalsService.getCurrentWeekGoals();

      // Load challenge stats for streak
      final stats = await _challengeService.getChallengeStats();
      final streak = (stats['currentStreak'] as int?) ?? 0;

      // Load active users count - placeholder for now
      _activeWalkersNearby = 12; // Placeholder

      if (!_isDisposed && mounted) {
        setState(() {
          _todaysChallenge = challenge;
          _weeklyGoals = weeklyGoals;
          _currentStreak = streak;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading engagement data: $e');
    }
  }

  void _startNotificationMonitoring() {
    // Start monitoring for nearby art notifications when we have location
    if (_currentPosition != null) {
      _notificationSubscription = _discoveryService
          .monitorNearbyArtNotifications(
            userPosition: _currentPosition!,
            notificationRadiusMeters: 100, // Notify when art is within 100m
            checkInterval: const Duration(
              seconds: 30,
            ), // Check every 30 seconds
          )
          .listen((notification) {
            if (_isDisposed || !mounted) return;

            // Handle notification - could show in-app notification or update UI
            if (notification['type'] == 'nearby_art_discovered') {
              setState(() {});

              final art = notification['art'] as Map<String, dynamic>? ?? {};
              final rawTitle = (art['title'] as String?)?.trim();
              final artTitle = rawTitle != null && rawTitle.isNotEmpty
                  ? rawTitle
                  : 'art_walk_dashboard_snackbar_unknown_art'.tr();
              final rawDistance = (notification['distanceText'] as String?)
                  ?.trim();
              final distanceText = rawDistance != null && rawDistance.isNotEmpty
                  ? rawDistance
                  : 'art_walk_dashboard_distance_unknown'.tr();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'art_walk_dashboard_snackbar_art_nearby'.tr(
                      namedArgs: {'title': artTitle, 'distance': distanceText},
                    ),
                  ),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'art_walk_dashboard_snackbar_view_action'.tr(),
                    onPressed: () {
                      _openInstantDiscovery();
                    },
                  ),
                ),
              );
            }
          });
    }
  }

  Future<void> _openInstantDiscovery() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_dashboard_text_getting_your_location'.tr(),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Get nearby art
      final nearbyArt = await _discoveryService.getNearbyArt(
        _currentPosition!,
        radiusMeters: 500,
      );

      if (!mounted) return;

      if (nearbyArt.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_dashboard_text_no_art_nearby'.tr(),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      // Navigate to radar screen
      final result = await Navigator.pushNamed(
        context,
        '/instant-discovery',
        arguments: {
          'userPosition': _currentPosition,
          'initialNearbyArt': nearbyArt,
        },
      );

      // Refresh nearby art count if discoveries were made
      if (result == true && mounted) {
        _hasDiscoveriesMade = true; // Mark that discoveries were made
        _loadNearbyArtCount();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_dashboard_error_error_loading_nearby'.tr(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _navigateToLocation(String locationName, List<CaptureModel> captures) {
    // Navigate to location-specific view or show captures for that location
    Navigator.pushNamed(
      context,
      '/art-walk/location',
      arguments: {'locationName': locationName, 'captures': captures},
    );
  }

  Map<String, List<CaptureModel>> _groupCapturesByLocation() {
    final clusters = <String, List<CaptureModel>>{};

    for (final capture in _localCaptures) {
      final rawName = capture.locationName?.trim();
      final locationName = (rawName != null && rawName.isNotEmpty)
          ? rawName
          : _unknownLocationKey;
      if (!clusters.containsKey(locationName)) {
        clusters[locationName] = [];
      }
      clusters[locationName]!.add(capture);
    }

    return clusters;
  }
}
