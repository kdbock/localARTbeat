import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/social_activity_model.dart';
import '../utils/logger.dart';

class SocialActivityReadService {
  FirebaseFirestore? _firestoreInstance;

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  CollectionReference get _activities =>
      _firestore.collection('socialActivities');

  Future<List<SocialActivityModel>> getNearbyActivities({
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
          .map((doc) => SocialActivityModel.fromFirestore(doc))
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

      AppLogger.debug('Loaded ${activities.length} nearby activities');
      return activities;
    } catch (e) {
      AppLogger.error('Error loading nearby activities: $e');
      return [];
    }
  }

  Future<List<SocialActivityModel>> getRecentActivities({
    int limit = 20,
  }) async {
    try {
      final snapshot = await _activities
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final activities = snapshot.docs
          .map((doc) {
            try {
              return SocialActivityModel.fromFirestore(doc);
            } catch (e) {
              AppLogger.error('Error parsing social activity ${doc.id}: $e');
              return null;
            }
          })
          .whereType<SocialActivityModel>()
          .toList();

      AppLogger.debug('Loaded ${activities.length} recent activities');
      return activities;
    } catch (e) {
      AppLogger.error('Error loading recent activities: $e');
      return [];
    }
  }
}
