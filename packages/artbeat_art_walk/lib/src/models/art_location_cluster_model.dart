import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'dart:math' as math;
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Represents a cluster of art pieces at similar locations
class ArtLocationCluster extends Equatable {
  final String id;
  final GeoPoint location;
  final List<String> artPieceIds;
  final String primaryArtId;
  final double radius;
  final int contributorCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, int> artPieceVotes; // artId -> vote count
  final ClusterStatus status;

  const ArtLocationCluster({
    required this.id,
    required this.location,
    required this.artPieceIds,
    required this.primaryArtId,
    required this.radius,
    required this.contributorCount,
    required this.createdAt,
    required this.updatedAt,
    required this.artPieceVotes,
    required this.status,
  });

  /// Check if a new art piece is within this cluster's radius
  bool isWithinCluster(GeoPoint artLocation, {double threshold = 50.0}) {
    final distance = _calculateDistance(location, artLocation);
    return distance <= threshold;
  }

  /// Calculate distance between two GeoPoints in meters
  double _calculateDistance(GeoPoint point1, GeoPoint point2) {
    const double earthRadius = 6371000; // Earth's radius in meters

    final double lat1Rad = point1.latitude * (math.pi / 180);
    final double lat2Rad = point2.latitude * (math.pi / 180);
    final double deltaLatRad =
        (point2.latitude - point1.latitude) * (math.pi / 180);
    final double deltaLngRad =
        (point2.longitude - point1.longitude) * (math.pi / 180);

    final double a =
        math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLngRad / 2) *
            math.sin(deltaLngRad / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  /// Get the art piece with the most votes (primary art)
  String selectPrimaryArt() {
    if (artPieceVotes.isEmpty) return artPieceIds.first;

    String bestArtId = artPieceIds.first;
    int maxVotes = 0;

    for (final artId in artPieceIds) {
      final votes = artPieceVotes[artId] ?? 0;
      if (votes > maxVotes) {
        maxVotes = votes;
        bestArtId = artId;
      }
    }

    return bestArtId;
  }

  /// Check if this cluster has multiple art submissions
  bool get hasMultipleSubmissions => artPieceIds.length > 1;

  /// Get the number of alternative submissions
  int get alternativeCount => math.max(0, artPieceIds.length - 1);

  /// Create from Firestore document
  factory ArtLocationCluster.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtLocationCluster(
      id: doc.id,
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      artPieceIds: (data['artPieceIds'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          [],
      primaryArtId: FirestoreUtils.safeStringDefault(data['primaryArtId']),
      radius: FirestoreUtils.safeDouble(data['radius'], 50.0),
      contributorCount: FirestoreUtils.safeInt(data['contributorCount']),
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      updatedAt: FirestoreUtils.safeDateTime(data['updatedAt']),
      artPieceVotes: (data['artPieceVotes'] as Map?)?.map(
            (key, value) => MapEntry(
              FirestoreUtils.safeStringDefault(key),
              FirestoreUtils.safeInt(value),
            ),
          ) ??
          {},
      status: ClusterStatus.values.firstWhere(
        (e) => e.name == FirestoreUtils.safeString(data['status']),
        orElse: () => ClusterStatus.active,
      ),
    );
  }

  /// Convert to Firestore data
  Map<String, dynamic> toFirestore() {
    return {
      'location': location,
      'artPieceIds': artPieceIds,
      'primaryArtId': primaryArtId,
      'radius': radius,
      'contributorCount': contributorCount,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'artPieceVotes': artPieceVotes,
      'status': status.name,
    };
  }

  /// Create a copy with updated fields
  ArtLocationCluster copyWith({
    String? id,
    GeoPoint? location,
    List<String>? artPieceIds,
    String? primaryArtId,
    double? radius,
    int? contributorCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, int>? artPieceVotes,
    ClusterStatus? status,
  }) {
    return ArtLocationCluster(
      id: id ?? this.id,
      location: location ?? this.location,
      artPieceIds: artPieceIds ?? this.artPieceIds,
      primaryArtId: primaryArtId ?? this.primaryArtId,
      radius: radius ?? this.radius,
      contributorCount: contributorCount ?? this.contributorCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      artPieceVotes: artPieceVotes ?? this.artPieceVotes,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    location,
    artPieceIds,
    primaryArtId,
    radius,
    contributorCount,
    createdAt,
    updatedAt,
    artPieceVotes,
    status,
  ];
}

/// Status of an art location cluster
enum ClusterStatus { active, inactive, merged, disputed }
