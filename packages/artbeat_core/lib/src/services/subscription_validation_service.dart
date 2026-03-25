import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show SubscriptionTier;
import './subscription_plan_validator.dart';

/// Service to validate and handle subscription transitions
class SubscriptionValidationService {
  static final SubscriptionValidationService _instance =
      SubscriptionValidationService._internal();
  factory SubscriptionValidationService() => _instance;
  SubscriptionValidationService._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;
  final SubscriptionPlanValidator _planValidator = SubscriptionPlanValidator();

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
    _authInstance ??= FirebaseAuth.instance;
    _planValidator.initialize();
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  FirebaseAuth get _auth {
    initialize();
    return _authInstance!;
  }

  /// Get the current user's subscription tier
  Future<SubscriptionTier> getCurrentSubscriptionTier() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return SubscriptionTier.free;

    try {
      final doc = await _firestore
          .collection('subscriptions')
          .doc(userId)
          .get();

      final data = doc.data();
      if (!doc.exists || data == null || !data.containsKey('tier')) {
        return SubscriptionTier.free;
      }

      final tierStr = data['tier'] as String;
      return SubscriptionTier.fromLegacyName(tierStr);
    } catch (e) {
      return SubscriptionTier.free;
    }
  }

  /// Validate subscription change request
  Future<Map<String, dynamic>> validateSubscriptionChange(
    SubscriptionTier targetTier,
  ) async {
    try {
      final currentTier = await getCurrentSubscriptionTier();
      final canTransition = await _planValidator.canTransitionTo(
        currentTier,
        targetTier,
      );

      if (!canTransition) {
        final conflicts = await _getTransitionConflicts(
          currentTier,
          targetTier,
        );
        return {
          'isValid': false,
          'conflicts': conflicts,
          'message': _getConflictMessage(conflicts),
        };
      }

      return {
        'isValid': true,
        'conflicts': <String>[],
        'message': 'Transition is valid',
      };
    } catch (e) {
      return {
        'isValid': false,
        'conflicts': <String>[],
        'message': 'Error validating subscription change: $e',
      };
    }
  }

  /// Get conflicts that prevent subscription transition
  Future<List<String>> _getTransitionConflicts(
    SubscriptionTier currentTier,
    SubscriptionTier targetTier,
  ) async {
    final List<String> conflicts = [];
    final userId = _auth.currentUser?.uid;
    if (userId == null) return ['User not authenticated'];

    // Check for downgrade conflicts
    if (targetTier.index < currentTier.index) {
      // Gallery to Pro/Basic conflicts
      if (currentTier == SubscriptionTier.business) {
        final commissionSnapshot = await _firestore
            .collection('commissions')
            .where('galleryId', isEqualTo: userId)
            .where('status', whereIn: ['active', 'pending'])
            .limit(1)
            .get();

        if (commissionSnapshot.docs.isNotEmpty) {
          conflicts.add(
            'Active commissions must be completed or cancelled before downgrading',
          );
        }

        final artistsSnapshot = await _firestore
            .collection('galleryArtists')
            .where('galleryId', isEqualTo: userId)
            .limit(1)
            .get();

        if (artistsSnapshot.docs.isNotEmpty) {
          conflicts.add(
            'Remove managed artists before downgrading from Gallery plan',
          );
        }
      }

      // Pro to Basic conflicts
      if (currentTier == SubscriptionTier.creator &&
          (targetTier == SubscriptionTier.starter ||
              targetTier == SubscriptionTier.free)) {
        final artworkCount = await _firestore
            .collection('artwork')
            .where('artistId', isEqualTo: userId)
            .count()
            .get();

        if ((artworkCount.count ?? 0) > 5) {
          conflicts.add(
            'Remove excess artwork to downgrade to Basic plan (max 5 artworks)',
          );
        }
      }
    }

    return conflicts;
  }

  /// Get user-friendly message for conflicts
  String _getConflictMessage(List<String> conflicts) {
    if (conflicts.isEmpty) return 'No conflicts found';

    if (conflicts.length == 1) {
      return conflicts.first;
    }

    return 'Multiple conflicts found:\n${conflicts.map((c) => '• $c').join('\n')}';
  }

  /// Validate and preprocess tier change
  Future<Map<String, dynamic>> prepareTierChange(
    SubscriptionTier targetTier,
  ) async {
    final validation = await validateSubscriptionChange(targetTier);

    if ((validation['isValid'] as bool? ?? false) == false) {
      return validation;
    }

    try {
      final currentTier = await getCurrentSubscriptionTier();

      // Get price difference for prorated billing
      final proratedAmount = _calculateProratedAmount(currentTier, targetTier);

      return {
        'isValid': true,
        'proratedAmount': proratedAmount,
        'currentTier': currentTier,
        'targetTier': targetTier,
        'message': 'Ready to process tier change',
      };
    } catch (e) {
      return {'isValid': false, 'message': 'Error preparing tier change: $e'};
    }
  }

  /// Calculate prorated amount for tier change
  double _calculateProratedAmount(
    SubscriptionTier currentTier,
    SubscriptionTier targetTier,
  ) {
    // Get monthly prices
    final currentPrice = currentTier.monthlyPrice;
    final targetPrice = targetTier.monthlyPrice;

    // Simple prorated calculation (can be enhanced with actual billing period)
    return targetPrice - currentPrice;
  }
}
