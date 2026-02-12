import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'dart:math' as math;

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final List<String> details;
  final Color accentColor;

  TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    this.details = const [],
    required this.accentColor,
  });
}

class DiscoverTourOverlay extends StatefulWidget {
  final GlobalKey menuKey;
  final GlobalKey searchKey;
  final GlobalKey chatKey;
  final GlobalKey notificationsKey;
  final GlobalKey heroKey;
  final GlobalKey radarKey;
  final GlobalKey kioskKey;
  final GlobalKey statsKey;
  final GlobalKey goalsKey;
  final GlobalKey socialKey;
  final GlobalKey quickActionsKey;
  final GlobalKey achievementsKey;
  final GlobalKey hotspotsKey;
  final GlobalKey radarTitleKey;
  final VoidCallback onFinish;

  const DiscoverTourOverlay({
    super.key,
    required this.menuKey,
    required this.searchKey,
    required this.chatKey,
    required this.notificationsKey,
    required this.heroKey,
    required this.radarKey,
    required this.kioskKey,
    required this.statsKey,
    required this.goalsKey,
    required this.socialKey,
    required this.quickActionsKey,
    required this.achievementsKey,
    required this.hotspotsKey,
    required this.radarTitleKey,
    required this.onFinish,
  });

  @override
  State<DiscoverTourOverlay> createState() => _DiscoverTourOverlayState();
}

class _DiscoverTourOverlayState extends State<DiscoverTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late List<TourStep> _steps;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _steps = [
      TourStep(
        targetKey: widget.menuKey,
        title: 'OPERATIONS HUB',
        description: 'Access your settings, toolkit, and resource library.',
        accentColor: ArtbeatColors.secondaryTeal,
      ),
      TourStep(
        targetKey: widget.searchKey,
        title: 'ART SCANNER',
        description:
            'Search for specific art walks, artists, or locations across the global network.',
        accentColor: ArtbeatColors.primaryGreen,
      ),
      TourStep(
        targetKey: widget.chatKey,
        title: 'COMMS CHANNEL',
        description:
            'Message other explorers to coordinate art walks or share intel.',
        accentColor: ArtbeatColors.primaryBlue,
      ),
      TourStep(
        targetKey: widget.notificationsKey,
        title: 'INTEL FEED',
        description:
            'Stay updated on new engagement, nearby art walks, and achievement updates.',
        accentColor: ArtbeatColors.primaryPurple,
      ),
      TourStep(
        targetKey: widget.heroKey,
        title: 'EXPLORER COMMAND',
        description:
            'Your central status hub showing your current level, XP progress, and daily mission.',
        details: [
          'Track Level and XP progress',
          'Monitor your daily missions',
          'View active explorer stats',
        ],
        accentColor: const Color(0xFF7C4DFF),
      ),
      TourStep(
        targetKey: widget.radarTitleKey,
        title: 'DISCOVERY RADAR',
        description:
            'Real-time map scanning for nearby art. Tap the radar to begin an instant discovery mission.',
        details: [
          'See nearby art count',
          'Access instant discovery',
          'View local scene highlights',
        ],
        accentColor: const Color(0xFF22D3EE),
      ),
      TourStep(
        targetKey: widget.kioskKey,
        title: 'ARTIST SPOTLIGHT',
        description:
            'Discover featured artists currently showcasing their work in the Kiosk Lane.',
        accentColor: const Color(0xFFFF3D8D),
      ),
      TourStep(
        targetKey: widget.statsKey,
        title: 'EXPLORER STATS',
        description:
            'Your performance metrics at a glance. Keep your streak alive and level up!',
        accentColor: const Color(0xFFFFC857),
      ),
      TourStep(
        targetKey: widget.goalsKey,
        title: 'SEASONAL OBJECTIVES',
        description:
            'Complete long-term goals to earn massive rewards and exclusive badges.',
        accentColor: const Color(0xFF34D399),
      ),
      TourStep(
        targetKey: widget.socialKey,
        title: 'ACTIVITY STREAM',
        description:
            'See what other explorers are discovering in real-time. Join the global conversation.',
        accentColor: const Color(0xFF2947FF),
      ),
      TourStep(
        targetKey: widget.quickActionsKey,
        title: 'RAPID DEPLOYMENT',
        description:
            'Quick access to essential tools and actions for efficient art exploration.',
        accentColor: const Color(0xFFFF6B35),
      ),
      TourStep(
        targetKey: widget.achievementsKey,
        title: 'GLORY VAULT',
        description:
            'Showcase your exploration achievements and unlock exclusive rewards.',
        accentColor: const Color(0xFF9D4EDD),
      ),
      TourStep(
        targetKey: widget.hotspotsKey,
        title: 'HOT ZONE NAVIGATOR',
        description:
            'Discover high-activity art locations and trending discovery spots in your area.',
        accentColor: const Color(0xFF06FFA5),
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

    _ensureStepVisible();
  }

  void _ensureStepVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final screenHeight = MediaQuery.of(context).size.height;
      final targetContext = _steps[_currentStepIndex].targetKey.currentContext;

      if (targetContext != null) {
        final renderBox = targetContext.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;

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
    await OnboardingService().markDiscoverOnboardingCompleted();
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
      final Offset globalPos = renderBox.localToGlobal(Offset.zero);
      final RenderBox? overlayBox = context.findRenderObject() as RenderBox?;
      if (overlayBox != null) {
        position = overlayBox.globalToLocal(globalPos);
      } else {
        position = globalPos;
      }
      size = renderBox.size;
    }

    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    final double targetCenterX = position.dx + size.width / 2;
    final double topSafetyMargin = MediaQuery.of(context).padding.top + 20;

    double? top;
    double? bottom;

    final double spaceBelow = screenHeight - (position.dy + size.height);

    if (position.dy < screenHeight * 0.4) {
      top = position.dy + size.height + 15;
    } else if (spaceBelow > 300) {
      top = position.dy + size.height + 15;
    } else {
      bottom = screenHeight - position.dy + 15;
    }

    if (top != null && top < topSafetyMargin) {
      top = topSafetyMargin;
    }

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
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

          Positioned(
            left: 20,
            right: 20,
            top: top,
            bottom: bottom,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: math.max(
                    0.0,
                    bottom != null
                        ? (screenHeight - bottom - topSafetyMargin)
                        : (screenHeight - (top ?? 0) - 40),
                  ),
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
    final double arrowHorizontalPos = (targetCenterX - 20).clamp(
      20.0,
      screenWidth - 60,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                  Expanded(
                    child: Text(
                      step.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
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
              if (step.details.isNotEmpty) ...[
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
              ],
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
                      letterSpacing: 1,
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
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

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
    final rect = Rect.fromLTWH(0, 0, canvasSize.width, canvasSize.height);
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
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.close();
    } else {
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
