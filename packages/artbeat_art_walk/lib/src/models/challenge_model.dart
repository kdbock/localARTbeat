import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Enum representing different types of challenges
enum ChallengeType { daily, weekly, monthly, special }

/// Model class for user challenges
class ChallengeModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ChallengeType type;
  final int targetCount;
  final int currentCount;
  final int rewardXP;
  final String rewardDescription;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;

  const ChallengeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.currentCount,
    required this.rewardXP,
    required this.rewardDescription,
    required this.isCompleted,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
  });

  /// Create ChallengeModel from Firestore document
  factory ChallengeModel.fromMap(Map<String, dynamic> map) {
    return ChallengeModel(
      id: FirestoreUtils.safeStringDefault(map['id']),
      userId: FirestoreUtils.safeStringDefault(map['userId']),
      title: FirestoreUtils.safeStringDefault(map['title']),
      description: FirestoreUtils.safeStringDefault(map['description']),
      type: ChallengeType.values.firstWhere(
        (e) =>
            e.toString() ==
            'ChallengeType.${FirestoreUtils.safeString(map['type'])}',
        orElse: () => ChallengeType.daily,
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
        DateTime.now().add(const Duration(days: 1)),
      ),
      completedAt: map['completedAt'] != null
          ? FirestoreUtils.safeDateTime(map['completedAt'])
          : null,
    );
  }

  /// Convert to map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
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
    };
  }

  /// Get progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetCount == 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }

  /// Check if challenge is expired
  bool get isExpired {
    return DateTime.now().isAfter(expiresAt);
  }

  /// Create a copy with updated fields
  ChallengeModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    ChallengeType? type,
    int? targetCount,
    int? currentCount,
    int? rewardXP,
    String? rewardDescription,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? completedAt,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      rewardXP: rewardXP ?? this.rewardXP,
      rewardDescription: rewardDescription ?? this.rewardDescription,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
