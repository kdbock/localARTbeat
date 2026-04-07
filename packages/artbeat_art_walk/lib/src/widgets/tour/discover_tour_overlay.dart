import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:provider/provider.dart';
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
  late final OnboardingService _onboardingService;

  @override
  void initState() {
    super.initState();
    _onboardingService = context.read<OnboardingService>();
    _steps = [
      TourStep(
        targetKey: widget.heroKey,
        title: 'COMMAND',
        description: 'See your level, XP, and mission progress.',
        accentColor: ArtbeatColors.secondaryTeal,
      ),
      TourStep(
        targetKey: widget.radarTitleKey,
        title: 'RADAR',
        description: 'Scan nearby art and launch instant discovery.',
        accentColor: const Color(0xFF22D3EE),
      ),
      TourStep(
        targetKey: widget.quickActionsKey,
        title: 'QUICK ACTIONS',
        description: 'Jump to your most-used actions.',
        accentColor: const Color(0xFFFF6B35),
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
    await _onboardingService.markDiscoverOnboardingCompleted();
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
    } else {
      // If renderBox is not yet available, return empty to avoid black screen
      return const SizedBox.shrink();
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
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
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
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
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
