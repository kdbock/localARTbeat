import 'package:intl/intl.dart' as intl;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/models/models.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class InProgressWalkCard extends StatelessWidget {
  final ArtWalkProgress progress;
  final VoidCallback onResume;
  final VoidCallback onPause;
  final VoidCallback onAbandon;
  final VoidCallback onTap;
  final String? walkTitle;

  const InProgressWalkCard({
    super.key,
    required this.progress,
    required this.onResume,
    required this.onPause,
    required this.onAbandon,
    required this.onTap,
    this.walkTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isPaused = progress.status == WalkStatus.paused;
    final statusColor = _statusColor(progress.status);
    final statusLabel = 'art_walk_progress_cards_status_${progress.status.name}'
        .tr();
    final primaryLabel = isPaused
        ? 'art_walk_progress_cards_button_resume'.tr()
        : 'art_walk_progress_cards_button_pause'.tr();
    final primaryIcon = isPaused ? Icons.play_arrow : Icons.pause;
    final piecesLabel = 'art_walk_progress_cards_text_pieces_progress'.tr(
      namedArgs: {
        'current': progress.visitedArt.length.toString(),
        'total': progress.totalArtCount.toString(),
      },
    );

    return _WalkCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(
            label: statusLabel,
            color: statusColor,
            timestamp: _formatLastActive(progress.lastActiveAt),
          ),
          const SizedBox(height: 12),
          Text(
            (walkTitle?.trim().isNotEmpty ?? false)
                ? walkTitle!
                : 'art_walk_progress_cards_text_default_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          _ProgressSection(
            label: piecesLabel,
            progress: progress.progressPercentage,
            accent: statusColor,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.timer,
                label: _formatDuration(progress.timeSpent),
              ),
              _InfoChip(
                icon: Icons.stars,
                label: 'art_walk_progress_cards_text_points'.tr(
                  namedArgs: {'points': progress.totalPointsEarned.toString()},
                ),
              ),
              if (progress.isStale)
                _InfoChip(
                  icon: Icons.warning_amber,
                  label: 'art_walk_progress_cards_text_stale'.tr(),
                  color: const Color(0xFFFFC857),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  label: primaryLabel,
                  icon: primaryIcon,
                  onPressed: isPaused ? onResume : onPause,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _OutlinedGlassButton(
                  label: 'art_walk_progress_cards_button_abandon'.tr(),
                  icon: Icons.delete_outline,
                  color: const Color(0xFFFF3D8D),
                  onPressed: onAbandon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CompletedWalkCard extends StatelessWidget {
  final ArtWalkProgress progress;
  final VoidCallback onTap;
  final VoidCallback onShare;
  final VoidCallback onReview;
  final String? walkTitle;

  const CompletedWalkCard({
    super.key,
    required this.progress,
    required this.onTap,
    required this.onShare,
    required this.onReview,
    this.walkTitle,
  });

  @override
  Widget build(BuildContext context) {
    final completionDate = progress.completedAt != null
        ? intl.DateFormat('MMM d, yyyy').format(progress.completedAt!)
        : '';

    return _WalkCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _HeaderRow(
            label: 'art_walk_progress_cards_status_completed'.tr(),
            color: const Color(0xFF34D399),
            timestamp: completionDate,
          ),
          const SizedBox(height: 12),
          Text(
            (walkTitle?.trim().isNotEmpty ?? false)
                ? walkTitle!
                : 'art_walk_progress_cards_text_default_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.palette,
                label: 'art_walk_progress_cards_text_artworks_count'.tr(
                  namedArgs: {'count': progress.visitedArt.length.toString()},
                ),
              ),
              _InfoChip(
                icon: Icons.timer,
                label: _formatDuration(progress.timeSpent),
              ),
              _InfoChip(
                icon: Icons.stars,
                label: 'art_walk_progress_cards_text_points'.tr(
                  namedArgs: {'points': progress.totalPointsEarned.toString()},
                ),
              ),
            ],
          ),
          if (progress.progressPercentage >= 1.0) ...[
            const SizedBox(height: 12),
            _InfoBanner(
              icon: Icons.auto_awesome,
              color: const Color(0xFFFFC857),
              label: 'art_walk_progress_cards_text_perfect_walk'.tr(),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _OutlinedGlassButton(
                  label: 'art_walk_progress_cards_button_share'.tr(),
                  icon: Icons.share,
                  color: const Color(0xFF22D3EE),
                  onPressed: onShare,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GradientCTAButton(
                  label: 'art_walk_progress_cards_button_review'.tr(),
                  icon: Icons.rate_review,
                  onPressed: onReview,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CreatedWalkCard extends StatelessWidget {
  final ArtWalkModel walk;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onShare;

  const CreatedWalkCard({
    super.key,
    required this.walk,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final visibilityLabel = walk.isPublic
        ? 'art_walk_art_walk_card_chip_public'.tr()
        : 'art_walk_art_walk_card_chip_private'.tr();

    return _WalkCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _InfoChip(
                icon: walk.isPublic ? Icons.public : Icons.lock_outline,
                label: visibilityLabel,
                color: walk.isPublic
                    ? const Color(0xFF34D399)
                    : const Color(0xFFFFC857),
              ),
              const Spacer(),
              _GlassIconButton(
                icon: Icons.edit,
                tooltip: 'art_walk_progress_cards_text_edit'.tr(),
                onTap: onEdit,
              ),
              const SizedBox(width: 8),
              _GlassIconButton(
                icon: Icons.share,
                tooltip: 'art_walk_progress_cards_button_share'.tr(),
                onTap: onShare,
              ),
              const SizedBox(width: 8),
              _GlassIconButton(
                icon: Icons.delete_outline,
                tooltip: 'art_walk_button_delete'.tr(),
                onTap: onDelete,
                color: const Color(0xFFFF3D8D),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            walk.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (walk.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              walk.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.palette,
                label: 'art_walk_progress_cards_text_artworks_count'.tr(
                  namedArgs: {'count': walk.artworkIds.length.toString()},
                ),
              ),
              _InfoChip(
                icon: Icons.people,
                label: 'art_walk_progress_cards_text_views'.tr(
                  namedArgs: {'count': walk.viewCount.toString()},
                ),
              ),
              FutureBuilder<double>(
                future: getAverageRating(walk.id),
                builder: (context, snapshot) {
                  final label =
                      snapshot.connectionState == ConnectionState.waiting
                      ? 'art_walk_progress_cards_text_loading'.tr()
                      : 'art_walk_progress_cards_text_rating'.tr(
                          namedArgs: {
                            'rating': (snapshot.data ?? 0.0).toStringAsFixed(1),
                          },
                        );
                  return _InfoChip(icon: Icons.star, label: label);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'art_walk_progress_cards_text_created_on'.tr(
              namedArgs: {
                'date': intl.DateFormat('MMM d, yyyy').format(walk.createdAt),
              },
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class SavedWalkCard extends StatelessWidget {
  final ArtWalkModel walk;
  final VoidCallback onTap;
  final VoidCallback onUnsave;
  final VoidCallback onStart;

  const SavedWalkCard({
    super.key,
    required this.walk,
    required this.onTap,
    required this.onUnsave,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return _WalkCardShell(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bookmark, color: Color(0xFF22D3EE), size: 20),
              const SizedBox(width: 8),
              Text(
                'art_walk_progress_cards_text_saved_label'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _GlassIconButton(
                icon: Icons.bookmark_remove,
                tooltip: 'art_walk_progress_cards_button_remove_saved'.tr(),
                onTap: onUnsave,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            walk.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          if (walk.description.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              walk.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _InfoChip(
                icon: Icons.palette,
                label: 'art_walk_progress_cards_text_artworks_count'.tr(
                  namedArgs: {'count': walk.artworkIds.length.toString()},
                ),
              ),
              FutureBuilder<double>(
                future: getAverageRating(walk.id),
                builder: (context, snapshot) {
                  final label =
                      snapshot.connectionState == ConnectionState.waiting
                      ? 'art_walk_progress_cards_text_loading'.tr()
                      : 'art_walk_progress_cards_text_rating'.tr(
                          namedArgs: {
                            'rating': (snapshot.data ?? 0.0).toStringAsFixed(1),
                          },
                        );
                  return _InfoChip(icon: Icons.star, label: label);
                },
              ),
              _InfoChip(
                icon: Icons.access_time,
                label: 'art_walk_progress_cards_text_duration_minutes'.tr(
                  namedArgs: {
                    'minutes':
                        walk.estimatedDuration?.round().toString() ?? '30',
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GradientCTAButton(
            label: 'art_walk_progress_cards_button_start_walk'.tr(),
            icon: Icons.play_arrow,
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  final String label;
  final String timestamp;
  final Color color;

  const _HeaderRow({
    required this.label,
    required this.timestamp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(icon: Icons.circle, label: label, color: color),
        const Spacer(),
        if (timestamp.isNotEmpty)
          Text(
            timestamp,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
      ],
    );
  }
}

class _WalkCardShell extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;

  const _WalkCardShell({this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        button: onTap != null,
        child: GestureDetector(
          onTap: onTap,
          child: GlassCard(
            borderRadius: 28,
            padding: const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoBanner({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        color: color.withValues(alpha: 0.12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSection extends StatelessWidget {
  final String label;
  final double progress;
  final Color accent;

  const _ProgressSection({
    required this.label,
    required this.progress,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
      ],
    );
  }
}

class _OutlinedGlassButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;

  const _OutlinedGlassButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color.withValues(alpha: 0.5)),
            color: Colors.white.withValues(alpha: 0.03),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _GlassIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Colors.white;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tint.withValues(alpha: 0.3)),
            color: tint.withValues(alpha: 0.08),
          ),
          child: Icon(icon, size: 18, color: tint),
        ),
      ),
    );
  }
}

Color _statusColor(WalkStatus status) {
  switch (status) {
    case WalkStatus.inProgress:
      return const Color(0xFF22D3EE);
    case WalkStatus.paused:
      return const Color(0xFFFFC857);
    case WalkStatus.completed:
      return const Color(0xFF34D399);
    case WalkStatus.abandoned:
      return const Color(0xFFFF3D8D);
    case WalkStatus.notStarted:
      return const Color(0xFF94A3B8);
  }
}

String _formatLastActive(DateTime lastActive) {
  final now = DateTime.now();
  final difference = now.difference(lastActive);

  if (difference.inMinutes < 1) {
    return 'art_walk_progress_cards_time_just_now'.tr();
  } else if (difference.inHours < 1) {
    return 'art_walk_progress_cards_time_minutes_ago'.tr(
      namedArgs: {'count': difference.inMinutes.toString()},
    );
  } else if (difference.inDays < 1) {
    return 'art_walk_progress_cards_time_hours_ago'.tr(
      namedArgs: {'count': difference.inHours.toString()},
    );
  } else if (difference.inDays < 7) {
    return 'art_walk_progress_cards_time_days_ago'.tr(
      namedArgs: {'count': difference.inDays.toString()},
    );
  }

  return 'art_walk_progress_cards_time_date'.tr(
    namedArgs: {'date': intl.DateFormat('MMM d').format(lastActive)},
  );
}

String _formatDuration(Duration duration) {
  if (duration.inHours > 0) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    return 'art_walk_progress_cards_text_duration_hours_minutes'.tr(
      namedArgs: {'hours': hours.toString(), 'minutes': minutes.toString()},
    );
  }

  return 'art_walk_progress_cards_text_duration_minutes'.tr(
    namedArgs: {'minutes': duration.inMinutes.toString()},
  );
}

Future<double> getAverageRating(String walkId) async {
  try {
    final QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('walk_reviews')
        .where('walkId', isEqualTo: walkId)
        .get();

    if (snapshot.docs.isEmpty) {
      return 0.0;
    }

    double totalRating = 0.0;
    int count = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data.containsKey('rating') && data['rating'] is num) {
        totalRating += (data['rating'] as num).toDouble();
        count++;
      }
    }

    return count > 0 ? totalRating / count : 0.0;
  } catch (e) {
    AppLogger.error('Error getting average rating: $e');
    return 0.0;
  }
}
