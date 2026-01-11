import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:artbeat_sponsorships/artbeat_sponsorships.dart';
import 'package:artbeat_art_walk/src/models/public_art_model.dart';
import 'package:artbeat_art_walk/src/services/instant_discovery_service.dart';
import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';

/// Particle class for radar background animation
class RadarParticle {
  double x;
  double y;
  double vx;
  double vy;
  double opacity;
  double size;
  Color color;
  IconData icon;

  RadarParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.opacity,
    required this.size,
    required this.color,
    required this.icon,
  });

  void update() {
    x += vx;
    y += vy;

    // Wrap around edges
    if (x > 1.0) x = 0.0;
    if (x < 0.0) x = 1.0;
    if (y > 1.0) y = 0.0;
    if (y < 0.0) y = 1.0;

    // Subtle opacity animation
    opacity =
        0.1 +
        (math.sin(DateTime.now().millisecondsSinceEpoch * 0.001 + x * 10) *
            0.1);
  }
}

/// Radar widget showing nearby art in Pokemon Go style
class InstantDiscoveryRadar extends StatefulWidget {
  final Position userPosition;
  final List<PublicArtModel> nearbyArt;
  final double radiusMeters;
  final void Function(PublicArtModel art, double distance)? onArtTap;

  const InstantDiscoveryRadar({
    super.key,
    required this.userPosition,
    required this.nearbyArt,
    this.radiusMeters = 500,
    this.onArtTap,
  });

  @override
  State<InstantDiscoveryRadar> createState() => _InstantDiscoveryRadarState();
}

class _InstantDiscoveryRadarState extends State<InstantDiscoveryRadar>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  late AnimationController _particleController;
  late AnimationController _gridController;
  final InstantDiscoveryService _discoveryService = InstantDiscoveryService();

  // Discovery statistics
  int _todayDiscoveries = 0;
  int _streakCount = 0;

  // Particles for background animation
  final List<RadarParticle> _particles = [];

  // Achievement system
  final List<String> _recentAchievements = [];

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _gridController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _initializeParticles();
    _loadDiscoveryStats();
  }

  void _initializeParticles() {
    final random = math.Random();
    final artIcons = [
      Icons.palette,
      Icons.brush,
      Icons.color_lens,
      Icons.draw,
      Icons.art_track,
    ];

    for (int i = 0; i < 15; i++) {
      _particles.add(
        RadarParticle(
          x: random.nextDouble(),
          y: random.nextDouble(),
          vx: (random.nextDouble() - 0.5) * 0.002,
          vy: (random.nextDouble() - 0.5) * 0.002,
          opacity: 0.1 + random.nextDouble() * 0.1,
          size: 8 + random.nextDouble() * 4,
          color: random.nextBool()
              ? ArtWalkDesignSystem.primaryTeal
              : ArtWalkDesignSystem.accentOrange,
          icon: artIcons[random.nextInt(artIcons.length)],
        ),
      );
    }
  }

  void _loadDiscoveryStats() {
    // Simulate loading discovery statistics
    setState(() {
      _todayDiscoveries = 3;
      _streakCount = 7;
      _checkAchievements();
    });
  }

  void _checkAchievements() {
    if (_todayDiscoveries >= 5 &&
        !_recentAchievements.contains('Art Explorer')) {
      _recentAchievements.add('🎨 Art Explorer - Discovered 5 artworks today!');
    }
    if (_streakCount >= 7 && !_recentAchievements.contains('Week Warrior')) {
      _recentAchievements.add('🔥 Week Warrior - 7 day discovery streak!');
    }
    if (widget.nearbyArt.length >= 10 &&
        !_recentAchievements.contains('Art Magnet')) {
      _recentAchievements.add('🧲 Art Magnet - 10+ artworks in range!');
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    _gridController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            ArtWalkDesignSystem.backgroundGradientStart,
            ArtWalkDesignSystem.backgroundGradientEnd,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Radar
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: _buildRadar(),
                ),
              ),
            ),
          ),
          // Overlays moved below
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [_buildStatsWidget(), _buildMiniMapWidget()],
            ),
          ),
          // Sponsor Banner
          SponsorBanner(
            placementKey: SponsorshipPlacements.discoverRadarBanner,
            userLocation: LatLng(
              widget.userPosition.latitude,
              widget.userPosition.longitude,
            ),
            showPlaceholder: true,
            onPlaceholderTap: () => Navigator.pushNamed(
              context,
              '/discover-sponsorship',
            ),
          ),
          // Art list
          _buildArtList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: ArtWalkDesignSystem.glassDecoration(borderRadius: 0),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.maybePop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Instant Discovery',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: ArtWalkDesignSystem.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.nearbyArt.length} artworks nearby',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: ArtWalkDesignSystem.textSecondary,
                        ),
                      ),
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) {
                          final timeRemaining =
                              3 - (_sweepController.value * 3);
                          return Text(
                            'Next scan: ${timeRemaining.toStringAsFixed(1)}s',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: ArtWalkDesignSystem.accentOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: ArtWalkDesignSystem.primaryTeal,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.radar, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.radiusMeters.toInt()}m',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadar() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _particleController,
        _pulseController,
        _gridController,
      ]),
      builder: (context, child) {
        // Update particles
        for (var particle in _particles) {
          particle.update();
        }

        return CustomPaint(
          painter: EnhancedRadarPainter(
            sweepAnimation: _sweepController,
            pulseAnimation: _pulseController,
            gridAnimation: _gridController,
            particleAnimation: _particleController,
            userPosition: widget.userPosition,
            nearbyArt: widget.nearbyArt,
            radiusMeters: widget.radiusMeters,
            particles: _particles,
          ),
          child: Stack(
            children: [
              // 1. Pulse rings for close art (bottom) - IgnorePointer is now inside
              ..._buildPulseRings(),
              // 2. Discovery trails (visual paths) - These are CustomPaint, not Positioned
              ..._buildDiscoveryTrails().map((w) => IgnorePointer(child: w)),
              // 3. User position (center) with compass
              Center(child: IgnorePointer(child: _buildEnhancedUserPin())),
              // 4. Art pins with enhanced effects (top - most interactive)
              ...widget.nearbyArt.map((art) => _buildEnhancedArtPin(art)),
            ],
          ),
        );
      },
    );
  }

  // Overlay widgets
  Widget _buildMiniMapWidget() {
    return Container(
      width: 80,
      height: 80,
      decoration: ArtWalkDesignSystem.glassDecoration(borderRadius: 12),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  ArtWalkDesignSystem.primaryTeal,
                  ArtWalkDesignSystem.accentOrange,
                ],
              ),
            ),
            child: const Center(
              child: Icon(Icons.map, color: Colors.white, size: 24),
            ),
          ),
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: ArtWalkDesignSystem.accentOrange,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsWidget() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ArtWalkDesignSystem.glassDecoration(borderRadius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.star,
                color: ArtWalkDesignSystem.accentOrange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Today: $_todayDiscoveries',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: ArtWalkDesignSystem.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department,
                color: ArtWalkDesignSystem.accentOrange,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Streak: $_streakCount',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: ArtWalkDesignSystem.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.nearbyArt.length} nearby',
            style: const TextStyle(
              fontSize: 10,
              color: ArtWalkDesignSystem.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // Enhanced radar elements
  List<Widget> _buildPulseRings() {
    return widget.nearbyArt
        .where((art) {
          final distance = _discoveryService.calculateDistance(
            widget.userPosition,
            art,
          );
          return distance < 100; // Show pulse for close art
        })
        .map((art) {
          return AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final bearing = Geolocator.bearingBetween(
                widget.userPosition.latitude,
                widget.userPosition.longitude,
                art.location.latitude,
                art.location.longitude,
              );

              final angleRadians = (bearing - 90) * math.pi / 180;
              final distance = _discoveryService.calculateDistance(
                widget.userPosition,
                art,
              );
              final normalizedDistance = (distance / widget.radiusMeters).clamp(
                0.0,
                1.0,
              );

              final x =
                  0.5 + (normalizedDistance * 0.45 * math.cos(angleRadians));
              final y =
                  0.5 + (normalizedDistance * 0.45 * math.sin(angleRadians));

              return Positioned.fill(
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment((x - 0.5) * 2, (y - 0.5) * 2),
                    child: Container(
                      width: 60 + (_pulseController.value * 20),
                      height: 60 + (_pulseController.value * 20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ArtWalkDesignSystem.accentOrange.withValues(
                            alpha: 0.3 * (1 - _pulseController.value),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        })
        .toList();
  }

  List<Widget> _buildDiscoveryTrails() {
    // Show path suggestions as dotted lines to nearby art
    final closeArt = widget.nearbyArt.where((art) {
      final distance = _discoveryService.calculateDistance(
        widget.userPosition,
        art,
      );
      return distance < 200; // Show paths to art within 200m
    }).toList();

    return closeArt.map((art) {
      final bearing = Geolocator.bearingBetween(
        widget.userPosition.latitude,
        widget.userPosition.longitude,
        art.location.latitude,
        art.location.longitude,
      );

      final angleRadians = (bearing - 90) * math.pi / 180;
      final distance = _discoveryService.calculateDistance(
        widget.userPosition,
        art,
      );
      final normalizedDistance = (distance / widget.radiusMeters).clamp(
        0.0,
        1.0,
      );

      final x = 0.5 + (normalizedDistance * 0.45 * math.cos(angleRadians));
      final y = 0.5 + (normalizedDistance * 0.45 * math.sin(angleRadians));

      return AnimatedBuilder(
        animation: _gridController,
        builder: (context, child) {
          return CustomPaint(
            size: const Size.square(400),
            painter: PathSuggestionPainter(
              startX: 0.5,
              startY: 0.5,
              endX: x,
              endY: y,
              animation: _gridController.value,
            ),
          );
        },
      );
    }).toList();
  }

  Widget _buildEnhancedUserPin() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Compass rose
        AnimatedBuilder(
          animation: _gridController,
          builder: (context, child) {
            return Transform.rotate(
              angle: _gridController.value * 2 * math.pi,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: ArtWalkDesignSystem.primaryTeal.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
                child: const Stack(
                  children: [
                    // Compass directions
                    Positioned(
                      top: 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 2,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          'W',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 2,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Text(
                          'E',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        // User pin
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.2),
          duration: const Duration(milliseconds: 1000),
          curve: Curves.easeInOut,
          builder: (context, scale, child) {
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: ArtWalkDesignSystem.accentOrange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: ArtWalkDesignSystem.accentOrange.withValues(
                        alpha: 0.5,
                      ),
                      blurRadius: 15,
                      spreadRadius: 3,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.my_location,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            );
          },
          onEnd: () {
            setState(() {}); // Restart animation
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedArtPin(PublicArtModel art) {
    final distance = _discoveryService.calculateDistance(
      widget.userPosition,
      art,
    );
    final bearing = Geolocator.bearingBetween(
      widget.userPosition.latitude,
      widget.userPosition.longitude,
      art.location.latitude,
      art.location.longitude,
    );

    final angleRadians = (bearing - 90) * math.pi / 180;
    final normalizedDistance = (distance / widget.radiusMeters).clamp(0.0, 1.0);
    final x = 0.5 + (normalizedDistance * 0.45 * math.cos(angleRadians));
    final y = 0.5 + (normalizedDistance * 0.45 * math.sin(angleRadians));

    final isClose = distance < 100;
    final isVeryClose = distance < 50;

    return Positioned.fill(
      child: Align(
        alignment: Alignment((x - 0.5) * 2, (y - 0.5) * 2),
        child: GestureDetector(
          onTap: () => widget.onArtTap?.call(art, distance),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Rarity glow for special art
              if (art.description.toLowerCase().contains('rare'))
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 50 + (_pulseController.value * 10),
                      height: 50 + (_pulseController.value * 10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            const Color(0xFFFFD700).withValues(
                              alpha: 0.3 * (1 - _pulseController.value),
                            ),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    );
                  },
                ),
              // Art marker
              TweenAnimationBuilder<double>(
                tween: Tween(
                  begin: 0.9,
                  end: isVeryClose ? 1.4 : (isClose ? 1.2 : 1.0),
                ),
                duration: Duration(milliseconds: isClose ? 600 : 1200),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isVeryClose
                            ? const Color(0xFFFFD700)
                            : (isClose
                                  ? ArtWalkDesignSystem.accentOrange
                                  : ArtWalkDesignSystem.primaryTeal),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (isVeryClose
                                        ? const Color(0xFFFFD700)
                                        : (isClose
                                              ? ArtWalkDesignSystem.accentOrange
                                              : ArtWalkDesignSystem
                                                    .primaryTeal))
                                    .withValues(alpha: 0.6),
                            blurRadius: isVeryClose ? 20 : (isClose ? 15 : 8),
                            spreadRadius: isVeryClose ? 4 : (isClose ? 3 : 1),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _getArtTypeIcon(art.description),
                            color: Colors.white,
                            size: 20,
                          ),
                          // Distance indicator
                          if (isClose)
                            Positioned(
                              bottom: -2,
                              right: -2,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${distance.round()}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 8,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
                onEnd: () {
                  if (isClose) setState(() {}); // Keep animating for close art
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getArtTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'mural':
        return Icons.wallpaper;
      case 'sculpture':
        return Icons.view_in_ar;
      case 'installation':
        return Icons.architecture;
      case 'graffiti':
        return Icons.brush;
      default:
        return Icons.palette;
    }
  }

  Widget _buildArtList() {
    if (widget.nearbyArt.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: ArtWalkDesignSystem.textSecondaryDark,
            ),
            const SizedBox(height: 16),
            Text(
              'No art nearby',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: ArtWalkDesignSystem.textSecondaryDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try moving to a different location',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: ArtWalkDesignSystem.textSecondaryDark,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: ArtWalkDesignSystem.glassDecoration(borderRadius: 0),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: widget.nearbyArt.length,
        itemBuilder: (context, index) {
          final art = widget.nearbyArt[index];
          final distance = _discoveryService.calculateDistance(
            widget.userPosition,
            art,
          );
          return _buildArtListItem(art, distance);
        },
      ),
    );
  }

  Widget _buildArtListItem(PublicArtModel art, double distance) {
    final proximityMessage = _discoveryService.getProximityMessage(distance);
    final isClose = distance < 100;
    final isVeryClose = distance < 50;
    final isAccessible =
        art.description.toLowerCase().contains('wheelchair') ||
        art.description.toLowerCase().contains('accessible');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isVeryClose
                    ? ArtWalkDesignSystem.accentOrange
                    : (isClose
                          ? ArtWalkDesignSystem.accentOrange
                          : ArtWalkDesignSystem.primaryTeal),
                borderRadius: BorderRadius.circular(8),
                boxShadow: isClose
                    ? [
                        BoxShadow(
                          color: ArtWalkDesignSystem.accentOrange.withValues(
                            alpha: 0.4,
                          ),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                _getArtTypeIcon(art.description),
                color: Colors.white,
                size: 24,
              ),
            ),
            if (isAccessible)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.accessible,
                    color: Colors.white,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                art.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ArtWalkDesignSystem.textPrimaryDark,
                ),
              ),
            ),
            if (art.description.toLowerCase().contains('rare'))
              const Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (art.artistName != null)
              Text(
                'by ${art.artistName}',
                style: const TextStyle(
                  color: ArtWalkDesignSystem.textSecondaryDark,
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    proximityMessage,
                    style: TextStyle(
                      color: isVeryClose
                          ? const Color(0xFFFFD700)
                          : (isClose
                                ? ArtWalkDesignSystem.accentOrange
                                : ArtWalkDesignSystem.primaryTeal),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isClose)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ArtWalkDesignSystem.accentOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'CLOSE!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            if (isAccessible)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  'Wheelchair accessible',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${distance.toInt()}m',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Icon(
              Icons.arrow_forward,
              size: 16,
              color: ArtWalkDesignSystem.textSecondary,
            ),
          ],
        ),
        onTap: () => widget.onArtTap?.call(art, distance),
      ),
    );
  }
}

/// Custom painter for radar background
class EnhancedRadarPainter extends CustomPainter {
  final Animation<double> sweepAnimation;
  final Animation<double> pulseAnimation;
  final Animation<double> gridAnimation;
  final Animation<double> particleAnimation;
  final Position userPosition;
  final List<PublicArtModel> nearbyArt;
  final double radiusMeters;
  final List<RadarParticle> particles;

  EnhancedRadarPainter({
    required this.sweepAnimation,
    required this.pulseAnimation,
    required this.gridAnimation,
    required this.particleAnimation,
    required this.userPosition,
    required this.nearbyArt,
    required this.radiusMeters,
    required this.particles,
  }) : super(
         repaint: Listenable.merge([
           sweepAnimation,
           pulseAnimation,
           gridAnimation,
           particleAnimation,
         ]),
       );

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw animated grid pattern
    _drawAnimatedGrid(canvas, size, center, radius);

    // Draw particles
    _drawParticles(canvas, size);

    // Draw topographical lines
    _drawTopographicalLines(canvas, center, radius);

    // Draw heat map overlay
    _drawHeatMapOverlay(canvas, center, radius);

    // Draw enhanced distance rings with labels
    _drawEnhancedDistanceRings(canvas, center, radius);

    // Draw pulse rings
    _drawPulseRings(canvas, center, radius);

    // Draw sweep line with enhanced effects
    _drawEnhancedSweepLine(canvas, center, radius);

    // Draw crosshairs with compass
    _drawEnhancedCrosshairs(canvas, center, radius);

    // Draw scanner trails
    _drawScannerTrails(canvas, center, radius);
  }

  void _drawAnimatedGrid(
    Canvas canvas,
    Size size,
    Offset center,
    double radius,
  ) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const gridSpacing = 20.0;
    final offset = gridAnimation.value * gridSpacing;

    // Vertical lines
    for (double x = -offset; x < size.width + gridSpacing; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = -offset; y < size.height + gridSpacing; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawParticles(Canvas canvas, Size size) {
    for (var particle in particles) {
      final position = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      // Draw particle as small icon
      final textPainter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(particle.icon.codePoint),
          style: TextStyle(
            fontSize: particle.size,
            fontFamily: particle.icon.fontFamily,
            color: particle.color.withValues(alpha: particle.opacity),
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        position - Offset(particle.size / 2, particle.size / 2),
      );
    }
  }

  void _drawTopographicalLines(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw organic, terrain-like contour lines
    final random = math.Random(42); // Fixed seed for consistency
    for (int i = 0; i < 5; i++) {
      final path = Path();
      final points = <Offset>[];

      for (int j = 0; j <= 360; j += 15) {
        final angle = j * math.pi / 180;
        final variation = random.nextDouble() * 0.1 + 0.3 + (i * 0.15);
        final r = radius * variation;
        final point = Offset(
          center.dx + r * math.cos(angle),
          center.dy + r * math.sin(angle),
        );
        points.add(point);
      }

      if (points.isNotEmpty) {
        path.moveTo(points.first.dx, points.first.dy);
        for (int k = 1; k < points.length; k++) {
          path.lineTo(points[k].dx, points[k].dy);
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawHeatMapOverlay(Canvas canvas, Offset center, double radius) {
    // Create density-based color overlay
    if (nearbyArt.length >= 3) {
      final paint = Paint()
        ..color = ArtWalkDesignSystem.accentOrange.withValues(alpha: 0.1);

      canvas.drawCircle(center, radius * 0.3, paint);
    }
  }

  void _drawEnhancedDistanceRings(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw 3 rings with labels (100m, 250m, 500m)
    final rings = [
      {'radius': 0.2, 'distance': '100m'},
      {'radius': 0.5, 'distance': '250m'},
      {'radius': 0.9, 'distance': '500m'},
    ];

    for (var ring in rings) {
      final ringRadius = radius * ((ring['radius'] as num?)?.toDouble() ?? 0);
      canvas.drawCircle(center, ringRadius, paint);

      // Draw distance labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: ring['distance'] as String,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: ArtWalkDesignSystem.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx + ringRadius - textPainter.width / 2,
          center.dy - ringRadius - textPainter.height - 4,
        ),
      );
    }
  }

  void _drawPulseRings(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.accentOrange.withValues(
        alpha: 0.2 * (1 - pulseAnimation.value),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pulseRadius = radius * 0.1 * (1 + pulseAnimation.value * 2);
    canvas.drawCircle(center, pulseRadius, paint);
  }

  void _drawEnhancedSweepLine(Canvas canvas, Offset center, double radius) {
    final sweepAngle = sweepAnimation.value * 2 * math.pi;

    // Enhanced gradient for sweep
    final gradient = SweepGradient(
      colors: [
        ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.0),
        ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.4),
        ArtWalkDesignSystem.accentOrange.withValues(alpha: 0.3),
        ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
      transform: GradientRotation(sweepAngle),
    );

    final paint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      );

    canvas.drawCircle(center, radius * 0.9, paint);

    // Draw sweep line
    final linePaint = Paint()
      ..color = ArtWalkDesignSystem.accentOrange.withValues(alpha: 0.6)
      ..strokeWidth = 2;

    final endPoint = Offset(
      center.dx + (radius * 0.9) * math.cos(sweepAngle - math.pi / 2),
      center.dy + (radius * 0.9) * math.sin(sweepAngle - math.pi / 2),
    );

    canvas.drawLine(center, endPoint, linePaint);
  }

  void _drawEnhancedCrosshairs(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - radius * 0.9, center.dy),
      Offset(center.dx + radius * 0.9, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.9),
      Offset(center.dx, center.dy + radius * 0.9),
      paint,
    );

    // Compass directions
    const textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: ArtWalkDesignSystem.textSecondary,
    );

    // North
    final northPainter = TextPainter(
      text: const TextSpan(text: 'N', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    northPainter.layout();
    northPainter.paint(
      canvas,
      Offset(center.dx - 6, center.dy - radius * 0.95 - 15),
    );

    // South
    final southPainter = TextPainter(
      text: const TextSpan(text: 'S', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    southPainter.layout();
    southPainter.paint(
      canvas,
      Offset(center.dx - 6, center.dy + radius * 0.95 + 5),
    );

    // East
    final eastPainter = TextPainter(
      text: const TextSpan(text: 'E', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    eastPainter.layout();
    eastPainter.paint(
      canvas,
      Offset(center.dx + radius * 0.95 + 5, center.dy - 6),
    );

    // West
    final westPainter = TextPainter(
      text: const TextSpan(text: 'W', style: textStyle),
      textDirection: TextDirection.ltr,
    );
    westPainter.layout();
    westPainter.paint(
      canvas,
      Offset(center.dx - radius * 0.95 - 15, center.dy - 6),
    );
  }

  void _drawScannerTrails(Canvas canvas, Offset center, double radius) {
    // Draw fading trails behind the sweep line for discovered art
    final sweepAngle = sweepAnimation.value * 2 * math.pi;

    for (int i = 1; i <= 5; i++) {
      final trailAngle = sweepAngle - (i * 0.1);
      final alpha = 0.3 * (1 - i / 5);

      final paint = Paint()
        ..color = ArtWalkDesignSystem.accentOrange.withValues(alpha: alpha)
        ..strokeWidth = 1;

      final endPoint = Offset(
        center.dx + (radius * 0.9) * math.cos(trailAngle - math.pi / 2),
        center.dy + (radius * 0.9) * math.sin(trailAngle - math.pi / 2),
      );

      canvas.drawLine(center, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(EnhancedRadarPainter oldDelegate) {
    return oldDelegate.nearbyArt != nearbyArt ||
        oldDelegate.userPosition != userPosition ||
        oldDelegate.particles != particles;
  }
}

/// Painter for drawing path suggestions
class PathSuggestionPainter extends CustomPainter {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double animation;

  PathSuggestionPainter({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = ArtWalkDesignSystem.accentOrange.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final startPoint = Offset(startX * size.width, startY * size.height);
    final endPoint = Offset(endX * size.width, endY * size.height);

    // Create a curved path
    final controlPoint = Offset(
      (startPoint.dx + endPoint.dx) / 2 +
          (math.sin(animation * 2 * math.pi) * 20),
      (startPoint.dy + endPoint.dy) / 2,
    );

    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      controlPoint.dx,
      controlPoint.dy,
      endPoint.dx,
      endPoint.dy,
    );

    // Draw dotted line effect
    final pathMetrics = path.computeMetrics();
    final pathMetric = pathMetrics.first;

    for (double i = 0; i < pathMetric.length; i += 10) {
      final start = pathMetric.extractPath(i, i + 5);
      canvas.drawPath(start, paint);
    }
  }

  @override
  bool shouldRepaint(PathSuggestionPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}
