import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../utils/logger.dart';

class ArtistFollowService {
  ArtistFollowService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<bool> followArtist(String artistId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || artistId.isEmpty) return false;

    try {
      await _firestore.collection('follows').doc('${currentUser.uid}_$artistId').set({
        'followerId': currentUser.uid,
        'followedId': artistId,
        'createdAt': FieldValue.serverTimestamp(),
        'type': 'artist',
      });

      await _updateArtistFollowerCounts(artistId, delta: 1);
      return true;
    } catch (error) {
      AppLogger.error('Error following artist: $error');
      return false;
    }
  }

  Future<bool> unfollowArtist(String artistId) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null || artistId.isEmpty) return false;

    try {
      await _firestore
          .collection('follows')
          .doc('${currentUser.uid}_$artistId')
          .delete();

      await _updateArtistFollowerCounts(artistId, delta: -1);
      return true;
    } catch (error) {
      AppLogger.error('Error unfollowing artist: $error');
      return false;
    }
  }

  Future<void> _updateArtistFollowerCounts(
    String artistId, {
    required int delta,
  }) async {
    final artistProfileQuery = await _firestore
        .collection('artistProfiles')
        .where('userId', isEqualTo: artistId)
        .limit(1)
        .get();

    for (final doc in artistProfileQuery.docs) {
      await doc.reference.update({
        'followersCount': FieldValue.increment(delta),
      });
    }
  }
}
