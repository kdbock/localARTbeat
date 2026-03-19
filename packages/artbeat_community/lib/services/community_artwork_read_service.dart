import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artwork_model.dart';

class CommunityArtworkReadService {
  final FirebaseFirestore _firestore;

  CommunityArtworkReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<ArtworkModel>> getArtworkByArtistProfileId(
    String artistProfileId,
  ) async {
    if (artistProfileId.isEmpty) return [];

    final snapshot = await _firestore
        .collection('artwork')
        .where('artistProfileId', isEqualTo: artistProfileId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ArtworkModel.fromFirestore(doc, null))
        .toList();
  }
}
