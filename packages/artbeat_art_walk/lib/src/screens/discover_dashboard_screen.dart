import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'dart:async';
import 'dart:ui';

// Clean Dashboard Colors - Aligned with ArtBeat design system
class ArtWalkDashboardColors {
  // Use standard ArtBeat colors
  static const Color primaryPurple = ArtbeatColors.primaryPurple;
  static const Color primaryGreen = ArtbeatColors.primaryGreen;
  static const Color primaryBlue = ArtbeatColors.primaryBlue;
  static const Color accentOrange = ArtbeatColors.accentOrange;

  // Text colors
  static const Color textPrimary = Color(0xFFE6ECF7);
  static const Color textSecondary = Color(0xFF97A4C2);

  // Background colors
  static const Color cardBackground = Color(0xFF101527);
  static const Color backgroundLight = Color(0xFF05060A);
}

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
  final AchievementService _achievementService = AchievementService();
  final UserService _userService = UserService();
  final CaptureService _captureService = CaptureService();
  final InstantDiscoveryService _discoveryService = InstantDiscoveryService();
  final ChallengeService _challengeService = ChallengeService();
  final WeeklyGoalsService _weeklyGoalsService = WeeklyGoalsService();
  final RewardsService _rewardsService = RewardsService();

  // Notification monitoring
  StreamSubscription<Map<String, dynamic>>? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAllData();
    _startNotificationMonitoring();
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
      SliverToBoxAdapter(child: _buildHeroSection()),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _buildInstantDiscoveryRadar()),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _buildStatsSection()),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _buildHeroDetailsSection()),
    ];

    if (_todaysChallenge != null) {
      slivers.addAll([
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        SliverToBoxAdapter(child: _buildDailyChallenge()),
      ]);
    }

    if (_weeklyGoals.isNotEmpty) {
      slivers.addAll([
        const SliverToBoxAdapter(child: SizedBox(height: 18)),
        SliverToBoxAdapter(child: _buildWeeklyGoals()),
      ]);
    }

    slivers.addAll([
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _buildLiveSocialFeed()),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _buildQuickActionGrid()),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _buildAchievementShowcase()),
      const SliverToBoxAdapter(child: SizedBox(height: 18)),
      SliverToBoxAdapter(child: _buildNearbyArtClusters()),
      const SliverToBoxAdapter(child: SizedBox(height: 120)),
    ]);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          Navigator.pop(context, _hasDiscoveriesMade);
        }
      },
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF05060A),
              Color(0xFF0B1220),
              Color(0xFF05060A),
            ],
          ),
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          drawer: const ArtWalkDrawer(),
          body: Stack(
            children: [
              Positioned.fill(child: _buildAuroraBackdrop()),
              SafeArea(
                bottom: false,
                child: CustomScrollView(
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
                  colors: [
                    Color(0x3322D3EE),
                    Colors.transparent,
                  ],
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
                    colors: [
                      Color(0x3325D366),
                      Colors.transparent,
                    ],
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
                    colors: [
                      Color(0x332947FF),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final greeting = _getDynamicGreeting();
    final userName = _getExplorerName();

    return _glassCard(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      radius: 28,
      colors: const [
        Color(0x3D7C4DFF),
        Color(0x3322D3EE),
        Color(0x1A05060A),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) => _glassIconButton(
              icon: Icons.menu,
              tooltip: 'art_walk_dashboard_menu_tooltip'.tr(),
              onTap: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.map_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $userName!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'art_walk_dashboard_greeting_subtitle'.tr(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
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
      colors: const [
        Color(0x19090E1F),
        Color(0x14283A74),
      ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stacked_bar_chart,
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
                      'art_walk_dashboard_hero_xp_label'.tr(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_hero_level_title'.tr(
                        namedArgs: {
                          'level': level.toString(),
                          'title': levelTitle,
                        },
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 8),
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
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'art_walk_dashboard_hero_mission_title'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push<void>(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const QuestHistoryScreen(),
                    ),
                  );
                },
                child: Text(
                  'art_walk_dashboard_hero_mission_cta'.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          if (rewardXp > 0) ...[
            const SizedBox(height: 12),
            Text(
              'art_walk_dashboard_hero_mission_reward'.tr(
                namedArgs: {'xp': rewardXp.toString()},
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
          child: ElevatedButton.icon(
            onPressed: _openInstantDiscovery,
            icon: const Icon(Icons.radar),
            label: Text('art_walk_dashboard_hero_cta_radar'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: ArtWalkDashboardColors.primaryPurple,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/community/dashboard');
            },
            icon: const Icon(Icons.handshake_rounded, color: Colors.white),
            label: Text(
              'art_walk_dashboard_hero_cta_community'.tr(),
              textAlign: TextAlign.center,
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Stats Section - Clean white cards
  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.local_fire_department,
            iconColor: ArtWalkDashboardColors.accentOrange,
            value: '$_currentStreak',
            label: 'art_walk_dashboard_stat_streak'.tr(),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.explore,
            iconColor: ArtWalkDashboardColors.primaryGreen,
            value: '${_localCaptures.length}',
            label: 'art_walk_dashboard_stat_discoveries'.tr(),
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.star,
            iconColor: ArtWalkDashboardColors.primaryPurple,
            value: '$_level',
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
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        radius: 22,
        colors: [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.04),
        ],
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.35),
                ),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ArtWalkDashboardColors.textPrimary,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: ArtWalkDashboardColors.textSecondary,
              ),
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
            Navigator.push<void>(
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
              Navigator.push<void>(
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
              foregroundColor: ArtWalkDashboardColors.primaryPurple,
            ),
          ),
        ),
      ],
    );
  }

  // Weekly Goals Section
  Widget _buildWeeklyGoals() {
    return WeeklyGoalsCard(
      goals: _weeklyGoals,
      onTap: () {
        Navigator.push<void>(
          context,
          MaterialPageRoute<void>(
            builder: (context) => const WeeklyGoalsScreen(),
          ),
        );
      },
    );
  }

  // Instant Discovery Radar - Clean featured section with map background
  Widget _buildInstantDiscoveryRadar() {
    return _glassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.zero,
      radius: 30,
      colors: const [
        Color(0x19090E1F),
        Color(0x1910152B),
      ],
      child: SizedBox(
        height: 400,
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
                        ArtWalkDashboardColors.primaryPurple,
                        ArtWalkDashboardColors.primaryBlue,
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
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'art_walk_dashboard_discovery_subtitle'.tr(),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
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
                            height: 80,
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
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Text(
                                    'art_walk_dashboard_discovery_nearby',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ).tr(),
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
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _openInstantDiscovery,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: ArtWalkDashboardColors.primaryPurple,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'art_walk_dashboard_discovery_button'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }

  // Social Feed - Clean community section
  Widget _buildLiveSocialFeed() {
    return _glassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtWalkDashboardColors.primaryGreen.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_rounded,
                  color: ArtWalkDashboardColors.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_community_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ArtWalkDashboardColors.textPrimary,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_community_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: ArtWalkDashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: ArtWalkDashboardColors.primaryGreen.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'art_walk_dashboard_community_online'.tr(
                    namedArgs: {'count': _activeWalkersNearby.toString()},
                  ),
                  style: const TextStyle(
                    color: ArtWalkDashboardColors.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SocialActivityFeed(userPosition: _currentPosition, maxItems: 2),
        ],
      ),
    );
  }

  // Quick Action Grid - Clean action cards
  Widget _buildQuickActionGrid() {
    return _glassCard(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtWalkDashboardColors.primaryBlue.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: ArtWalkDashboardColors.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_quick_actions_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ArtWalkDashboardColors.textPrimary,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_quick_actions_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: ArtWalkDashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(
                'art_walk_dashboard_action_create_walk'.tr(),
                Icons.add_location_rounded,
                ArtWalkDashboardColors.accentOrange,
                () => Navigator.pushNamed(context, '/art-walk/create'),
              ),
              _buildActionCard(
                'art_walk_dashboard_action_browse_art'.tr(),
                Icons.palette_rounded,
                ArtWalkDashboardColors.primaryPurple,
                () => Navigator.pushNamed(context, '/artwork/browse'),
              ),
              _buildActionCard(
                'art_walk_dashboard_action_my_walks'.tr(),
                Icons.map_rounded,
                ArtWalkDashboardColors.primaryBlue,
                () => Navigator.pushNamed(context, '/art-walk/list'),
              ),
              _buildActionCard(
                'art_walk_dashboard_action_achievements'.tr(),
                Icons.emoji_events_rounded,
                ArtWalkDashboardColors.primaryGreen,
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ArtWalkDashboardColors.cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ArtWalkDashboardColors.textPrimary,
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtWalkDashboardColors.accentOrange.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  color: ArtWalkDashboardColors.accentOrange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_achievements_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ArtWalkDashboardColors.textPrimary,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_achievements_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: ArtWalkDashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
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
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ArtWalkDashboardColors.primaryPurple.withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: ArtWalkDashboardColors.primaryPurple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'art_walk_dashboard_nearby_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ArtWalkDashboardColors.textPrimary,
                      ),
                    ),
                    Text(
                      'art_walk_dashboard_nearby_subtitle'.tr(),
                      style: const TextStyle(
                        fontSize: 14,
                        color: ArtWalkDashboardColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_localCaptures.isEmpty)
            _buildEmptyClustersState()
          else
            _buildClustersGrid(),
        ],
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsets margin = EdgeInsets.zero,
    EdgeInsets padding = const EdgeInsets.all(20),
    double radius = 22,
    List<Color>? colors,
    bool showBorder = true,
    bool elevated = true,
  }) {
    final gradientColors = colors ??
        [
          Colors.white.withValues(alpha: 0.12),
          Colors.white.withValues(alpha: 0.04),
        ];

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: elevated
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 16),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              border: showBorder
                  ? Border.all(color: Colors.white.withValues(alpha: 0.15))
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _glassIconButton({
    required IconData icon,
    required VoidCallback onTap,
    String? tooltip,
  }) {
    final button = ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 48,
              height: 48,
              child: Icon(icon, color: Colors.white, size: 22),
            ),
          ),
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ArtWalkDashboardColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.emoji_events_outlined,
            color: ArtWalkDashboardColors.accentOrange.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'art_walk_dashboard_empty_achievements'.tr(),
            style: const TextStyle(
              color: ArtWalkDashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'art_walk_dashboard_empty_achievements_subtitle'.tr(),
            style: const TextStyle(
              color: ArtWalkDashboardColors.textSecondary,
              fontSize: 12,
            ),
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
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 0.8,
      children: _artWalkAchievements.take(6).map((achievement) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/achievements'),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ArtWalkDashboardColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArtWalkDashboardColors.accentOrange,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  achievement.title,
                  style: const TextStyle(
                    color: ArtWalkDashboardColors.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: ArtWalkDashboardColors.backgroundLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.location_searching,
            color: ArtWalkDashboardColors.primaryPurple.withValues(alpha: 0.5),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'art_walk_dashboard_empty_clusters'.tr(),
            style: const TextStyle(
              color: ArtWalkDashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'art_walk_dashboard_empty_clusters_subtitle'.tr(),
            style: const TextStyle(
              color: ArtWalkDashboardColors.textSecondary,
              fontSize: 12,
            ),
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
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: ArtWalkDashboardColors.backgroundLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArtWalkDashboardColors.primaryPurple,
                  ),
                  child: Center(
                    child: Text(
                      '${captures.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          color: ArtWalkDashboardColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'art_walk_dashboard_clusters_artwork_count'.plural(
                          captures.length,
                          namedArgs: {
                            'count': captures.length.toString(),
                          },
                        ),
                        style: const TextStyle(
                          color: ArtWalkDashboardColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _navigateToLocation(displayName, captures),
                  icon: const Icon(
                    Icons.arrow_forward,
                    color: ArtWalkDashboardColors.primaryPurple,
                    size: 20,
                  ),
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
              final rawDistance = (notification['distanceText'] as String?)?.trim();
              final distanceText = rawDistance != null && rawDistance.isNotEmpty
                  ? rawDistance
                  : 'art_walk_dashboard_distance_unknown'.tr();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'art_walk_dashboard_snackbar_art_nearby'.tr(
                      namedArgs: {
                        'title': artTitle,
                        'distance': distanceText,
                      },
                    ),
                  ),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'art_walk_dashboard_snackbar_view_action'.tr(),
                    onPressed: () {
                      Navigator.of(context).pushNamed('/instant-discovery');
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
      final result = await Navigator.push(
        context,
        MaterialPageRoute<dynamic>(
          builder: (context) => InstantDiscoveryRadarScreen(
            userPosition: _currentPosition!,
            initialNearbyArt: nearbyArt,
          ),
        ),
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
      final locationName =
          (rawName != null && rawName.isNotEmpty) ? rawName : _unknownLocationKey;
      if (!clusters.containsKey(locationName)) {
        clusters[locationName] = [];
      }
      clusters[locationName]!.add(capture);
    }

    return clusters;
  }
}
