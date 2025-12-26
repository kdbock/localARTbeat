import 'dart:io' show Platform;
import 'dart:math' as math;
import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtbeatInput;
import '../constants/routes.dart';

/// Login screen with email/password authentication (Quest theme)
class LoginScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing
  const LoginScreen({super.key, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late final AnimationController _loop;
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();

    _loop = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
    _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final formState = _formKey.currentState;
    if (formState == null) return;
    if (!formState.validate()) return;

    setState(() => _isLoading = true);

    try {
      final userCredential = await _authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (mounted && userCredential.user != null) {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop(true);
        } else {
          navigator.pushReplacementNamed(AuthRoutes.dashboard);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'auth_login_failed'.tr())),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      final userCredential = await _authService.signInWithGoogle();
      if (mounted && userCredential.user != null) {
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'auth_google_signin_failed'.tr().replaceAll('{error}', e.toString()),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      setState(() => _isLoading = true);
      await _authService.signInWithAppleFresh();

      if (!mounted) return;
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(true);
      } else {
        navigator.pushReplacementNamed(AuthRoutes.dashboard);
      }
    } catch (e) {
      if (!mounted) return;

      String errorMessage = e.toString();
      if (errorMessage.contains('User cancelled')) {
        errorMessage = 'auth_apple_signin_cancelled'.tr();
      } else if (errorMessage.contains('not available')) {
        errorMessage = 'auth_apple_signin_not_available'.tr();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'auth_apple_signin_failed'.tr().replaceAll('{error}', errorMessage),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _showApple => !kIsWeb && Platform.isIOS;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Animated quest background
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, __) => CustomPaint(
                painter: _AuthWorldPainter(t: _loop.value),
                size: Size.infinite,
              ),
            ),
          ),

          // Vignette focus
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic)),
                      child: _GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Top lockup
                              Row(
                                children: [
                                  _MiniBadge(loop: _loop),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Local ",
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white.withValues(alpha: 0.90),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "ART",
                                            style: GoogleFonts.dmSerifDisplay(
                                              color: const Color(0xFFFFC857),
                                              fontSize: 20,
                                              fontWeight: FontWeight.w400,
                                              letterSpacing: -0.2,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "beat",
                                            style: GoogleFonts.spaceGrotesk(
                                              color: Colors.white.withValues(alpha: 0.90),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: -0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              Text(
                                'auth_welcome'.tr(),
                                textAlign: TextAlign.left,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.95),
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'auth_sign_in_continue'.tr(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.66),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Inputs in soft glass field containers
                              _FieldShell(
                                child: ArtbeatInput(
                                  key: const Key('emailField'),
                                  controller: _emailController,
                                  label: 'auth_email'.tr(),
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_error_email_required'.tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(height: 12),
                              _FieldShell(
                                child: ArtbeatInput(
                                  key: const Key('passwordField'),
                                  controller: _passwordController,
                                  label: 'auth_password'.tr(),
                                  obscureText: _obscurePassword,
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withValues(alpha: 0.70),
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_error_password_required'.tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 16),

                              // Primary quest CTA
                              SizedBox(
                                height: 54,
                                child: AnimatedBuilder(
                                  animation: _loop,
                                  builder: (_, __) {
                                    final t = (_loop.value + 0.08) % 1.0;
                                    final power = (1.0 - (t - 0.55).abs() * 4.5).clamp(0.0, 1.0);
                                    return _QuestPrimaryButton(
                                      width: w,
                                      power: power,
                                      isLoading: _isLoading,
                                      label: 'auth_sign_in'.tr(),
                                      onTap: _isLoading ? null : _handleLogin,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Two quest chips (register + forgot)
                              Row(
                                children: [
                                  Expanded(
                                    child: _QuestChipButton(
                                      label: 'auth_create_account'.tr(),
                                      icon: Icons.auto_awesome_rounded,
                                      glow: const Color(0xFF7C4DFF),
                                      onTap: _isLoading
                                          ? null
                                          : () => Navigator.of(context).pushReplacementNamed(
                                                AuthRoutes.register,
                                              ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _QuestChipButton(
                                      label: 'auth_forgot_password'.tr(),
                                      icon: Icons.key_rounded,
                                      glow: const Color(0xFF22D3EE),
                                      onTap: _isLoading
                                          ? null
                                          : () => Navigator.of(context).pushNamed(
                                                AuthRoutes.forgotPassword,
                                              ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // OR divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(alpha: 0.10),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: Text(
                                      'common_or'.tr(),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withValues(alpha: 0.55),
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 1.2,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(alpha: 0.10),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // Social buttons (glass neon)
                              _SocialButton(
                                label: 'auth_sign_in_with_google'.tr(),
                                icon: Icons.g_mobiledata,
                                accent: const Color(0xFFFF3D8D),
                                onTap: _isLoading ? null : _handleGoogleSignIn,
                              ),
                              const SizedBox(height: 10),
                              if (_showApple)
                                _SocialButton(
                                  label: 'auth_sign_in_with_apple'.tr(),
                                  icon: Icons.apple,
                                  accent: const Color(0xFFFFC857),
                                  onTap: _isLoading ? null : _handleAppleSignIn,
                                ),

                              const SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ),
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
}

/// =======================
/// UI pieces
/// =======================

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

class _FieldShell extends StatelessWidget {
  final Widget child;
  const _FieldShell({required this.child});

  @override
  Widget build(BuildContext context) {
    // Keeps ArtbeatInput, but gives it a quest shell so it matches.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(
            border: InputBorder.none,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final AnimationController loop;
  const _MiniBadge({required this.loop});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, __) {
        final t = loop.value;
        final pulse = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
        return Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                const Color(0xFF22D3EE).withValues(alpha: 0.85),
                const Color(0xFF7C4DFF).withValues(alpha: 0.85),
                const Color(0xFFFF3D8D).withValues(alpha: 0.80),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF22D3EE).withValues(alpha: 0.14 * pulse),
                blurRadius: 18,
              ),
            ],
          ),
          child: const Icon(Icons.explore_rounded, color: Colors.white, size: 18),
        );
      },
    );
  }
}

class _QuestPrimaryButton extends StatelessWidget {
  final double width;
  final double power; // 0..1
  final bool isLoading;
  final String label;
  final VoidCallback? onTap;

  const _QuestPrimaryButton({
    required this.width,
    required this.power,
    required this.isLoading,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 0.10 + 0.22 * power;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
          // Base gradient
          Container(
            decoration: BoxDecoration(
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
                  color: const Color(0xFF22D3EE).withValues(alpha: glow),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),

          // Light sweep overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.70,
              child: Transform.translate(
                offset: Offset((power * 2 - 1) * width * 0.35, 0),
                child: Transform.rotate(
                  angle: -0.55,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.16 + 0.12 * power),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Tap layer
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        label,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestChipButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color glow;
  final VoidCallback? onTap;

  const _QuestChipButton({
    required this.label,
    required this.icon,
    required this.glow,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.white.withValues(alpha: 0.06),
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  boxShadow: [
                    BoxShadow(
                      color: glow.withValues(alpha: 0.10),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.92)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.90),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
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
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1.0,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.white.withValues(alpha: 0.05),
            child: InkWell(
              onTap: onTap,
              child: Container(
                height: 52,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.35),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.10),
                      blurRadius: 22,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: accent.withValues(alpha: 0.14),
                        border: Border.all(color: accent.withValues(alpha: 0.28)),
                      ),
                      child: Icon(icon, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white.withValues(alpha: 0.75),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =======================
/// Background painter
/// =======================

class _AuthWorldPainter extends CustomPainter {
  final double t;
  _AuthWorldPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark gradient
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Ambient blobs (art energy)
    _blob(canvas, size, const Color(0xFFFF3D8D), 0.18, 0.18, 0.42, phase: 0.0);
    _blob(canvas, size, const Color(0xFF7C4DFF), 0.82, 0.22, 0.34, phase: 0.2);
    _blob(canvas, size, const Color(0xFFFFC857), 0.74, 0.80, 0.50, phase: 0.45);
    _blob(canvas, size, const Color(0xFF34D399), 0.16, 0.78, 0.42, phase: 0.62);
    _blob(canvas, size, const Color(0xFF22D3EE), 0.54, 0.56, 0.44, phase: 0.78);

    // Radar rings behind the card
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

    // Sweep arc (subtle)
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

    // Tracing circle outlines
    for (int i = 1; i <= 3; i++) {
      final r = maxR * (0.16 + i * 0.13);
      final phase = (t + i * 0.17) % 1.0;
      final sweep = 2 * math.pi * (0.25 + 0.55 * phase);

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: 0.035 + 0.03 * phase)
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
  bool shouldRepaint(covariant _AuthWorldPainter oldDelegate) => oldDelegate.t != t;
}
