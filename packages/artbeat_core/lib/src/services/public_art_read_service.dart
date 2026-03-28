import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

import '../models/public_art_model.dart';
import '../utils/logger.dart';

class PublicArtReadService {
  FirebaseFirestore? _firestoreInstance;

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  Future<List<PublicArtModel>> getPublicArtNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    int limit = 300,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('publicArt')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map(PublicArtModel.fromFirestore).where((art) {
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          art.location.latitude,
          art.location.longitude,
        );
        return distance <= radiusKm * 1000;
      }).toList();
    } catch (e) {
      AppLogger.error('Error loading nearby public art: $e');
      return [];
    }
  }

  Future<List<PublicArtModel>> getNearbyArt(
    Position userPosition, {
    double radiusMeters = 500,
    int limit = 300,
  }) {
    return getPublicArtNearLocation(
      latitude: userPosition.latitude,
      longitude: userPosition.longitude,
      radiusKm: radiusMeters / 1000,
      limit: limit,
    );
  }
}
