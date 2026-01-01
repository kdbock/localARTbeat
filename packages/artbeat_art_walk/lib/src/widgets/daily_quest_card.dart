// lib/src/widgets/daily_quest_card.dart

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:artbeat_art_walk/src/models/challenge_model.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:artbeat_core/shared_widgets.dart';

class DailyQuestCard extends StatefulWidget {
  final ChallengeModel? challenge;
  final VoidCallback? onTap;
  final bool showTimeRemaining;
  final bool showRewardPreview;

  const DailyQuestCard({
    super.key,
    this.challenge,
    this.onTap,
    this.showTimeRemaining = true,
    this.showRewardPreview = true,
  });

  @override
  State<DailyQuestCard> createState() => _DailyQuestCardState();
}

class _DailyQuestCardState extends State<DailyQuestCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _showHelpOverlay = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challenge = widget.challenge;
    if (challenge == null) return _buildLoadingCard();

    final isCompleted = challenge.isCompleted;
    final progress = challenge.progressPercentage;

    return Stack(
      children: [
        GestureDetector(
          onTap: widget.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(challenge, isCompleted),
                  const SizedBox(height: 16),
                  Text(
                    challenge.description,
                    style: AppTypography.body(Colors.white),
                  ),
                  const SizedBox(height: 16),
                  if (!isCompleted)
                    _buildProgressSection(challenge, progress)
                  else
                    _buildCompletionSection(challenge),
                ],
              ),
            ),
          ),
        ),
        if (_showHelpOverlay) _buildHelpOverlay(challenge),
      ],
    );
  }

  Widget _buildHeader(ChallengeModel challenge, bool isCompleted) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _getQuestIcon(challenge.title),
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'daily_quest_label'.tr(),
                    style: AppTypography.badge(Colors.white70),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _showHelpOverlay = true),
                    child: const Icon(
                      Icons.help_outline,
                      color: Colors.white70,
                      size: 14,
                    ),
                  ),
                  if (isCompleted) ...[
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Text(challenge.title, style: AppTypography.screenTitle()),
            ],
          ),
        ),
        if (widget.showRewardPreview)
          ScaleTransition(
            scale: isCompleted
                ? _pulseAnimation
                : const AlwaysStoppedAnimation(1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.rewardXP}',
                    style: AppTypography.body(Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressSection(ChallengeModel challenge, double progress) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${challenge.currentCount}/${challenge.targetCount} ${_getProgressUnit(challenge.title)}',
              style: AppTypography.body(Colors.white),
            ),
            if (widget.showTimeRemaining)
              Row(
                children: [
                  const Icon(
                    Icons.access_time,
                    color: Colors.white70,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeRemaining(challenge.expiresAt),
                    style: AppTypography.helper(Colors.white70),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompletionSection(ChallengeModel challenge) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: Colors.amber, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'daily_quest_complete'.tr(),
                  style: AppTypography.body(Colors.white),
                ),
                Text(
                  challenge.rewardDescription,
                  style: AppTypography.helper(Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GlassCard(
        borderRadius: 24,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }

  Widget _buildHelpOverlay(ChallengeModel challenge) {
    final steps = _buildHelpSteps(challenge.title);

    return Positioned.fill(
      child: GestureDetector(
        onTap: () => setState(() => _showHelpOverlay = false),
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // prevent closing
              child: Container(
                padding: const EdgeInsets.all(20),
                margin: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          'daily_quest_how_to_complete'.tr(),
                          style: AppTypography.screenTitle(Colors.black87),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _showHelpOverlay = false),
                          child: const Icon(Icons.close, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: steps.asMap().entries.map((entry) {
                            final index = entry.key + 1;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFF7C4DFF,
                                      ).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: const Color(
                                          0xFF7C4DFF,
                                        ).withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '$index',
                                        style: AppTypography.body(
                                          const Color(0xFF7C4DFF),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value,
                                      style: AppTypography.body(Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
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

  List<String> _buildHelpSteps(String title) {
    final lower = title.toLowerCase();

    if (lower.contains('comment')) {
      return [
        'Open an artwork',
        'Go to comments',
        'Post a comment',
        'Repeat 3–5 times',
      ];
    } else if (lower.contains('discover')) {
      return ['Open map', 'Find artwork nearby', 'Mark as discovered'];
    }
    return [
      'Complete actions described in quest',
      'Check progress bar',
      'Earn your reward!',
    ];
  }

  IconData _getQuestIcon(String title) {
    if (title.contains('Photo')) return Icons.camera_alt;
    if (title.contains('Walk')) return Icons.directions_walk;
    if (title.contains('Step')) return Icons.directions_run;
    if (title.contains('Share')) return Icons.share;
    return Icons.flag;
  }

  String _getProgressUnit(String title) {
    if (title.contains('Walk')) return 'm';
    if (title.contains('Step')) return 'steps';
    return 'completed';
  }

  String _getTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final diff = expiresAt.difference(now);
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'soon';
  }
}
