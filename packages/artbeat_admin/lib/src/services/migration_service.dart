import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

import 'admin_capture_moderation_service.dart';

/// Service for migrating existing data to use standardized moderation status
class MigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AdminCaptureModerationService _captureService =
      AdminCaptureModerationService();

  /// Migrate all collections to use standardized moderation status
  Future<void> migrateAllCollections() async {
    AppLogger.info('Starting migration of all collections...');

    try {
      await Future.wait([
        migrateCapturesCollection(),
        migratePostsCollection(),
        migrateCommentsCollection(),
        migrateArtworkCollection(),
        migrateAdsCollection(),
      ]);

      AppLogger.info('Migration completed successfully!');
    } catch (e) {
      AppLogger.info('Migration failed: $e');
      rethrow;
    }
  }

  /// Migrate captures to add geo field for geospatial queries
  Future<void> migrateCapturesGeoField({int batchSize = 100}) async {
    AppLogger.info('Starting geo field migration for captures...');

    try {
      await _captureService.backfillGeoFieldForCaptures(
        batchSize: batchSize,
      );

      AppLogger.info('Geo field migration completed successfully');
    } catch (e) {
      AppLogger.error('Geo field migration failed: $e');
      rethrow;
    }
  }

  /// Migrate captures collection to use standardized status
  Future<void> migrateCapturesCollection() async {
    AppLogger.info('Migrating captures collection...');

    try {
      final batch = _firestore.batch();
      final captures = await _firestore.collection('captures').get();

      int updateCount = 0;
      for (final doc in captures.docs) {
        final data = doc.data();

        // Check if already has the new fields
        if (!data.containsKey('moderationStatus') ||
            !data.containsKey('flagged')) {
          // Map existing status to new format
          final existingStatus = data['status'] as String?;
          final String moderationStatus;
          const bool flagged = false;

          switch (existingStatus?.toLowerCase()) {
            case 'approved':
              moderationStatus = 'approved';
              break;
            case 'rejected':
              moderationStatus = 'rejected';
              break;
            case 'pending':
            default:
              moderationStatus = 'pending';
              break;
          }

          batch.update(doc.reference, {
            'moderationStatus': moderationStatus,
            'flagged': flagged,
            'flaggedAt': null,
            'moderationNotes': null,
          });

          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        AppLogger.info('Updated $updateCount captures');
      } else {
        AppLogger.info('No captures needed migration');
      }
    } catch (e) {
      AppLogger.error('Error migrating captures: $e');
      rethrow;
    }
  }

  /// Migrate posts collection to add moderation status
  Future<void> migratePostsCollection() async {
    AppLogger.info('Migrating posts collection...');

    try {
      final batch = _firestore.batch();
      final posts = await _firestore.collection('posts').get();

      int updateCount = 0;
      for (final doc in posts.docs) {
        final data = doc.data();

        // Check if already has the new fields
        if (!data.containsKey('moderationStatus') ||
            !data.containsKey('flagged')) {
          batch.update(doc.reference, {
            'moderationStatus':
                'approved', // Default to approved for existing posts
            'flagged': false,
            'flaggedAt': null,
            'moderationNotes': null,
          });

          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        AppLogger.info('Updated $updateCount posts');
      } else {
        AppLogger.info('No posts needed migration');
      }
    } catch (e) {
      AppLogger.error('Error migrating posts: $e');
      rethrow;
    }
  }

  /// Migrate comments collection to add moderation status
  Future<void> migrateCommentsCollection() async {
    AppLogger.info('Migrating comments collection...');

    try {
      final batch = _firestore.batch();
      final comments = await _firestore.collection('comments').get();

      int updateCount = 0;
      for (final doc in comments.docs) {
        final data = doc.data();

        // Check if already has the new fields
        if (!data.containsKey('moderationStatus') ||
            !data.containsKey('flagged')) {
          batch.update(doc.reference, {
            'moderationStatus':
                'approved', // Default to approved for existing comments
            'flagged': false,
            'flaggedAt': null,
            'moderationNotes': null,
          });

          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        AppLogger.info('Updated $updateCount comments');
      } else {
        AppLogger.info('No comments needed migration');
      }
    } catch (e) {
      AppLogger.error('Error migrating comments: $e');
      rethrow;
    }
  }

  /// Migrate artwork collection to add moderation status
  Future<void> migrateArtworkCollection() async {
    AppLogger.info('Migrating artwork collection...');

    try {
      final batch = _firestore.batch();
      final artwork = await _firestore.collection('artwork').get();

      int updateCount = 0;
      for (final doc in artwork.docs) {
        final data = doc.data();

        // Check if already has the new fields
        if (!data.containsKey('moderationStatus') ||
            !data.containsKey('flagged')) {
          batch.update(doc.reference, {
            'moderationStatus':
                'approved', // Default to approved for existing artwork
            'flagged': false,
            'flaggedAt': null,
            'moderationNotes': null,
          });

          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        AppLogger.info('Updated $updateCount artwork items');
      } else {
        AppLogger.info('No artwork needed migration');
      }
    } catch (e) {
      AppLogger.error('Error migrating artwork: $e');
      rethrow;
    }
  }

  /// Migrate ads collection to standardize status field
  Future<void> migrateAdsCollection() async {
    AppLogger.info('Migrating ads collection...');

    try {
      final batch = _firestore.batch();
      final ads = await _firestore.collection('ads').get();

      int updateCount = 0;
      for (final doc in ads.docs) {
        final data = doc.data();

        // Check if already has the new fields
        if (!data.containsKey('moderationStatus') ||
            !data.containsKey('flagged')) {
          // Map existing AdStatus index to new format
          final existingStatusIndex = data['status'] as int?;
          final String moderationStatus;
          const bool flagged = false;

          switch (existingStatusIndex) {
            case 0: // pending
              moderationStatus = 'pending';
              break;
            case 1: // approved
              moderationStatus = 'approved';
              break;
            case 2: // rejected
              moderationStatus = 'rejected';
              break;
            case 3: // running (treat as approved)
              moderationStatus = 'approved';
              break;
            case 4: // paused (treat as approved)
              moderationStatus = 'approved';
              break;
            case 5: // expired (treat as approved)
              moderationStatus = 'approved';
              break;
            default:
              moderationStatus = 'pending';
              break;
          }

          batch.update(doc.reference, {
            'moderationStatus': moderationStatus,
            'flagged': flagged,
            'flaggedAt': null,
            'moderationNotes': null,
          });

          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        AppLogger.info('Updated $updateCount ads');
      } else {
        AppLogger.info('No ads needed migration');
      }
    } catch (e) {
      AppLogger.error('Error migrating ads: $e');
      rethrow;
    }
  }

  /// Check migration status for all collections
  Future<Map<String, MigrationStatus>> checkMigrationStatus() async {
    final results = <String, MigrationStatus>{};

    try {
      results['captures'] = await _checkCollectionMigrationStatus('captures');
      results['posts'] = await _checkCollectionMigrationStatus('posts');
      results['comments'] = await _checkCollectionMigrationStatus('comments');
      results['artwork'] = await _checkCollectionMigrationStatus('artwork');
      results['ads'] = await _checkCollectionMigrationStatus('ads');
    } catch (e) {
      AppLogger.error('Error checking migration status: $e');
      rethrow;
    }

    return results;
  }

  /// Check migration status for a specific collection
  Future<MigrationStatus> _checkCollectionMigrationStatus(
      String collectionName) async {
    try {
      final snapshot =
          await _firestore.collection(collectionName).limit(100).get();

      if (snapshot.docs.isEmpty) {
        return MigrationStatus(
          collectionName: collectionName,
          totalDocuments: 0,
          migratedDocuments: 0,
          needsMigration: false,
        );
      }

      final int totalDocs = snapshot.docs.length;
      int migratedDocs = 0;

      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('moderationStatus') &&
            data.containsKey('flagged')) {
          migratedDocs++;
        }
      }

      return MigrationStatus(
        collectionName: collectionName,
        totalDocuments: totalDocs,
        migratedDocuments: migratedDocs,
        needsMigration: migratedDocs < totalDocs,
      );
    } catch (e) {
      AppLogger.error('Error checking $collectionName migration status: $e');
      rethrow;
    }
  }

  /// Rollback migration (remove new fields)
  Future<void> rollbackMigration() async {
    AppLogger.info('Rolling back migration...');

    try {
      await Future.wait([
        _rollbackCollection('captures'),
        _rollbackCollection('posts'),
        _rollbackCollection('comments'),
        _rollbackCollection('artwork'),
        _rollbackCollection('ads'),
      ]);

      AppLogger.info('Rollback completed successfully!');
    } catch (e) {
      AppLogger.info('Rollback failed: $e');
      rethrow;
    }
  }

  /// Rollback migration for a specific collection
  Future<void> _rollbackCollection(String collectionName) async {
    try {
      final batch = _firestore.batch();
      final docs = await _firestore.collection(collectionName).get();

      int updateCount = 0;
      for (final doc in docs.docs) {
        final data = doc.data();

        if (data.containsKey('moderationStatus') ||
            data.containsKey('flagged') ||
            data.containsKey('flaggedAt') ||
            data.containsKey('moderationNotes')) {
          batch.update(doc.reference, {
            'moderationStatus': FieldValue.delete(),
            'flagged': FieldValue.delete(),
            'flaggedAt': FieldValue.delete(),
            'moderationNotes': FieldValue.delete(),
          });

          updateCount++;
        }
      }

      if (updateCount > 0) {
        await batch.commit();
        AppLogger.info('Rolled back $updateCount documents in $collectionName');
      }
    } catch (e) {
      AppLogger.error('Error rolling back $collectionName: $e');
      rethrow;
    }
  }
}

/// Status of migration for a collection
class MigrationStatus {
  final String collectionName;
  final int totalDocuments;
  final int migratedDocuments;
  final bool needsMigration;

  MigrationStatus({
    required this.collectionName,
    required this.totalDocuments,
    required this.migratedDocuments,
    required this.needsMigration,
  });

  double get migrationProgress {
    if (totalDocuments == 0) return 1.0;
    return migratedDocuments / totalDocuments;
  }

  @override
  String toString() {
    return 'MigrationStatus($collectionName: $migratedDocuments/$totalDocuments, ${(migrationProgress * 100).toStringAsFixed(1)}%)';
  }
}
