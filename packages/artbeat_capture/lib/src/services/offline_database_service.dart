import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:artbeat_core/artbeat_core.dart' show CaptureModel, AppLogger;
import 'package:artbeat_capture/src/models/offline_queue_item.dart';

/// Service for managing offline capture queue using SQLite
class OfflineDatabaseService {
  static final OfflineDatabaseService _instance =
      OfflineDatabaseService._internal();
  static Database? _database;

  factory OfflineDatabaseService() {
    return _instance;
  }

  OfflineDatabaseService._internal();

  /// Get the database instance
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize the SQLite database
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'offline_capture_queue.db');

      AppLogger.info('Initializing offline database at: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _createDatabase,
        onUpgrade: _upgradeDatabase,
      );
    } catch (e) {
      AppLogger.error('Error initializing offline database: $e');
      rethrow;
    }
  }

  /// Create database tables
  Future<void> _createDatabase(Database db, int version) async {
    AppLogger.info('Creating offline queue tables');

    await db.execute('''
      CREATE TABLE offline_queue (
        id TEXT PRIMARY KEY,
        localCaptureId TEXT NOT NULL,
        remoteCaptureId TEXT,
        captureData TEXT NOT NULL,
        localImagePath TEXT NOT NULL,
        status TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0,
        lastError TEXT,
        metadata TEXT,
        syncPriority INTEGER DEFAULT 100
      )
    ''');

    // Index for efficient querying
    await db.execute('''
      CREATE INDEX idx_offline_queue_status ON offline_queue(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_offline_queue_created_at ON offline_queue(createdAt)
    ''');

    await db.execute('''
      CREATE INDEX idx_offline_queue_priority ON offline_queue(syncPriority DESC)
    ''');
  }

  /// Handle database upgrades
  Future<void> _upgradeDatabase(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    AppLogger.info(
      'Upgrading offline database from v$oldVersion to v$newVersion',
    );

    if (oldVersion < 2) {
      // Future version upgrades would go here
    }
  }

  /// Add item to offline queue
  Future<bool> addToQueue(OfflineQueueItem item) async {
    try {
      final db = await database;

      final result = await db.insert('offline_queue', {
        ...item.toJson(),
        'captureData': jsonEncode(item.captureData.toJson()),
        'metadata': item.metadata != null ? jsonEncode(item.metadata!) : null,
        'syncPriority': item.syncPriority,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      AppLogger.info('Added item to offline queue: ${item.id}');
      return result > 0;
    } catch (e) {
      AppLogger.error('Error adding item to offline queue: $e');
      return false;
    }
  }

  /// Update existing queue item
  Future<bool> updateQueueItem(OfflineQueueItem item) async {
    try {
      final db = await database;

      final result = await db.update(
        'offline_queue',
        {
          ...item.toJson(),
          'captureData': jsonEncode(item.captureData.toJson()),
          'metadata': item.metadata != null ? jsonEncode(item.metadata!) : null,
          'syncPriority': item.syncPriority,
        },
        where: 'id = ?',
        whereArgs: [item.id],
      );

      debugPrint(
        'Updated queue item: ${item.id} (status: ${item.status.displayName})',
      );
      return result > 0;
    } catch (e) {
      AppLogger.error('Error updating queue item: $e');
      return false;
    }
  }

  /// Remove item from queue (after successful sync)
  Future<bool> removeFromQueue(String itemId) async {
    try {
      final db = await database;

      final result = await db.delete(
        'offline_queue',
        where: 'id = ?',
        whereArgs: [itemId],
      );

      AppLogger.info('Removed item from offline queue: $itemId');
      return result > 0;
    } catch (e) {
      AppLogger.error('Error removing item from offline queue: $e');
      return false;
    }
  }

  /// Get all pending queue items
  Future<List<OfflineQueueItem>> getPendingItems() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'offline_queue',
        where: 'status IN (?, ?)',
        whereArgs: [
          OfflineQueueStatus.pending.toString(),
          OfflineQueueStatus.failed.toString(),
        ],
        orderBy: 'syncPriority DESC, createdAt ASC',
      );

      return maps.map((map) => _mapToQueueItem(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting pending items: $e');
      return [];
    }
  }

  /// Get all queue items with specific status
  Future<List<OfflineQueueItem>> getItemsByStatus(
    OfflineQueueStatus status,
  ) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'offline_queue',
        where: 'status = ?',
        whereArgs: [status.toString()],
        orderBy: 'createdAt DESC',
      );

      return maps.map((map) => _mapToQueueItem(map)).toList();
    } catch (e) {
      AppLogger.error('Error getting items by status: $e');
      return [];
    }
  }

  /// Get all queue items for a user
  Future<List<OfflineQueueItem>> getUserQueueItems(String userId) async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'offline_queue',
        orderBy: 'createdAt DESC',
      );

      // Filter by userId in the captureData
      return maps
          .map((map) => _mapToQueueItem(map))
          .where((item) => item.captureData.userId == userId)
          .toList();
    } catch (e) {
      AppLogger.error('Error getting user queue items: $e');
      return [];
    }
  }

  /// Get items that should be auto-retried
  Future<List<OfflineQueueItem>> getItemsForAutoRetry() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> maps = await db.query(
        'offline_queue',
        where: 'status = ? AND retryCount < 3',
        whereArgs: [OfflineQueueStatus.failed.toString()],
        orderBy: 'updatedAt ASC',
      );

      final items = maps.map((map) => _mapToQueueItem(map)).toList();

      // Filter for items ready for auto-retry
      return items.where((item) => item.shouldAutoRetry).toList();
    } catch (e) {
      AppLogger.error('Error getting items for auto-retry: $e');
      return [];
    }
  }

  /// Get queue statistics
  Future<Map<String, int>> getQueueStatistics() async {
    try {
      final db = await database;

      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT 
          status,
          COUNT(*) as count
        FROM offline_queue 
        GROUP BY status
      ''');

      final stats = <String, int>{};
      for (final row in result) {
        stats[row['status'] as String] = row['count'] as int;
      }

      return stats;
    } catch (e) {
      AppLogger.error('Error getting queue statistics: $e');
      return {};
    }
  }

  /// Clean up old synced items (older than 7 days)
  Future<int> cleanupOldItems() async {
    try {
      final db = await database;
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

      final result = await db.delete(
        'offline_queue',
        where: 'status = ? AND updatedAt < ?',
        whereArgs: [
          OfflineQueueStatus.synced.toString(),
          sevenDaysAgo.toIso8601String(),
        ],
      );

      if (result > 0) {
        AppLogger.info('Cleaned up $result old synced items');
      }

      return result;
    } catch (e) {
      AppLogger.error('Error cleaning up old items: $e');
      return 0;
    }
  }

  /// Clear all queue items (use with caution)
  Future<bool> clearQueue() async {
    try {
      final db = await database;
      await db.delete('offline_queue');
      AppLogger.info('Cleared offline queue');
      return true;
    } catch (e) {
      AppLogger.error('Error clearing queue: $e');
      return false;
    }
  }

  /// Helper to convert database map to OfflineQueueItem
  OfflineQueueItem _mapToQueueItem(Map<String, dynamic> map) {
    // Parse the captureData JSON string back to Map
    final captureDataStr = map['captureData'] as String;
    final captureData = jsonDecode(captureDataStr) as Map<String, dynamic>;

    // Parse metadata if present
    Map<String, dynamic>? metadata;
    if (map['metadata'] != null) {
      metadata = jsonDecode(map['metadata'] as String) as Map<String, dynamic>;
    }

    return OfflineQueueItem(
      id: map['id'] as String,
      localCaptureId: map['localCaptureId'] as String,
      remoteCaptureId: map['remoteCaptureId'] as String?,
      captureData: CaptureModel.fromJson(captureData),
      localImagePath: map['localImagePath'] as String,
      status: OfflineQueueStatusExtension.fromString(map['status'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      retryCount: map['retryCount'] as int? ?? 0,
      lastError: map['lastError'] as String?,
      metadata: metadata,
    );
  }

  /// Close the database connection
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
