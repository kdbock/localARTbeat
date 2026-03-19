import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

class ProfileAchievementModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String description;
  final DateTime earnedAt;
  final bool isNew;

  const ProfileAchievementModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.earnedAt,
    required this.isNew,
  });

  factory ProfileAchievementModel.fromFirestoreMap(
    Map<String, dynamic> data, {
    String? id,
  }) {
    final type = FirestoreUtils.safeStringDefault(data['type']);
    return ProfileAchievementModel(
      id: id ?? FirestoreUtils.safeStringDefault(data['id']),
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      type: type,
      title: FirestoreUtils.safeStringDefault(
        data['title'],
        _defaultTitleForType(type),
      ),
      description: FirestoreUtils.safeStringDefault(
        data['description'],
        _defaultDescriptionForType(type),
      ),
      earnedAt: FirestoreUtils.safeDateTime(data['earnedAt']),
      isNew: FirestoreUtils.safeBool(data['isNew'], false),
    );
  }

  static String _defaultTitleForType(String type) {
    switch (type) {
      case 'firstWalk':
        return 'First Steps';
      case 'walkExplorer':
        return 'Walk Explorer';
      case 'walkMaster':
        return 'Walk Master';
      case 'artCollector':
        return 'Art Collector';
      case 'artExpert':
        return 'Art Expert';
      case 'photographer':
        return 'Urban Photographer';
      case 'contributor':
        return 'Major Contributor';
      case 'commentator':
        return 'Art Commentator';
      case 'socialButterfly':
        return 'Social Butterfly';
      case 'curator':
        return 'Art Curator';
      case 'masterCurator':
        return 'Master Curator';
      case 'marathonWalker':
        return 'Marathon Walker';
      case 'earlyAdopter':
        return 'Early Adopter';
      default:
        return 'Achievement';
    }
  }

  static String _defaultDescriptionForType(String type) {
    switch (type) {
      case 'firstWalk':
        return 'Completed your first art walk. Welcome to the community!';
      case 'walkExplorer':
        return 'Completed 5 different art walks. You are getting to know the scene.';
      case 'walkMaster':
        return 'Completed 20 different art walks. You are a dedicated art explorer.';
      case 'artCollector':
        return 'Viewed 10 different art pieces. Building your mental art collection.';
      case 'artExpert':
        return 'Viewed 50 different art pieces. You are becoming an art expert.';
      case 'photographer':
        return 'Added 5 new public art pieces. Thanks for contributing.';
      case 'contributor':
        return 'Added 20 new public art pieces. The community appreciates your contributions.';
      case 'commentator':
        return 'Left 10 comments on art walks. Your feedback helps others.';
      case 'socialButterfly':
        return 'Shared 5 art walks. Spreading the love for art.';
      case 'curator':
        return 'Created 3 art walks. You are becoming a curator.';
      case 'masterCurator':
        return 'Created 10 art walks. You are a master curator.';
      case 'marathonWalker':
        return 'Completed a walk of at least 5km. That is dedication.';
      case 'earlyAdopter':
        return 'Joined during the app s first month. Thanks for being an early supporter.';
      default:
        return 'Unlocked a new achievement.';
    }
  }
}
