import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_art_walk/src/models/models.dart';
import 'dart:math' as math;

/// Service for managing art location clustering to handle duplicate submissions
class ArtLocationClusteringService {
  static final ArtLocationClusteringService _instance =
      ArtLocationClusteringService._internal();
  factory ArtLocationClusteringService() => _instance;
  ArtLocationClusteringService._internal();

  FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

  final Logger _logger = Logger();

  // Collection references
  CollectionReference get _clustersCollection =>
      _firestore.collection('artLocationClusters');
  CollectionReference get _artCollection => _firestore.collection('publicArt');

  // Default clustering parameters
  static const double defaultThreshold = 50.0; // 50 meters
  static const double maxClusterRadius = 100.0; // 100 meters
  static const int minArtPiecesForCluster = 2;

  /// Find or create a cluster for a new art piece
  Future<ArtLocationCluster?> findOrCreateCluster(PublicArtModel newArt) async {
    try {
      // Find existing clusters within threshold distance
      final nearbyClusters = await _findNearbyClusters(
        newArt.location,
        defaultThreshold,
      );

      if (nearbyClusters.isNotEmpty) {
        // Add to existing cluster
        final cluster = nearbyClusters.first;
        return await _addArtToCluster(cluster, newArt.id);
      } else {
        // Create new cluster
        return await _createNewCluster(newArt);
      }
    } catch (e) {
      _logger.e('Error finding or creating cluster: $e');
      return null;
    }
  }

  /// Get clustered art near a location
  Future<List<ArtLocationCluster>> getClusteredArtNearLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
    double clusterThreshold = 50.0,
  }) async {
    try {
      final center = GeoPoint(latitude, longitude);

      // Query clusters within radius
      final query = await _clustersCollection
          .where('status', isEqualTo: ClusterStatus.active.name)
          .get();

      final clusters = <ArtLocationCluster>[];

      for (final doc in query.docs) {
        final cluster = ArtLocationCluster.fromFirestore(doc);
        final distance = ClusteringHelper.calculateDistance(
          center,
          cluster.location,
        );

        if (distance <= radiusKm * 1000) {
          clusters.add(cluster);
        }
      }

      return clusters;
    } catch (e) {
      _logger.e('Error getting clustered art near location: $e');
      return [];
    }
  }

  /// Get all art pieces in a cluster
  Future<List<PublicArtModel>> getArtInCluster(String clusterId) async {
    try {
      final clusterDoc = await _clustersCollection.doc(clusterId).get();
      if (!clusterDoc.exists) return [];

      final cluster = ArtLocationCluster.fromFirestore(clusterDoc);
      final artPieces = <PublicArtModel>[];

      for (final artId in cluster.artPieceIds) {
        final artDoc = await _artCollection.doc(artId).get();
        if (artDoc.exists) {
          artPieces.add(PublicArtModel.fromFirestore(artDoc));
        }
      }

      return artPieces;
    } catch (e) {
      _logger.e('Error getting art in cluster: $e');
      return [];
    }
  }

  /// Vote for primary art in a cluster
  Future<bool> voteForPrimaryArt(String clusterId, String artId) async {
    try {
      final clusterRef = _clustersCollection.doc(clusterId);
      final clusterDoc = await clusterRef.get();

      if (!clusterDoc.exists) return false;

      final cluster = ArtLocationCluster.fromFirestore(clusterDoc);

      if (!cluster.artPieceIds.contains(artId)) return false;

      final updatedVotes = Map<String, int>.from(cluster.artPieceVotes);
      updatedVotes[artId] = (updatedVotes[artId] ?? 0) + 1;

      final newPrimaryArtId = _selectPrimaryArt(
        cluster.artPieceIds,
        updatedVotes,
      );

      await clusterRef.update({
        'artPieceVotes': updatedVotes,
        'primaryArtId': newPrimaryArtId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      _logger.e('Error voting for primary art: $e');
      return false;
    }
  }

  /// Merge two clusters
  Future<bool> mergeClusters(
    String sourceClusterId,
    String targetClusterId,
  ) async {
    try {
      return await _firestore.runTransaction((transaction) async {
        final sourceRef = _clustersCollection.doc(sourceClusterId);
        final targetRef = _clustersCollection.doc(targetClusterId);

        final sourceDoc = await transaction.get(sourceRef);
        final targetDoc = await transaction.get(targetRef);

        if (!sourceDoc.exists || !targetDoc.exists) return false;

        final sourceCluster = ArtLocationCluster.fromFirestore(sourceDoc);
        final targetCluster = ArtLocationCluster.fromFirestore(targetDoc);

        // Merge art pieces
        final mergedArtIds = <String>{
          ...targetCluster.artPieceIds,
          ...sourceCluster.artPieceIds,
        }.toList();

        // Merge votes
        final mergedVotes = Map<String, int>.from(targetCluster.artPieceVotes);
        sourceCluster.artPieceVotes.forEach((artId, votes) {
          mergedVotes[artId] = (mergedVotes[artId] ?? 0) + votes;
        });

        // Calculate new centroid
        final allLocations = [targetCluster.location, sourceCluster.location];
        final newLocation = ClusteringHelper.calculateCentroid(allLocations);

        // Calculate new radius
        final newRadius = ClusteringHelper.calculateOptimalRadius(
          allLocations,
          newLocation,
        );

        // Select new primary art
        final newPrimaryArtId = _selectPrimaryArt(mergedArtIds, mergedVotes);

        // Update target cluster
        transaction.update(targetRef, {
          'artPieceIds': mergedArtIds,
          'artPieceVotes': mergedVotes,
          'location': newLocation,
          'radius': newRadius,
          'primaryArtId': newPrimaryArtId,
          'contributorCount': mergedArtIds.length,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mark source cluster as merged
        transaction.update(sourceRef, {
          'status': ClusterStatus.merged.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        return true;
      });
    } catch (e) {
      _logger.e('Error merging clusters: $e');
      return false;
    }
  }

  /// Add art piece to existing cluster
  Future<ArtLocationCluster?> _addArtToCluster(
    ArtLocationCluster cluster,
    String artId,
  ) async {
    try {
      final clusterRef = _clustersCollection.doc(cluster.id);
      final updatedArtIds = List<String>.from(cluster.artPieceIds);

      if (updatedArtIds.contains(artId)) {
        return cluster; // Already in cluster
      }

      updatedArtIds.add(artId);

      final updatedVotes = Map<String, int>.from(cluster.artPieceVotes);
      updatedVotes[artId] = 1; // Initial vote for new art

      final updatedCluster = cluster.copyWith(
        artPieceIds: updatedArtIds,
        artPieceVotes: updatedVotes,
        contributorCount: updatedArtIds.length,
        updatedAt: DateTime.now(),
      );

      await clusterRef.update(updatedCluster.toFirestore());

      _logger.i('Added art $artId to cluster: ${cluster.id}');
      return updatedCluster;
    } catch (e) {
      _logger.e('Error adding art to cluster: $e');
      return null;
    }
  }

  /// Create a new cluster for an art piece
  Future<ArtLocationCluster> _createNewCluster(PublicArtModel art) async {
    final clusterId = _clustersCollection.doc().id;
    final now = DateTime.now();

    final cluster = ArtLocationCluster(
      id: clusterId,
      location: art.location,
      artPieceIds: [art.id],
      primaryArtId: art.id,
      radius: 25.0, // Default small radius
      contributorCount: 1,
      createdAt: now,
      updatedAt: now,
      artPieceVotes: {art.id: 1},
      status: ClusterStatus.active,
    );

    await _clustersCollection.doc(clusterId).set(cluster.toFirestore());

    _logger.i('Created new cluster: $clusterId for art: ${art.id}');
    return cluster;
  }

  /// Find nearby clusters within threshold distance
  Future<List<ArtLocationCluster>> _findNearbyClusters(
    GeoPoint location,
    double thresholdMeters,
  ) async {
    final query = await _clustersCollection
        .where('status', isEqualTo: ClusterStatus.active.name)
        .get();

    final nearbyClusters = <ArtLocationCluster>[];

    for (final doc in query.docs) {
      final cluster = ArtLocationCluster.fromFirestore(doc);
      final distance = ClusteringHelper.calculateDistance(
        location,
        cluster.location,
      );

      if (distance <= thresholdMeters) {
        nearbyClusters.add(cluster);
      }
    }

    return nearbyClusters;
  }

  /// Select primary art based on votes
  String _selectPrimaryArt(List<String> artIds, Map<String, int> votes) {
    if (artIds.isEmpty) return '';

    String bestArtId = artIds.first;
    int maxVotes = votes[bestArtId] ?? 0;

    for (final artId in artIds) {
      final voteCount = votes[artId] ?? 0;
      if (voteCount > maxVotes) {
        maxVotes = voteCount;
        bestArtId = artId;
      }
    }

    return bestArtId;
  }
}

/// Helper class for clustering algorithms
class ClusteringHelper {
  /// Calculate the centroid (average position) of multiple GeoPoints
  static GeoPoint calculateCentroid(List<GeoPoint> points) {
    if (points.isEmpty) {
      throw ArgumentError('Cannot calculate centroid of empty list');
    }

    double totalLat = 0;
    double totalLng = 0;

    for (final point in points) {
      totalLat += point.latitude;
      totalLng += point.longitude;
    }

    return GeoPoint(totalLat / points.length, totalLng / points.length);
  }

  /// Calculate the optimal radius for a cluster based on its points
  static double calculateOptimalRadius(
    List<GeoPoint> points,
    GeoPoint centroid,
  ) {
    if (points.isEmpty) return 0.0;

    double maxDistance = 0;
    for (final point in points) {
      final distance = _calculateDistance(centroid, point);
      if (distance > maxDistance) {
        maxDistance = distance;
      }
    }

    return math.min(
      maxDistance * 1.2,
      ArtLocationClusteringService.maxClusterRadius,
    );
  }

  /// Check if two points are within clustering threshold
  static bool arePointsWithinThreshold(
    GeoPoint point1,
    GeoPoint point2,
    double threshold,
  ) {
    return _calculateDistance(point1, point2) <= threshold;
  }

  /// Calculate distance between two GeoPoints in meters
  static double calculateDistance(GeoPoint point1, GeoPoint point2) {
    return _calculateDistance(point1, point2);
  }

  /// Calculate distance between two GeoPoints in meters (internal helper)
  static double _calculateDistance(GeoPoint point1, GeoPoint point2) {
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

  /// Find all clusters that should be merged based on proximity
  static List<List<String>> findMergeableClusters(
    List<ArtLocationCluster> clusters,
    double mergeThreshold,
  ) {
    final mergeGroups = <List<String>>[];
    final processedIds = <String>{};

    for (final cluster in clusters) {
      if (processedIds.contains(cluster.id)) continue;

      final group = <String>[cluster.id];
      processedIds.add(cluster.id);

      for (final otherCluster in clusters) {
        if (processedIds.contains(otherCluster.id) ||
            otherCluster.id == cluster.id) {
          continue;
        }

        if (arePointsWithinThreshold(
          cluster.location,
          otherCluster.location,
          mergeThreshold,
        )) {
          group.add(otherCluster.id);
          processedIds.add(otherCluster.id);
        }
      }

      if (group.length > 1) {
        mergeGroups.add(group);
      }
    }

    return mergeGroups;
  }

  /// Validate cluster integrity
  static bool isValidCluster(ArtLocationCluster cluster) {
    return cluster.artPieceIds.length >=
            ArtLocationClusteringService.minArtPiecesForCluster &&
        cluster.radius > 0 &&
        cluster.radius <= ArtLocationClusteringService.maxClusterRadius;
  }
}
