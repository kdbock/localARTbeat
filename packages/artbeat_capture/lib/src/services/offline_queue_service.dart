import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';
import 'package:artbeat_core/artbeat_core.dart' show CaptureModel, AppLogger;
import 'package:artbeat_capture/src/models/offline_queue_item.dart';
import 'offline_database_service.dart';
import 'capture_service.dart';
import 'storage_service.dart';

/// Service for managing offline capture queue and synchronization
class OfflineQueueService {
  static final OfflineQueueService _instance = OfflineQueueService._internal();

  final OfflineDatabaseService _dbService = OfflineDatabaseService();
  final CaptureService _captureService = CaptureService();
  final StorageService _storageService = StorageService();
  final Connectivity _connectivity = Connectivity();
  final Uuid _uuid = const Uuid();

  // Sync state management
  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamController<OfflineSyncEvent>? _syncEventController;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  factory OfflineQueueService() {
    return _instance;
  }

  OfflineQueueService._internal() {
    _initializeService();
  }

  /// Initialize the service and start monitoring
  void _initializeService() {
    // Start monitoring connectivity
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    // Start periodic sync
    _startPeriodicSync();

    AppLogger.info('OfflineQueueService initialized');
  }

  /// Stream for sync events
  Stream<OfflineSyncEvent> get syncEvents {
    _syncEventController ??= StreamController<OfflineSyncEvent>.broadcast();
    return _syncEventController!.stream;
  }

  /// Add a capture to the offline queue
  Future<String> addCaptureToQueue({
    required CaptureModel captureData,
    required String localImagePath,
  }) async {
    try {
      final localCaptureId = _uuid.v4();
      final queueItemId = _uuid.v4();

      final queueItem = OfflineQueueItem(
        id: queueItemId,
        localCaptureId: localCaptureId,
        captureData: captureData.copyWith(id: localCaptureId),
        localImagePath: localImagePath,
        status: OfflineQueueStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final added = await _dbService.addToQueue(queueItem);

      if (added) {
        AppLogger.info('Added capture to offline queue: $localCaptureId');
        _notifySyncEvent(
          OfflineSyncEvent(
            type: OfflineSyncEventType.itemAdded,
            itemId: queueItemId,
            status: OfflineQueueStatus.pending,
            message: 'Capture added to offline queue',
          ),
        );

        // Try immediate sync if connected
        _attemptImmediateSync();

        return localCaptureId;
      } else {
        throw Exception('Failed to add capture to offline queue');
      }
    } catch (e) {
      AppLogger.error('Error adding capture to offline queue: $e');
      rethrow;
    }
  }

  /// Get all pending items for a user
  Future<List<OfflineQueueItem>> getUserPendingItems(String userId) async {
    try {
      final allUserItems = await _dbService.getUserQueueItems(userId);
      return allUserItems.where((item) => !item.status.isSynced).toList();
    } catch (e) {
      AppLogger.error('Error getting user pending items: $e');
      return [];
    }
  }

  /// Get queue statistics
  Future<OfflineQueueStatistics> getQueueStatistics() async {
    try {
      final stats = await _dbService.getQueueStatistics();

      return OfflineQueueStatistics(
        pending: stats[OfflineQueueStatus.pending.toString()] ?? 0,
        syncing: stats[OfflineQueueStatus.syncing.toString()] ?? 0,
        synced: stats[OfflineQueueStatus.synced.toString()] ?? 0,
        failed: stats[OfflineQueueStatus.failed.toString()] ?? 0,
        lastSyncTime: _lastSyncTime,
        isSyncing: _isSyncing,
      );
    } catch (e) {
      AppLogger.error('Error getting queue statistics: $e');
      return OfflineQueueStatistics.empty();
    }
  }

  /// Manually trigger sync
  Future<bool> forceSyncNow() async {
    if (_isSyncing) {
      AppLogger.info('Sync already in progress');
      return false;
    }

    final isConnected = await _isConnectedToInternet();
    if (!isConnected) {
      _notifySyncEvent(
        OfflineSyncEvent(
          type: OfflineSyncEventType.syncFailed,
          message: 'No internet connection available',
        ),
      );
      return false;
    }

    return _performSync();
  }

  /// Handle connectivity changes
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    AppLogger.info('Connectivity changed: $results');

    // Check if any connection is available
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (hasConnection) {
      // Connection restored, attempt sync
      _attemptImmediateSync();
    }
  }

  /// Attempt immediate sync (non-blocking)
  void _attemptImmediateSync() {
    Future.microtask(() async {
      try {
        if (!_isSyncing) {
          final isConnected = await _isConnectedToInternet();
          if (isConnected) {
            await _performSync();
          }
        }
      } catch (e) {
        AppLogger.error('Error in immediate sync attempt: $e');
      }
    });
  }

  DateTime? _lastSyncTime;

  /// Perform the actual sync process
  Future<bool> _performSync() async {
    if (_isSyncing) return false;

    _isSyncing = true;
    _lastSyncTime = DateTime.now();

    _notifySyncEvent(
      OfflineSyncEvent(
        type: OfflineSyncEventType.syncStarted,
        message: 'Starting offline sync...',
      ),
    );

    try {
      // Get all items that can be synced
      final pendingItems = await _dbService.getPendingItems();
      final retryItems = await _dbService.getItemsForAutoRetry();
      final allItems = [...pendingItems, ...retryItems];

      if (allItems.isEmpty) {
        AppLogger.info('No items to sync');
        _notifySyncEvent(
          OfflineSyncEvent(
            type: OfflineSyncEventType.syncCompleted,
            message: 'Sync completed - no items to sync',
          ),
        );
        return true;
      }

      AppLogger.info('Syncing ${allItems.length} items');

      int successCount = 0;
      int failureCount = 0;

      for (final item in allItems) {
        try {
          final success = await _syncSingleItem(item);
          if (success) {
            successCount++;
          } else {
            failureCount++;
          }
        } catch (e) {
          AppLogger.error('Error syncing item ${item.id}: $e');
          failureCount++;

          // Update item with error
          final updatedItem = item.copyWith(
            status: OfflineQueueStatus.failed,
            retryCount: item.retryCount + 1,
            lastError: e.toString(),
          );
          await _dbService.updateQueueItem(updatedItem);
        }
      }

      final message =
          'Sync completed: $successCount success, $failureCount failed';
      AppLogger.info(message);

      _notifySyncEvent(
        OfflineSyncEvent(
          type: OfflineSyncEventType.syncCompleted,
          message: message,
          successCount: successCount,
          failureCount: failureCount,
        ),
      );

      return failureCount == 0;
    } catch (e) {
      AppLogger.error('Error during sync: $e');
      _notifySyncEvent(
        OfflineSyncEvent(
          type: OfflineSyncEventType.syncFailed,
          message: 'Sync failed: $e',
        ),
      );
      return false;
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single queue item
  Future<bool> _syncSingleItem(OfflineQueueItem item) async {
    try {
      // Update status to syncing
      final syncingItem = item.copyWith(status: OfflineQueueStatus.syncing);
      await _dbService.updateQueueItem(syncingItem);

      _notifySyncEvent(
        OfflineSyncEvent(
          type: OfflineSyncEventType.itemSyncStarted,
          itemId: item.id,
          status: OfflineQueueStatus.syncing,
          message: 'Syncing ${item.captureData.title ?? 'capture'}...',
        ),
      );

      // Upload image to Firebase Storage first
      String? imageUrl;
      String? thumbnailUrl;

      if (File(item.localImagePath).existsSync()) {
        // Use the optimized upload method that returns both image and thumbnail URLs
        final uploadResult = await _storageService.uploadImageOptimized(
          File(item.localImagePath),
        );

        imageUrl = uploadResult['imageUrl'];
        thumbnailUrl = uploadResult['thumbnailUrl'];

        if (imageUrl == null) {
          throw Exception('Failed to upload image');
        }
      } else {
        throw Exception('Local image file not found: ${item.localImagePath}');
      }

      // Update capture data with uploaded URLs
      final updatedCaptureData = item.captureData.copyWith(
        imageUrl: imageUrl,
        thumbnailUrl: thumbnailUrl,
      );

      // Save to Firestore
      final remoteCaptureId = await _captureService.saveCapture(
        updatedCaptureData,
      );

      if (remoteCaptureId == null) {
        throw Exception('Failed to save capture to Firestore');
      }

      // Update queue item as synced
      final syncedItem = item.copyWith(
        status: OfflineQueueStatus.synced,
        remoteCaptureId: remoteCaptureId,
      );
      await _dbService.updateQueueItem(syncedItem);

      _notifySyncEvent(
        OfflineSyncEvent(
          type: OfflineSyncEventType.itemSynced,
          itemId: item.id,
          status: OfflineQueueStatus.synced,
          message: 'Successfully synced ${item.captureData.title ?? 'capture'}',
        ),
      );

      // Clean up local file after successful sync (optional)
      // Uncomment if you want to delete local files after sync
      // try {
      //   await File(item.localImagePath).delete();
      // } catch (e) {
      //   debugPrint('Warning: Could not delete local file: $e');
      // }

      return true;
    } catch (e) {
      AppLogger.error('Error syncing item ${item.id}: $e');

      final failedItem = item.copyWith(
        status: OfflineQueueStatus.failed,
        retryCount: item.retryCount + 1,
        lastError: e.toString(),
      );
      await _dbService.updateQueueItem(failedItem);

      _notifySyncEvent(
        OfflineSyncEvent(
          type: OfflineSyncEventType.itemSyncFailed,
          itemId: item.id,
          status: OfflineQueueStatus.failed,
          message: 'Failed to sync: $e',
        ),
      );

      return false;
    }
  }

  /// Check internet connectivity
  Future<bool> _isConnectedToInternet() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      return connectivityResults.any(
        (result) => result != ConnectivityResult.none,
      );
    } catch (e) {
      AppLogger.error('Error checking connectivity: $e');
      return false;
    }
  }

  /// Start periodic sync (every 5 minutes when connected)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final isConnected = await _isConnectedToInternet();
      if (isConnected && !_isSyncing) {
        AppLogger.info('Performing periodic sync');
        await _performSync();
      }
    });
  }

  /// Notify sync event listeners
  void _notifySyncEvent(OfflineSyncEvent event) {
    _syncEventController?.add(event);
  }

  /// Clean up old synced items
  Future<int> cleanupOldItems() async {
    return _dbService.cleanupOldItems();
  }

  /// Dispose of the service
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    _syncEventController?.close();
    _isSyncing = false;
  }
}

/// Events emitted during sync process
class OfflineSyncEvent {
  final OfflineSyncEventType type;
  final String? itemId;
  final OfflineQueueStatus? status;
  final String message;
  final double? progress;
  final int? successCount;
  final int? failureCount;

  OfflineSyncEvent({
    required this.type,
    this.itemId,
    this.status,
    required this.message,
    this.progress,
    this.successCount,
    this.failureCount,
  });

  @override
  String toString() => 'OfflineSyncEvent(type: $type, message: $message)';
}

/// Types of sync events
enum OfflineSyncEventType {
  syncStarted,
  syncCompleted,
  syncFailed,
  itemAdded,
  itemSyncStarted,
  itemSynced,
  itemSyncFailed,
  uploadProgress,
}

/// Statistics about the offline queue
class OfflineQueueStatistics {
  final int pending;
  final int syncing;
  final int synced;
  final int failed;
  final DateTime? lastSyncTime;
  final bool isSyncing;

  OfflineQueueStatistics({
    required this.pending,
    required this.syncing,
    required this.synced,
    required this.failed,
    this.lastSyncTime,
    required this.isSyncing,
  });

  factory OfflineQueueStatistics.empty() {
    return OfflineQueueStatistics(
      pending: 0,
      syncing: 0,
      synced: 0,
      failed: 0,
      isSyncing: false,
    );
  }

  int get total => pending + syncing + synced + failed;
  int get unsynced => pending + failed;

  bool get hasUnsynced => unsynced > 0;
  bool get hasFailures => failed > 0;

  @override
  String toString() =>
      'OfflineQueueStatistics(pending: $pending, syncing: $syncing, synced: $synced, failed: $failed)';
}
