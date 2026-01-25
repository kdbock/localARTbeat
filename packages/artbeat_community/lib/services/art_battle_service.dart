import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    // Prefer statuses that are actively eligible, but fall back to any enabled artwork
    const preferredStatuses = ['eligible', 'active', 'cooling_down'];

    Query baseQuery = _firestore
        .collection('artwork')
        .where('artBattleEnabled', isEqualTo: true);

    if (region != null) {
      baseQuery = baseQuery.where('region', isEqualTo: region);
    }

    if (medium != null) {
      baseQuery = baseQuery.where('medium', isEqualTo: medium);
    }

    // First attempt: only pull clearly eligible statuses from 'artwork'
    try {
      final snapshot = await baseQuery
          .where('artBattleStatus', whereIn: preferredStatuses)
          .orderBy('artBattleScore', descending: true)
          .limit(limit * 2)
          .get();

      final preferred = snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
      if (preferred.length >= 2) return preferred;
    } catch (_) {
      // If the filtered query fails (e.g., missing index), fall through to the broader pull.
    }

    // Fallback 1: any enabled artwork from 'artwork'
    try {
      final fallbackSnapshot = await baseQuery.limit(limit * 2).get();
      final results = fallbackSnapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .where(
            (artwork) => artwork.artBattleStatus != ArtBattleStatus.opted_out,
          )
          .toList();
      if (results.length >= 2) return results;
    } catch (_) {}

    // Fallback 2: check 'artworks' collection (legacy/analytics)
    try {
      final legacySnapshot = await _firestore
          .collection('artworks')
          .where('artBattleEnabled', isEqualTo: true)
          .limit(limit)
          .get();
      final legacyResults = legacySnapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();
      if (legacyResults.length >= 2) return legacyResults;
    } catch (_) {}

    return [];
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

    // Simple matchmaking with guardrails: pick two random artworks from different artists
    artworks.shuffle();
    ArtworkModel? artworkA;
    ArtworkModel? artworkB;

    for (int i = 0; i < artworks.length; i++) {
      for (int j = i + 1; j < artworks.length; j++) {
        if (artworks[i].artistId != artworks[j].artistId) {
          artworkA = artworks[i];
          artworkB = artworks[j];
          break;
        }
      }
      if (artworkA != null && artworkB != null) break;
    }

    if (artworkA == null || artworkB == null) {
      return null; // Not enough variety to form a match
    }

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
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Sign in to vote in Art Battles.');
    }

    final callable = FirebaseFunctions.instance.httpsCallable(
      'submitArtBattleVote',
    );

    try {
      debugPrint(
        '[ArtBattle] submitVote callable match=$matchId artwork=$chosenArtworkId user=$userId',
      );

      await callable.call<void>({
        'battleId': matchId,
        'artworkIdChosen': chosenArtworkId,
      });
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[ArtBattle] submitVote callable failed code=${e.code} message=${e.message}',
      );
      throw Exception(e.message ?? 'Failed to submit vote (${e.code})');
    } catch (e) {
      debugPrint('[ArtBattle] submitVote callable exception error=$e');
      throw Exception('Failed to submit vote: $e');
    }
  }
}
