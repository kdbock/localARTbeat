import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_utils.dart';

class ChapterQuest {
  final String id;
  final String? chapterId;
  final String title;
  final String description;
  final int xpReward;
  final String badgeIcon;
  final List<String> locationRequirements;
  final String? sponsorLink;

  ChapterQuest({
    required this.id,
    this.chapterId,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.badgeIcon,
    required this.locationRequirements,
    this.sponsorLink,
  });

  factory ChapterQuest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChapterQuest(
      id: doc.id,
      chapterId: FirestoreUtils.getOptionalString(data, 'chapter_id'),
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      xpReward: FirestoreUtils.safeInt(data['xp_reward']),
      badgeIcon: FirestoreUtils.safeStringDefault(data['badge_icon']),
      locationRequirements: FirestoreUtils.getStringList(
        data,
        'location_requirements',
      ),
      sponsorLink: FirestoreUtils.getOptionalString(data, 'sponsor_link'),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (chapterId != null) 'chapter_id': chapterId,
      'title': title,
      'description': description,
      'xp_reward': xpReward,
      'badge_icon': badgeIcon,
      'location_requirements': locationRequirements,
      if (sponsorLink != null) 'sponsor_link': sponsorLink,
    };
  }
}
