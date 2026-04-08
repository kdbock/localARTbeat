import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:artbeat_art_walk/src/services/go_now_flow_service.dart';
import 'package:artbeat_art_walk/src/services/directions_service.dart';
import 'package:artbeat_art_walk/src/models/navigation_step_model.dart';
import 'package:artbeat_art_walk/src/services/instant_discovery_service.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/services/art_walk_distance_unit_service.dart';

class GoNowNavigationScreen extends StatefulWidget {
  final String pieceId;
  final String title;
  final double latitude;
  final double longitude;
  final String source;
  final bool showAddToWalkAction;

  const GoNowNavigationScreen({
    super.key,
    required this.pieceId,
    required this.title,
    required this.latitude,
    required this.longitude,
    required this.source,
    this.showAddToWalkAction = false,
  });

  @override
  State<GoNowNavigationScreen> createState() => _GoNowNavigationScreenState();
}

class _GoNowNavigationScreenState extends State<GoNowNavigationScreen> {
  static const double _arrivalThresholdMeters = 50.0;
  final GoNowFlowService _goNowFlow = GoNowFlowService();
  final DirectionsService _directionsService = DirectionsService();
  final InstantDiscoveryService _instantDiscoveryService =
      InstantDiscoveryService();
  final ArtWalkDistanceUnitService _distanceUnitService =
      ArtWalkDistanceUnitService();
  Position? _currentPosition;
  StreamSubscription<Position>? _positionSub;
  double? _distanceMeters;
  bool _hasArrived = false;
  bool _isDirectionsLoading = false;
  String? _directionsError;
  List<NavigationStepModel> _steps = <NavigationStepModel>[];
  List<LatLng> _routePoints = <LatLng>[];
  int _currentStepIndex = 0;
  GoogleMapController? _mapController;
  List<PublicArtModel> _nearbyArt = <PublicArtModel>[];
  final List<PublicArtModel> _addedStops = <PublicArtModel>[];
  String _distanceUnit = 'miles';

  @override
  void initState() {
    super.initState();
    _goNowFlow.setStatus(widget.pieceId, GoNowStatus.enRoute);
    _goNowFlow.trackFunnelEvent('navigation_started', <String, Object?>{
      'pieceId': widget.pieceId,
      'source': widget.source,
    });
    _loadDistanceUnit();
    _startTracking();
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }

  Future<void> _startTracking() async {
    try {
      final current = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _updateDistance(current);
      await _loadTurnByTurnRoute(current);
      await _loadNearbyArt(current);
      _positionSub = Geolocator.getPositionStream().listen((pos) {
        if (!mounted) return;
        _updateDistance(pos);
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to read location. You can retry in app.'),
        ),
      );
    }
  }

  Future<void> _loadDistanceUnit() async {
    final unit = await _distanceUnitService.getDistanceUnit();
    if (!mounted) return;
    setState(() => _distanceUnit = unit);
  }

  void _updateDistance(Position position) {
    final distance = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      widget.latitude,
      widget.longitude,
    );
    final hasArrivedNow = distance <= _arrivalThresholdMeters;
    if (hasArrivedNow && !_hasArrived) {
      _goNowFlow.setStatus(widget.pieceId, GoNowStatus.arrived);
      _goNowFlow.trackFunnelEvent('arrival_reached', <String, Object?>{
        'pieceId': widget.pieceId,
        'source': widget.source,
      });
    }

    _updateCurrentStep(position);

    setState(() {
      _currentPosition = position;
      _distanceMeters = distance;
      _hasArrived = hasArrivedNow;
    });
  }

  Future<void> _loadTurnByTurnRoute(Position from) async {
    if (!mounted) return;
    setState(() {
      _isDirectionsLoading = true;
      _directionsError = null;
    });

    final origin = '${from.latitude},${from.longitude}';
    final destination = '${widget.latitude},${widget.longitude}';
    final waypoints = _addedStops
        .map((art) => '${art.location.latitude},${art.location.longitude}')
        .toList(growable: false);

    try {
      final data = await _directionsService.getDirections(
        origin,
        destination,
        useCachedData: true,
        waypoints: waypoints.isEmpty ? null : waypoints,
      );
      final routes = data['routes'] as List<dynamic>? ?? <dynamic>[];
      if (routes.isEmpty) {
        throw Exception('No route geometry returned');
      }

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>? ?? <dynamic>[];
      if (legs.isEmpty) {
        throw Exception('No route legs returned');
      }

      final leg = legs.first as Map<String, dynamic>;
      final stepMaps = leg['steps'] as List<dynamic>? ?? <dynamic>[];
      final steps = stepMaps
          .whereType<Map<String, dynamic>>()
          .map(NavigationStepModel.fromGoogleMapsStep)
          .toList();

      final polylinePoints = <LatLng>[];
      for (final step in steps) {
        if (step.polylinePoints.isNotEmpty) {
          polylinePoints.addAll(step.polylinePoints);
        }
      }

      if (polylinePoints.isEmpty) {
        final overview =
            route['overview_polyline'] as Map<String, dynamic>? ??
            <String, dynamic>{};
        final encoded = overview['points'] as String? ?? '';
        polylinePoints.addAll(NavigationStepModel.decodePolyline(encoded));
      }

      setState(() {
        _steps = steps;
        _routePoints = polylinePoints;
        _currentStepIndex = 0;
        _isDirectionsLoading = false;
      });
    } catch (e) {
      setState(() {
        _directionsError = 'Turn-by-turn unavailable, showing fallback route.';
        _isDirectionsLoading = false;
      });
    }
  }

  void _updateCurrentStep(Position position) {
    if (_steps.isEmpty || _currentStepIndex >= _steps.length) return;

    final currentStep = _steps[_currentStepIndex];
    final remainingToStepEnd = Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      currentStep.endLocation.latitude,
      currentStep.endLocation.longitude,
    );

    if (remainingToStepEnd <= 20 && _currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex += 1;
      });
      _goNowFlow.trackFunnelEvent('step_advanced', <String, Object?>{
        'pieceId': widget.pieceId,
        'source': widget.source,
        'stepIndex': _currentStepIndex,
      });
    }
  }

  Future<void> _loadNearbyArt(Position from) async {
    final nearby = await _instantDiscoveryService.getNearbyArt(
      from,
      radiusMeters: 250,
    );

    if (!mounted) return;
    setState(() {
      _nearbyArt = nearby
          .where((art) => art.id != widget.pieceId)
          .where((art) => !_addedStops.any((added) => added.id == art.id))
          .toList(growable: false);
    });
  }

  double _distanceToRouteMeters(PublicArtModel art) {
    if (_routePoints.length < 2) return double.infinity;
    double minDistance = double.infinity;
    for (int i = 0; i < _routePoints.length - 1; i++) {
      final start = _routePoints[i];
      final end = _routePoints[i + 1];
      final d1 = Geolocator.distanceBetween(
        art.location.latitude,
        art.location.longitude,
        start.latitude,
        start.longitude,
      );
      final d2 = Geolocator.distanceBetween(
        art.location.latitude,
        art.location.longitude,
        end.latitude,
        end.longitude,
      );
      final localMin = d1 < d2 ? d1 : d2;
      if (localMin < minDistance) minDistance = localMin;
    }
    return minDistance;
  }

  Future<void> _showNearbyArtActions(PublicArtModel art) async {
    if (!mounted) return;
    final routeDistance = _distanceToRouteMeters(art);
    final isOnRoute = routeDistance <= 120;
    final classification = isOnRoute ? 'On Route' : 'Nearby Bonus';

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  art.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(classification),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      await _addNearbyArtToWalk(art);
                    },
                    child: const Text('Add to Walk'),
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep Current Route'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addNearbyArtToWalk(PublicArtModel art) async {
    final current = _currentPosition;
    if (current == null) return;

    setState(() {
      _addedStops.add(art);
      _nearbyArt = _nearbyArt.where((a) => a.id != art.id).toList();
    });

    _goNowFlow.trackFunnelEvent('nearby_art_added_to_walk', <String, Object?>{
      'pieceId': widget.pieceId,
      'addedArtId': art.id,
      'source': widget.source,
    });

    await _loadTurnByTurnRoute(current);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${art.title} added to your walk')));
  }

  Future<void> _recenterMap() async {
    final controller = _mapController;
    if (controller == null) return;

    final destination = LatLng(widget.latitude, widget.longitude);
    final currentLatLng = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    final bounds = currentLatLng == null
        ? null
        : LatLngBounds(
            southwest: LatLng(
              currentLatLng.latitude < destination.latitude
                  ? currentLatLng.latitude
                  : destination.latitude,
              currentLatLng.longitude < destination.longitude
                  ? currentLatLng.longitude
                  : destination.longitude,
            ),
            northeast: LatLng(
              currentLatLng.latitude > destination.latitude
                  ? currentLatLng.latitude
                  : destination.latitude,
              currentLatLng.longitude > destination.longitude
                  ? currentLatLng.longitude
                  : destination.longitude,
            ),
          );

    if (bounds != null) {
      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 56));
      return;
    }
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: destination, zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final distance = _distanceMeters;
    final etaMinutes = distance == null ? null : (distance / 84).ceil();
    final formattedDistance = distance == null
        ? null
        : _distanceUnitService.formatDistanceFromMeters(
            distance,
            _distanceUnit,
          );
    final estimatedSteps = distance == null
        ? null
        : _distanceUnitService.estimateStepsFromMeters(distance);
    final destination = LatLng(widget.latitude, widget.longitude);
    final currentLatLng = _currentPosition == null
        ? null
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final polylinePoints = _routePoints.isNotEmpty
        ? _routePoints
        : (currentLatLng == null
              ? <LatLng>[destination]
              : <LatLng>[currentLatLng, destination]);
    final activeStep = (_steps.isNotEmpty && _currentStepIndex < _steps.length)
        ? _steps[_currentStepIndex]
        : null;
    final stepInstruction = activeStep?.cleanInstruction;

    return Scaffold(
      appBar: AppBar(title: const Text('Go Now Navigation')),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.black.withValues(alpha: 0.05),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  distance == null
                      ? 'Locating you...'
                      : 'Walking • ${formattedDistance ?? '--'} • ETA ${etaMinutes ?? 0} min',
                ),
                if (estimatedSteps != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Approx. $estimatedSteps steps remaining'),
                  ),
                if (_isDirectionsLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text('Loading turn-by-turn route...'),
                  ),
                if (stepInstruction != null && stepInstruction.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${activeStep!.maneuverIcon} $stepInstruction (${activeStep.formattedDistance})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                if (_directionsError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _directionsError!,
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ),
                const SizedBox(height: 4),
                const Text(
                  'Stay aware of surroundings while walking.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: destination,
                zoom: 15,
              ),
              onMapCreated: (controller) => _mapController = controller,
              markers: <Marker>{
                Marker(
                  markerId: const MarkerId('destination'),
                  position: destination,
                  infoWindow: InfoWindow(title: widget.title),
                ),
                if (currentLatLng != null)
                  Marker(
                    markerId: const MarkerId('user'),
                    position: currentLatLng,
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueAzure,
                    ),
                    infoWindow: const InfoWindow(title: 'You'),
                  ),
                ..._nearbyArt.map(
                  (art) => Marker(
                    markerId: MarkerId('nearby_${art.id}'),
                    position: LatLng(
                      art.location.latitude,
                      art.location.longitude,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueOrange,
                    ),
                    infoWindow: InfoWindow(
                      title: art.title,
                      snippet: 'Tap to add to walk',
                    ),
                    onTap: () => _showNearbyArtActions(art),
                  ),
                ),
              },
              polylines: <Polyline>{
                Polyline(
                  polylineId: const PolylineId('route'),
                  points: polylinePoints,
                  color: Colors.blueAccent,
                  width: 5,
                ),
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_hasArrived) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _goNowFlow.trackFunnelEvent(
                          'arrival_capture_action',
                          <String, Object?>{
                            'pieceId': widget.pieceId,
                            'source': widget.source,
                          },
                        );
                        Navigator.pop(context, 'arrived_capture');
                      },
                      child: const Text("You're Here - Capture"),
                    ),
                  ),
                  if (widget.showAddToWalkAction) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          _goNowFlow.trackFunnelEvent(
                            'arrival_add_to_walk',
                            <String, Object?>{
                              'pieceId': widget.pieceId,
                              'source': widget.source,
                            },
                          );
                          Navigator.pop(context, 'arrived_add_to_walk');
                        },
                        child: const Text('Add to Walk'),
                      ),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () async {
                          await _startTracking();
                        },
                        child: const Text('Retry'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _recenterMap,
                        child: const Text('Recenter'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          _goNowFlow.setStatus(
                            widget.pieceId,
                            GoNowStatus.skipped,
                          );
                          _goNowFlow.trackFunnelEvent(
                            'navigation_skipped',
                            <String, Object?>{
                              'pieceId': widget.pieceId,
                              'source': widget.source,
                            },
                          );
                          Navigator.pop(context, 'skipped');
                        },
                        child: const Text('Skip'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
