import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class EventsTourOverlay extends StatefulWidget {
  final GlobalKey menuKey;
  final GlobalKey heroKey;
  final GlobalKey searchKey;
  final GlobalKey statsKey;
  final GlobalKey categoryKey;
  final GlobalKey featuredKey;
  final GlobalKey quickActionsKey;
  final GlobalKey nearMeKey;
  final GlobalKey trendingKey;
  final GlobalKey weekendKey;
  final GlobalKey ticketsKey;
  final GlobalKey createKey;
  final VoidCallback onFinish;

  const EventsTourOverlay({
    super.key,
    required this.menuKey,
    required this.heroKey,
    required this.searchKey,
    required this.statsKey,
    required this.categoryKey,
    required this.featuredKey,
    required this.quickActionsKey,
    required this.nearMeKey,
    required this.trendingKey,
    required this.weekendKey,
    required this.ticketsKey,
    required this.createKey,
    required this.onFinish,
  });

  @override
  State<EventsTourOverlay> createState() => _EventsTourOverlayState();
}

class _EventsTourOverlayState extends State<EventsTourOverlay>
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late List<TourStep> _steps;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late OnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = context.read<OnboardingService>();
    _steps = [
      TourStep(
        targetKey: widget.searchKey,
        title: 'SEARCH',
        description: 'Find events, artists, or venues quickly.',
        accentColor: ArtbeatColors.secondaryTeal,
        details: const [],
      ),
      TourStep(
        targetKey: widget.featuredKey,
        title: 'FEATURED',
        description: 'See highlighted upcoming events.',
        accentColor: const Color(0xFF22D3EE),
        details: const [],
      ),
      TourStep(
        targetKey: widget.createKey,
        title: 'CREATE',
        description: 'Publish your own event to the community.',
        accentColor: const Color(0xFF9D4EDD),
        details: const [],
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Shorter delay to allow layout to settle
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final context = _steps[_currentStepIndex].targetKey.currentContext;
      if (context != null && context.mounted) {
        final renderObject = context.findRenderObject();
        if (renderObject != null) {
          // Try to scroll the target into view
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.5,
          );
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
    await _onboardingService.markEventsOnboardingCompleted();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];
    final renderObject = step.targetKey.currentContext?.findRenderObject();

    Offset position = Offset.zero;
    Size size = Size.zero;

    if (renderObject != null) {
      if (renderObject is RenderBox) {
        position = renderObject.localToGlobal(Offset.zero);
        size = renderObject.size;
      } else if (renderObject is RenderSliver) {
        // Handle sliver render objects
        final sliver = renderObject;
        final geometry = sliver.geometry;
        if (geometry != null) {
          // Get the paint bounds of the sliver
          final paintBounds = sliver.paintBounds;
          // For slivers, paintBounds are relative to the viewport
          position = paintBounds.topLeft;
          size = paintBounds.size;
        }
      }
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;

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
    final double topSafetyMargin = MediaQuery.of(context).padding.top + 20;
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

          // Skip Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 10,
            child: TextButton(
              onPressed: _finish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              child: Text(
                'SKIP',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
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
                    targetCenterX: position.dx + size.width / 2,
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
          padding: const EdgeInsets.all(18),
          borderColor: step.accentColor.withValues(alpha: 0.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: step.accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'QUICK TOUR',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.9),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(height: 10),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                step.description,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentStepIndex + 1}/${_steps.length}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
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
                      _currentStepIndex == _steps.length - 1 ? 'DONE' : 'NEXT',
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
      path.moveTo(size.width / 2, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, paint);

    // Add glow effect
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 3);

    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(_ArrowPainter oldDelegate) => color != oldDelegate.color;
}
