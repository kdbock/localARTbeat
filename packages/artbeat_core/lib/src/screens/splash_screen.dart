import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/user_sync_helper.dart';
import '../utils/performance_monitor.dart';

/// Splash screen that matches the "Quest / Glass / Neon" theme.
/// - Keeps your existing auth + navigation logic
/// - Dark ambient world background + subtle radar rings
/// - Logo "breathes" with a neon aura
/// - Optional tiny "LOADING" HUD text
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _heartbeatController;
  late final AnimationController _loopController;
  late final Animation<double> _scaleAnimation;

  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      UserSyncHelper.resetState();
    }

    _heartbeatController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );

    _loopController = AnimationController(
      duration: const Duration(seconds: 9),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOutCubic)),
        weight: 1,
      ),
    ]).animate(_heartbeatController);

    // Skip looping animations in test mode.
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      _heartbeatController.repeat();
      _loopController.repeat();
      _checkAuthAndNavigate();
    }
  }

  Future<void> _checkAuthAndNavigate() async {
    if (_hasNavigated) return;

    await Future<void>.delayed(const Duration(seconds: 5));
    if (!mounted || _hasNavigated) return;

    try {
      if (Firebase.apps.isEmpty) {
        if (!mounted || _hasNavigated) return;
        _hasNavigated = true;
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (Route<dynamic> route) => false,
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _syncUserInBackground();
      }

      FocusScope.of(context).unfocus();

      const String route = '/dashboard';
      PerformanceMonitor.startTimer('dashboard_navigation');

      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;

      Navigator.of(context).pushNamedAndRemoveUntil(
        route,
        (Route<dynamic> route) => false,
      );
    } catch (_) {
      if (!mounted || _hasNavigated) return;
      _hasNavigated = true;
      FocusScope.of(context).unfocus();
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (Route<dynamic> route) => false,
      );
    }
  }

  void _syncUserInBackground() {
    Future.delayed(Duration.zero, () async {
      try {
        await UserSyncHelper.ensureUserDocumentExists()
            .timeout(const Duration(seconds: 5));
      } on TimeoutException {
        // ignore
      } catch (_) {
        // ignore
      }
    });
  }

  @override
  void dispose() {
    _heartbeatController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Ambient "world" background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loopController,
              builder: (_, __) => CustomPaint(
                painter: _SplashWorldPainter(t: _loopController.value),
                size: Size.infinite,
              ),
            ),
          ),

          // Soft vignette to focus center
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.15,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.70),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Glass" halo card with logo
                AnimatedBuilder(
                  animation: Listenable.merge([_heartbeatController, _loopController]),
                  builder: (context, child) {
                    final t = _loopController.value;
                    final pulse =
                        0.60 + 0.40 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));

                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(32),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            width: math.min(320, size.width * 0.78),
                            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.12),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.45),
                                  blurRadius: 34,
                                  offset: const Offset(0, 18),
                                ),
                                BoxShadow(
                                  color: const Color(0xFF22D3EE)
                                      .withValues(alpha: 0.10 * pulse),
                                  blurRadius: 38,
                                  spreadRadius: 1,
                                ),
                                BoxShadow(
                                  color: const Color(0xFF7C4DFF)
                                      .withValues(alpha: 0.10 * pulse),
                                  blurRadius: 38,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                // Logo
                                SizedBox(
                                  width: 210,
                                  height: 210,
                                  child: Image.asset(
                                    'assets/images/splashTRANS_logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Icon(
                                        Icons.image_not_supported_rounded,
                                        size: 96,
                                        color: Colors.white.withValues(alpha: 0.55),
                                      );
                                    },
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // App name lockup
                                RichText(
                                  text: TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "Local ",
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white.withValues(alpha: 0.90),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "ART",
                                        style: GoogleFonts.dmSerifDisplay(
                                          color: const Color(0xFFFFC857),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      TextSpan(
                                        text: "beat",
                                        style: GoogleFonts.spaceGrotesk(
                                          color: Colors.white.withValues(alpha: 0.90),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: -0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  "SCAVENGE • CAPTURE • QUEST",
                                  style: GoogleFonts.spaceGrotesk(
                                    color: Colors.white.withValues(alpha: 0.58),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // Tiny loading HUD
                AnimatedBuilder(
                  animation: _loopController,
                  builder: (_, __) {
                    final p = 0.35 +
                        0.65 *
                            (0.5 +
                                0.5 *
                                    math.sin(_loopController.value * 2 * math.pi));
                    return Opacity(
                      opacity: p,
                      child: Text(
                        "LOADING…",
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.2,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashWorldPainter extends CustomPainter {
  final double t;
  _SplashWorldPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Dark base gradient
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Ambient blobs
    _blob(canvas, size, const Color(0xFFFF3D8D), 0.20, 0.22, 0.42, phase: 0.00);
    _blob(canvas, size, const Color(0xFF7C4DFF), 0.80, 0.22, 0.34, phase: 0.20);
    _blob(canvas, size, const Color(0xFFFFC857), 0.76, 0.78, 0.50, phase: 0.45);
    _blob(canvas, size, const Color(0xFF34D399), 0.16, 0.80, 0.42, phase: 0.62);
    _blob(canvas, size, const Color(0xFF22D3EE), 0.52, 0.56, 0.46, phase: 0.78);

    // Radar rings (subtle)
    final center = Offset(size.width * 0.5, size.height * 0.48);
    final maxR = size.width * 0.62;

    for (int i = 1; i <= 4; i++) {
      final r = maxR * (i / 4.0);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.035);
      canvas.drawCircle(center, r, p);
    }

    // Sweep arc (very subtle)
    final angle = t * 2 * math.pi;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * 0.95),
      angle - 0.55,
      0.75,
      false,
      arcPaint,
    );

    // Tracing rings (thin outlines that "draw")
    for (int i = 1; i <= 3; i++) {
      final r = maxR * (0.18 + i * 0.14);
      final phase = (t + i * 0.17) % 1.0;
      final sweep = 2 * math.pi * (0.25 + 0.55 * phase);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.04 + 0.03 * phase)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: r),
        phase * 2 * math.pi,
        sweep,
        false,
        paint,
      );
    }
  }

  void _blob(
    Canvas canvas,
    Size size,
    Color color,
    double ax,
    double ay,
    double r, {
    required double phase,
  }) {
    final dx = math.sin((t + phase) * 2 * math.pi) * 0.035;
    final dy = math.cos((t + phase) * 2 * math.pi) * 0.035;
    final center = Offset(size.width * (ax + dx), size.height * (ay + dy));
    final radius = size.width * r;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.22), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SplashWorldPainter oldDelegate) =>
      oldDelegate.t != t;
}
