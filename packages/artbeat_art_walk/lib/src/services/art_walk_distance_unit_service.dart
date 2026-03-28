import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArtWalkDistanceUnitService {
  ArtWalkDistanceUnitService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> getDistanceUnit() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 'miles';

    final doc = await _firestore.collection('userSettings').doc(userId).get();
    if (!doc.exists) return 'miles';

    final data = doc.data();
    final distanceUnit = data?['distanceUnit'] as String?;
    if (distanceUnit == 'kilometers') return 'kilometers';
    return 'miles';
  }
}
