import 'package:cloud_firestore/cloud_firestore.dart';

class ArtBattleMatch {
  final String id;
  final String artworkAId;
  final String artworkBId;
  final String winnerArtworkId;
  final DateTime timestamp;
  final String region;
  final String medium;
  final bool isSponsored;
  final String? sponsorId;

  ArtBattleMatch({
    required this.id,
    required this.artworkAId,
    required this.artworkBId,
    required this.winnerArtworkId,
    required this.timestamp,
    required this.region,
    required this.medium,
    this.isSponsored = false,
    this.sponsorId,
  });

  factory ArtBattleMatch.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ArtBattleMatch(
      id: doc.id,
      artworkAId: data['artworkAId'] as String? ?? '',
      artworkBId: data['artworkBId'] as String? ?? '',
      winnerArtworkId: data['winnerArtworkId'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      region: data['region'] as String? ?? '',
      medium: data['medium'] as String? ?? '',
      isSponsored: data['isSponsored'] as bool? ?? false,
      sponsorId: data['sponsorId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'artworkAId': artworkAId,
      'artworkBId': artworkBId,
      'winnerArtworkId': winnerArtworkId,
      'timestamp': Timestamp.fromDate(timestamp),
      'region': region,
      'medium': medium,
      'isSponsored': isSponsored,
      if (sponsorId != null) 'sponsorId': sponsorId,
    };
  }
}
