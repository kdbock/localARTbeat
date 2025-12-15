import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

/// Art Walk Hero Section - Makes Art Walk the star of the main dashboard
class ArtWalkHeroSection extends StatefulWidget {
  final VoidCallback onInstantDiscoveryTap;
  final VoidCallback onProfileMenuTap;
  final VoidCallback onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final bool hasNotifications;
  final int notificationCount;

  const ArtWalkHeroSection({
    Key? key,
    required this.onInstantDiscoveryTap,
    required this.onProfileMenuTap,
    required this.onMenuPressed,
    this.onNotificationPressed,
    this.hasNotifications = false,
    this.notificationCount = 0,
  }) : super(key: key);

  @override
  State<ArtWalkHeroSection> createState() => _ArtWalkHeroSectionState();
}

class _ArtWalkHeroSectionState extends State<ArtWalkHeroSection>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late Animation<double> _radarAnimation;

  int _nearbyArtCount = 0;
  int _activeUsersNearby = 0;
  int _userStreak = 0;
  bool _isLoading = true;

  final InstantDiscoveryService _discoveryService = InstantDiscoveryService();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadHeroData();
  }

  void _setupAnimations() {
    _radarController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _radarAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _radarController, curve: Curves.linear));
  }

  Future<void> _loadHeroData() async {
    try {
      // Load nearby art count
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 5),
        ),
      );

      final nearbyArt = await _discoveryService.getNearbyArt(
        position,
        radiusMeters: 500,
      );

      // Load user streak (placeholder - would need to implement)
      // final currentUser = await _userService.getCurrentUserModel();

      if (mounted) {
        setState(() {
          _nearbyArtCount = nearbyArt.length;
          _activeUsersNearby = 0; // Placeholder - would need social service
          _userStreak = 0; // Placeholder - would need streak service
          _isLoading = false;
        });
      }
    } catch (e) {
      // Fallback to demo data if location fails
      if (mounted) {
        setState(() {
          _nearbyArtCount = 3; // Demo data
          _activeUsersNearby = 7; // Demo data
          _userStreak = 2; // Demo data
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryPurple, // Purple
            ArtbeatColors.primaryGreen, // Green
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated radar background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _radarAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: RadarPainter(
                    progress: _radarAnimation.value,
                    nearbyCount: _nearbyArtCount,
                  ),
                );
              },
            ),
          ),

          // Dark overlay for better contrast
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.05),
                  ],
                ),
              ),
            ),
          ),

          // Content overlay
          SafeArea(
            child: Column(
              children: [
                // Header with profile menu
                _buildHeader(),

                // Main content
                Expanded(
                  child: _isLoading
                      ? _buildLoadingState()
                      : _buildHeroContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Menu button
          Material(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: widget.onMenuPressed,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(Icons.menu, color: Colors.white, size: 24),
              ),
            ),
          ),

          // Center: ARTbeat title with logo
          const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.palette, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'ARTbeat',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Right: Action buttons (search, notifications, messaging, profile)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/search'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Notification button with badge
              if (widget.onNotificationPressed != null)
                _buildNotificationButton(),
              if (widget.onNotificationPressed != null)
                const SizedBox(width: 4),
              // Messaging button with unread indicator
              _buildMessagingButton(),
              const SizedBox(width: 4),
              // Profile button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onProfileMenuTap,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.account_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessagingButton() {
    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  // Debug: Check if button is being tapped
                  if (kDebugMode) {
                    print('[DEBUG] Messaging button tapped! Route: /messaging');
                  }

                  // Show immediate feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('dashboard_opening_messages'.tr()),
                      duration: const Duration(seconds: 1),
                    ),
                  );

                  try {
                    await Navigator.pushNamed(context, '/messaging');
                    if (context.mounted) {
                      messagingProvider.refreshUnreadCount();
                    }
                  } catch (error) {
                    // If route navigation fails, show error
                    if (context.mounted) {
                      AppLogger.error('Messaging navigation error: $error');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'dashboard_messaging_error'.tr(
                              namedArgs: {'error': error.toString()},
                            ),
                          ),
                          backgroundColor: Colors.red,
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    }
                  }
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.message_outlined,
                    color: messagingProvider.hasError
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Unread message indicator
            if (messagingProvider.isInitialized &&
                !messagingProvider.hasError &&
                messagingProvider.hasUnreadMessages)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.error,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    messagingProvider.unreadCount > 99
                        ? '99+'
                        : messagingProvider.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationButton() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              widget.onNotificationPressed?.call();
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: const Icon(
                Icons.notifications_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ),
        // Notification badge
        if (widget.hasNotifications)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: ArtbeatColors.error,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                widget.notificationCount > 99
                    ? '99+'
                    : widget.notificationCount.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 16),
          Text(
            'Finding nearby art...',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dynamic messaging based on nearby art
            _buildDynamicMessage(),

            const SizedBox(height: 8),

            // Social proof
            if (_activeUsersNearby > 0)
              Text(
                '$_activeUsersNearby art explorers active nearby',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 14,
                ),
              ),

            const SizedBox(height: 24),

            // Call to action button
            _buildActionButton(),

            const SizedBox(height: 16),

            // Streak indicator
            if (_userStreak > 0) _buildStreakIndicator(),
          ],
        ),
      ),
    );
  }

  Widget _buildDynamicMessage() {
    String title;
    String subtitle;
    String emoji;

    if (_nearbyArtCount == 0) {
      title = 'Explore somewhere exciting!';
      subtitle = 'Find art hotspots in your city';
      emoji = '';
    } else if (_nearbyArtCount == 1) {
      title = 'One hidden artwork nearby!';
      subtitle = 'Ready for discovery?';
      emoji = '🎨';
    } else if (_nearbyArtCount < 5) {
      title = '$_nearbyArtCount artworks waiting!';
      subtitle = 'Your art adventure awaits';
      emoji = '🎯';
    } else {
      title = '$_nearbyArtCount artworks nearby!';
      subtitle = 'Art hunt time!';
      emoji = '🔥';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ArtBeat logo (only show when no nearby art)
        if (_nearbyArtCount == 0) ...[
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: Image.asset(
              'packages/artbeat_core/assets/images/artbeat_logo.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 16),
        ],
        // Text content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (emoji.isNotEmpty) ...[
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onInstantDiscoveryTap,
          borderRadius: BorderRadius.circular(25),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar, color: Color(0xFF4FB3BE), size: 20),
                const SizedBox(width: 8),
                Text(
                  _nearbyArtCount > 0
                      ? 'Start Discovering'
                      : 'Find Art Hotspots',
                  style: const TextStyle(
                    color: Color(0xFF4FB3BE),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStreakIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$_userStreak day streak!',
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for animated radar background
class RadarPainter extends CustomPainter {
  final double progress;
  final int nearbyCount;

  RadarPainter({required this.progress, required this.nearbyCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw radar circles
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 3; i++) {
      final radius = maxRadius * (i / 3);
      canvas.drawCircle(center, radius, circlePaint);
    }

    // Draw sweeping radar line
    final sweepPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final sweepAngle = progress * 2 * 3.14159; // Full circle
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxRadius),
      -3.14159 / 2, // Start from top
      sweepAngle,
      false,
      sweepPaint,
    );

    // Draw art indicators (simplified)
    if (nearbyCount > 0) {
      final artPaint = Paint()
        ..color = Colors.orange
        ..style = PaintingStyle.fill;

      // Draw some sample art dots around the radar
      for (int i = 0; i < nearbyCount && i < 5; i++) {
        final angle = (i * 2 * 3.14159) / nearbyCount;
        final distance = maxRadius * 0.6;
        final x = center.dx + distance * math.cos(angle);
        final y = center.dy + distance * math.sin(angle);
        canvas.drawCircle(Offset(x, y), 4, artPaint);
      }
    }
  }

  @override
  bool shouldRepaint(RadarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.nearbyCount != nearbyCount;
  }
}
