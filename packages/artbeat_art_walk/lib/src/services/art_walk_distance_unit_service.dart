import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArtWalkDistanceUnitService {
  ArtWalkDistanceUnitService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  String? _cachedDistanceUnit;

  Future<String> getDistanceUnit() async {
    if (_cachedDistanceUnit != null) {
      return _cachedDistanceUnit!;
    }

    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      _cachedDistanceUnit = 'miles';
      return _cachedDistanceUnit!;
    }

    final doc = await _firestore.collection('userSettings').doc(userId).get();
    if (!doc.exists) {
      _cachedDistanceUnit = 'miles';
      return _cachedDistanceUnit!;
    }

    final data = doc.data();
    final distanceUnit = data?['distanceUnit'] as String?;
    _cachedDistanceUnit = distanceUnit == 'kilometers' ? 'kilometers' : 'miles';
    return _cachedDistanceUnit!;
  }

  Future<void> setDistanceUnit(String unit) async {
    final normalized = unit == 'kilometers' ? 'kilometers' : 'miles';
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    await _firestore.collection('userSettings').doc(userId).set({
      'distanceUnit': normalized,
    }, SetOptions(merge: true));
    _cachedDistanceUnit = normalized;
  }

  String formatDistanceFromMeters(double meters, String unit) {
    if (unit == 'kilometers') {
      if (meters < 1000) return '${meters.round()} m';
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }

    final miles = meters / 1609.344;
    if (miles < 0.1) {
      final feet = meters * 3.28084;
      return '${feet.round()} ft';
    }
    return '${miles.toStringAsFixed(1)} mi';
  }

  String formatDistanceFromMiles(double miles, String unit) {
    if (unit == 'kilometers') {
      final km = miles * 1.609344;
      return '${km.toStringAsFixed(1)} km';
    }
    return '${miles.toStringAsFixed(1)} mi';
  }

  int estimateStepsFromMeters(double meters) {
    const double averageStepLengthMeters = 0.762;
    return (meters / averageStepLengthMeters).round();
  }
}
