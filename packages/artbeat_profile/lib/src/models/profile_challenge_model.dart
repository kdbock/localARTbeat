import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

enum ProfileChallengeType { daily, weekly, monthly, special }

class ProfileChallengeModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final ProfileChallengeType type;
  final int targetCount;
  final int currentCount;
  final int rewardXp;
  final String rewardDescription;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime? completedAt;

  const ProfileChallengeModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.type,
    required this.targetCount,
    required this.currentCount,
    required this.rewardXp,
    required this.rewardDescription,
    required this.isCompleted,
    required this.createdAt,
    required this.expiresAt,
    this.completedAt,
  });

  factory ProfileChallengeModel.fromMap(Map<String, dynamic> map) {
    return ProfileChallengeModel(
      id: FirestoreUtils.safeStringDefault(map['id']),
      userId: FirestoreUtils.safeStringDefault(map['userId']),
      title: FirestoreUtils.safeStringDefault(map['title']),
      description: FirestoreUtils.safeStringDefault(map['description']),
      type: ProfileChallengeType.values.firstWhere(
        (value) => value.name == FirestoreUtils.safeStringDefault(map['type']),
        orElse: () => ProfileChallengeType.daily,
      ),
      targetCount: FirestoreUtils.safeInt(map['targetCount']),
      currentCount: FirestoreUtils.safeInt(map['currentCount']),
      rewardXp: FirestoreUtils.safeInt(map['rewardXP']),
      rewardDescription: FirestoreUtils.safeStringDefault(
        map['rewardDescription'],
      ),
      isCompleted: FirestoreUtils.safeBool(map['isCompleted'], false),
      createdAt: FirestoreUtils.safeDateTime(map['createdAt']),
      expiresAt: FirestoreUtils.safeDateTime(
        map['expiresAt'],
        DateTime.now().add(const Duration(days: 1)),
      ),
      completedAt: map['completedAt'] == null
          ? null
          : FirestoreUtils.safeDateTime(map['completedAt']),
    );
  }
}
