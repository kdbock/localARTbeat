import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../utils/logger.dart';

class EventReadService {
  EventReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<EventModel>> getUpcomingPublicEvents({
    int? limit,
    String? chapterId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('events')
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.now());

      if (chapterId != null) {
        query = query.where('chapterId', isEqualTo: chapterId);
      }

      query = query.orderBy('dateTime', descending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            try {
              return EventModel.fromFirestore(doc);
            } on Exception catch (error) {
              AppLogger.error('Error parsing event ${doc.id}: $error');
              return null;
            }
          })
          .whereType<EventModel>()
          .toList();
    } catch (error) {
      AppLogger.error('Error getting upcoming public events: $error');
      rethrow;
    }
  }
}
