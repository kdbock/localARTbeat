import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

enum CommunitySocialActivityType {
  discovery,
  capture,
  walkCompleted,
  achievement,
  friendJoined,
  milestone,
}

class CommunitySocialActivity {
  final String id;
  final String userId;
  final String userName;
  final String? userAvatar;
  final CommunitySocialActivityType type;
  final String message;
  final DateTime timestamp;
  final Position? location;
  final Map<String, dynamic>? metadata;

  CommunitySocialActivity({
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

  factory CommunitySocialActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String? safeId(dynamic val) {
      if (val == null) return null;
      if (val is String) return val;
      if (val is DocumentReference) return val.id;
      return val.toString();
    }

    return CommunitySocialActivity(
      id: doc.id,
      userId: safeId(data['userId']) ?? '',
      userName: data['userName'] as String? ?? 'Anonymous',
      userAvatar: data['userAvatar'] as String?,
      type: CommunitySocialActivityType.values.firstWhere(
        (e) => e.name == data['type'] as String?,
        orElse: () => CommunitySocialActivityType.discovery,
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

class CommunitySocialActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _activities =>
      _firestore.collection('socialActivities');

  Future<List<CommunitySocialActivity>> getNearbyActivities({
    required Position userPosition,
    double radiusKm = 5.0,
    int limit = 20,
  }) async {
    try {
      final lat = userPosition.latitude;
      final latDelta = radiusKm / 111.0;

      final query = _activities
          .orderBy('timestamp', descending: true)
          .limit(limit * 10);

      final snapshot = await query.get();
      final activities = snapshot.docs
          .map(CommunitySocialActivity.fromFirestore)
          .where((activity) {
            if (activity.location == null) return false;
            final activityLat = activity.location!.latitude;
            if (activityLat < lat - latDelta || activityLat > lat + latDelta) {
              return false;
            }

            final distance = Geolocator.distanceBetween(
              userPosition.latitude,
              userPosition.longitude,
              activity.location!.latitude,
              activity.location!.longitude,
            );
            return distance <= radiusKm * 1000;
          })
          .toList();

      AppLogger.debug(
        'Loaded ${activities.length} nearby community activities',
      );
      return activities;
    } catch (e) {
      AppLogger.error('Error loading nearby community activities: $e');
      return [];
    }
  }

  Future<List<CommunitySocialActivity>> getUserActivities({
    required String userId,
    int limit = 10,
  }) async {
    try {
      debugPrint(
        'CommunitySocialActivityService: getUserActivities for $userId limit=$limit',
      );

      final query = _activities
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit);

      final snapshot = await query.get();

      final activities = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['userId'] is! String && data['userId'] != null) {
          debugPrint(
            'CommunitySocialActivityService: non-string userId in ${doc.id}: ${data['userId'].runtimeType}',
          );
        }
        return CommunitySocialActivity.fromFirestore(doc);
      }).toList();

      AppLogger.debug('Loaded ${activities.length} user community activities');
      return activities;
    } catch (e) {
      AppLogger.error('Error loading user community activities: $e');

      if (e.toString().contains('ParseExpectedReferenceValue')) {
        AppLogger.warning(
          'CommunitySocialActivityService fallback: filtering recent activities in memory',
        );

        try {
          final snapshot = await _activities
              .orderBy('timestamp', descending: true)
              .limit(limit * 5)
              .get();

          final activities = snapshot.docs
              .map(CommunitySocialActivity.fromFirestore)
              .where((activity) => activity.userId == userId)
              .take(limit)
              .toList();

          AppLogger.info(
            'Fallback loaded ${activities.length} user community activities',
          );
          return activities;
        } catch (fallbackError) {
          AppLogger.error(
            'Error loading fallback user community activities: $fallbackError',
          );
        }
      }

      return [];
    }
  }

  Future<List<CommunitySocialActivity>> getActivitiesForUsers({
    required List<String> userIds,
    int limit = 20,
  }) async {
    if (userIds.isEmpty) return [];

    try {
      final uniqueIds = userIds.toSet().toList(growable: false);
      final chunks = <List<String>>[];
      for (var i = 0; i < uniqueIds.length; i += 10) {
        final end = (i + 10) > uniqueIds.length ? uniqueIds.length : i + 10;
        chunks.add(uniqueIds.sublist(i, end));
      }

      final merged = <CommunitySocialActivity>[];
      for (final chunk in chunks) {
        final snapshot = await _activities
            .where('userId', whereIn: chunk)
            .orderBy('timestamp', descending: true)
            .limit(limit)
            .get();

        merged.addAll(snapshot.docs.map(CommunitySocialActivity.fromFirestore));
      }

      merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      if (merged.length > limit) {
        return merged.take(limit).toList(growable: false);
      }
      return merged;
    } catch (e) {
      AppLogger.error('Error loading activities for users: $e');
      return [];
    }
  }

  Future<List<CommunitySocialActivity>> getRecentActivities({
    int limit = 20,
  }) async {
    try {
      final snapshot = await _activities
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map(CommunitySocialActivity.fromFirestore)
          .toList(growable: false);
    } catch (e) {
      AppLogger.error('Error loading recent community activities: $e');
      return [];
    }
  }
}
