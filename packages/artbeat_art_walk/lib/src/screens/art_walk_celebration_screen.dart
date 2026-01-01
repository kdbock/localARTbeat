// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:confetti/confetti.dart';
import 'package:lottie/lottie.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, WorldBackground, HudTopBar, GradientCTAButton;
import 'package:artbeat_art_walk/src/models/models.dart';
import 'package:artbeat_art_walk/src/services/social_service.dart';
import 'package:artbeat_art_walk/src/widgets/widgets.dart';

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
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _achievementController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pointsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

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

  Future<void> _startCelebrationSequence() async {
    _confettiController.play();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _statsController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 800));
    _pointsController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    _achievementController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              _buildConfetti(),
              _buildCelebrationContent(),
              _buildBottomActions(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfetti() => Align(
    alignment: Alignment.topCenter,
    child: ConfettiWidget(
      confettiController: _confettiController,
      blastDirection: 1.57,
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

  Widget _buildCelebrationContent() => Column(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      const SizedBox(height: 32),
      _buildAnimatedHeader(),
      const SizedBox(height: 32),
      _buildStatsCard(),
      const SizedBox(height: 24),
      _buildPointsCard(),
      const SizedBox(height: 24),
      if (widget.celebrationData.newAchievements.isNotEmpty)
        _buildAchievementsCard(),
      const Spacer(),
      if (widget.celebrationData.visitedArtPhotos.isNotEmpty)
        _buildPhotoPreview(),
    ],
  );

  Widget _buildAnimatedHeader() => AnimatedBuilder(
    animation: _fadeInAnimation,
    builder: (context, child) => Opacity(
      opacity: _fadeInAnimation.value,
      child: Transform.translate(
        offset: Offset(0, _slideUpAnimation.value),
        child: Column(
          children: [
            if (widget.celebrationData.isSignificantAchievement)
              SizedBox(
                height: 120,
                child: Lottie.asset(
                  'assets/animations/trophy_celebration.json',
                  repeat: false,
                ),
              )
            else
              const Icon(Icons.celebration, color: Colors.white, size: 80),
            const SizedBox(height: 16),
            Text(
              widget.celebrationData.primaryMessage,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.celebrationData.walk.title}"',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildStatsCard() => AnimatedBuilder(
    animation: _fadeInAnimation,
    builder: (context, child) => Opacity(
      opacity: _fadeInAnimation.value,
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              widget.celebrationData.secondaryMessage,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statItem(
                  Icons.palette,
                  '${widget.celebrationData.artPiecesVisited}',
                  'art_walk_art_walk_celebration_label_art_pieces'.tr(),
                ),
                _statItem(
                  Icons.timer,
                  '${widget.celebrationData.walkDuration.inMinutes}m',
                  'art_walk_art_walk_celebration_label_duration'.tr(),
                ),
                _statItem(
                  Icons.directions_walk,
                  '${(widget.celebrationData.distanceWalked * 0.621371).toStringAsFixed(1)} mi',
                  'art_walk_art_walk_celebration_label_distance'.tr(),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );

  Widget _statItem(IconData icon, String value, String label) => Column(
    children: [
      Icon(icon, color: Colors.white, size: 24),
      const SizedBox(height: 8),
      Text(
        value,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      Text(
        label,
        style: GoogleFonts.spaceGrotesk(fontSize: 12, color: Colors.white70),
      ),
    ],
  );

  Widget _buildPointsCard() => AnimatedBuilder(
    animation: _pointsCountAnimation,
    builder: (context, child) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              red: 0,
              green: 0,
              blue: 0,
              alpha: (0.2 * 255),
            ),
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
            'art_walk_art_walk_celebration_text_points_earned'.tr(
              args: ['${_pointsCountAnimation.value}'],
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildAchievementsCard() => AnimatedBuilder(
    animation: _achievementController,
    builder: (context, child) => Transform.scale(
      scale: _achievementController.value,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'art_walk_art_walk_celebration_text_new_achievements_unlocked'
                  .tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.celebrationData.newAchievements
                  .take(3)
                  .map((a) => _achievementBadge(a))
                  .toList(),
            ),
            if (widget.celebrationData.newAchievements.length > 3)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'art_walk_art_walk_celebration_text_more_achievements'.tr(
                    args: [
                      '${widget.celebrationData.newAchievements.length - 3}',
                    ],
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );

  Widget _achievementBadge(AchievementModel achievement) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: Colors.white.withValues(
        red: 255.0,
        green: 255.0,
        blue: 255.0,
        alpha: (0.2 * 255),
      ),
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
          _getAchievementTitle(achievement.type).tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildPhotoPreview() => SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: widget.celebrationData.visitedArtPhotos.length.clamp(0, 5),
      itemBuilder: (context, index) => Container(
        width: 80,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(
              red: 255.0,
              green: 255.0,
              blue: 255.0,
              alpha: (0.3 * 255),
            ),
          ),
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
                )
              : Container(
                  color: Colors.white.withValues(
                    red: 255.0,
                    green: 255.0,
                    blue: 255.0,
                    alpha: (0.1 * 255),
                  ),
                  child: const Icon(Icons.image, color: Colors.white54),
                ),
        ),
      ),
    ),
  );

  Widget _buildBottomActions() => Positioned(
    bottom: 0,
    left: 0,
    right: 0,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GradientCTAButton(
            label: 'art_walk_art_walk_celebration_text_share_achievement'.tr(),
            onPressed: _shareAchievement,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: GlassSecondaryButton(
                  icon: Icons.emoji_events,
                  label: 'admin_admin_system_monitoring_text_view_all'.tr(),
                  onTap: () => Navigator.pushNamed(context, '/achievements'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GlassSecondaryButton(
                  icon: Icons.explore,
                  label: 'art_walk_art_walk_celebration_text_explore_more'.tr(),
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/art-walk/map',
                    (route) => false,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  void _shareAchievement() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');
      final socialService = context.read<SocialService>();
      final distanceMiles = (widget.celebrationData.distanceWalked * 0.621371)
          .toStringAsFixed(1);
      final message =
          'Congratulations to ${user.displayName ?? 'this walker'} for completing "${widget.celebrationData.walk.title}"! '
          'They walked $distanceMiles miles and visited ${widget.celebrationData.artPiecesVisited} amazing art pieces. Great job exploring our community\'s public art! 🎨';

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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_celebration_text_achievement_posted_to'.tr(),
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'art_walk_art_walk_celebration_error_failed_to_post'.tr(),
          ),
          backgroundColor: Colors.red,
        ),
      );
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
        return 'art_walk_art_walk_celebration_badge_first_walk';
      case AchievementType.walkMaster:
        return 'art_walk_art_walk_celebration_badge_walk_master';
      case AchievementType.walkExplorer:
        return 'art_walk_art_walk_celebration_badge_explorer';
      case AchievementType.artCollector:
        return 'art_walk_art_walk_celebration_badge_art_collector';
      case AchievementType.socialButterfly:
        return 'art_walk_art_walk_celebration_badge_social';
      case AchievementType.earlyAdopter:
        return 'art_walk_art_walk_celebration_badge_early_adopter';
      default:
        return 'art_walk_art_walk_celebration_badge_default';
    }
  }
}
