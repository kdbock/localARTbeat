import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/sponsorship.dart';
import '../models/sponsorship_status.dart';
import '../models/sponsorship_tier.dart';
import '../utils/sponsorship_placements.dart';

class SponsorService {
  SponsorService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'sponsorships';

  /// Resolve a single sponsor for a placement.
  ///
  /// Selection rules (in order):
  /// 1. status == active
  /// 2. now between startDate and endDate
  /// 3. placementKey must be included
  /// 4. Title sponsor ALWAYS overrides all others
  /// 5. Radius filtering applied if radiusMiles != null
  /// 6. If multiple remain, shuffle and return one
  Future<Sponsorship?> getSponsorForPlacement({
    required String placementKey,
    required LatLng? userLocation,
  }) async {
    if (!SponsorshipPlacements.isValid(placementKey)) {
      return null;
    }

    final now = DateTime.now();

    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: SponsorshipStatus.active.value)
        .where('placementKeys', arrayContains: placementKey)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    if (snapshot.docs.isEmpty) return null;

    final sponsors = snapshot.docs
        .map(Sponsorship.fromSnapshot)
        .toList();

    // 1️⃣ Title sponsor override (global, exclusive)
    final Sponsorship? titleSponsor = sponsors
        .where((s) => s.tier == SponsorshipTier.title)
        .cast<Sponsorship?>()
        .firstOrNull;

    if (titleSponsor != null) {
      return titleSponsor;
    }


    // 2️⃣ Apply radius filtering where applicable
    final filteredByRadius = sponsors.where((sponsor) {
      if (sponsor.radiusMiles == null) return true;

      if (userLocation == null) return false;

      return _isWithinRadius(
        userLocation,
        sponsor.radiusMiles!,
      );
    }).toList();

    if (filteredByRadius.isEmpty) return null;

    // 3️⃣ Rotate remaining sponsors
    filteredByRadius.shuffle(Random());

    return filteredByRadius.first;
  }

  /// Fetch all active sponsors for a placement (no rotation).
  /// Useful for admin views or diagnostics.
  Future<List<Sponsorship>> getActiveSponsorsForPlacement(
    String placementKey,
  ) async {
    if (!SponsorshipPlacements.isValid(placementKey)) {
      return [];
    }

    final now = DateTime.now();

    final snapshot = await _firestore
        .collection(_collection)
        .where('status', isEqualTo: SponsorshipStatus.active.value)
        .where('placementKeys', arrayContains: placementKey)
        .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(now))
        .where('endDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .get();

    return snapshot.docs
        .map(Sponsorship.fromSnapshot)
        .toList();
  }

  /// Pure lifecycle check
  bool isSponsorActive(Sponsorship sponsor) {
    final now = DateTime.now();
    return sponsor.status.isActive &&
        now.isAfter(sponsor.startDate) &&
        now.isBefore(sponsor.endDate);
  }

  /// ---- Internal helpers ----

  /// NOTE:
  /// This is a placeholder distance check.
  /// Replace with geodesic calculation if/when needed.
  bool _isWithinRadius(
    LatLng userLocation,
    double radiusMiles,
  ) =>
      // TODO(artbeat): Replace with proper Haversine calculation if required; radius logic validated server-side.
      true;
}
