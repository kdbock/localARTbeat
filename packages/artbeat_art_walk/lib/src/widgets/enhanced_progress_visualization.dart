import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'glass_card.dart';

class EnhancedProgressVisualization extends StatefulWidget {
  final int visitedCount;
  final int totalCount;
  final double progressPercentage;
  final bool isNavigationMode;
  final VoidCallback? onTap;

  const EnhancedProgressVisualization({
    super.key,
    required this.visitedCount,
    required this.totalCount,
    required this.progressPercentage,
    this.isNavigationMode = false,
    this.onTap,
  });

  @override
  State<EnhancedProgressVisualization> createState() =>
      _EnhancedProgressVisualizationState();
}

class _EnhancedProgressVisualizationState
    extends State<EnhancedProgressVisualization>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _progressAnimation =
        Tween<double>(begin: 0.0, end: widget.progressPercentage).animate(
          CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
        );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant EnhancedProgressVisualization oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progressPercentage != widget.progressPercentage) {
      _progressAnimation =
          Tween<double>(
            begin: oldWidget.progressPercentage,
            end: widget.progressPercentage,
          ).animate(
            CurvedAnimation(
              parent: _progressController,
              curve: Curves.easeInOut,
            ),
          );
      _progressController
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'art_walk_progress_visualization_label_progress'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.visitedCount}/${widget.totalCount}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.isNavigationMode)
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF22D3EE).withValues(alpha: 0.5),
                        ),
                        color: const Color(0xFF22D3EE).withValues(alpha: 0.12),
                      ),
                      child: Text(
                        'art_walk_progress_visualization_nav_label'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF22D3EE),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 84,
              child: Row(
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _CircularProgressPainter(
                            progress: _progressAnimation.value,
                            isCompleted: widget.progressPercentage >= 1.0,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: LinearProgressIndicator(
                                value: _progressAnimation.value,
                                minHeight: 10,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.12,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  widget.progressPercentage >= 1.0
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF22D3EE),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'art_walk_progress_visualization_label_momentum'
                                      .tr(),
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                                Text(
                                  '${(_progressAnimation.value * 100).round()}%',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: widget.progressPercentage >= 1.0 ? 1.0 : 0.8,
              child: Row(
                children: [
                  Icon(
                    widget.progressPercentage >= 1.0
                        ? Icons.celebration
                        : Icons.local_fire_department,
                    color: widget.progressPercentage >= 1.0
                        ? const Color(0xFF34D399)
                        : const Color(0xFFFFC857),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.progressPercentage >= 1.0
                          ? 'art_walk_progress_visualization_text_completed'
                                .tr()
                          : 'art_walk_progress_visualization_text_discovered'
                                .tr(
                                  namedArgs: {
                                    'count': widget.visitedCount.toString(),
                                  },
                                ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final bool isCompleted;

  _CircularProgressPainter({required this.progress, required this.isCompleted});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawCircle(center, radius, backgroundPaint);

    final gradient = SweepGradient(
      colors: isCompleted
          ? [const Color(0xFF34D399), const Color(0xFF34D399)]
          : [
              const Color(0xFF7C4DFF),
              const Color(0xFF22D3EE),
              const Color(0xFF34D399),
            ],
      startAngle: -math.pi / 2,
      endAngle: (-math.pi / 2) + 2 * math.pi,
    );

    final rect = Rect.fromCircle(center: center, radius: radius);
    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );

    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: isCompleted ? 0.25 : 0.12);
    canvas.drawCircle(center, radius - 18, centerPaint);

    if (isCompleted) {
      final dotPaint = Paint()
        ..color = const Color(0xFF34D399)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 8, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isCompleted != isCompleted;
  }
}

class MiniProgressIndicator extends StatelessWidget {
  final int visitedCount;
  final int totalCount;
  final double progressPercentage;

  const MiniProgressIndicator({
    super.key,
    required this.visitedCount,
    required this.totalCount,
    required this.progressPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CustomPaint(
              painter: _CircularProgressPainter(
                progress: progressPercentage,
                isCompleted: progressPercentage >= 1.0,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$visitedCount/$totalCount',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
