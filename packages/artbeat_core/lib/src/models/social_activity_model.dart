import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

enum SocialActivityType {
  discovery,
  capture,
  walkCompleted,
  achievement,
  friendJoined,
  milestone,
}

class SocialActivityModel {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final SocialActivityType type;
  final String message;
  final DateTime timestamp;
  final Position? location;
  final Map<String, dynamic>? metadata;

  const SocialActivityModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.type,
    required this.message,
    required this.timestamp,
    this.location,
    this.metadata,
  });

  factory SocialActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String? safeId(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is DocumentReference) return val.id;
      return val.toString();
    }

    return SocialActivityModel(
      id: doc.id,
      userId: safeId(data['userId']) ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userAvatar: data['userAvatar'] as String?,
      type: SocialActivityType.values.firstWhere(
        (e) => e.name == data['type'] as String?,
        orElse: () => SocialActivityType.discovery,
      ),
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] != null
          ? Position(
              latitude:
                  (data['location']['latitude'] as num?)?.toDouble() ?? 0.0,
              longitude:
                  (data['location']['longitude'] as num?)?.toDouble() ?? 0.0,
              timestamp: DateTime.now(),
              accuracy:
                  (data['location']['accuracy'] as num?)?.toDouble() ?? 0.0,
              altitude:
                  (data['location']['altitude'] as num?)?.toDouble() ?? 0.0,
              heading: (data['location']['heading'] as num?)?.toDouble() ?? 0.0,
              speed: (data['location']['speed'] as num?)?.toDouble() ?? 0.0,
              speedAccuracy:
                  (data['location']['speedAccuracy'] as num?)?.toDouble() ??
                  0.0,
              altitudeAccuracy:
                  (data['location']['altitudeAccuracy'] as num?)?.toDouble() ??
                  0.0,
              headingAccuracy:
                  (data['location']['headingAccuracy'] as num?)?.toDouble() ??
                  0.0,
            )
          : null,
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }
}
