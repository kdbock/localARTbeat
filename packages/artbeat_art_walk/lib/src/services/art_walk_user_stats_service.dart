import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ArtWalkUserStatsService {
  ArtWalkUserStatsService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  String? get currentUserId => _auth.currentUser?.uid;
  User? get currentUser => _auth.currentUser;

  Future<Map<String, dynamic>> updateCurrentUserPersonalBests({
    required double distance,
    required Duration duration,
    required int artPieces,
  }) async {
    final userId = currentUserId;
    if (userId == null) return <String, dynamic>{};

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data() ?? <String, dynamic>{};
    final stats = data['artWalkStats'] as Map<String, dynamic>? ?? <String, dynamic>{};

    final bests = <String, dynamic>{};

    if (distance > ((stats['longestWalk'] as num?) ?? 0)) {
      bests['longestWalk'] = distance;
    }
    if (artPieces > ((stats['mostArtInOneWalk'] as num?) ?? 0)) {
      bests['mostArtInOneWalk'] = artPieces;
    }
    if (duration.inMinutes < ((stats['fastestWalk'] as num?) ?? 999999)) {
      bests['fastestWalk'] = duration.inMinutes;
    }

    if (bests.isNotEmpty) {
      await _firestore.collection('users').doc(userId).update({
        'artWalkStats': {...stats, ...bests},
      });
    }

    return bests;
  }

  Future<int> getCurrentUserTotalWalksCompleted() async {
    final userId = currentUserId;
    if (userId == null) return 0;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data() ?? <String, dynamic>{};
    final stats = data['stats'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return stats['walksCompleted'] as int? ?? 0;
  }

  Future<double> getCurrentUserTotalDistance() async {
    final userId = currentUserId;
    if (userId == null) return 0.0;

    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data() ?? <String, dynamic>{};
    final stats = data['artWalkStats'] as Map<String, dynamic>? ?? <String, dynamic>{};
    return (stats['totalDistance'] as num?)?.toDouble() ?? 0.0;
  }
}
