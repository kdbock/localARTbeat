import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Represents a user's progress through an art walk
class ArtWalkProgress extends Equatable {
  final String id;
  final String userId;
  final String artWalkId;
  final List<ArtVisit> visitedArt;
  final DateTime startedAt;
  final DateTime lastActiveAt;
  final DateTime? completedAt;
  final WalkStatus status;
  final GeoPoint? lastKnownLocation;
  final int currentArtIndex;
  final Map<String, dynamic> navigationState;
  final int totalArtCount;
  final int totalPointsEarned;

  const ArtWalkProgress({
    required this.id,
    required this.userId,
    required this.artWalkId,
    this.visitedArt = const <ArtVisit>[],
    required this.startedAt,
    required this.lastActiveAt,
    this.completedAt,
    required this.status,
    this.lastKnownLocation,
    this.currentArtIndex = 0,
    this.navigationState = const <String, dynamic>{},
    this.totalArtCount = 0,
    this.totalPointsEarned = 0,
  });

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (totalArtCount == 0) return 0.0;
    return (visitedArt.length / totalArtCount).clamp(0.0, 1.0);
  }

  /// Total time spent on this walk
  Duration get timeSpent => lastActiveAt.difference(startedAt);

  /// Whether this progress is stale (inactive for >7 days)
  bool get isStale => DateTime.now().difference(lastActiveAt).inDays > 7;

  /// Whether the walk can be completed (80% threshold)
  bool get canComplete => progressPercentage >= 0.8;

  /// Whether the walk is completed
  bool get isCompleted => status == WalkStatus.completed;

  /// Whether the walk is currently active
  bool get isActive => status == WalkStatus.inProgress;

  /// Get next art piece to visit
  int? get nextArtIndex {
    if (currentArtIndex >= totalArtCount) return null;
    return currentArtIndex;
  }

  /// Create from Firestore document
  factory ArtWalkProgress.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtWalkProgress(
      id: doc.id,
      userId: FirestoreUtils.safeStringDefault(data['userId']),
      artWalkId: FirestoreUtils.safeStringDefault(data['artWalkId']),
      visitedArt: (data['visitedArt'] as List<dynamic>?)
              ?.map((item) => ArtVisit.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      startedAt: FirestoreUtils.safeDateTime(data['startedAt']),
      lastActiveAt: FirestoreUtils.safeDateTime(data['lastActiveAt']),
      completedAt: data['completedAt'] != null
          ? FirestoreUtils.safeDateTime(data['completedAt'])
          : null,
      status: WalkStatus.values.firstWhere(
        (e) => e.name == FirestoreUtils.safeString(data['status']),
        orElse: () => WalkStatus.notStarted,
      ),
      lastKnownLocation: data['lastKnownLocation'] as GeoPoint?,
      currentArtIndex: FirestoreUtils.safeInt(data['currentArtIndex']),
      navigationState: Map<String, dynamic>.from(
        data['navigationState'] as Map? ?? {},
      ),
      totalArtCount: FirestoreUtils.safeInt(data['totalArtCount']),
      totalPointsEarned: FirestoreUtils.safeInt(data['totalPointsEarned']),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'artWalkId': artWalkId,
      'visitedArt': visitedArt.map((visit) => visit.toMap()).toList(),
      'startedAt': Timestamp.fromDate(startedAt),
      'lastActiveAt': Timestamp.fromDate(lastActiveAt),
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'status': status.name,
      'lastKnownLocation': lastKnownLocation,
      'currentArtIndex': currentArtIndex,
      'navigationState': navigationState,
      'totalArtCount': totalArtCount,
      'totalPointsEarned': totalPointsEarned,
    };
  }

  /// Create a copy with updated fields
  ArtWalkProgress copyWith({
    String? id,
    String? userId,
    String? artWalkId,
    List<ArtVisit>? visitedArt,
    DateTime? startedAt,
    DateTime? lastActiveAt,
    DateTime? completedAt,
    WalkStatus? status,
    GeoPoint? lastKnownLocation,
    int? currentArtIndex,
    Map<String, dynamic>? navigationState,
    int? totalArtCount,
    int? totalPointsEarned,
  }) {
    return ArtWalkProgress(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      artWalkId: artWalkId ?? this.artWalkId,
      visitedArt: visitedArt ?? this.visitedArt,
      startedAt: startedAt ?? this.startedAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      currentArtIndex: currentArtIndex ?? this.currentArtIndex,
      navigationState: navigationState ?? this.navigationState,
      totalArtCount: totalArtCount ?? this.totalArtCount,
      totalPointsEarned: totalPointsEarned ?? this.totalPointsEarned,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    artWalkId,
    visitedArt,
    startedAt,
    lastActiveAt,
    completedAt,
    status,
    lastKnownLocation,
    currentArtIndex,
    navigationState,
    totalArtCount,
    totalPointsEarned,
  ];
}

/// Represents a visit to an art piece during a walk
class ArtVisit extends Equatable {
  final String artId;
  final DateTime visitedAt;
  final GeoPoint visitLocation;
  final int pointsAwarded;
  final bool wasNearArt;
  final String? photoTaken;
  final double? distanceFromArt;
  final Duration? timeSpentViewing;

  const ArtVisit({
    required this.artId,
    required this.visitedAt,
    required this.visitLocation,
    this.pointsAwarded = 0,
    this.wasNearArt = false,
    this.photoTaken,
    this.distanceFromArt,
    this.timeSpentViewing,
  });

  /// Create from map data
  factory ArtVisit.fromMap(Map<String, dynamic> data) {
    return ArtVisit(
      artId: FirestoreUtils.safeStringDefault(data['artId']),
      visitedAt: FirestoreUtils.safeDateTime(data['visitedAt']),
      visitLocation: data['visitLocation'] as GeoPoint? ?? const GeoPoint(0, 0),
      pointsAwarded: FirestoreUtils.safeInt(data['pointsAwarded']),
      wasNearArt: FirestoreUtils.safeBool(data['wasNearArt'], false),
      photoTaken: FirestoreUtils.safeString(data['photoTaken']),
      distanceFromArt: data['distanceFromArt'] != null
          ? FirestoreUtils.safeDouble(data['distanceFromArt'])
          : null,
      timeSpentViewing: data['timeSpentViewing'] != null
          ? Duration(seconds: FirestoreUtils.safeInt(data['timeSpentViewing']))
          : null,
    );
  }

  /// Convert to map data
  Map<String, dynamic> toMap() {
    return {
      'artId': artId,
      'visitedAt': Timestamp.fromDate(visitedAt),
      'visitLocation': visitLocation,
      'pointsAwarded': pointsAwarded,
      'wasNearArt': wasNearArt,
      'photoTaken': photoTaken,
      'distanceFromArt': distanceFromArt,
      'timeSpentViewing': timeSpentViewing?.inSeconds,
    };
  }

  @override
  List<Object?> get props => [
    artId,
    visitedAt,
    visitLocation,
    pointsAwarded,
    wasNearArt,
    photoTaken,
    distanceFromArt,
    timeSpentViewing,
  ];
}

/// Status of an art walk progress
enum WalkStatus { notStarted, inProgress, paused, completed, abandoned }

/// Extension to get display names for walk status
extension WalkStatusExtension on WalkStatus {
  String get displayName {
    switch (this) {
      case WalkStatus.notStarted:
        return 'Not Started';
      case WalkStatus.inProgress:
        return 'In Progress';
      case WalkStatus.paused:
        return 'Paused';
      case WalkStatus.completed:
        return 'Completed';
      case WalkStatus.abandoned:
        return 'Abandoned';
    }
  }

  String get description {
    switch (this) {
      case WalkStatus.notStarted:
        return 'Ready to begin your art walk adventure';
      case WalkStatus.inProgress:
        return 'Currently exploring art pieces';
      case WalkStatus.paused:
        return 'Take a break and resume anytime';
      case WalkStatus.completed:
        return 'Congratulations on completing this walk!';
      case WalkStatus.abandoned:
        return 'Walk was not completed';
    }
  }
}
