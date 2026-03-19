import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/artist_profile_model.dart';
import '../models/commission_artist_preview_model.dart';
import '../utils/logger.dart';

class CommissionArtistPreviewService {
  CommissionArtistPreviewService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Future<List<CommissionArtistPreviewModel>> getAvailableArtists() async {
    try {
      final snapshot = await _firestore
          .collection('artist_commission_settings')
          .where('acceptingCommissions', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => CommissionArtistPreviewModel.fromFirestore(doc))
          .toList();
    } catch (error) {
      AppLogger.error('Failed to get commission artists: $error');
      rethrow;
    }
  }

  Future<Map<String, String>> getArtistNames(Iterable<String> artistIds) async {
    final results = <String, String>{};

    for (final id in artistIds) {
      try {
        final profileQuery = await _firestore
            .collection('artistProfiles')
            .where('userId', isEqualTo: id)
            .limit(1)
            .get();
        if (profileQuery.docs.isNotEmpty) {
          final profile = ArtistProfileModel.fromFirestore(
            profileQuery.docs.first,
          );
          results[id] = profile.displayName;
        }
      } catch (error) {
        AppLogger.error('Failed to load commission artist name for $id: $error');
      }
    }

    return results;
  }
}
