import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'package:artbeat_core/artbeat_core.dart'
  show ArtbeatInput;

/// Forgot password screen with email reset functionality (Quest theme)
class ForgotPasswordScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing
  const ForgotPasswordScreen({super.key, this.authService});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  String? _errorMessage;
  bool _resetSent = false;

  late final AnimationController _loop;
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _loop = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _resetSent = false;
    });

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (!mounted) return;
      setState(() => _resetSent = true);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = _getErrorMessage(e));
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorMessage = 'auth_forgot_password_unexpected_error'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'auth_forgot_password_error_user_not_found'.tr();
      case 'invalid-email':
        return 'auth_forgot_password_error_invalid_email'.tr();
      default:
        return 'auth_forgot_password_error_failed'.tr(namedArgs: {'code': e.code});
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF07060F),
      body: Stack(
        children: [
          // Background world
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _loop,
              builder: (_, __) => CustomPaint(
                painter: _AuthWorldPainter(t: _loop.value),
                size: Size.infinite,
              ),
            ),
          ),

          // Vignette
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _intro, curve: Curves.easeOut),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.04),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic),
                      ),
                      child: _GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  _MiniBadge(loop: _loop, icon: Icons.lock_reset_rounded),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'auth_forgot_password_title'.tr(),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withValues(alpha: 0.95),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  _BackIconButton(onTap: _isLoading ? null : () => Navigator.pop(context)),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'auth_forgot_password_subtitle'.tr(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.66),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 14),

                              if (_errorMessage != null) ...[
                                _Banner(
                                  icon: Icons.error_outline,
                                  color: const Color(0xFFFF3D8D),
                                  message: _errorMessage!,
                                ),
                                const SizedBox(height: 10),
                              ],

                              if (_resetSent) ...[
                                _Banner(
                                  icon: Icons.check_circle_outline,
                                  color: const Color(0xFF34D399),
                                  message: 'auth_forgot_password_reset_sent'.tr(),
                                ),
                                const SizedBox(height: 10),
                              ],

                              const SizedBox(height: 4),

                              _FieldShell(
                                child: ArtbeatInput(
                                  controller: _emailController,
                                  label: 'auth_forgot_password_email'.tr(),
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  validator: (String? value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_forgot_password_email_required'.tr();
                                    }
                                    if (!value.contains('@')) {
                                      return 'auth_forgot_password_email_invalid'.tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              // Primary CTA (quest sweep)
                              SizedBox(
                                height: 54,
                                child: AnimatedBuilder(
                                  animation: _loop,
                                  builder: (_, __) {
                                    final t = (_loop.value + 0.10) % 1.0;
                                    final power =
                                        (1.0 - (t - 0.55).abs() * 4.5).clamp(0.0, 1.0);
                                    return _QuestPrimaryButton(
                                      width: w,
                                      power: power,
                                      isLoading: _isLoading,
                                      label: 'auth_forgot_password_button'.tr(),
                                      icon: Icons.restore_outlined,
                                      onTap: _isLoading ? null : _handleResetPassword,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),

                              _QuestChipButton(
                                label: 'auth_forgot_password_back_to_login'.tr(),
                                icon: Icons.arrow_back_rounded,
                                glow: const Color(0xFF22D3EE),
                                onTap: _isLoading ? null : () => Navigator.pop(context),
                              ),
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
/// UI helpers
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Theme(
        data: Theme.of(context).copyWith(
          inputDecorationTheme: const InputDecorationTheme(border: InputBorder.none),
        ),
        child: child,
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final AnimationController loop;
  final IconData icon;
  const _MiniBadge({required this.loop, required this.icon});

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
          child: Icon(icon, color: Colors.white, size: 18),
        );
      },
    );
  }
}

class _BackIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _BackIconButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.55 : 1.0,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Icon(
            Icons.close_rounded,
            color: Colors.white.withValues(alpha: 0.86),
            size: 20,
          ),
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String message;

  const _Banner({
    required this.icon,
    required this.color,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.86),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestPrimaryButton extends StatelessWidget {
  final double width;
  final double power;
  final bool isLoading;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuestPrimaryButton({
    required this.width,
    required this.power,
    required this.isLoading,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 0.10 + 0.22 * power;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Stack(
        children: [
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            label,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ],
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

/// Background painter (shared auth “world” look)
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
  bool shouldRepaint(covariant _AuthWorldPainter oldDelegate) => oldDelegate.t != t;
}
