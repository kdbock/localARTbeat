import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'dart:async';

// Clean Dashboard Colors - Aligned with ArtBeat design system
class ArtWalkDashboardColors {
  // Use standard ArtBeat colors
  static const Color primaryPurple = ArtbeatColors.primaryPurple;
  static const Color primaryGreen = ArtbeatColors.primaryGreen;
  static const Color primaryBlue = ArtbeatColors.primaryBlue;
  static const Color accentOrange = ArtbeatColors.accentOrange;

  // Text colors
  static const Color textPrimary = ArtbeatColors.textPrimary;
  static const Color textSecondary = ArtbeatColors.textSecondary;

  // Background colors
  static const Color cardBackground = Colors.white;
  static const Color backgroundLight = Color(0xFFF8F9FA);
}

/// 🎨 ARTbeat ArtWalk Dashboard Screen
/// Clean, professional design aligned with ArtBeat design system
class ArtbeatArtwalkDashboardScreen extends StatefulWidget {
  const ArtbeatArtwalkDashboardScreen({super.key});

  @override
  State<ArtbeatArtwalkDashboardScreen> createState() =>
      _ArtbeatArtwalkDashboardScreenState();
}

class _ArtbeatArtwalkDashboardScreenState
    extends State<ArtbeatArtwalkDashboardScreen>
    with TickerProviderStateMixin {
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          // Return true if discoveries were made to refresh main dashboard
          Navigator.pop(context, _hasDiscoveriesMade);
        }
      },
      child: Scaffold(
        backgroundColor: ArtWalkDashboardColors.backgroundLight,
        drawer: const ArtWalkDrawer(),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Section - Clean gradient header
              _buildHeroSection(),

              const SizedBox(height: 16),

              // 2. Stats Cards - XP, Level, Streaks
              _buildStatsSection(),

              const SizedBox(height: 16),

              // 3. Instant Discovery Radar - Featured section
              _buildInstantDiscoveryRadar(),

              const SizedBox(height: 16),

              // 3.5. Ad0 - Art Walks Zone (Early placement)
              const SizedBox.shrink(),

              const SizedBox(height: 16),

              // 4. Daily Challenge
              if (_todaysChallenge != null) _buildDailyChallenge(),
              if (_todaysChallenge != null) const SizedBox(height: 16),

              // 5. Weekly Goals
              if (_weeklyGoals.isNotEmpty) _buildWeeklyGoals(),
              if (_weeklyGoals.isNotEmpty) const SizedBox(height: 16),

              // 6. Social Activity Feed
              _buildLiveSocialFeed(),

              const SizedBox(height: 16),

              // 7. Quick Action Grid
              _buildQuickActionGrid(),

              const SizedBox(height: 16),

              // 7.5. Ad1 - Art Walks Zone
              const SizedBox.shrink(),

              const SizedBox(height: 16),

              // 8. Achievement Showcase
              _buildAchievementShowcase(),

              const SizedBox(height: 16),

              // 8.5. Ad2 - Art Walks Zone
              const SizedBox.shrink(),

              const SizedBox(height: 16),

              // 9. Nearby Art Clusters
              _buildNearbyArtClusters(),

              const SizedBox(height: 16),

              // 10. Ad3 - Art Walks Zone
              const SizedBox.shrink(),

              const SizedBox(height: 16),

              // 11. Ad4 - Art Walks Zone
              const SizedBox.shrink(),

              const SizedBox(height: 16),

              // 12. Ad5 - Art Walks Zone
              const SizedBox.shrink(),

              const SizedBox(height: 100),
            ],
          ),
        ),
        bottomNavigationBar: EnhancedBottomNav(
          currentIndex: 1, // Art Walk is index 1
          onTap: _handleNavigation,
        ),
      ),
    );
  }

  // Hero Section - Clean gradient header
  Widget _buildHeroSection() {
    final userName = _currentUser?.fullName.split(' ').first ?? 'Art Explorer';
    final greeting = _getDynamicGreeting();

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtWalkDashboardColors.primaryPurple,
            ArtWalkDashboardColors.primaryGreen,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menu button and greeting row
              Row(
                children: [
                  // Menu button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(
                          Icons.menu,
                          color: Colors.white,
                          size: 24,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                        tooltip: 'Open Menu',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Greeting
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.map_rounded,
                            color: Colors.white,
                            size: 24,
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
                              const Text(
                                'Ready for your next art adventure?',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
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
            ],
          ),
        ),
      ),
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
            label: 'Day Streak',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.explore,
            iconColor: ArtWalkDashboardColors.primaryGreen,
            value: '${_localCaptures.length}',
            label: 'Discoveries',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.star,
            iconColor: ArtWalkDashboardColors.primaryPurple,
            value: '$_level',
            label: 'Level',
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
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 400,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: ArtWalkDashboardColors.primaryPurple.withValues(
                alpha: 0.3,
              ),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Map background
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
                  onMapCreated: (controller) {
                    // Optional: store controller if needed for updates
                  },
                )
              else
                // Fallback gradient if location not available yet
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

              // Gradient overlay for better text readability
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),

              // Content overlay
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Header
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
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Instant Discovery',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Find art around you in real-time',
                                style: TextStyle(
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

                    // Status display
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          // Art count display
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.4),
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
                                    'nearby',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Status message
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
                                ? 'Move around to discover art nearby'
                                : 'Tap below to start exploring',
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

                    // Action button
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
                        child: const Text(
                          'Start Discovery',
                          style: TextStyle(
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ArtWalkDashboardColors.primaryGreen.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.people_rounded,
                    color: ArtWalkDashboardColors.primaryGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Community Activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ArtWalkDashboardColors.textPrimary,
                        ),
                      ),
                      Text(
                        'See what others are discovering',
                        style: TextStyle(
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
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$_activeWalkersNearby online',
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

            // Social activity feed
            SocialActivityFeed(userPosition: _currentPosition, maxItems: 2),
          ],
        ),
      ),
    );
  }

  // Quick Action Grid - Clean action cards
  Widget _buildQuickActionGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ArtWalkDashboardColors.primaryBlue.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    color: ArtWalkDashboardColors.primaryBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ArtWalkDashboardColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Explore more features',
                        style: TextStyle(
                          fontSize: 14,
                          color: ArtWalkDashboardColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Action cards grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
            children: [
              _buildActionCard(
                'Create Walk',
                Icons.add_location_rounded,
                ArtWalkDashboardColors.accentOrange,
                () => Navigator.pushNamed(context, '/art-walk/create'),
              ),
              _buildActionCard(
                'Browse Art',
                Icons.palette_rounded,
                ArtWalkDashboardColors.primaryPurple,
                () => Navigator.pushNamed(context, '/artwork/browse'),
              ),
              _buildActionCard(
                'My Walks',
                Icons.map_rounded,
                ArtWalkDashboardColors.primaryBlue,
                () => Navigator.pushNamed(context, '/art-walk/list'),
              ),
              _buildActionCard(
                'Achievements',
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ArtWalkDashboardColors.accentOrange.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    color: ArtWalkDashboardColors.accentOrange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ArtWalkDashboardColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Your art walk milestones',
                        style: TextStyle(
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
      ),
    );
  }

  // Nearby Art Clusters - Clean location display
  Widget _buildNearbyArtClusters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(20),
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
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ArtWalkDashboardColors.primaryPurple.withValues(
                      alpha: 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: ArtWalkDashboardColors.primaryPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nearby Art Hotspots',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ArtWalkDashboardColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Explore art clusters near you',
                        style: TextStyle(
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
      ),
    );
  }

  // 🎯 Helper methods for dynamic content

  String _getDynamicGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _getRadarStatusMessage() {
    if (_nearbyArtCount == 0) return 'Scanning for art...';
    if (_nearbyArtCount == 1) return '1 artwork nearby!';
    if (_nearbyArtCount < 5) return '$_nearbyArtCount artworks nearby!';
    return 'Art hotspot! $_nearbyArtCount artworks nearby!';
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
          const Text(
            'Your achievement gallery awaits!',
            style: TextStyle(
              color: ArtWalkDashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Start discovering art to unlock amazing achievements',
            style: TextStyle(
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
        return Container(
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
          const Text(
            'Art hotspots loading...',
            style: TextStyle(
              color: ArtWalkDashboardColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          const Text(
            'Move around to discover amazing art in your area!',
            style: TextStyle(
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

        return Container(
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
                      locationName,
                      style: const TextStyle(
                        color: ArtWalkDashboardColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${captures.length} artwork${captures.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: ArtWalkDashboardColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _navigateToLocation(locationName, captures),
                icon: const Icon(
                  Icons.arrow_forward,
                  color: ArtWalkDashboardColors.primaryPurple,
                  size: 20,
                ),
              ),
            ],
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
              // Update nearby art count if needed
              setState(() {
                // Could update UI to show notification or refresh nearby art count
              });

              // Show a brief snackbar notification
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '🎨 ${notification['art']['title'] ?? 'Art'} is nearby! (${notification['distanceText']})',
                  ),
                  duration: const Duration(seconds: 3),
                  action: SnackBarAction(
                    label: 'View',
                    onPressed: () {
                      // Navigate to instant discovery radar
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
      final locationName = capture.locationName ?? 'Unknown Location';
      if (!clusters.containsKey(locationName)) {
        clusters[locationName] = [];
      }
      clusters[locationName]!.add(capture);
    }

    return clusters;
  }
}
