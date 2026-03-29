import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/artwork_model.dart';

class ArtworkLocalReadService {
  ArtworkLocalReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ArtworkModel>> watchLocalArtwork(String zipCode) {
    return _firestore
        .collection('artwork')
        .where('location', isEqualTo: zipCode)
        .orderBy('createdAt', descending: true)
        .limit(10)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ArtworkModel.fromFirestore).toList(),
        );
  }

  Future<Map<String, String>> fetchArtistNames(List<String> artistIds) async {
    if (artistIds.isEmpty) {
      return {};
    }

    final snapshot = await _firestore
        .collection('artistProfiles')
        .where(FieldPath.documentId, whereIn: artistIds)
        .get();

    return {
      for (final doc in snapshot.docs)
        doc.id: (doc.data()['displayName'] as String?) ?? 'Unknown Artist',
    };
  }
}
