import 'package:artbeat_artwork/src/models/artwork_rating_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ArtworkRatingModel rating({required String id, required int stars}) {
    return ArtworkRatingModel(
      id: id,
      artworkId: 'art-1',
      userId: 'user-$id',
      userName: 'User $id',
      userAvatarUrl: '',
      rating: stars,
      createdAt: Timestamp.fromDate(DateTime(2026, 1, 1)),
      updatedAt: Timestamp.fromDate(DateTime(2026, 1, 1)),
    );
  }

  group('ArtworkRatingStats', () {
    test('empty returns zeroed stats', () {
      final stats = ArtworkRatingStats.empty();
      expect(stats.averageRating, 0.0);
      expect(stats.totalRatings, 0);
      expect(stats.ratingDistribution[5], 0);
    });

    test('fromRatings computes distribution and average', () {
      final stats = ArtworkRatingStats.fromRatings([
        rating(id: '1', stars: 5),
        rating(id: '2', stars: 4),
        rating(id: '3', stars: 5),
        rating(id: '4', stars: 1),
      ]);

      expect(stats.totalRatings, 4);
      expect(stats.averageRating, closeTo(3.75, 0.0001));
      expect(stats.fiveStarCount, 2);
      expect(stats.fourStarCount, 1);
      expect(stats.oneStarCount, 1);
    });
  });
}
