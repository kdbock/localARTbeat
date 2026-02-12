import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

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

class CaptureTourOverlay extends StatefulWidget {
  final GlobalKey menuKey;
  final GlobalKey searchKey;
  final GlobalKey chatKey;
  final GlobalKey notificationsKey;
  final GlobalKey profileKey;
  final GlobalKey questTrackerKey;
  final GlobalKey communityPulseKey;
  final GlobalKey recentLootKey;
  final GlobalKey communityInspirationKey;
  final GlobalKey quickCaptureKey;
  final VoidCallback onFinish;

  const CaptureTourOverlay({
    super.key,
    required this.menuKey,
    required this.searchKey,
    required this.chatKey,
    required this.notificationsKey,
    required this.profileKey,
    required this.questTrackerKey,
    required this.communityPulseKey,
    required this.recentLootKey,
    required this.communityInspirationKey,
    required this.quickCaptureKey,
    required this.onFinish,
  });

  @override
  State<CaptureTourOverlay> createState() => _CaptureTourOverlayState();
}

class _CaptureTourOverlayState extends State<CaptureTourOverlay> with SingleTickerProviderStateMixin {
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
        title: 'OPERATIONS MENU',
        description: 'Access your settings, toolkit, and resource library.',
        accentColor: ArtbeatColors.secondaryTeal,
      ),
      TourStep(
        targetKey: widget.searchKey,
        title: 'ART SCANNER',
        description: 'Search for specific captures, artists, or locations across the global network.',
        accentColor: ArtbeatColors.primaryGreen,
      ),
      TourStep(
        targetKey: widget.chatKey,
        title: 'COMMS CHANNEL',
        description: 'Message other hunters to coordinate drops or share Intel.',
        accentColor: ArtbeatColors.primaryBlue,
      ),
      TourStep(
        targetKey: widget.notificationsKey,
        title: 'INTEL FEED',
        description: 'Stay updated on new engagement, nearby drops, and mission updates.',
        accentColor: ArtbeatColors.primaryPurple,
      ),
      TourStep(
        targetKey: widget.profileKey,
        title: 'YOUR IDENTITY',
        description: 'View your rank, achievements, and your public art collection.',
        accentColor: ArtbeatColors.accentYellow,
      ),
      TourStep(
        targetKey: widget.questTrackerKey,
        title: 'ACTIVE MISSIONS',
        description: 'Complete daily challenges to earn XP and level up your Hunter rank.',
        details: [
          'Daily Drop: Capture 3 pieces of art',
          'Community Scout: Engage with others',
          'Map Block: Explore new neighborhoods',
        ],
        accentColor: const Color(0xFF34D399),
      ),
      TourStep(
        targetKey: widget.communityPulseKey,
        title: 'NEIGHBORHOOD BEAT',
        description: 'Real-time stats showing the activity of fellow art hunters in your area.',
        details: [
          'See active hunters nearby',
          'Track new drops in the last 24h',
        ],
        accentColor: const Color(0xFF22D3EE),
      ),
      TourStep(
        targetKey: widget.recentLootKey,
        title: 'YOUR COLLECTION',
        description: 'Quick access to your most recent art captures and their current status.',
        accentColor: const Color(0xFF7C4DFF),
      ),
      TourStep(
        targetKey: widget.communityInspirationKey,
        title: 'HUNTER INSPIRATION',
        description: 'See what other hunters are discovering to find new spots for your next mission.',
        accentColor: const Color(0xFFFFC857),
      ),
      TourStep(
        targetKey: widget.quickCaptureKey,
        title: 'DEPLOY CAMERA',
        description: 'The primary tool for every mission. Tap here to start capturing art instantly.',
        accentColor: ArtbeatColors.accentYellow,
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      
      final context = _steps[_currentStepIndex].targetKey.currentContext;
      if (context != null) {
        final renderBox = context.findRenderObject() as RenderBox?;
        if (renderBox != null) {
          final position = renderBox.localToGlobal(Offset.zero);
          final size = renderBox.size;
          final screenHeight = MediaQuery.of(this.context).size.height;
          
          final bool isInView = position.dy > 100 && (position.dy + size.height) < (screenHeight - 150);
          
          if (!isInView) {
            await Scrollable.ensureVisible(
              context,
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
    await OnboardingService().markCaptureOnboardingCompleted();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStepIndex];
    final RenderBox? renderBox = step.targetKey.currentContext?.findRenderObject() as RenderBox?;
    
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
    
    final bool isBottomNav = _currentStepIndex == 9;
    final double targetCenterX = position.dx + size.width / 2;
    final double topSafetyMargin = MediaQuery.of(context).padding.top + 20;
    
    double? top;
    double? bottom;
    
    final double spaceBelow = screenHeight - (position.dy + size.height);
    
    if (isBottomNav) {
      bottom = screenHeight - position.dy + 15;
    } else if (position.dy < screenHeight * 0.4) {
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
                  maxHeight: bottom != null ? (screenHeight - bottom - topSafetyMargin) : (screenHeight - (top ?? 0) - 40),
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
    bool isAboveTarget,
    {required double targetCenterX, required double screenWidth}
  ) {
    final double arrowHorizontalPos = (targetCenterX - 20).clamp(20.0, screenWidth - 60);

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
                ...step.details.map((detail) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 14, color: step.accentColor),
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
                )),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      _currentStepIndex == _steps.length - 1 ? 'GOT IT!' : 'NEXT',
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
    position != oldDelegate.position || size != oldDelegate.size || accentColor != oldDelegate.accentColor;
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
