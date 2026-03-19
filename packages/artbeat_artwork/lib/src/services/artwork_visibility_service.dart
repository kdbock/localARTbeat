import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

class ArtworkVisibilityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference get _artworkViewsCollection =>
      _firestore.collection('artworkViews');

  String? getCurrentUserId() => _auth.currentUser?.uid;

  Future<void> trackArtworkView({
    required String artworkId,
    required String artistId,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null || userId == artistId) {
      return;
    }

    try {
      final viewsSnapshot = await _artworkViewsCollection
          .where('artworkId', isEqualTo: artworkId)
          .where('viewerId', isEqualTo: userId)
          .where(
            'viewedAt',
            isGreaterThan: Timestamp.fromDate(
              DateTime.now().subtract(const Duration(hours: 24)),
            ),
          )
          .limit(1)
          .get();

      if (viewsSnapshot.docs.isEmpty) {
        await _artworkViewsCollection.add({
          'artworkId': artworkId,
          'artistId': artistId,
          'viewerId': userId,
          'viewedAt': FieldValue.serverTimestamp(),
        });

        await _firestore.collection('artwork').doc(artworkId).update({
          'viewCount': FieldValue.increment(1),
        });
      }
    } catch (e) {
      AppLogger.error('Error tracking artwork view: $e');
    }
  }
}
