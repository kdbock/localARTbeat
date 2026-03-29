import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/artist_profile_model.dart';
import '../models/artwork_model.dart';

class StorePreviewReadService {
  StorePreviewReadService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  Stream<List<ArtworkModel>> watchAuctionPreviewArtworks({int limit = 5}) {
    return _firestore
        .collection('artwork')
        .where('isPublic', isEqualTo: true)
        .where('isAuction', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            return snapshot.docs.map(ArtworkModel.fromFirestore).toList();
          }

          final fallback = await _firestore
              .collection('artwork')
              .where('isPublic', isEqualTo: true)
              .where('auctionEnabled', isEqualTo: true)
              .limit(limit)
              .get();

          return fallback.docs.map(ArtworkModel.fromFirestore).toList();
        });
  }

  Stream<List<ArtworkModel>> watchSalePreviewArtworks({int limit = 5}) {
    return _firestore
        .collection('artwork')
        .where('isPublic', isEqualTo: true)
        .where('isForSale', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ArtworkModel.fromFirestore).toList(),
        );
  }

  Stream<List<ArtworkModel>> watchMarketArtworks({required bool isAuction}) {
    if (isAuction) {
      return _firestore
          .collection('artwork')
          .where('isPublic', isEqualTo: true)
          .where('auctionEnabled', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .snapshots()
          .asyncMap((snapshot) async {
            if (snapshot.docs.isNotEmpty) {
              return snapshot.docs.map(ArtworkModel.fromFirestore).toList();
            }

            final fallback = await _firestore
                .collection('artwork')
                .where('isPublic', isEqualTo: true)
                .where('isAuction', isEqualTo: true)
                .orderBy('createdAt', descending: true)
                .get();

            return fallback.docs.map(ArtworkModel.fromFirestore).toList();
          });
    }

    return _firestore
        .collection('artwork')
        .where('isPublic', isEqualTo: true)
        .where('isForSale', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ArtworkModel.fromFirestore).toList(),
        );
  }

  Stream<List<ArtistProfileModel>> watchKioskLaneArtists({int limit = 10}) {
    return _firestore
        .collection('artistProfiles')
        .where(
          'kioskLaneUntil',
          isGreaterThan: Timestamp.fromDate(DateTime.now()),
        )
        .orderBy('kioskLaneUntil', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(ArtistProfileModel.fromFirestore).toList(),
        );
  }

  Stream<List<Map<String, dynamic>>> watchFeaturedContent({int limit = 5}) {
    return _firestore
        .collection('featuredContent')
        .where('isActive', isEqualTo: true)
        .orderBy('publishedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList(),
        );
  }
}
