import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/models.dart';
import '../services/social_service.dart';

/// Celebratory screen shown when an art walk is completed
class ArtWalkCelebrationScreen extends StatefulWidget {
  final CelebrationData celebrationData;

  const ArtWalkCelebrationScreen({super.key, required this.celebrationData});

  @override
  State<ArtWalkCelebrationScreen> createState() =>
      _ArtWalkCelebrationScreenState();
}

class _ArtWalkCelebrationScreenState extends State<ArtWalkCelebrationScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _statsController;
  late AnimationController _achievementController;
  late AnimationController _pointsController;

  late Animation<double> _fadeInAnimation;
  late Animation<double> _slideUpAnimation;
  late Animation<int> _pointsCountAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _achievementController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pointsController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Create animations
    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeInOut),
    );

    _slideUpAnimation = Tween<double>(begin: 50.0, end: 0.0).animate(
      CurvedAnimation(parent: _statsController, curve: Curves.easeOutBack),
    );

    _pointsCountAnimation =
        IntTween(begin: 0, end: widget.celebrationData.pointsEarned).animate(
          CurvedAnimation(parent: _pointsController, curve: Curves.easeOut),
        );

    // Start celebration sequence
    _startCelebrationSequence();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _statsController.dispose();
    _achievementController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _startCelebrationSequence() async {
    // Start confetti immediately
    _confettiController.play();

    // Stagger animations for dramatic effect
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _statsController.forward();

    await Future<void>.delayed(const Duration(milliseconds: 800));
    _pointsController.forward();

    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _achievementController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient background
          _buildGradientBackground(),

          // Confetti animation
          _buildConfettiAnimation(),

          // Main content
          _buildMainContent(),

          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: widget.celebrationData.isSignificantAchievement
              ? [
                  Colors.purple.shade800,
                  Colors.purple.shade600,
                  Colors.pink.shade400,
                  Colors.orange.shade300,
                ]
              : [
                  Colors.blue.shade800,
                  Colors.blue.shade600,
                  Colors.teal.shade400,
                  Colors.green.shade300,
                ],
        ),
      ),
    );
  }

  Widget _buildConfettiAnimation() {
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _confettiController,
        blastDirection: 1.57, // Downward
        particleDrag: 0.05,
        emissionFrequency: 0.05,
        numberOfParticles: 50,
        gravity: 0.05,
        shouldLoop: false,
        colors: const [
          Colors.green,
          Colors.blue,
          Colors.pink,
          Colors.orange,
          Colors.purple,
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // Celebration header
            _buildCelebrationHeader(),

            const SizedBox(height: 40),

            // Walk stats
            _buildWalkStats(),

            const SizedBox(height: 30),

            // Points animation
            _buildPointsAnimation(),

            const SizedBox(height: 30),

            // Achievements showcase
            if (widget.celebrationData.newAchievements.isNotEmpty)
              _buildAchievementsShowcase(),

            const Spacer(),

            // Photo gallery preview
            if (widget.celebrationData.visitedArtPhotos.isNotEmpty)
              _buildPhotoGalleryPreview(),
          ],
        ),
      ),
    );
  }

  Widget _buildCelebrationHeader() {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideUpAnimation.value),
          child: Opacity(
            opacity: _fadeInAnimation.value,
            child: Column(
              children: [
                // Celebration icon/animation
                if (widget.celebrationData.isSignificantAchievement)
                  SizedBox(
                    height: 120,
                    child: Lottie.asset(
                      'assets/animations/trophy_celebration.json',
                      repeat: false,
                    ),
                  )
                else
                  const Icon(Icons.celebration, size: 80, color: Colors.white),

                const SizedBox(height: 20),

                // Primary message
                Text(
                  widget.celebrationData.primaryMessage,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),

                // Walk title
                Text(
                  '"${widget.celebrationData.walk.title}"',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white70,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWalkStats() {
    return AnimatedBuilder(
      animation: _fadeInAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeInAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  widget.celebrationData.secondaryMessage,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Stats grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem(
                      icon: Icons.palette,
                      value: '${widget.celebrationData.artPiecesVisited}',
                      label: 'Art Pieces',
                    ),
                    _buildStatItem(
                      icon: Icons.timer,
                      value:
                          '${widget.celebrationData.walkDuration.inMinutes}m',
                      label: 'Duration',
                    ),
                    _buildStatItem(
                      icon: Icons.directions_walk,
                      value:
                          '${(widget.celebrationData.distanceWalked * 0.621371).toStringAsFixed(1)} mi',
                      label: 'Distance',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white70),
        ),
      ],
    );
  }

  Widget _buildPointsAnimation() {
    return AnimatedBuilder(
      animation: _pointsCountAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars, color: Colors.amber, size: 28),
              const SizedBox(width: 12),
              Text(
                '${_pointsCountAnimation.value} Points Earned!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsShowcase() {
    return AnimatedBuilder(
      animation: _achievementController,
      builder: (context, child) {
        return Transform.scale(
          scale: _achievementController.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(
                  'New Achievements Unlocked!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: widget.celebrationData.newAchievements
                      .take(3) // Show max 3 achievements
                      .map((achievement) => _buildAchievementBadge(achievement))
                      .toList(),
                ),

                if (widget.celebrationData.newAchievements.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '+${widget.celebrationData.newAchievements.length - 3} more',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAchievementBadge(AchievementModel achievement) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _getAchievementIcon(achievement.type),
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 6),
          Text(
            _getAchievementTitle(achievement.type),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoGalleryPreview() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.celebrationData.visitedArtPhotos.length.clamp(0, 5),
        itemBuilder: (context, index) {
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child:
                  ImageUrlValidator.safeCorrectedNetworkImage(
                        widget.celebrationData.visitedArtPhotos[index],
                      ) !=
                      null
                  ? Image(
                      image: ImageUrlValidator.safeCorrectedNetworkImage(
                        widget.celebrationData.visitedArtPhotos[index],
                      )!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.white.withValues(alpha: 0.1),
                          child: const Icon(Icons.image, color: Colors.white54),
                        );
                      },
                    )
                  : Container(
                      color: Colors.white.withValues(alpha: 0.1),
                      child: const Icon(Icons.image, color: Colors.white54),
                    ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Share button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _shareAchievement,
                icon: const Icon(Icons.share),
                label: Text(
                  'art_walk_art_walk_celebration_text_share_achievement'.tr(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Action buttons row
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/achievements'),
                    icon: const Icon(Icons.emoji_events),
                    label: Text(
                      'admin_admin_system_monitoring_text_view_all'.tr(),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/art-walk/map',
                      (route) => false,
                    ),
                    icon: const Icon(Icons.explore),
                    label: Text(
                      'art_walk_art_walk_celebration_text_explore_more'.tr(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareAchievement() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final socialService = SocialService();
      final distanceMiles = (widget.celebrationData.distanceWalked * 0.621371)
          .toStringAsFixed(1);

      final message =
          'Congratulations to ${user.displayName ?? 'this walker'} for completing "${widget.celebrationData.walk.title}"! '
          'They walked $distanceMiles miles and visited ${widget.celebrationData.artPiecesVisited} amazing art pieces. '
          'Great job exploring our community\'s public art! 🎨';

      await socialService.postActivity(
        userId: user.uid,
        userName: user.displayName ?? 'Anonymous Walker',
        userAvatar: user.photoURL,
        type: SocialActivityType.achievement,
        message: message,
        metadata: {
          'walkTitle': widget.celebrationData.walk.title,
          'artPiecesVisited': widget.celebrationData.artPiecesVisited,
          'distanceWalked': widget.celebrationData.distanceWalked,
          'pointsEarned': widget.celebrationData.pointsEarned,
          'walkDuration': widget.celebrationData.walkDuration.inMinutes,
          'photoUrl': widget.celebrationData.userPhotoUrl,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_celebration_text_achievement_posted_to'.tr(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_art_walk_celebration_error_failed_to_post'.tr(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _getAchievementIcon(AchievementType type) {
    switch (type) {
      case AchievementType.firstWalk:
        return '🎉';
      case AchievementType.walkMaster:
        return '🏆';
      case AchievementType.walkExplorer:
        return '🗺️';
      case AchievementType.artCollector:
        return '🎨';
      case AchievementType.socialButterfly:
        return '🦋';
      case AchievementType.earlyAdopter:
        return '⭐';
      default:
        return '🏅';
    }
  }

  String _getAchievementTitle(AchievementType type) {
    switch (type) {
      case AchievementType.firstWalk:
        return 'First Walk';
      case AchievementType.walkMaster:
        return 'Walk Master';
      case AchievementType.walkExplorer:
        return 'Explorer';
      case AchievementType.artCollector:
        return 'Art Collector';
      case AchievementType.socialButterfly:
        return 'Social';
      case AchievementType.earlyAdopter:
        return 'Early Adopter';
      default:
        return 'Achievement';
    }
  }
}
