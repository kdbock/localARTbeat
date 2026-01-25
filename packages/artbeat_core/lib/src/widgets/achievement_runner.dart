import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/artbeat_colors.dart';

/// A themed visual runner/progress bar for achievements with animations
class AchievementRunner extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final int currentLevel;
  final int experiencePoints;
  final String levelTitle;
  final bool showAnimations;
  final double height;
  final EdgeInsets margin;

  const AchievementRunner({
    super.key,
    required this.progress,
    required this.currentLevel,
    required this.experiencePoints,
    required this.levelTitle,
    this.showAnimations = true,
    this.height = 50.0,
    this.margin = const EdgeInsets.symmetric(vertical: 8.0),
  });

  @override
  State<AchievementRunner> createState() => _AchievementRunnerState();
}

class _AchievementRunnerState extends State<AchievementRunner>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;

  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();

    // Progress animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(begin: 0.0, end: widget.progress)
        .animate(
          CurvedAnimation(
            parent: _progressController,
            curve: Curves.easeOutCubic,
          ),
        );

    // Pulse animation for active progress
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sparkle animation for visual effects
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sparkleController, curve: Curves.linear),
    );

    if (widget.showAnimations) {
      _startAnimations();
    } else {
      _progressController.value = 1.0;
    }
  }

  void _startAnimations() {
    _progressController.forward();
    _pulseController.repeat(reverse: true);
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AchievementRunner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progress,
            end: widget.progress,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeOutCubic,
            ),
          );
      _progressController.reset();
      if (widget.showAnimations) {
        _progressController.forward();
      } else {
        _progressController.value = 1.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: Column(
        children: [
          // Level info row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: ArtbeatColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: ArtbeatColors.primaryPurple.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        '${'achievement_level_prefix'.tr()} ${widget.currentLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.levelTitle,
                        style: const TextStyle(
                          color: ArtbeatColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.experiencePoints} ${'achievement_xp_suffix'.tr()}',
                style: const TextStyle(
                  color: ArtbeatColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar container
          Container(
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(widget.height / 2),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(widget.height / 2),
              child: Stack(
                children: [
                  // Background pattern
                  _buildBackgroundPattern(),

                  // Progress bar
                  AnimatedBuilder(
                    animation: widget.showAnimations
                        ? _progressAnimation
                        : _progressController,
                    builder: (context, child) {
                      final progress = widget.showAnimations
                          ? _progressAnimation.value
                          : widget.progress;

                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scaleY: widget.showAnimations
                                  ? _pulseAnimation.value
                                  : 1.0,
                              child: Container(
                                height: widget.height,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      ArtbeatColors.primaryPurple,
                                      ArtbeatColors.primaryGreen,
                                      ArtbeatColors.secondaryTeal,
                                    ],
                                    stops: [0.0, 0.6, 1.0],
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    widget.height / 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ArtbeatColors.primaryPurple
                                          .withValues(alpha: 0.4),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Shine effect
                                    _buildShineEffect(),

                                    // Sparkle effects
                                    if (widget.showAnimations)
                                      _buildSparkleEffects(),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),

                  // Progress indicator dot
                  AnimatedBuilder(
                    animation: widget.showAnimations
                        ? _progressAnimation
                        : _progressController,
                    builder: (context, child) {
                      final progress = widget.showAnimations
                          ? _progressAnimation.value
                          : widget.progress;

                      return Positioned(
                        left:
                            (MediaQuery.of(context).size.width - 32) *
                                progress -
                            12,
                        top: widget.height / 2 - 12,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: widget.showAnimations
                                  ? _pulseAnimation.value
                                  : 1.0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: ArtbeatColors.primaryPurple,
                                    width: 3,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ArtbeatColors.primaryPurple
                                          .withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: ArtbeatColors.primaryPurple,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Next level info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${'achievement_next_level_prefix'.tr()}: ${_getNextLevelTitle(widget.currentLevel + 1)}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${_getXPForNextLevel(widget.currentLevel)} ${'achievement_xp_suffix'.tr()}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundPattern() {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[50]!, Colors.grey[100]!],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }

  Widget _buildShineEffect() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.3),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: [
                (_sparkleAnimation.value - 0.3).clamp(0.0, 1.0),
                _sparkleAnimation.value.clamp(0.0, 1.0),
                (_sparkleAnimation.value + 0.3).clamp(0.0, 1.0),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(widget.height / 2),
          ),
        );
      },
    );
  }

  Widget _buildSparkleEffects() {
    return AnimatedBuilder(
      animation: _sparkleAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Multiple sparkle positions
            for (int i = 0; i < 3; i++)
              Positioned(
                left:
                    (widget.height * 0.8) *
                    ((_sparkleAnimation.value + i * 0.33) % 1.0),
                top:
                    widget.height * 0.2 +
                    (widget.height * 0.6) *
                        (((_sparkleAnimation.value * 2 + i) % 1.0)),
                child: Transform.scale(
                  scale:
                      0.5 +
                      0.5 *
                          (1 -
                              ((_sparkleAnimation.value + i * 0.33) % 1.0)
                                  .abs()),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.5),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  String _getNextLevelTitle(int level) {
    final Map<int, String> levelTitles = {
      0: 'Art Explorer',
      1: 'Art Enthusiast',
      2: 'Art Collector',
      3: 'Art Connoisseur',
      4: 'Art Advocate',
      5: 'Art Ambassador',
      6: 'Art Curator',
      7: 'Art Patron',
      8: 'Art Master',
      9: 'Art Legend',
      10: 'Art Icon',
      11: 'Art Deity',
    };

    return levelTitles[level] ?? 'Art Master';
  }

  int _getXPForNextLevel(int currentLevel) {
    return (currentLevel + 1) * 100;
  }
}
