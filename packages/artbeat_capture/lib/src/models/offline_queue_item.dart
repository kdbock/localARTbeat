import 'package:artbeat_core/artbeat_core.dart';

/// Enum for offline queue item status
enum OfflineQueueStatus { pending, syncing, synced, failed }

/// Extension for OfflineQueueStatus enum
extension OfflineQueueStatusExtension on OfflineQueueStatus {
  static OfflineQueueStatus fromString(String value) {
    switch (value) {
      case 'OfflineQueueStatus.pending':
        return OfflineQueueStatus.pending;
      case 'OfflineQueueStatus.syncing':
        return OfflineQueueStatus.syncing;
      case 'OfflineQueueStatus.synced':
        return OfflineQueueStatus.synced;
      case 'OfflineQueueStatus.failed':
        return OfflineQueueStatus.failed;
      default:
        return OfflineQueueStatus.pending;
    }
  }

  String get displayName {
    switch (this) {
      case OfflineQueueStatus.pending:
        return 'Pending Upload';
      case OfflineQueueStatus.syncing:
        return 'Uploading...';
      case OfflineQueueStatus.synced:
        return 'Synced';
      case OfflineQueueStatus.failed:
        return 'Upload Failed';
    }
  }

  bool get canRetry => this == OfflineQueueStatus.failed;
  bool get isPending => this == OfflineQueueStatus.pending;
  bool get isSyncing => this == OfflineQueueStatus.syncing;
  bool get isSynced => this == OfflineQueueStatus.synced;
  bool get isFailed => this == OfflineQueueStatus.failed;
}

/// Model for offline capture queue items
class OfflineQueueItem {
  final String id;
  final String localCaptureId; // Temporary local ID
  final String? remoteCaptureId; // Firestore document ID after sync
  final CaptureModel captureData;
  final String localImagePath; // Local file path
  final OfflineQueueStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int retryCount;
  final String? lastError;
  final Map<String, dynamic>? metadata;

  OfflineQueueItem({
    required this.id,
    required this.localCaptureId,
    this.remoteCaptureId,
    required this.captureData,
    required this.localImagePath,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.retryCount = 0,
    this.lastError,
    this.metadata,
  });

  /// Check if the queue item is ready for sync
  bool get canSync {
    return status == OfflineQueueStatus.pending ||
        (status == OfflineQueueStatus.failed && retryCount < 3);
  }

  /// Check if the queue item should be auto-retried
  bool get shouldAutoRetry {
    return status == OfflineQueueStatus.failed &&
        retryCount < 3 &&
        DateTime.now().difference(updatedAt).inMinutes >= 5;
  }

  /// Get priority for sync queue (higher number = higher priority)
  int get syncPriority {
    int priority = 100;

    // Older items get higher priority
    final ageInHours = DateTime.now().difference(createdAt).inHours;
    priority += ageInHours;

    // Failed items get lower priority unless they're ready for retry
    if (status == OfflineQueueStatus.failed) {
      priority -= 50;
    }

    // Recently created items get slight boost
    if (ageInHours < 1) {
      priority += 20;
    }

    return priority;
  }

  /// Create a copy with updated status
  OfflineQueueItem copyWith({
    String? remoteCaptureId,
    OfflineQueueStatus? status,
    DateTime? updatedAt,
    int? retryCount,
    String? lastError,
    Map<String, dynamic>? metadata,
  }) {
    return OfflineQueueItem(
      id: id,
      localCaptureId: localCaptureId,
      remoteCaptureId: remoteCaptureId ?? this.remoteCaptureId,
      captureData: captureData,
      localImagePath: localImagePath,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert to JSON for SQLite storage
  Map<String, dynamic> toJson() {
    final captureJson = captureData.toJson();
    // CaptureModel.toJson omits `id`; keep it for OfflineQueueItem.fromJson.
    captureJson['id'] = captureData.id;

    return {
      'id': id,
      'localCaptureId': localCaptureId,
      'remoteCaptureId': remoteCaptureId,
      'captureData': captureJson,
      'localImagePath': localImagePath,
      'status': status.toString(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
      'metadata': metadata,
    };
  }

  /// Create from JSON stored in SQLite
  factory OfflineQueueItem.fromJson(Map<String, dynamic> json) {
    return OfflineQueueItem(
      id: json['id'] as String,
      localCaptureId: json['localCaptureId'] as String,
      remoteCaptureId: json['remoteCaptureId'] as String?,
      captureData: CaptureModel.fromJson(
        json['captureData'] as Map<String, dynamic>,
      ),
      localImagePath: json['localImagePath'] as String,
      status: OfflineQueueStatusExtension.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      retryCount: json['retryCount'] as int? ?? 0,
      lastError: json['lastError'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  @override
  String toString() =>
      'OfflineQueueItem(id: $id, status: ${status.displayName}, retryCount: $retryCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OfflineQueueItem &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
