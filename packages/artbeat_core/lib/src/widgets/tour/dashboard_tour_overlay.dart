import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/artbeat_colors.dart';
import '../../theme/glass_card.dart';
import '../../services/onboarding_service.dart';
import 'tour_step.dart';

class DashboardTourOverlay extends StatefulWidget {
  final GlobalKey menuKey;
  final GlobalKey xpKey;
  final GlobalKey profileKey;
  final GlobalKey settingsKey;
  final GlobalKey captureKey;
  final GlobalKey discoverKey;
  final GlobalKey exploreKey;
  final GlobalKey communityKey;
  final GlobalKey homeNavKey;
  final GlobalKey walkNavKey;
  final GlobalKey captureNavKey;
  final GlobalKey communityNavKey;
  final GlobalKey eventsNavKey;
  final VoidCallback onFinish;

  const DashboardTourOverlay({
    super.key,
    required this.menuKey,
    required this.xpKey,
    required this.profileKey,
    required this.settingsKey,
    required this.captureKey,
    required this.discoverKey,
    required this.exploreKey,
    required this.communityKey,
    required this.homeNavKey,
    required this.walkNavKey,
    required this.captureNavKey,
    required this.communityNavKey,
    required this.eventsNavKey,
    required this.onFinish,
  });

  @override
  State<DashboardTourOverlay> createState() => _DashboardTourOverlayState();
}

class _DashboardTourOverlayState extends State<DashboardTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late List<TourStep> _steps;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _steps = [
      // 1-4 Top navigation
      TourStep(
        targetKey: widget.menuKey,
        title: 'MAIN MENU',
        description: 'Access your full toolkit and resources.',
        accentColor: ArtbeatColors.secondaryTeal,
        details: [
          'View your collections',
          'Explore art by local artists',
          'Get help and support',
        ],
      ),
      TourStep(
        targetKey: widget.xpKey,
        title: 'PROGRESS TRACKER',
        description: 'Monitor your growth and daily consistency.',
        accentColor: ArtbeatColors.primaryGreen,
        details: [
          'Track Level and XP progress',
          'Keep your daily Streak alive',
          'See your current XP bar',
        ],
      ),
      TourStep(
        targetKey: widget.profileKey,
        title: 'YOUR IDENTITY',
        description: 'Customize how the art world sees you.',
        accentColor: ArtbeatColors.accentYellow,
        details: [
          'Edit your public bio',
          'View your shared captures',
          'Check your achievements',
        ],
      ),
      TourStep(
        targetKey: widget.settingsKey,
        title: 'PREFERENCES',
        description: 'Tailor the app experience to your needs.',
        accentColor: ArtbeatColors.primaryPurple,
        details: [
          'Manage notifications',
          'Change language settings',
          'Adjust privacy options',
        ],
      ),
      // 5-8 Middle
      TourStep(
        targetKey: widget.captureKey,
        title: 'CAPTURE ART',
        description: 'The core tool for documentating your finds.',
        accentColor: ArtbeatColors.primaryPurple,
        details: [
          'Take high-quality art photos',
          'Add locations to your finds',
          'Share with the community',
        ],
      ),
      TourStep(
        targetKey: widget.discoverKey,
        title: 'DISCOVER QUESTS',
        description: 'Find new art through guided challenges.',
        accentColor: ArtbeatColors.primaryBlue,
        details: [
          'Join local art missions',
          'Earn unique rewards',
          'Follow curated paths',
        ],
      ),
      TourStep(
        targetKey: widget.exploreKey,
        title: 'EXPLORE MAP',
        description: 'A birds-eye view of art around you.',
        accentColor: ArtbeatColors.primaryGreen,
        details: [
          'See all nearby artwork',
          'Find upcoming events',
          'Plan your art routes',
        ],
      ),
      TourStep(
        targetKey: widget.communityKey,
        title: 'COMMUNITY HUB',
        description: 'Connect with fellow art enthusiasts.',
        accentColor: ArtbeatColors.accentOrange,
        details: [
          'See trending art posts',
          'Follow your favorite artists',
          'Comment and give feedback',
        ],
      ),
      // 9-13 Bottom navigation
      TourStep(
        targetKey: widget.homeNavKey,
        title: 'HOME BASE',
        description: 'Your central starting point for everything.',
        accentColor: ArtbeatColors.secondaryTeal,
        details: ['Quick return to dashboard', 'View latest highlights'],
      ),
      TourStep(
        targetKey: widget.walkNavKey,
        title: 'ART WALKS',
        description: 'Embark on curated walking tours.',
        accentColor: ArtbeatColors.primaryBlue,
        details: ['Discover themed routes', 'Learn about local history'],
      ),
      TourStep(
        targetKey: widget.captureNavKey,
        title: 'QUICK CAPTURE',
        description: 'Launch the camera instantly.',
        accentColor: ArtbeatColors.accentYellow,
        details: ['Never miss a piece of art', 'One-tap camera access'],
      ),
      TourStep(
        targetKey: widget.communityNavKey,
        title: 'SOCIAL FEED',
        description: 'The heartbeat of the art community.',
        accentColor: ArtbeatColors.accentOrange,
        details: ['See what others are finding', 'Stay connected on the go'],
      ),
      TourStep(
        targetKey: widget.eventsNavKey,
        title: 'ART EVENTS',
        description: 'Local happenings you won\'t want to miss.',
        accentColor: ArtbeatColors.primaryPurple,
        details: [
          'Exhibitions and gallery openings',
          'Community art workshops',
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

  void _ensureStepVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final context = _steps[_currentStepIndex].targetKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final screenHeight = MediaQuery.of(this.context).size.height;

          // Only scroll if the item is not comfortably in view
          // (allowing some margin for the callout box)
          final bool isInView =
              position.dy > 100 &&
              (position.dy + size.height) < (screenHeight - 150);

          if (!isInView && mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.5,
            );
          }

          // Recalculate and rebuild immediately
          if (mounted) setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _animationController.reset();
      _animationController.forward();
      _ensureStepVisible();
    } else {
      _finish();
    }
  }

  void _finish() async {
    await OnboardingService().markOnboardingCompleted();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];
    final RenderBox? renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;

    Offset position = Offset.zero;
    Size size = Size.zero;

    if (renderBox != null) {
      position = renderBox.localToGlobal(Offset.zero);
      size = renderBox.size;
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    // Steps 9-13 (indices 8-12) are bottom navigation
    final bool isBottomNav = _currentStepIndex >= 8;

    // Horizontal center of the target for arrow alignment
    final double targetCenterX = position.dx + size.width / 2;

    // Margin from the notch/camera area at the top
    final double topSafetyMargin = MediaQuery.of(context).padding.top + 20;

    // Position callout based on target position and available space
    double? top;
    double? bottom;

    final double spaceBelow = screenHeight - (position.dy + size.height);

    if (isBottomNav) {
      // Bottom nav items: ALWAYS place callout above them
      bottom = screenHeight - position.dy + 15;
    } else if (position.dy < screenHeight * 0.4) {
      // Target is in top 40% of screen: ALWAYS place below
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
    TourStep step,
    bool isBelowTarget,
    bool isAboveTarget, {
    required double targetCenterX,
    required double screenWidth,
  }) {
    // Determine which arrow to show and its alignment
    // arrowPadding helps align it directly under/above the target
    // targetCenterX is global, so we need to offset it by the Positioned's left (20)
    final double arrowHorizontalPos = (targetCenterX - 20).clamp(
      20.0,
      screenWidth - 60,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arrow pointing up to target (if card is BELOW target)
        if (isBelowTarget)
          Padding(
            padding: EdgeInsets.only(left: arrowHorizontalPos - 20),
            child: _buildArrow(true, step.accentColor),
          ),

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

        // Arrow pointing down to target (if card is ABOVE target)
        if (isAboveTarget)
          Padding(
            padding: EdgeInsets.only(left: arrowHorizontalPos - 20),
            child: _buildArrow(false, step.accentColor),
          ),
      ],
    );
  }

  Widget _buildArrow(bool pointingUp, Color color) {
    return Container(
      width: 40,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: CustomPaint(
        painter: _ArrowPainter(pointingUp: pointingUp, color: color),
      ),
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

    // The mask
    final rect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);

    // The spotlight hole (with padding)
    final RRect hole = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx - 12,
        position.dy - 12,
        size.width + 24,
        size.height + 24,
      ),
      const Radius.circular(24),
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(rect),
        Path()..addRRect(hole),
      ),
      paint,
    );

    // Draw a neon border around the hole to make it "seen"
    final borderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 4);

    canvas.drawRRect(hole, borderPaint);

    final solidBorderPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(hole, solidBorderPaint);
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) =>
      position != oldDelegate.position ||
      size != oldDelegate.size ||
      accentColor != oldDelegate.accentColor;
}

class _ArrowPainter extends CustomPainter {
  final bool pointingUp;
  final Color color;

  _ArrowPainter({required this.pointingUp, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (pointingUp) {
      // Simple sharp triangle pointing up
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      // Simple sharp triangle pointing down
      path.moveTo(size.width / 2, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
      path.close();
    }
    canvas.drawShadow(path, color.withValues(alpha: 0.8), 8, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ExploreTourOverlay extends StatefulWidget {
  final GlobalKey menuKey;
  final GlobalKey titleKey;
  final GlobalKey searchKey;
  final GlobalKey locationKey;
  final GlobalKey forYouTabKey;
  final GlobalKey exploreTabKey;
  final GlobalKey communityTabKey;
  final GlobalKey artistSpotlightKey;
  final GlobalKey artworkGalleryKey;
  final GlobalKey browseSectionKey;
  final VoidCallback onFinish;

  const ExploreTourOverlay({
    super.key,
    required this.menuKey,
    required this.titleKey,
    required this.searchKey,
    required this.locationKey,
    required this.forYouTabKey,
    required this.exploreTabKey,
    required this.communityTabKey,
    required this.artistSpotlightKey,
    required this.artworkGalleryKey,
    required this.browseSectionKey,
    required this.onFinish,
  });

  @override
  State<ExploreTourOverlay> createState() => _ExploreTourOverlayState();
}

class _ExploreTourOverlayState extends State<ExploreTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late List<TourStep> _steps;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _steps = [
      // Step 1: Main Menu
      TourStep(
        targetKey: widget.menuKey,
        title: 'MAIN MENU',
        description: 'Access your full toolkit and resources.',
        accentColor: ArtbeatColors.secondaryTeal,
        details: [
          'View your collections',
          'Explore art by local artists',
          'Get help and support',
        ],
      ),
      // Step 2: Dashboard Title
      TourStep(
        targetKey: widget.titleKey,
        title: 'LOCAL ART DASHBOARD',
        description: 'Your personalized gateway to local art discovery.',
        accentColor: ArtbeatColors.primaryGreen,
        details: [
          'Curated content just for you',
          'Explore trending local artists',
          'Discover nearby art scenes',
        ],
      ),
      // Step 3: Search Bar
      TourStep(
        targetKey: widget.searchKey,
        title: 'ART SEARCH',
        description: 'Find specific artists, artworks, or locations instantly.',
        accentColor: ArtbeatColors.primaryBlue,
        details: [
          'Search by artist name',
          'Find artworks by title',
          'Locate art in specific areas',
        ],
      ),
      // Step 4: Location Indicator
      TourStep(
        targetKey: widget.locationKey,
        title: 'YOUR LOCATION',
        description: 'See art based on your current location.',
        accentColor: ArtbeatColors.primaryPurple,
        details: [
          'Location-based recommendations',
          'Nearby art discovery',
          'Local artist spotlights',
        ],
      ),
      // Step 5: For You Tab
      TourStep(
        targetKey: widget.forYouTabKey,
        title: 'PERSONALIZED FOR YOU',
        description: 'Curated content tailored to your interests.',
        accentColor: const Color(0xFF7C4DFF),
        details: [
          'Artist spotlights near you',
          'Recommended artworks',
          'Upcoming local events',
        ],
      ),
      // Step 6: Explore Tab
      TourStep(
        targetKey: widget.exploreTabKey,
        title: 'DISCOVER MORE',
        description: 'Browse all available artists and artworks.',
        accentColor: const Color(0xFF22D3EE),
        details: [
          'Complete artist galleries',
          'Full artwork collections',
          'Browse by category',
        ],
      ),
      // Step 7: Community Tab
      TourStep(
        targetKey: widget.communityTabKey,
        title: 'JOIN THE COMMUNITY',
        description: 'Connect with fellow art enthusiasts and artists.',
        accentColor: const Color(0xFFFF3D8D),
        details: [
          'See community posts',
          'Follow your favorite artists',
          'Join art discussions',
        ],
      ),
      // Step 8: Artist Spotlight
      TourStep(
        targetKey: widget.artistSpotlightKey,
        title: 'FEATURED ARTIST',
        description: 'Discover amazing local artists and their work.',
        accentColor: const Color(0xFFFFC857),
        details: [
          'View artist portfolios',
          'Learn about their background',
          'See upcoming exhibitions',
        ],
      ),
      // Step 9: Artwork Gallery
      TourStep(
        targetKey: widget.artworkGalleryKey,
        title: 'ARTWORK GALLERY',
        description: 'Browse beautiful artworks from local creators.',
        accentColor: const Color(0xFF34D399),
        details: [
          'High-quality art previews',
          'Artist attribution',
          'Quick access to details',
        ],
      ),
      // Step 10: Browse Gateway
      TourStep(
        targetKey: widget.browseSectionKey,
        title: 'BROWSE ALL CONTENT',
        description: 'Access the complete art database and filters.',
        accentColor: const Color(0xFF2947FF),
        details: [
          'Advanced search options',
          'Filter by style, medium, price',
          'Save favorite artworks',
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

  void _ensureStepVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final context = _steps[_currentStepIndex].targetKey.currentContext;
      if (context != null && context.mounted) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null && mounted) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final screenHeight = MediaQuery.of(this.context).size.height;

          // Only scroll if the item is not comfortably in view
          // (allowing some margin for the callout box)
          final bool isInView =
              position.dy > 100 &&
              (position.dy + size.height) < (screenHeight - 150);

          if (!isInView && context.mounted && mounted) {
            Scrollable.ensureVisible(
              context,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
              alignment: 0.5,
            );
          }

          // Recalculate and rebuild immediately
          if (mounted) setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      _animationController.reset();
      _animationController.forward();
      _ensureStepVisible();
    } else {
      _finish();
    }
  }

  void _finish() async {
    await OnboardingService().markExploreOnboardingCompleted();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];
    final RenderBox? renderBox =
        step.targetKey.currentContext?.findRenderObject() as RenderBox?;

    Offset position = Offset.zero;
    Size size = Size.zero;

    if (renderBox != null) {
      position = renderBox.localToGlobal(Offset.zero);
      size = renderBox.size;
    }

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
      // Target is in top 40% of screen: ALWAYS place below
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
    TourStep step,
    bool isBelowTarget,
    bool isAboveTarget, {
    required double targetCenterX,
    required double screenWidth,
  }) {
    // Determine which arrow to show and its alignment
    // arrowPadding helps align it directly under/above the target
    // targetCenterX is global, so we need to offset it by the Positioned's left (20)
    final double arrowHorizontalPos = (targetCenterX - 20).clamp(
      20.0,
      screenWidth - 60,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Arrow pointing up to target (if card is BELOW target)
        if (isBelowTarget)
          Padding(
            padding: EdgeInsets.only(left: arrowHorizontalPos - 20),
            child: _buildArrow(true, step.accentColor),
          ),

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

        // Arrow pointing down to target (if card is ABOVE target)
        if (isAboveTarget)
          Padding(
            padding: EdgeInsets.only(left: arrowHorizontalPos - 20),
            child: _buildArrow(false, step.accentColor),
          ),
      ],
    );
  }

  Widget _buildArrow(bool pointingUp, Color color) {
    return Container(
      width: 40,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: CustomPaint(
        painter: _ArrowPainter(pointingUp: pointingUp, color: color),
      ),
    );
  }
}
