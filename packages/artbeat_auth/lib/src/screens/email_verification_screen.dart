import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/routes.dart';
import '../services/auth_service.dart';

/// Email verification screen (Quest theme) for Local ARTbeat
class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key, this.authService});

  final AuthService? authService;

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with TickerProviderStateMixin {
  late final AuthService _authService;

  bool _isLoading = false;
  bool _canResendEmail = true;
  Timer? _timer;
  int _resendCooldown = 0;
  User? _user;

  late final AnimationController _loop;
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _user = _authService.currentUser;

    _loop = AnimationController(vsync: this, duration: const Duration(seconds: 9))
      ..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _startEmailVerificationCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _startEmailVerificationCheck() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    await _user?.reload();
    final user = FirebaseAuth.instance.currentUser;

    if (user?.emailVerified == true) {
      _timer?.cancel();
      if (!mounted) return;
      _showSuccessMessage();
      Navigator.pushReplacementNamed(context, AuthRoutes.dashboard);
    }
  }

  Future<void> _sendVerificationEmail() async {
    if (!_canResendEmail || _user == null) return;

    setState(() => _isLoading = true);

    try {
      await _user!.sendEmailVerification();
      if (!mounted) return;

      _showSuccessSnackBar(
        'auth_email_verification_sent_to'.tr().replaceAll(
              '{email}',
              _user!.email ?? '',
            ),
      );
      _startResendCooldown();
    } on FirebaseAuthException catch (e) {
      if (mounted) _showErrorSnackBar(_getErrorMessage(e.code));
    } catch (_) {
      if (mounted) _showErrorSnackBar('auth_email_verification_send_failed'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startResendCooldown() {
    setState(() {
      _canResendEmail = false;
      _resendCooldown = 60;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) {
        setState(() => _canResendEmail = true);
        timer.cancel();
      }
    });
  }

  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'too-many-requests':
        return 'auth_email_verification_error_too_many_requests'.tr();
      case 'user-disabled':
        return 'auth_email_verification_error_user_disabled'.tr();
      case 'user-not-found':
        return 'auth_email_verification_error_user_not_found'.tr();
      default:
        return 'auth_email_verification_error_unexpected'.tr();
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('auth_email_verification_success'.tr()),
        backgroundColor: const Color(0xFF34D399),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF34D399),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF3D8D),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _skipVerification() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B1024),
        title: Text(
          'auth_email_verification_skip_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.92),
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'auth_email_verification_skip_desc'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.72),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'auth_email_verification_cancel'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, AuthRoutes.dashboard);
            },
            child: Text(
              'auth_email_verification_skip'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: const Color(0xFF22D3EE),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = _user?.email ?? '';
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
                  constraints: const BoxConstraints(maxWidth: 560),
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                _MiniBadge(loop: _loop, icon: Icons.mark_email_read_rounded),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'auth_email_verification_title'.tr(),
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white.withValues(alpha: 0.95),
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ),
                                _CloseIconButton(
                                  onTap: _isLoading ? null : () => Navigator.pop(context),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            Text(
                              'auth_email_verification_verify_title'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.86),
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),

                            _InfoLine(
                              icon: Icons.alternate_email_rounded,
                              label: 'auth_email_verification_sent_to'.tr(),
                              value: email,
                            ),
                            const SizedBox(height: 10),

                            Text(
                              'auth_email_verification_instructions'.tr(),
                              textAlign: TextAlign.left,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // “Waiting” chip (auto-check runs every 3s)
                            _PulseChip(loop: _loop),
                            const SizedBox(height: 14),

                            // Resend
                            SizedBox(
                              height: 54,
                              child: AnimatedBuilder(
                                animation: _loop,
                                builder: (_, __) {
                                  final t = (_loop.value + 0.10) % 1.0;
                                  final power =
                                      (1.0 - (t - 0.55).abs() * 4.5).clamp(0.0, 1.0);
                                  final label = _canResendEmail
                                      ? 'auth_email_verification_resend_button'.tr()
                                      : 'auth_email_verification_resend_cooldown'.tr(
                                          namedArgs: {'seconds': _resendCooldown.toString()},
                                        );

                                  return _QuestPrimaryButton(
                                    width: w,
                                    power: power,
                                    isLoading: _isLoading,
                                    enabled: _canResendEmail,
                                    label: label,
                                    icon: Icons.refresh_rounded,
                                    onTap: (_canResendEmail && !_isLoading)
                                        ? _sendVerificationEmail
                                        : null,
                                  );
                                },
                              ),
                            ),

                            const SizedBox(height: 10),

                            // Skip
                            _QuestChipButton(
                              label: 'auth_email_verification_skip_now'.tr(),
                              icon: Icons.fast_forward_rounded,
                              glow: const Color(0xFFFFC857),
                              onTap: _isLoading ? null : _skipVerification,
                            ),

                            const SizedBox(height: 12),

                            Text(
                              'auth_email_verification_help_text'.tr(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.52),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
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
        ],
      ),
    );
  }
}

/// =======================
/// UI helpers (same auth theme language)
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

class _CloseIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  const _CloseIconButton({required this.onTap});

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

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF22D3EE).withValues(alpha: 0.9), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulseChip extends StatelessWidget {
  final AnimationController loop;
  const _PulseChip({required this.loop});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: loop,
      builder: (_, __) {
        final pulse = 0.55 + 0.45 * (0.5 + 0.5 * math.sin(loop.value * 2 * math.pi));
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF22D3EE).withValues(alpha: 0.08 + 0.06 * pulse),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: const Color(0xFF22D3EE).withValues(alpha: 0.16 + 0.10 * pulse),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF22D3EE).withValues(alpha: 0.6 + 0.35 * pulse),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Checking verification…',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.86),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _QuestPrimaryButton extends StatelessWidget {
  final double width;
  final double power;
  final bool isLoading;
  final bool enabled;
  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  const _QuestPrimaryButton({
    required this.width,
    required this.power,
    required this.isLoading,
    required this.enabled,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glow = 0.10 + 0.22 * power;

    return Opacity(
      opacity: enabled ? 1.0 : 0.65,
      child: ClipRRect(
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
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: Colors.white, size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white,
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
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

/// Background painter (same “auth world” vibe as the other screens)
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
