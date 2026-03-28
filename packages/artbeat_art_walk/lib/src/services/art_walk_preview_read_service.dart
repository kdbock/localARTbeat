import 'package:cloud_firestore/cloud_firestore.dart';

class ArtWalkPreviewReadService {
  ArtWalkPreviewReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<Map<String, dynamic>>> watchPublicPreviewWalks({int limit = 3}) {
    try {
      return _firestore
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
                .toList(),
          );
    } catch (_) {
      return _firestore
          .collection('artWalks')
          .where('isPublic', isEqualTo: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) => snapshot.docs
                .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
                .toList(),
          );
    }
  }

  Future<double> getAverageRating(String walkId) async {
    try {
      final snapshot = await _firestore
          .collection('walk_reviews')
          .where('walkId', isEqualTo: walkId)
          .get();

      if (snapshot.docs.isEmpty) {
        return 0.0;
      }

      double totalRating = 0.0;
      int count = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('rating') && data['rating'] is num) {
          totalRating += (data['rating'] as num).toDouble();
          count++;
        }
      }

      return count > 0 ? totalRating / count : 0.0;
    } catch (_) {
      return 0.0;
    }
  }
}
