import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/challenge_model.dart';

/// Enhanced Daily Quest Card Widget
/// Displays the current daily challenge with progress, rewards, and time remaining
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
    if (widget.challenge == null) {
      return _buildLoadingCard();
    }

    final challenge = widget.challenge!;
    final isCompleted = challenge.isCompleted;
    final progressPercent = challenge.progressPercentage;

    return Stack(
      children: [
        _buildMainCard(challenge, isCompleted, progressPercent),
        if (_showHelpOverlay) _buildHelpOverlayWidget(challenge),
      ],
    );
  }

  Widget _buildMainCard(
    ChallengeModel challenge,
    bool isCompleted,
    double progressPercent,
  ) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCompleted
                ? [
                    ArtbeatColors.primaryGreen.withValues(alpha: 0.9),
                    ArtbeatColors.primaryGreen,
                  ]
                : [
                    ArtbeatColors.primaryPurple.withValues(alpha: 0.9),
                    ArtbeatColors.primaryBlue,
                  ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color:
                  (isCompleted
                          ? ArtbeatColors.primaryGreen
                          : ArtbeatColors.primaryPurple)
                      .withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: _QuestPatternPainter(isCompleted: isCompleted),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Row(
                    children: [
                      // Quest icon
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getQuestIcon(challenge.title),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Title and subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'daily_quest_label'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _showHelpOverlay = true;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.help_outline,
                                      color: Colors.white70,
                                      size: 12,
                                    ),
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
                            Text(
                              challenge.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // XP reward badge
                      if (widget.showRewardPreview)
                        ScaleTransition(
                          scale: isCompleted
                              ? _pulseAnimation
                              : const AlwaysStoppedAnimation(1.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.3),
                                width: 2,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.stars,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${challenge.rewardXP}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Description
                  Text(
                    challenge.description,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Progress section
                  if (!isCompleted) ...[
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              widthFactor: progressPercent,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.amber, Colors.orange],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amber.withValues(
                                        alpha: 0.5,
                                      ),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Progress text and time remaining
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${challenge.currentCount}/${challenge.targetCount} ${_getProgressUnit(challenge.title)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ] else ...[
                    // Completion message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.celebration,
                            color: Colors.amber,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'daily_quest_complete'.tr(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  challenge.rewardDescription,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpOverlayWidget(ChallengeModel challenge) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _showHelpOverlay = false;
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: GestureDetector(
              onTap: () {}, // Prevent closing when tapping content
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                constraints: const BoxConstraints(maxHeight: 500),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'daily_quest_how_to_complete'.tr(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showHelpOverlay = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _buildHelpSteps(challenge),
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

  Widget _buildLoadingCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  List<Widget> _buildHelpSteps(ChallengeModel challenge) {
    final steps = _getCompletionSteps(challenge.title);

    return steps.asMap().entries.map((entry) {
      final index = entry.key + 1;
      final step = entry.value;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ArtbeatColors.primaryPurple.withValues(alpha: 0.3),
                ),
              ),
              child: Center(
                child: Text(
                  '$index',
                  style: const TextStyle(
                    color: ArtbeatColors.primaryPurple,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  List<String> _getCompletionSteps(String title) {
    final lowerTitle = title.toLowerCase();

    // Comment-related quests
    if (lowerTitle.contains('comment')) {
      return [
        'Navigate to "Captures" or "Local Art" section',
        'Browse other users\' art discoveries',
        'Tap on an art piece to open details',
        'Scroll to the "Comments" section',
        'Type your comment and press send',
        'Repeat for ${title.contains('3')
            ? '3'
            : title.contains('5')
            ? '5'
            : '10'} different artworks',
      ];
    }

    // Discovery/Explorer quests
    if (lowerTitle.contains('discover') || lowerTitle.contains('explorer')) {
      return [
        'Open the "Art Walk" or "Radar" feature',
        'Check nearby art using location services',
        'Tap on artworks to view details',
        'Mark as discovered to log your find',
        'Complete the target number of discoveries',
      ];
    }

    // Photo/Capture quests
    if (lowerTitle.contains('photo') || lowerTitle.contains('hunter')) {
      return [
        'Tap the camera icon in the capture section',
        'Take a photo of public art you find',
        'Add title, artist, location details',
        'Choose art type and medium',
        'Review and confirm before posting',
      ];
    }

    // Walking quests
    if (lowerTitle.contains('walk') || lowerTitle.contains('step')) {
      return [
        'Enable location tracking in app settings',
        'Go on a walk or explore your neighborhood',
        'The app will track your steps automatically',
        'Keep app open or use background tracking',
        'Complete the distance/step goal',
      ];
    }

    // Sharing/Social quests
    if (lowerTitle.contains('share') || lowerTitle.contains('social')) {
      return [
        'Find an artwork or capture you like',
        'Tap the share button',
        'Choose where to share (Messages, Social)',
        'Send to friends or post on social media',
        'Complete the target number of shares',
      ];
    }

    // Like/Applause quests
    if (lowerTitle.contains('like') || lowerTitle.contains('applause')) {
      return [
        'Browse artworks or captures',
        'Tap the like/applause icon on items',
        'Each like counts toward your quest',
        'Like different artworks to complete',
        'Check progress on the quest card',
      ];
    }

    // Community/Mastery quests
    if (lowerTitle.contains('community') || lowerTitle.contains('master')) {
      return [
        'Participate in community activities',
        'Engage with other users\' content',
        'Complete daily or weekly challenges',
        'Build your reputation and streaks',
        'Reach quest completion milestone',
      ];
    }

    // Default fallback
    return [
      'Open the relevant app section',
      'Look for the activity described in the quest',
      'Engage with content as instructed',
      'Track your progress in real-time',
      'Complete to earn rewards',
    ];
  }

  IconData _getQuestIcon(String title) {
    if (title.contains('Explorer') || title.contains('Discover')) {
      return Icons.explore;
    } else if (title.contains('Photo') || title.contains('Hunter')) {
      return Icons.camera_alt;
    } else if (title.contains('Walk') || title.contains('Wanderer')) {
      return Icons.directions_walk;
    } else if (title.contains('Share') || title.contains('Social')) {
      return Icons.share;
    } else if (title.contains('Community') || title.contains('Connector')) {
      return Icons.people;
    } else if (title.contains('Step')) {
      return Icons.directions_run;
    } else if (title.contains('Early Bird')) {
      return Icons.wb_sunny;
    } else if (title.contains('Night Owl')) {
      return Icons.nightlight;
    } else if (title.contains('Golden Hour')) {
      return Icons.wb_twilight;
    } else if (title.contains('Critic')) {
      return Icons.rate_review;
    } else if (title.contains('Style')) {
      return Icons.palette;
    } else if (title.contains('Streak')) {
      return Icons.local_fire_department;
    } else if (title.contains('Neighborhood')) {
      return Icons.location_city;
    }
    return Icons.flag;
  }

  String _getProgressUnit(String title) {
    if (title.contains('Walk') && title.contains('km')) {
      return 'm';
    } else if (title.contains('Step')) {
      return 'steps';
    }
    return 'completed';
  }

  String _getTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m left';
    } else {
      return 'Expiring soon';
    }
  }
}

/// Custom painter for quest card background pattern
class _QuestPatternPainter extends CustomPainter {
  final bool isCompleted;

  _QuestPatternPainter({required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw decorative circles
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(size.width - 30 - (i * 40), 30 + (i * 20)),
        20 + (i * 10),
        paint,
      );
    }

    // Draw decorative lines
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.2,
      size.width * 0.6,
      size.height * 0.4,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
