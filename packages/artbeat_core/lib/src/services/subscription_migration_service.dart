import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import '../models/subscription_tier.dart';

/// Service to handle migration from old pricing to 2025 industry standard pricing
/// Ensures smooth transition for existing users while implementing new features
class SubscriptionMigrationService {
  FirebaseFirestore? _firestoreInstance;
  final Logger _logger = Logger('SubscriptionMigrationService');

  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

  /// Migrate user from legacy subscription tier to new 2025 tier
  Future<bool> migrateUserSubscription(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return false;

      final currentTier = userData['subscriptionTier'] as String?;
      if (currentTier == null) return false;

      // Check if already migrated
      final migrationVersion = userData['migrationVersion'] as int? ?? 0;

      if (migrationVersion >= 2025) {
        return true; // Already migrated to 2025 standards
      }

      // Map legacy tiers to new 2025 tiers
      final newTier = _mapLegacyToNewTier(currentTier);
      final grandfatheredPricing = _shouldGrandfatherPricing(
        currentTier,
        userData,
      );

      // Prepare migration data
      final migrationData = <String, dynamic>{
        'subscriptionTier': newTier.apiName,
        'migrationVersion': 2025,
        'lastSubscriptionMigration': Timestamp.fromDate(DateTime.now()),
        'legacyTier': currentTier,
        'isGrandfathered': grandfatheredPricing,
      };

      // Initialize usage tracking fields
      migrationData.addAll({
        'artworksCount': userData['artworksCount'] ?? 0,
        'aiCreditsUsed': 0, // Reset AI credits for new feature
        'teamMembersCount': userData['teamMembersCount'] ?? 1,
        'storageUsedMB': userData['storageUsedMB'] ?? 0,
        'lastUsageReset': Timestamp.fromDate(DateTime.now()),
        'aiCreditsResetDate': Timestamp.fromDate(DateTime.now()),
      });

      // If grandfathered, preserve old pricing
      if (grandfatheredPricing) {
        migrationData['grandfatheredPrice'] = _getLegacyPrice(currentTier);
        migrationData['grandfatheredUntil'] = Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 365)), // 1 year grace period
        );
      }

      // Apply migration
      await _firestore.collection('users').doc(userId).update(migrationData);

      // Log migration for analytics
      await _logMigration(
        userId,
        currentTier,
        newTier.apiName,
        grandfatheredPricing,
      );

      // Send welcome notification about new features
      await _sendMigrationWelcomeNotification(userId, newTier);

      return true;
    } catch (e) {
      _logger.severe('Error migrating user subscription', e);
      return false;
    }
  }

  /// Migrate all users in batches
  Future<void> migrateAllUsers() async {
    try {
      const batchSize = 100;
      QueryDocumentSnapshot? lastDoc;

      while (true) {
        Query query = _firestore
            .collection('users')
            .where('migrationVersion', isLessThan: 2025)
            .limit(batchSize);

        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final snapshot = await query.get();

        if (snapshot.docs.isEmpty) break;

        // Process batch
        final futures = snapshot.docs
            .map((doc) => migrateUserSubscription(doc.id))
            .toList();

        await Future.wait(futures);

        lastDoc = snapshot.docs.last;

        // Add delay to avoid rate limiting
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }

      _logger.info('Migration completed successfully');
    } catch (e) {
      _logger.severe('Error in batch migration', e);
    }
  }

  /// Check if user needs migration
  Future<bool> needsMigration(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return false;

      final migrationVersion = userData['migrationVersion'] as int? ?? 0;
      return migrationVersion < 2025;
    } catch (e) {
      _logger.severe('Error checking migration status', e);
      return false;
    }
  }

  /// Get migration statistics
  Future<Map<String, dynamic>> getMigrationStats() async {
    try {
      // Count users by migration status
      final totalUsers = await _firestore.collection('users').count().get();
      final migratedUsers = await _firestore
          .collection('users')
          .where('migrationVersion', isEqualTo: 2025)
          .count()
          .get();

      final grandfatheredUsers = await _firestore
          .collection('users')
          .where('isGrandfathered', isEqualTo: true)
          .count()
          .get();

      // Get recent migrations
      final recentMigrations = await _firestore
          .collection('migration_logs')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .get();

      final totalCount = totalUsers.count ?? 0;
      final migratedCount = migratedUsers.count ?? 0;
      final grandfatheredCount = grandfatheredUsers.count ?? 0;

      return {
        'totalUsers': totalCount,
        'migratedUsers': migratedCount,
        'pendingMigrations': totalCount - migratedCount,
        'grandfatheredUsers': grandfatheredCount,
        'migrationProgress': totalCount > 0
            ? (migratedCount / totalCount * 100).toStringAsFixed(1)
            : '0.0',
        'recentMigrations': recentMigrations.docs
            .map((doc) => doc.data())
            .toList(),
      };
    } catch (e) {
      _logger.severe('Error getting migration stats', e);
      return {};
    }
  }

  /// Map legacy tier to new 2025 tier
  SubscriptionTier _mapLegacyToNewTier(String legacyTier) {
    switch (legacyTier.toLowerCase()) {
      case 'free':
        return SubscriptionTier.free;
      case 'artist_basic':
      case 'artistbasic':
        return SubscriptionTier.starter;
      case 'artist_pro':
      case 'artistpro':
        return SubscriptionTier.creator;
      case 'business':
        return SubscriptionTier.business;
      default:
        return SubscriptionTier.free;
    }
  }

  /// Determine if user should get grandfathered pricing
  bool _shouldGrandfatherPricing(
    String currentTier,
    Map<String, dynamic> userData,
  ) {
    // Grandfather users who:
    // 1. Are currently paying subscribers
    // 2. Have been active in the last 30 days
    // 3. Would pay more under new pricing

    if (currentTier == 'free') return false;

    final lastActiveDate = userData['lastActiveDate'] as Timestamp?;
    if (lastActiveDate != null) {
      final daysSinceActive = DateTime.now()
          .difference(lastActiveDate.toDate())
          .inDays;
      if (daysSinceActive > 30) return false;
    }

    final legacyPrice = _getLegacyPrice(currentTier);
    final newTier = _mapLegacyToNewTier(currentTier);

    // Grandfather if old price was lower
    return legacyPrice < newTier.monthlyPrice;
  }

  /// Get legacy pricing
  double _getLegacyPrice(String legacyTier) {
    switch (legacyTier.toLowerCase()) {
      case 'artist_pro':
      case 'artistpro':
        return 9.99;
      case 'business':
        return 49.99;
      default:
        return 0.0;
    }
  }

  /// Log migration for analytics
  Future<void> _logMigration(
    String userId,
    String fromTier,
    String toTier,
    bool grandfathered,
  ) async {
    await _firestore.collection('migration_logs').add({
      'userId': userId,
      'fromTier': fromTier,
      'toTier': toTier,
      'grandfathered': grandfathered,
      'timestamp': Timestamp.fromDate(DateTime.now()),
      'migrationVersion': 2025,
    });
  }

  /// Send welcome notification about new features
  Future<void> _sendMigrationWelcomeNotification(
    String userId,
    SubscriptionTier newTier,
  ) async {
    final features = newTier.features;
    final keyFeatures = features.take(3).join(', ');

    await _firestore.collection('notifications').add({
      'userId': userId,
      'type': 'migration_welcome',
      'title': 'Welcome to ARTbeat 2025!',
      'message':
          'Your account has been upgraded with new features: $keyFeatures and more!',
      'isRead': false,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'actionType': 'explore_features',
      'actionData': {'newTier': newTier.apiName, 'features': features},
    });
  }

  /// Handle grandfathered pricing expiration
  Future<void> processGrandfatherExpirations() async {
    try {
      final expiredUsers = await _firestore
          .collection('users')
          .where('isGrandfathered', isEqualTo: true)
          .where(
            'grandfatheredUntil',
            isLessThan: Timestamp.fromDate(DateTime.now()),
          )
          .get();

      for (final doc in expiredUsers.docs) {
        final userId = doc.id;
        final userData = doc.data();
        final currentTier = SubscriptionTier.fromLegacyName(
          userData['subscriptionTier'] as String? ?? 'free',
        );

        // Remove grandfathered status
        await _firestore.collection('users').doc(userId).update({
          'isGrandfathered': false,
          'grandfatheredPrice': FieldValue.delete(),
          'grandfatheredUntil': FieldValue.delete(),
        });

        // Notify user about pricing change
        await _firestore.collection('notifications').add({
          'userId': userId,
          'type': 'pricing_update',
          'title': 'Pricing Update',
          'message':
              'Your grandfathered pricing has expired. Your plan now uses current pricing: \$${currentTier.monthlyPrice}/month.',
          'isRead': false,
          'createdAt': Timestamp.fromDate(DateTime.now()),
          'actionType': 'view_pricing',
        });
      }
    } catch (e) {
      _logger.severe('Error processing grandfather expirations', e);
    }
  }
}
