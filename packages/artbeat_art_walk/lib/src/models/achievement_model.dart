import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Achievement types for art walks
enum AchievementType {
  firstWalk, // Completed first art walk
  walkExplorer, // Completed 5 different art walks
  walkMaster, // Completed 20 different art walks
  artCollector, // Viewed 10 different art pieces
  artExpert, // Viewed 50 different art pieces
  photographer, // Added 5 new public art pieces
  contributor, // Added 20 new public art pieces
  commentator, // Left 10 comments on art walks
  socialButterfly, // Shared 5 art walks
  curator, // Created 3 art walks
  masterCurator, // Created 10 art walks
  marathonWalker, // Completed a walk of at least 5km
  earlyAdopter, // Joined in the first month of the app launch
}

/// Model class for user achievements
class AchievementModel {
  final String id;
  final String userId;
  final AchievementType type;
  final DateTime earnedAt;
  final bool isNew; // Whether the user has viewed this achievement yet
  final Map<String, dynamic> metadata; // Additional data about the achievement

  /// Constructor
  AchievementModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.earnedAt,
    this.isNew = true,
    this.metadata = const {},
  });

  /// Create an AchievementModel from Firestore document
  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Parse the achievement type
    final achievementTypeStr = FirestoreUtils.safeStringDefault(data['type'], 'firstWalk');
    final achievementType = AchievementType.values.firstWhere(
      (type) => type.name == achievementTypeStr,
      orElse: () => AchievementType.firstWalk,
    );

    return AchievementModel(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      type: achievementType,
      earnedAt: FirestoreUtils.safeDateTime(data['earnedAt']),
      isNew: FirestoreUtils.safeBool(data['isNew'], true),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  /// Convert to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'earnedAt': FieldValue.serverTimestamp(),
      'isNew': isNew,
      'metadata': metadata,
    };
  }

  /// Get the title of this achievement
  String get title {
    switch (type) {
      case AchievementType.firstWalk:
        return 'First Steps';
      case AchievementType.walkExplorer:
        return 'Walk Explorer';
      case AchievementType.walkMaster:
        return 'Walk Master';
      case AchievementType.artCollector:
        return 'Art Collector';
      case AchievementType.artExpert:
        return 'Art Expert';
      case AchievementType.photographer:
        return 'Urban Photographer';
      case AchievementType.contributor:
        return 'Major Contributor';
      case AchievementType.commentator:
        return 'Art Commentator';
      case AchievementType.socialButterfly:
        return 'Social Butterfly';
      case AchievementType.curator:
        return 'Art Curator';
      case AchievementType.masterCurator:
        return 'Master Curator';
      case AchievementType.marathonWalker:
        return 'Marathon Walker';
      case AchievementType.earlyAdopter:
        return 'Early Adopter';
    }
  }

  /// Get the description of this achievement
  String get description {
    switch (type) {
      case AchievementType.firstWalk:
        return 'Completed your first art walk. Welcome to the community!';
      case AchievementType.walkExplorer:
        return 'Completed 5 different art walks. You\'re getting to know the scene!';
      case AchievementType.walkMaster:
        return 'Completed 20 different art walks. You\'re a dedicated art explorer!';
      case AchievementType.artCollector:
        return 'Viewed 10 different art pieces. Building your mental art collection!';
      case AchievementType.artExpert:
        return 'Viewed 50 different art pieces. You\'re becoming an art expert!';
      case AchievementType.photographer:
        return 'Added 5 new public art pieces. Thanks for contributing!';
      case AchievementType.contributor:
        return 'Added 20 new public art pieces. The community appreciates your contributions!';
      case AchievementType.commentator:
        return 'Left 10 comments on art walks. Your feedback helps others!';
      case AchievementType.socialButterfly:
        return 'Shared 5 art walks. Spreading the love for art!';
      case AchievementType.curator:
        return 'Created 3 art walks. You\'re becoming a curator!';
      case AchievementType.masterCurator:
        return 'Created 10 art walks. You\'re a master curator!';
      case AchievementType.marathonWalker:
        return 'Completed a walk of at least 5km. That\'s dedication!';
      case AchievementType.earlyAdopter:
        return 'Joined during the app\'s first month. Thanks for being an early supporter!';
    }
  }

  /// Get the icon name for this achievement (for use with Icons class)
  String get iconName {
    switch (type) {
      case AchievementType.firstWalk:
        return 'directions_walk';
      case AchievementType.walkExplorer:
        return 'explore';
      case AchievementType.walkMaster:
        return 'emoji_events';
      case AchievementType.artCollector:
        return 'collections';
      case AchievementType.artExpert:
        return 'auto_awesome';
      case AchievementType.photographer:
        return 'add_a_photo';
      case AchievementType.contributor:
        return 'volunteer_activism';
      case AchievementType.commentator:
        return 'comment';
      case AchievementType.socialButterfly:
        return 'share';
      case AchievementType.curator:
        return 'palette';
      case AchievementType.masterCurator:
        return 'star';
      case AchievementType.marathonWalker:
        return 'fitness_center';
      case AchievementType.earlyAdopter:
        return 'access_time';
    }
  }

  /// Mark this achievement as viewed
  AchievementModel markAsViewed() {
    return AchievementModel(
      id: id,
      userId: userId,
      type: type,
      earnedAt: earnedAt,
      isNew: false,
      metadata: metadata,
    );
  }
}
