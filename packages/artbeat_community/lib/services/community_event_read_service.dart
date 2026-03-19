import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CommunityEventReadService {
  final FirebaseFirestore _firestore;

  CommunityEventReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<EventModel>> getEventsByArtist(String artistId) async {
    if (artistId.isEmpty) return [];

    try {
      final snapshot = await _firestore
          .collection('events')
          .where('artistId', isEqualTo: artistId)
          .orderBy('dateTime')
          .get();

      return snapshot.docs.map(EventModel.fromFirestore).toList();
    } catch (e) {
      AppLogger.error('Error getting events by artist: $e');
      return [];
    }
  }
}
