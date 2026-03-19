import '../utils/firestore_utils.dart';

enum DailyChallengeType { daily, weekly, monthly, special }

class DailyChallengeModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DailyChallengeType type;
  final int targetCount;
  final int currentCount;
  final int rewardXP;
  final String rewardDescription;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;

  const DailyChallengeModel({
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

  factory DailyChallengeModel.fromMap(Map<String, dynamic> map) {
    return DailyChallengeModel(
      id: FirestoreUtils.safeStringDefault(map['id']),
      userId: FirestoreUtils.safeStringDefault(map['userId']),
      title: FirestoreUtils.safeStringDefault(map['title']),
      description: FirestoreUtils.safeStringDefault(map['description']),
      type: DailyChallengeType.values.firstWhere(
        (e) =>
            e.toString() ==
            'DailyChallengeType.${FirestoreUtils.safeString(map['type'])}',
        orElse: () => DailyChallengeType.daily,
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

  double get progressPercentage {
    if (targetCount == 0) return 0.0;
    return (currentCount / targetCount).clamp(0.0, 1.0);
  }
}
