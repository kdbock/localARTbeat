import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/art_battle_match.dart';

class ArtBattleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Simple sponsor list (in production, this would come from a database)
  final List<String> _sponsors = [
    'ArtSupplyCo',
    'CanvasMasters',
    'PaintPro',
    'BrushStudio',
    'ColorPalette',
  ];

  // Get eligible artworks for battles
  Future<List<ArtworkModel>> getEligibleArtworks({
    String? region,
    String? medium,
    int limit = 100,
  }) async {
    Query query = _firestore
        .collection('artwork')
        .where('artBattleEnabled', isEqualTo: true)
        .where('artBattleStatus', isEqualTo: ArtBattleStatus.eligible.name)
        .orderBy('artBattleScore', descending: true)
        .limit(limit);

    if (region != null) {
      query = query.where('region', isEqualTo: region);
    }

    if (medium != null) {
      query = query.where('medium', isEqualTo: medium);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();
  }

  // Generate a battle matchup
  Future<ArtBattleMatch?> generateMatchup({
    String? userRegion,
    String? preferredMedium,
  }) async {
    // Get eligible artworks
    final artworks = await getEligibleArtworks(
      region: userRegion,
      medium: preferredMedium,
    );

    if (artworks.length < 2) {
      return null; // Not enough artworks
    }

    // Simple matchmaking: pick two random artworks
    artworks.shuffle();
    final artworkA = artworks[0];
    final artworkB = artworks[1];

    // Check if this should be a sponsored battle (every 5th battle)
    final isSponsored = await _shouldInjectSponsor();

    // Create match record
    final matchId = _firestore.collection('art_battles').doc().id;
    final match = ArtBattleMatch(
      id: matchId,
      artworkAId: artworkA.id,
      artworkBId: artworkB.id,
      winnerArtworkId: '', // To be filled after vote
      timestamp: DateTime.now(),
      region: userRegion ?? '',
      medium: preferredMedium ?? '',
      isSponsored: isSponsored,
      sponsorId: isSponsored ? _getRandomSponsor() : null,
    );

    // Save to Firestore
    await _firestore
        .collection('art_battles')
        .doc(matchId)
        .set(match.toFirestore());

    return match;
  }

  // Check if we should inject a sponsor (every 5th battle)
  Future<bool> _shouldInjectSponsor() async {
    // Count battles created today
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final battlesToday = await _firestore
        .collection('art_battles')
        .where(
          'timestamp',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
        )
        .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
        .get();

    // Inject sponsor every 5th battle
    return (battlesToday.docs.length + 1) % 5 == 0;
  }

  // Get a random sponsor
  String _getRandomSponsor() {
    _sponsors.shuffle();
    return _sponsors.first;
  }

  // Submit vote (via Cloud Function)
  Future<void> submitVote({
    required String matchId,
    required String chosenArtworkId,
    required String userId,
  }) async {
    // Call Cloud Function
    final functions = FirebaseFunctions.instance;
    final callable = functions.httpsCallable('submitArtBattleVote');

    try {
      await callable.call<Map<String, dynamic>>({
        'battleId': matchId,
        'artworkIdChosen': chosenArtworkId,
      });
    } catch (e) {
      throw Exception('Failed to submit vote: $e');
    }
  }
}
