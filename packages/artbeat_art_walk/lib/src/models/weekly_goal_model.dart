import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Enum representing different categories of weekly goals
enum WeeklyGoalCategory {
  exploration, // Discover art, explore neighborhoods
  photography, // Take photos, capture different styles
  social, // Share, comment, connect with community
  fitness, // Walking, steps, distance
  mastery, // Complete daily quests, maintain streaks
  collection, // Collect different art styles, artists
}

/// Model class for weekly goals (longer-term challenges)
class WeeklyGoalModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final WeeklyGoalCategory category;
  final int targetCount;
  final int currentCount;
  final int rewardXP;
  final String rewardDescription;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;
  final int weekNumber; // ISO week number
  final int year;
  final String? iconEmoji; // Optional emoji for visual representation
  final List<String> milestones; // Sub-goals or checkpoints

  const WeeklyGoalModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.category,
    required this.targetCount,
    required this.currentCount,
    required this.rewardXP,
    required this.rewardDescription,
    required this.isCompleted,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
    required this.weekNumber,
    required this.year,
    this.iconEmoji,
    this.milestones = const [],
  });

  /// Create WeeklyGoalModel from Firestore document
  factory WeeklyGoalModel.fromMap(Map<String, dynamic> map) {
    return WeeklyGoalModel(
      id: FirestoreUtils.safeStringDefault(map['id']),
      userId: FirestoreUtils.safeStringDefault(map['userId']),
      title: FirestoreUtils.safeStringDefault(map['title']),
      description: FirestoreUtils.safeStringDefault(map['description']),
      category: WeeklyGoalCategory.values.firstWhere(
        (e) =>
            e.toString() ==
            'WeeklyGoalCategory.${FirestoreUtils.safeString(map['category'])}',
        orElse: () => WeeklyGoalCategory.exploration,
      ),
      targetCount: FirestoreUtils.safeInt(map['targetCount']),
      currentCount: FirestoreUtils.safeInt(map['currentCount']),
      rewardXP: FirestoreUtils.safeInt(map['rewardXP']),
      rewardDescription: FirestoreUtils.safeStringDefault(
        map['rewardDescription'],
      ),
      isCompleted: FirestoreUtils.safeBool(map['isCompleted'], false),
      createdAt: FirestoreUtils.safeDateTime(map['createdAt']),
      expiresAt: FirestoreUtils.safeDateTime(
        map['expiresAt'],
        DateTime.now().add(const Duration(days: 7)),
      ),
      completedAt: map['completedAt'] != null
          ? FirestoreUtils.safeDateTime(map['completedAt'])
          : null,
      weekNumber: FirestoreUtils.safeInt(map['weekNumber'], 1),
      year: FirestoreUtils.safeInt(map['year'], DateTime.now().year),
      iconEmoji: FirestoreUtils.safeString(map['iconEmoji']),
      milestones:
          (map['milestones'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'category': category.toString().split('.').last,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'rewardXP': rewardXP,
      'rewardDescription': rewardDescription,
      'isCompleted': isCompleted,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'weekNumber': weekNumber,
      'year': year,
      'iconEmoji': iconEmoji,
      'milestones': milestones,
    };
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetCount == 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Check if goal is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inDays;
  }

  /// Get hours remaining
  int get hoursRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return 0;
    return expiresAt.difference(now).inHours;
  }

  /// Get current milestone index (which checkpoint user is on)
  int get currentMilestoneIndex {
    if (milestones.isEmpty) return 0;
    final progressPerMilestone = 1.0 / milestones.length;
    return (progressPercentage / progressPerMilestone).floor();
  }

  /// Get next milestone description
  String? get nextMilestone {
    if (milestones.isEmpty) return null;
    final nextIndex = currentMilestoneIndex;
    if (nextIndex >= milestones.length) return null;
    return milestones[nextIndex];
  }

  /// Create a copy with updated fields
  WeeklyGoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    WeeklyGoalCategory? category,
    int? targetCount,
    int? currentCount,
    int? rewardXP,
    String? rewardDescription,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
    int? weekNumber,
    int? year,
    String? iconEmoji,
    List<String>? milestones,
  }) {
    return WeeklyGoalModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      rewardXP: rewardXP ?? this.rewardXP,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
      weekNumber: weekNumber ?? this.weekNumber,
      year: year ?? this.year,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      milestones: milestones ?? this.milestones,
    );
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case WeeklyGoalCategory.exploration:
        return 'Exploration';
      case WeeklyGoalCategory.photography:
        return 'Photography';
      case WeeklyGoalCategory.social:
        return 'Social';
      case WeeklyGoalCategory.fitness:
        return 'Fitness';
      case WeeklyGoalCategory.mastery:
        return 'Mastery';
      case WeeklyGoalCategory.collection:
        return 'Collection';
    }
  }

  /// Get category color
  String get categoryColorHex {
    switch (category) {
      case WeeklyGoalCategory.exploration:
        return '#6C63FF'; // Purple
      case WeeklyGoalCategory.photography:
        return '#4ECDC4'; // Teal
      case WeeklyGoalCategory.social:
        return '#FF6B6B'; // Red
      case WeeklyGoalCategory.fitness:
        return '#95E1D3'; // Green
      case WeeklyGoalCategory.mastery:
        return '#FFD93D'; // Yellow
      case WeeklyGoalCategory.collection:
        return '#F38181'; // Pink
    }
  }
}
