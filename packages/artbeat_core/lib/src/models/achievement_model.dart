import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/firestore_utils.dart';

enum AchievementType {
  firstWalk,
  walkExplorer,
  walkMaster,
  artCollector,
  artExpert,
  photographer,
  contributor,
  commentator,
  socialButterfly,
  curator,
  masterCurator,
  marathonWalker,
  earlyAdopter,
}

@immutable
class AchievementModel {
  final String id;
  final String userId;
  final AchievementType type;
  final DateTime earnedAt;
  final bool isNew;
  final Map<String, dynamic> metadata;

  const AchievementModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.earnedAt,
    this.isNew = true,
    this.metadata = const {},
  });

  factory AchievementModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final typeName = FirestoreUtils.safeStringDefault(
      data['type'],
      'firstWalk',
    );
    final type = AchievementType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => AchievementType.firstWalk,
    );

    return AchievementModel(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      type: type,
      earnedAt: FirestoreUtils.safeDateTime(data['earnedAt']),
      isNew: FirestoreUtils.safeBool(data['isNew'], true),
      metadata: Map<String, dynamic>.from(data['metadata'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'earnedAt': FieldValue.serverTimestamp(),
      'isNew': isNew,
      'metadata': metadata,
    };
  }

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

  String get description {
    switch (type) {
      case AchievementType.firstWalk:
        return 'Completed your first art walk. Welcome to the community!';
      case AchievementType.walkExplorer:
        return 'Completed 5 different art walks. You are getting to know the scene!';
      case AchievementType.walkMaster:
        return 'Completed 20 different art walks. You are a dedicated art explorer!';
      case AchievementType.artCollector:
        return 'Viewed 10 different art pieces. Building your mental art collection!';
      case AchievementType.artExpert:
        return 'Viewed 50 different art pieces. You are becoming an art expert!';
      case AchievementType.photographer:
        return 'Added 5 new public art pieces. Thanks for contributing!';
      case AchievementType.contributor:
        return 'Added 20 new public art pieces. The community appreciates your contributions!';
      case AchievementType.commentator:
        return 'Left 10 comments on art walks. Your feedback helps others!';
      case AchievementType.socialButterfly:
        return 'Shared 5 art walks. Spreading the love for art!';
      case AchievementType.curator:
        return 'Created 3 art walks. You are becoming a curator!';
      case AchievementType.masterCurator:
        return 'Created 10 art walks. You are a master curator!';
      case AchievementType.marathonWalker:
        return 'Completed a walk of at least 5km. That is dedication!';
      case AchievementType.earlyAdopter:
        return 'Joined during the app\'s first month. Thanks for being an early supporter!';
    }
  }

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
}
