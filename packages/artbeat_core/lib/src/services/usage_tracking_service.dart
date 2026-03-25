import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/subscription_tier.dart';
import '../models/feature_limits.dart';

/// Service for tracking and managing usage-based feature limits
/// Implements 2025 industry standards with soft limits and overage tracking
class UsageTrackingService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;
  final Logger _logger = Logger('UsageTrackingService');

  void initialize() {
    _firestoreInstance ??= FirebaseFirestore.instance;
    _authInstance ??= FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    initialize();
    return _firestoreInstance!;
  }

  FirebaseAuth get _auth {
    initialize();
    return _authInstance!;
  }

  /// Get current usage for a user
  Future<Map<String, int>> getCurrentUsage(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      // Reset usage if new month
      await _checkAndResetMonthlyUsage(userId, userData);

      return {
        'artworks': userData['artworksCount'] as int? ?? 0,
        'aiCredits': userData['aiCreditsUsed'] as int? ?? 0,
        'teamMembers': userData['teamMembersCount'] as int? ?? 1,
        'storageUsedMB': userData['storageUsedMB'] as int? ?? 0,
      };
    } catch (e) {
      _logger.severe('Error getting current usage', e);
      return {
        'artworks': 0,
        'aiCredits': 0,
        'teamMembers': 1,
        'storageUsedMB': 0,
      };
    }
  }

  /// Check if user can perform an action within their limits
  Future<bool> canPerformAction(String action, {String? userId}) async {
    try {
      userId ??= _auth.currentUser?.uid;
      if (userId == null) return false;

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final subscriptionTier = SubscriptionTier.fromLegacyName(
        (userData['subscriptionTier'] as String?) ?? 'free',
      );

      final limits = FeatureLimits.forTier(subscriptionTier);
      final usage = await getCurrentUsage(userId);

      switch (action) {
        case 'upload_artwork':
          return limits.hasUnlimitedArtworks ||
              usage['artworks']! < limits.artworks;

        case 'use_ai_credit':
          return limits.hasUnlimitedAICredits ||
              usage['aiCredits']! < limits.aiCredits;

        case 'add_team_member':
          return limits.hasUnlimitedTeamMembers ||
              usage['teamMembers']! < limits.teamMembers;

        default:
          return true;
      }
    } catch (e) {
      _logger.severe('Error checking action permission', e);
      return false;
    }
  }

  /// Track usage of a specific feature
  Future<void> trackUsage(
    String feature, {
    int amount = 1,
    String? userId,
  }) async {
    try {
      userId ??= _auth.currentUser?.uid;
      if (userId == null) return;

      final updates = <String, dynamic>{};

      switch (feature) {
        case 'artwork':
          updates['artworksCount'] = FieldValue.increment(amount);
          break;
        case 'ai_credit':
          updates['aiCreditsUsed'] = FieldValue.increment(amount);
          break;
        case 'team_member':
          updates['teamMembersCount'] = FieldValue.increment(amount);
          break;
        case 'storage':
          updates['storageUsedMB'] = FieldValue.increment(amount);
          break;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);

        // Track overage if user exceeds limits
        await _trackOverageIfNeeded(userId, feature, amount);
      }
    } catch (e) {
      _logger.severe('Error tracking usage', e);
    }
  }

  /// Get usage statistics with percentage and warnings
  Future<Map<String, dynamic>> getUsageStats(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final subscriptionTier = SubscriptionTier.fromLegacyName(
        (userData['subscriptionTier'] as String?) ?? 'free',
      );

      final limits = FeatureLimits.forTier(subscriptionTier);
      final usage = await getCurrentUsage(userId);

      return {
        'subscription': subscriptionTier.displayName,
        'artworks': {
          'used': usage['artworks'],
          'limit': limits.hasUnlimitedArtworks ? -1 : limits.artworks,
          'percentage': limits.getUsagePercentage(
            'artworks',
            usage['artworks']!,
          ),
          'approaching_limit': limits.isApproachingLimit(
            'artworks',
            usage['artworks']!,
          ),
          'unlimited': limits.hasUnlimitedArtworks,
        },
        'aiCredits': {
          'used': usage['aiCredits'],
          'limit': limits.hasUnlimitedAICredits ? -1 : limits.aiCredits,
          'percentage': limits.getUsagePercentage(
            'aiCredits',
            usage['aiCredits']!,
          ),
          'approaching_limit': limits.isApproachingLimit(
            'aiCredits',
            usage['aiCredits']!,
          ),
          'unlimited': limits.hasUnlimitedAICredits,
        },
        'teamMembers': {
          'used': usage['teamMembers'],
          'limit': limits.hasUnlimitedTeamMembers ? -1 : limits.teamMembers,
          'percentage': limits.getUsagePercentage(
            'teamMembers',
            usage['teamMembers']!,
          ),
          'approaching_limit': limits.isApproachingLimit(
            'teamMembers',
            usage['teamMembers']!,
          ),
          'unlimited': limits.hasUnlimitedTeamMembers,
        },
        'storage': {
          'used_mb': usage['storageUsedMB'],
          'used_gb': (usage['storageUsedMB']! / 1024).toStringAsFixed(2),
          'limit_gb': limits.hasUnlimitedStorage ? -1 : limits.storageGB,
          'unlimited': limits.hasUnlimitedStorage,
        },
      };
    } catch (e) {
      _logger.severe('Error getting usage stats', e);
      return {};
    }
  }

  /// Calculate current month's overage costs
  Future<double> calculateOverageCosts(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final subscriptionTier = SubscriptionTier.fromLegacyName(
        (userData['subscriptionTier'] as String?) ?? 'free',
      );

      final limits = FeatureLimits.forTier(subscriptionTier);
      final usage = await getCurrentUsage(userId);

      // Calculate overages
      final artworkOverage = limits.hasUnlimitedArtworks
          ? 0
          : (usage['artworks']! - limits.artworks)
                .clamp(0, double.infinity)
                .toInt();

      final aiCreditOverage = limits.hasUnlimitedAICredits
          ? 0
          : (usage['aiCredits']! - limits.aiCredits)
                .clamp(0, double.infinity)
                .toInt();

      final teamMemberOverage = limits.hasUnlimitedTeamMembers
          ? 0
          : (usage['teamMembers']! - limits.teamMembers)
                .clamp(0, double.infinity)
                .toInt();

      final storageOverageGB = limits.hasUnlimitedStorage
          ? 0.0
          : ((usage['storageUsedMB']! / 1024) - limits.storageGB).clamp(
              0.0,
              double.infinity,
            );

      return limits.calculateOverageCost(
        additionalArtworks: artworkOverage,
        additionalAICredits: aiCreditOverage,
        additionalTeamMembers: teamMemberOverage,
        additionalStorageGB: storageOverageGB,
      );
    } catch (e) {
      _logger.severe('Error calculating overage costs', e);
      return 0.0;
    }
  }

  /// Send notifications when users approach limits
  Future<void> checkAndSendLimitWarnings(String userId) async {
    try {
      final stats = await getUsageStats(userId);
      final notifications = <String>[];

      // Check each feature for approaching limits
      for (final feature in ['artworks', 'aiCredits', 'teamMembers']) {
        final featureStats = stats[feature] as Map<String, dynamic>?;
        if (featureStats != null &&
            featureStats['approaching_limit'] == true &&
            featureStats['unlimited'] == false) {
          notifications.add(
            'You\'re approaching your ${feature} limit (${featureStats['used']}/${featureStats['limit']})',
          );
        }
      }

      // Send notifications if any warnings
      if (notifications.isNotEmpty) {
        await _sendLimitWarningNotifications(userId, notifications);
      }
    } catch (e) {
      _logger.severe('Error checking limit warnings', e);
    }
  }

  /// Reset monthly usage counters
  Future<void> _checkAndResetMonthlyUsage(
    String userId,
    Map<String, dynamic> userData,
  ) async {
    final lastReset = userData['lastUsageReset'] as Timestamp?;
    final now = DateTime.now();

    // Reset if it's a new month
    if (lastReset == null ||
        now.month != lastReset.toDate().month ||
        now.year != lastReset.toDate().year) {
      await _firestore.collection('users').doc(userId).update({
        'aiCreditsUsed': 0,
        'lastUsageReset': Timestamp.fromDate(now),
      });
    }
  }

  /// Track overage usage for billing
  Future<void> _trackOverageIfNeeded(
    String userId,
    String feature,
    int amount,
  ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      final subscriptionTier = SubscriptionTier.fromLegacyName(
        (userData['subscriptionTier'] as String?) ?? 'free',
      );

      final limits = FeatureLimits.forTier(subscriptionTier);
      final usage = await getCurrentUsage(userId);

      // Check if this usage puts user over limit
      bool isOverage = false;
      switch (feature) {
        case 'artwork':
          isOverage =
              !limits.hasUnlimitedArtworks &&
              usage['artworks']! > limits.artworks;
          break;
        case 'ai_credit':
          isOverage =
              !limits.hasUnlimitedAICredits &&
              usage['aiCredits']! > limits.aiCredits;
          break;
        case 'team_member':
          isOverage =
              !limits.hasUnlimitedTeamMembers &&
              usage['teamMembers']! > limits.teamMembers;
          break;
      }

      if (isOverage) {
        // Track overage for billing
        await _firestore.collection('usage_overages').add({
          'userId': userId,
          'feature': feature,
          'amount': amount,
          'timestamp': Timestamp.fromDate(DateTime.now()),
          'subscriptionTier': subscriptionTier.apiName,
          'processed': false,
        });
      }
    } catch (e) {
      _logger.severe('Error tracking overage', e);
    }
  }

  /// Send limit warning notifications
  Future<void> _sendLimitWarningNotifications(
    String userId,
    List<String> warnings,
  ) async {
    for (final warning in warnings) {
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'usage_warning',
        'title': 'Approaching Usage Limit',
        'message': warning,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'actionType': 'upgrade_subscription',
      });
    }
  }
}
