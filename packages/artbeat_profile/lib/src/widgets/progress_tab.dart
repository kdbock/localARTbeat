import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';

// Dummy level system for progress calculation
const Map<int, Map<String, dynamic>> _levelSystem = {
  1: {'minXP': 0, 'maxXP': 100, 'title': 'Beginner'},
  2: {'minXP': 101, 'maxXP': 300, 'title': 'Explorer'},
  3: {'minXP': 301, 'maxXP': 600, 'title': 'Artist'},
  4: {'minXP': 601, 'maxXP': 1000, 'title': 'Creator'},
  5: {'minXP': 1001, 'maxXP': 1500, 'title': 'Master'},
  // Add more levels as needed
};

/// Tab showing user's progress including challenges, goals, and streaks
class ProgressTab extends StatefulWidget {
  final String userId;

  const ProgressTab({super.key, required this.userId});

  @override
  State<ProgressTab> createState() => _ProgressTabState();
}

class _ProgressTabState extends State<ProgressTab> {
  final ChallengeService _challengeService = ChallengeService();

  ChallengeModel? _todaysChallenge;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgressData();
  }

  Future<void> _loadProgressData() async {
    setState(() => _isLoading = true);

    try {
      final challenge = await _challengeService.getTodaysChallenge();

      if (mounted) {
        setState(() {
          _todaysChallenge = challenge;
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading progress data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: ArtbeatColors.primaryPurple),
              SizedBox(width: 8),
              Text(
                'Your Progress',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Today's Challenge
          if (_todaysChallenge != null) ...[
            _buildTodaysChallenge(_todaysChallenge!),
            const SizedBox(height: 16),
          ],

          // Weekly Goals (placeholder for now)
          _buildWeeklyGoals(),
          const SizedBox(height: 16),

          // Streak Calendar
          _buildStreakCalendar(),
          const SizedBox(height: 16),

          // Level Progress
          _buildLevelProgress(),
        ],
      ),
    );
  }

  Widget _buildTodaysChallenge(ChallengeModel challenge) {
    final progress = challenge.targetCount > 0
        ? challenge.currentCount / challenge.targetCount
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
              ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.today, color: ArtbeatColors.primaryPurple),
                    SizedBox(width: 8),
                    Text(
                      'Today\'s Challenge',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                if (challenge.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: ArtbeatColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              challenge.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              challenge.description,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${challenge.currentCount}/${challenge.targetCount}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          Text(
                            '${(progress * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[300],
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            ArtbeatColors.primaryPurple,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: ArtbeatColors.accentYellow,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${challenge.rewardXP} XP',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: ArtbeatColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  _getTimeRemaining(challenge.expiresAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: ArtbeatColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyGoals() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_today, color: ArtbeatColors.primaryGreen),
                SizedBox(width: 8),
                Text(
                  'Weekly Goals',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildGoalItem('Complete 5 challenges', 3, 5),
            const SizedBox(height: 8),
            _buildGoalItem('Capture 10 artworks', 7, 10),
            const SizedBox(height: 8),
            _buildGoalItem('Visit 3 new locations', 1, 3),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalItem(String title, int current, int target) {
    final progress = current / target;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            Text(
              '$current/$target',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(
              ArtbeatColors.primaryGreen,
            ),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildStreakCalendar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Streak Calendar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildWeekCalendar(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekCalendar() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const completed = [true, true, true, true, true, false, false];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (index) {
        return Column(
          children: [
            Text(
              days[index],
              style: const TextStyle(
                fontSize: 12,
                color: ArtbeatColors.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: completed[index]
                    ? ArtbeatColors.primaryGreen
                    : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  completed[index] ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLevelProgress() {
    // This would use actual user data
    const currentLevel = 5;
    const currentXP = 1750;
    final levelInfo = _levelSystem[currentLevel]!;
    final nextLevelInfo = _levelSystem[currentLevel + 1];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.emoji_events, color: ArtbeatColors.accentYellow),
                SizedBox(width: 8),
                Text(
                  'Level Progress',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Level $currentLevel: ${levelInfo['title']}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ArtbeatColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            if (nextLevelInfo != null) ...[
              Text(
                'Next: ${nextLevelInfo['title']}',
                style: const TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$currentXP / ${nextLevelInfo['minXP']} XP',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeRemaining(DateTime expiresAt) {
    final now = DateTime.now();
    final difference = expiresAt.difference(now);

    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}m remaining';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m remaining';
    } else {
      return 'Expires soon';
    }
  }
}
