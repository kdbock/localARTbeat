import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/community_post_model.dart';
import '../utils/logger.dart';

class CommunityPostReadService {
  CommunityPostReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<CommunityPostModel>> getFeed({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => CommunityPostModel.fromFirestore(doc))
          .toList();
    } catch (error) {
      AppLogger.error('Error loading community posts: $error');
      rethrow;
    }
  }
}
