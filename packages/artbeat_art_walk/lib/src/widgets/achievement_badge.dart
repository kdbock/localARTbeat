import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ignore: unnecessary_import

class AchievementBadge extends StatelessWidget {
  final AchievementModel achievement;
  final bool showDetails;
  final VoidCallback? onTap;
  final bool isNew;
  final double size;

  const AchievementBadge({
    super.key,
    required this.achievement,
    this.showDetails = false,
    this.onTap,
    this.isNew = false,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _buildBadge(context);

    if (!showDetails) return badge;

    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          badge,
          const SizedBox(height: 12),
          Text(
            achievement.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (achievement.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          if (achievement.earnedAt.isAfter(
            DateTime.fromMillisecondsSinceEpoch(0),
          ))
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                DateFormat('MMM d, yyyy').format(achievement.earnedAt),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final colors = _getBadgeColors();
    final gradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );

    return Semantics(
      label: achievement.title,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.35),
                      blurRadius: 28,
                      offset: const Offset(0, 12),
                    ),
                    BoxShadow(
                      color: colors.last.withValues(alpha: 0.18),
                      blurRadius: 40,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _getIconData(),
                        size: size * 0.48,
                        color: Colors.white,
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (isNew) _buildNewIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Positioned _buildNewIndicator() {
    return Positioned(
      top: -4,
      right: -4,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF3D8D), Color(0xFF22D3EE)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFFF3D8D),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              'explore_new'.tr().toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Color> _getBadgeColors() {
    switch (achievement.type) {
      case AchievementType.firstWalk:
      case AchievementType.artCollector:
      case AchievementType.photographer:
      case AchievementType.commentator:
      case AchievementType.socialButterfly:
      case AchievementType.curator:
      case AchievementType.earlyAdopter:
        return const [Color(0xFFF59E0B), Color(0xFFB45309)];
      case AchievementType.walkExplorer:
      case AchievementType.artExpert:
      case AchievementType.marathonWalker:
        return const [Color(0xFFCBD5F5), Color(0xFF6B7280)];
      case AchievementType.walkMaster:
      case AchievementType.contributor:
      case AchievementType.masterCurator:
        return const [Color(0xFF7C4DFF), Color(0xFF22D3EE)];
    }
  }

  IconData _getIconData() {
    switch (achievement.iconName) {
      case 'directions_walk':
        return Icons.directions_walk;
      case 'explore':
        return Icons.explore;
      case 'emoji_events':
        return Icons.emoji_events;
      case 'collections':
        return Icons.collections;
      case 'auto_awesome':
        return Icons.auto_awesome;
      case 'add_a_photo':
        return Icons.add_a_photo;
      case 'volunteer_activism':
        return Icons.volunteer_activism;
      case 'comment':
        return Icons.comment;
      case 'share':
        return Icons.share;
      case 'palette':
        return Icons.palette;
      case 'star':
        return Icons.star;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'access_time':
        return Icons.access_time;
      default:
        return Icons.emoji_events;
    }
  }
}
