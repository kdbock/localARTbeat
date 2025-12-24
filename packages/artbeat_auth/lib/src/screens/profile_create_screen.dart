import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:artbeat_profile/artbeat_profile.dart' show CreateProfileScreen;
import '../constants/routes.dart';
import '../services/auth_service.dart';

/// Bridge screen that redirects to the full profile creation screen
/// Styled to match Local ARTbeat auth/quest theme
class ProfileCreateScreen extends StatefulWidget {
  const ProfileCreateScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<ProfileCreateScreen> createState() => _ProfileCreateScreenState();
}

class _ProfileCreateScreenState extends State<ProfileCreateScreen>
    with TickerProviderStateMixin {
  late final AuthService _authService;
  late final AnimationController _loop;
  bool _didKickLoginRedirect = false;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _loop = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  void _redirectToLoginOnce() {
    if (_didKickLoginRedirect) return;
    _didKickLoginRedirect = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AuthRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      _redirectToLoginOnce();
      return Scaffold(
        backgroundColor: const Color(0xFF07060F),
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) => CustomPaint(
                  painter: _AuthWorldPainter(t: _loop.value),
                  size: Size.infinite,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      radius: 1.2,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.74),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: _GlassCard(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _Badge(icon: Icons.person_add_alt_1_rounded),
                          const SizedBox(height: 14),
                          Text(
                            'Sign in required',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.94),
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Redirecting you to login…',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.70),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF22D3EE),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Delegate to the real profile creation experience
    return CreateProfileScreen(
      userId: user.uid,
      onProfileCreated: () {
        // Navigate to dashboard after profile creation
        Navigator.pushReplacementNamed(context, AuthRoutes.dashboard);
      },
    );
  }
}

/// =======
/// Shared themed widgets (same language as the new auth screens)
/// =======

class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
              BoxShadow(
                color: const Color(0xFF22D3EE).withValues(alpha: 0.10),
                blurRadius: 38,
                spreadRadius: 1,
              ),
              BoxShadow(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                blurRadius: 38,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  const _Badge({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF7C4DFF),
            Color(0xFF22D3EE),
            Color(0xFF34D399),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

/// Background painter (same “auth world” vibe as other screens)
class _AuthWorldPainter extends CustomPainter {
  final double t;
  _AuthWorldPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    _blob(canvas, size, const Color(0xFFFF3D8D), 0.18, 0.18, 0.42, phase: 0.0);
    _blob(canvas, size, const Color(0xFF7C4DFF), 0.82, 0.22, 0.34, phase: 0.2);
    _blob(canvas, size, const Color(0xFFFFC857), 0.74, 0.80, 0.50, phase: 0.45);
    _blob(canvas, size, const Color(0xFF34D399), 0.16, 0.78, 0.42, phase: 0.62);
    _blob(canvas, size, const Color(0xFF22D3EE), 0.54, 0.56, 0.44, phase: 0.78);

    final center = Offset(size.width * 0.5, size.height * 0.44);
    final maxR = size.width * 0.70;

    for (int i = 1; i <= 4; i++) {
      final r = maxR * (i / 4.0);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.030);
      canvas.drawCircle(center, r, p);
    }

    final angle = t * 2 * math.pi;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * 0.90),
      angle - 0.55,
      0.75,
      false,
      arcPaint,
    );
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
  bool shouldRepaint(covariant _AuthWorldPainter oldDelegate) =>
      oldDelegate.t != t;
}
