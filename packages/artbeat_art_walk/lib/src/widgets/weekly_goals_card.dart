import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_art_walk/src/models/weekly_goal_model.dart';
import 'package:artbeat_core/shared_widgets.dart';

class WeeklyGoalsCard extends StatefulWidget {
  final List<WeeklyGoalModel> goals;
  final VoidCallback? onTap;

  const WeeklyGoalsCard({required this.goals, this.onTap, super.key});

  @override
  State<WeeklyGoalsCard> createState() => _WeeklyGoalsCardState();
}

class _WeeklyGoalsCardState extends State<WeeklyGoalsCard> {
  bool _showHelpOverlay = false;

  @override
  Widget build(BuildContext context) {
    if (widget.goals.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: widget.onTap,
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 12),
                  ...widget.goals.map(_buildGoalItem).toList(),
                  const SizedBox(height: 16),
                  if (widget.onTap != null)
                    GradientCTAButton(
                      label: 'weekly_goals_view_all'.tr(),
                      icon: Icons.visibility,
                      onPressed: widget.onTap!,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (_showHelpOverlay) _buildHelpOverlay(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        _iconContainer(icon: Icons.calendar_today),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'weekly_goals_title'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _helpIcon(),
                ],
              ),
              Text(
                'weekly_goals_completed'.tr(
                  namedArgs: {
                    'count': _getCompletedCount().toString(),
                    'total': widget.goals.length.toString(),
                  },
                ),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (widget.onTap != null)
          _iconContainer(icon: Icons.arrow_forward_ios, size: 16),
      ],
    );
  }

  Widget _iconContainer({required IconData icon, double size = 24}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Colors.white, size: size),
    );
  }

  Widget _helpIcon() {
    return GestureDetector(
      onTap: () => setState(() => _showHelpOverlay = true),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.help_outline, color: Colors.white70, size: 14),
      ),
    );
  }

  Widget _buildGoalItem(WeeklyGoalModel goal) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _goalHeader(goal),
            const SizedBox(height: 12),
            _progressBar(goal),
            if (goal.milestones.isNotEmpty) ...[
              const SizedBox(height: 12),
              _milestones(goal),
            ],
            const SizedBox(height: 12),
            _rewardRow(goal),
          ],
        ),
      ),
    );
  }

  Widget _goalHeader(WeeklyGoalModel goal) {
    return Row(
      children: [
        if (goal.iconEmoji != null) _emojiContainer(goal.iconEmoji!),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal.title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                goal.categoryDisplayName,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        if (goal.isCompleted)
          _iconContainer(icon: Icons.check_circle, size: 20),
      ],
    );
  }

  Widget _emojiContainer(String emoji) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 20)),
    );
  }

  Widget _progressBar(WeeklyGoalModel goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${goal.currentCount} / ${goal.targetCount}',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${(goal.progressPercentage * 100).toInt()}%',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: goal.progressPercentage,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              goal.isCompleted ? const Color(0xFF34D399) : Colors.white,
            ),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  Widget _milestones(WeeklyGoalModel goal) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'weekly_goals_milestones'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...goal.milestones.asMap().entries.map((entry) {
          final index = entry.key;
          final milestone = entry.value;
          final isReached = index <= goal.currentMilestoneIndex;

          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isReached
                        ? const Color(0xFF34D399)
                        : Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: isReached
                          ? const Color(0xFF34D399)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: isReached
                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    milestone,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      color: Colors.white.withValues(
                        alpha: isReached ? 1.0 : 0.6,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _rewardRow(WeeklyGoalModel goal) {
    return Row(
      children: [
        const Icon(Icons.stars, color: Color(0xFFFFC857), size: 16),
        const SizedBox(width: 4),
        Text(
          '+${goal.rewardXP} XP',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(width: 16),
        const Icon(Icons.timer_outlined, size: 16, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          'weekly_goals_days_left'.tr(
            namedArgs: {'days': goal.daysRemaining.toString()},
          ),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildHelpOverlay() {
    // Keep this logic similar to yours, just apply typography + spacing cleanup if needed
    return const SizedBox.shrink(); // Replace with custom modal using same design guide
  }

  int _getCompletedCount() {
    return widget.goals.where((g) => g.isCompleted).length;
  }
}
