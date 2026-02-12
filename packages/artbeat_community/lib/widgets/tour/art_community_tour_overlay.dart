import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

class ArtCommunityTourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final List<String> details;
  final Color accentColor;

  ArtCommunityTourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.details,
    required this.accentColor,
  });
}

class ArtCommunityTourOverlay extends StatefulWidget {
  final GlobalKey menuKey;
  final GlobalKey titleKey;
  final GlobalKey searchKey;
  final GlobalKey feedTabKey;
  final GlobalKey artistsTabKey;
  final GlobalKey artworkTabKey;
  final GlobalKey commissionsTabKey;
  final GlobalKey fabKey;
  final GlobalKey feedContentKey;
  final GlobalKey artistSpotlightKey;
  final GlobalKey artworkGalleryKey;
  final GlobalKey commissionArtistsKey;
  final VoidCallback onFinish;

  const ArtCommunityTourOverlay({
    super.key,
    required this.menuKey,
    required this.titleKey,
    required this.searchKey,
    required this.feedTabKey,
    required this.artistsTabKey,
    required this.artworkTabKey,
    required this.commissionsTabKey,
    required this.fabKey,
    required this.feedContentKey,
    required this.artistSpotlightKey,
    required this.artworkGalleryKey,
    required this.commissionArtistsKey,
    required this.onFinish,
  });

  @override
  State<ArtCommunityTourOverlay> createState() =>
      _ArtCommunityTourOverlayState();
}

class _ArtCommunityTourOverlayState extends State<ArtCommunityTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late List<ArtCommunityTourStep> _steps;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _steps = [
      // 1-3: Header elements
      ArtCommunityTourStep(
        targetKey: widget.menuKey,
        title: 'COMMUNITY MENU',
        description: 'Access your community toolkit and navigation options.',
        accentColor: ArtbeatColors.secondaryTeal,
        details: [
          'View trending content',
          'Browse artwork collections',
          'Access artist onboarding',
          'Check leaderboards',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.titleKey,
        title: 'ART COMMUNITY HUB',
        description:
            'Your central hub for connecting with artists and art enthusiasts.',
        accentColor: ArtbeatColors.primaryGreen,
        details: [
          'Share your art journey',
          'Discover new artists',
          'Connect with the community',
          'Commission custom artwork',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.searchKey,
        title: 'COMMUNITY SEARCH',
        description:
            'Find specific posts, artists, or artwork within the community.',
        accentColor: ArtbeatColors.primaryBlue,
        details: [
          'Search community posts',
          'Find artists by name',
          'Discover artwork by title',
          'Filter by categories',
        ],
      ),
      // 4-7: Tabs
      ArtCommunityTourStep(
        targetKey: widget.feedTabKey,
        title: 'COMMUNITY FEED',
        description:
            'Stay updated with the latest posts and community activity.',
        accentColor: const Color(0xFF7C4DFF),
        details: [
          'View recent posts',
          'See community discussions',
          'Follow artist updates',
          'Engage with content',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.artistsTabKey,
        title: 'ARTISTS GALLERY',
        description: 'Explore and connect with talented artists in your area.',
        accentColor: const Color(0xFF22D3EE),
        details: [
          'Browse artist profiles',
          'View portfolios',
          'Follow favorite artists',
          'Discover new talent',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.artworkTabKey,
        title: 'ARTWORK DISCOVERY',
        description: 'Browse and discover amazing artwork from the community.',
        accentColor: const Color(0xFFFF3D8D),
        details: [
          'Explore artwork collections',
          'Filter by style and medium',
          'Save favorite pieces',
          'Get inspired',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.commissionsTabKey,
        title: 'COMMISSION MARKET',
        description: 'Find artists to create custom artwork for you.',
        accentColor: const Color(0xFFFFC857),
        details: [
          'Browse available artists',
          'View commission details',
          'Request custom work',
          'Connect with creators',
        ],
      ),
      // 8: FAB
      ArtCommunityTourStep(
        targetKey: widget.fabKey,
        title: 'SHARE YOUR ART',
        description: 'Create and share your own posts with the community.',
        accentColor: const Color(0xFF34D399),
        details: [
          'Share your artwork',
          'Post updates and thoughts',
          'Start discussions',
          'Connect with others',
        ],
      ),
      // 9-12: Content sections
      ArtCommunityTourStep(
        targetKey: widget.feedContentKey,
        title: 'LIVE COMMUNITY FEED',
        description: 'See real-time posts and activity from community members.',
        accentColor: const Color(0xFF2947FF),
        details: [
          'Recent community posts',
          'Artist announcements',
          'Community discussions',
          'Trending content',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.artistSpotlightKey,
        title: 'FEATURED ARTISTS',
        description: 'Discover amazing local artists and their creative work.',
        accentColor: const Color(0xFFFF6B35),
        details: [
          'Artist profiles and bios',
          'Portfolio previews',
          'Commission availability',
          'Contact information',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.artworkGalleryKey,
        title: 'ARTWORK SHOWCASE',
        description: 'Browse beautiful artworks shared by community members.',
        accentColor: const Color(0xFF9D4EDD),
        details: [
          'High-quality art previews',
          'Artist attributions',
          'Style and medium filters',
          'Save and share options',
        ],
      ),
      ArtCommunityTourStep(
        targetKey: widget.commissionArtistsKey,
        title: 'COMMISSION ARTISTS',
        description:
            'Connect with artists who offer custom commission services.',
        accentColor: const Color(0xFF06FFA5),
        details: [
          'Artist specialties',
          'Pricing information',
          'Portfolio samples',
          'Commission process',
        ],
      ),
    ];

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Ensure first step is visible
    _ensureStepVisible();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _ensureStepVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final targetContext = _steps[_currentStepIndex].targetKey.currentContext;
      if (targetContext == null) return;

      final renderBox = targetContext.findRenderObject() as RenderBox?;
      if (renderBox == null) return;

      final position = renderBox.localToGlobal(Offset.zero);
      final size = renderBox.size;
      final screenHeight = MediaQuery.of(targetContext).size.height;

      // Only scroll if the item is not comfortably in view
      // (allowing some margin for the callout box)
      final bool isInView =
          position.dy > 100 &&
          (position.dy + size.height) < (screenHeight - 150);

      if (!isInView && mounted) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  void _nextStep() async {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _ensureStepVisible();
      _animationController.reset();
      _animationController.forward();
    } else {
      // Mark onboarding as completed
      await OnboardingService().markArtCommunityOnboardingCompleted();
      widget.onFinish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];

    // Get target position and size
    final targetContext = step.targetKey.currentContext;
    if (targetContext == null) {
      return const SizedBox.shrink();
    }

    final renderBox = targetContext.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return const SizedBox.shrink();
    }

    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Horizontal center of the target for arrow alignment
    final double targetCenterX = position.dx + size.width / 2;

    // Margin from the notch/camera area at the top
    final double topSafetyMargin = MediaQuery.of(context).padding.top + 20;

    // Position callout based on target position and available space
    double? top;
    double? bottom;

    final double spaceBelow = screenHeight - (position.dy + size.height);

    if (position.dy < screenHeight * 0.4) {
      // Target is in top 40% of screen: place below
      top = position.dy + size.height + 15;
    } else if (spaceBelow > 300) {
      // Plenty of space below
      top = position.dy + size.height + 15;
    } else {
      // Place above
      bottom = screenHeight - position.dy + 15;
    }

    // Safety: if top is too high, push it down
    if (top != null && top < topSafetyMargin) {
      top = topSafetyMargin;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Semi-transparent background
          GestureDetector(
            onTap: _nextStep,
            child: CustomPaint(
              painter: _SpotlightPainter(
                position: position,
                size: size,
                color: Colors.black.withValues(alpha: 0.85),
                accentColor: step.accentColor,
              ),
              size: Size.infinite,
            ),
          ),

          // Callout Content
          Positioned(
            left: 20,
            right: 20,
            top: top,
            bottom: bottom,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: bottom != null
                      ? (screenHeight - bottom - topSafetyMargin)
                      : (screenHeight - (top ?? 0) - 40),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: _buildCalloutContent(
                    step,
                    top != null,
                    bottom != null,
                    targetCenterX: targetCenterX,
                    screenWidth: screenWidth,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalloutContent(
    ArtCommunityTourStep step,
    bool isBelowTarget,
    bool isAboveTarget, {
    required double targetCenterX,
    required double screenWidth,
  }) {
    // Determine which arrow to show and its alignment
    final double arrowHorizontalPos = (targetCenterX - 20).clamp(
      20.0,
      screenWidth - 60,
    );

    return Stack(
      children: [
        // Arrow pointing to target
        if (isBelowTarget)
          Positioned(
            left: arrowHorizontalPos,
            top: -10,
            child: CustomPaint(
              painter: _ArrowPainter(
                color: step.accentColor,
                direction: ArrowDirection.up,
              ),
              size: const Size(20, 10),
            ),
          ),

        if (isAboveTarget)
          Positioned(
            left: arrowHorizontalPos,
            bottom: -10,
            child: CustomPaint(
              painter: _ArrowPainter(
                color: step.accentColor,
                direction: ArrowDirection.down,
              ),
              size: const Size(20, 10),
            ),
          ),

        // Main content card
        GlassCard(
          padding: const EdgeInsets.all(24),
          borderColor: step.accentColor.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 24,
                    decoration: BoxDecoration(
                      color: step.accentColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: step.accentColor.withValues(alpha: 0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    step.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              ...step.details.map(
                (detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: step.accentColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          detail,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'STEP ${_currentStepIndex + 1} OF ${_steps.length}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white.withValues(alpha: 0.4),
                      letterSpacing: 0,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: step.accentColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentStepIndex == _steps.length - 1
                          ? 'GOT IT!'
                          : 'NEXT',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Offset position;
  final Size size;
  final Color color;
  final Color accentColor;

  _SpotlightPainter({
    required this.position,
    required this.size,
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final paint = Paint()..color = color;
    final accentPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Add padding around the target for better visibility
    const double padding = 8.0;
    final expandedPosition = Offset(
      position.dx - padding,
      position.dy - padding,
    );
    final expandedSize = Size(
      size.width + 2 * padding,
      size.height + 2 * padding,
    );

    // Create a path for the spotlight (inverse of the rectangle)
    final path = Path()
      ..addRect(Offset.zero & canvasSize)
      ..addRRect(
        RRect.fromRectAndRadius(
          expandedPosition & expandedSize,
          const Radius.circular(12),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw accent border around target
    final accentRect = RRect.fromRectAndRadius(
      expandedPosition & expandedSize,
      const Radius.circular(12),
    );
    canvas.drawRRect(accentRect, accentPaint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return oldDelegate.position != position ||
        oldDelegate.size != size ||
        oldDelegate.color != color ||
        oldDelegate.accentColor != accentColor;
  }
}

enum ArrowDirection { up, down }

class _ArrowPainter extends CustomPainter {
  final Color color;
  final ArrowDirection direction;

  _ArrowPainter({required this.color, required this.direction});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    if (direction == ArrowDirection.up) {
      path
        ..moveTo(size.width / 2, 0)
        ..lineTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..close();
    } else {
      path
        ..moveTo(size.width / 2, size.height)
        ..lineTo(0, 0)
        ..lineTo(size.width, 0)
        ..close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.direction != direction;
  }
}
