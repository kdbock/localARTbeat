import 'package:artbeat_artwork/src/models/artwork_model.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show ArtworkContentType, EngagementStats;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ArtworkModel buildArtwork() {
    return ArtworkModel(
      id: 'art-1',
      userId: 'user-1',
      artistProfileId: 'artist-1',
      title: 'Sunset',
      description: 'Warm tones',
      imageUrl: 'https://example.com/image.jpg',
      additionalImageUrls: const ['https://example.com/1.jpg'],
      styles: const ['Abstract'],
      medium: 'Oil',
      isForSale: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 2),
      moderationStatus: ArtworkModerationStatus.approved,
      contentType: ArtworkContentType.visual,
      engagementStats: EngagementStats(
        likeCount: 3,
        commentCount: 2,
        lastUpdated: DateTime(2026, 1, 2),
      ),
    );
  }

  group('ArtworkModerationStatus', () {
    test('fromString maps known values and defaults to pending', () {
      expect(
        ArtworkModerationStatus.fromString('approved'),
        ArtworkModerationStatus.approved,
      );
      expect(
        ArtworkModerationStatus.fromString('underReview'),
        ArtworkModerationStatus.underReview,
      );
      expect(
        ArtworkModerationStatus.fromString('unknown'),
        ArtworkModerationStatus.pending,
      );
    });
  });

  group('ArtworkModel', () {
    test('defensively wraps list fields as unmodifiable', () {
      final model = buildArtwork();
      expect(() => model.styles.add('New'), throwsUnsupportedError);
      expect(
        () => model.additionalImageUrls.add('https://example.com/new.jpg'),
        throwsUnsupportedError,
      );
    });

    test('toFirestore serializes key fields and timestamps', () {
      final model = buildArtwork();
      final map = model.toFirestore();

      expect(map['title'], 'Sunset');
      expect(map['moderationStatus'], 'approved');
      expect(map['contentType'], 'visual');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect(map['styles'], ['Abstract']);
    });

    test('copyWith updates mutable fields and preserves identity fields', () {
      final model = buildArtwork();
      final updated = model.copyWith(
        title: 'New Title',
        isForSale: false,
        moderationStatus: ArtworkModerationStatus.flagged,
      );

      expect(updated.id, 'art-1');
      expect(updated.userId, 'user-1');
      expect(updated.artistProfileId, 'artist-1');
      expect(updated.title, 'New Title');
      expect(updated.isForSale, isFalse);
      expect(updated.moderationStatus, ArtworkModerationStatus.flagged);
    });
  });
}
