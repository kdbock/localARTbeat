import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/artwork_model.dart';

class ArtistAuctionDashboardData {
  const ArtistAuctionDashboardData({
    required this.activeAuctions,
    required this.endedAuctions,
    required this.scheduledAuctions,
    required this.totalBids,
    required this.bidCounts,
  });

  final List<ArtworkModel> activeAuctions;
  final List<ArtworkModel> endedAuctions;
  final List<ArtworkModel> scheduledAuctions;
  final Map<String, double> totalBids;
  final Map<String, int> bidCounts;
}

class ArtistAuctionReadService {
  ArtistAuctionReadService({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<ArtistAuctionDashboardData> loadAuctionDashboard() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const ArtistAuctionDashboardData(
        activeAuctions: [],
        endedAuctions: [],
        scheduledAuctions: [],
        totalBids: {},
        bidCounts: {},
      );
    }

    final now = DateTime.now();
    final artworksSnapshot = await _firestore
        .collection('artworks')
        .where('userId', isEqualTo: userId)
        .where('auctionEnabled', isEqualTo: true)
        .get();

    final allAuctions = artworksSnapshot.docs
        .map((doc) => ArtworkModel.fromMap({'id': doc.id, ...doc.data()}))
        .toList();

    final active = <ArtworkModel>[];
    final ended = <ArtworkModel>[];
    final scheduled = <ArtworkModel>[];
    final totalBids = <String, double>{};
    final bidCounts = <String, int>{};

    for (final auction in allAuctions) {
      if (auction.auctionEnd == null) {
        scheduled.add(auction);
      } else if (auction.auctionEnd!.isAfter(now)) {
        active.add(auction);

        final bidsSnapshot = await _firestore
            .collection('artworks')
            .doc(auction.id)
            .collection('bids')
            .get();
        bidCounts[auction.id] = bidsSnapshot.docs.length;
        if (auction.currentHighestBid != null) {
          totalBids[auction.id] = auction.currentHighestBid!;
        }
      } else {
        ended.add(auction);
        if (auction.currentHighestBid != null) {
          totalBids[auction.id] = auction.currentHighestBid!;
        }
      }
    }

    active.sort((a, b) => a.auctionEnd!.compareTo(b.auctionEnd!));
    ended.sort((a, b) => b.auctionEnd!.compareTo(a.auctionEnd!));

    return ArtistAuctionDashboardData(
      activeAuctions: active,
      endedAuctions: ended,
      scheduledAuctions: scheduled,
      totalBids: totalBids,
      bidCounts: bidCounts,
    );
  }
}
