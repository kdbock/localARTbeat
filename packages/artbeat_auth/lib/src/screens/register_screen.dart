import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../constants/routes.dart';
import 'package:artbeat_core/artbeat_core.dart'
  show ArtbeatInput;
import 'package:artbeat_core/artbeat_core.dart' show UserService;

/// Registration screen with email/password account creation (Quest theme)
class RegisterScreen extends StatefulWidget {
  final AuthService? authService; // Optional for testing
  const RegisterScreen({super.key, this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  late final AuthService _authService;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _agreedToTerms = false;

  late final AnimationController _loop;
  late final AnimationController _intro;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_agreedToTerms) {
      setState(() => _errorMessage = 'auth_register_error_agree_terms'.tr());
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final fullName =
          "${_firstNameController.text.trim()} ${_lastNameController.text.trim()}";
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      final userCredential = await _authService.registerWithEmailAndPassword(
        email,
        password,
        fullName,
      );

      // Ensure user document exists
      final user = userCredential.user;
      if (user != null) {
        final userService = UserService();
        final userDoc = await userService.getUserById(user.uid);
        if (userDoc == null) {
          await userService.createNewUser(
            uid: user.uid,
            email: user.email ?? email,
            displayName: fullName,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AuthRoutes.dashboard);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e));
    } catch (_) {
      setState(() => _errorMessage = 'auth_register_error_unexpected'.tr());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'auth_register_error_email_exists'.tr();
      case 'invalid-email':
        return 'auth_register_error_invalid_email'.tr();
      case 'weak-password':
        return 'auth_register_error_weak_password'.tr();
      default:
        return 'auth_register_error_failed'.tr(namedArgs: {'code': e.code});
    }
  }

  void _navigateToTerms() => Navigator.pushNamed(context, '/terms-of-service');
  void _navigateToPrivacyPolicy() =>
      Navigator.pushNamed(context, '/privacy-policy');

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
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _intro,
                      curve: Curves.easeOut,
                    ),
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 0.04),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: _intro,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: _GlassCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  _MiniBadge(
                                    loop: _loop,
                                    icon: Icons.auto_awesome_rounded,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'auth_register_title'.tr(),
                                      style: GoogleFonts.spaceGrotesk(
                                        color: Colors.white.withValues(
                                          alpha: 0.95,
                                        ),
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'auth_register_subtitle'.tr(),
                                style: GoogleFonts.spaceGrotesk(
                                  color: Colors.white.withValues(alpha: 0.66),
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                              const SizedBox(height: 16),

                              if (_errorMessage != null) ...[
                                _ErrorBanner(message: _errorMessage!),
                                const SizedBox(height: 12),
                              ],

                              // Name row (responsive: stacks on narrow screens)
                              LayoutBuilder(
                                builder: (context, c) {
                                  final stacked = c.maxWidth < 420;
                                  final children = <Widget>[
                                    Flexible(
                                      child: _FieldShell(
                                        child: ArtbeatInput(
                                          controller: _firstNameController,
                                          label: 'auth_register_first_name'
                                              .tr(),
                                          prefixIcon: const Icon(
                                            Icons.person_outline,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'auth_register_first_name_required'
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: stacked ? 0 : 12,
                                      height: stacked ? 12 : 0,
                                    ),
                                    Flexible(
                                      child: _FieldShell(
                                        child: ArtbeatInput(
                                          controller: _lastNameController,
                                          label: 'auth_register_last_name'.tr(),
                                          prefixIcon: const Icon(
                                            Icons.person_outline,
                                          ),
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'auth_register_last_name_required'
                                                  .tr();
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ),
                                  ];

                                  return stacked
                                      ? Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: children,
                                        )
                                      : Row(children: children);
                                },
                              ),

                              const SizedBox(height: 12),

                              _FieldShell(
                                child: ArtbeatInput(
                                  controller: _emailController,
                                  label: 'auth_register_email'.tr(),
                                  keyboardType: TextInputType.emailAddress,
                                  prefixIcon: const Icon(Icons.email_outlined),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_register_email_required'
                                          .tr();
                                    }
                                    if (!value.contains('@')) {
                                      return 'auth_register_email_invalid'.tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              _FieldShell(
                                child: ArtbeatInput(
                                  controller: _passwordController,
                                  label: 'auth_register_password'.tr(),
                                  obscureText: _obscurePassword,
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withValues(
                                        alpha: 0.70,
                                      ),
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_register_password_required'
                                          .tr();
                                    }
                                    if (value.length < 8) {
                                      return 'auth_register_password_min_length'
                                          .tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 12),

                              _FieldShell(
                                child: ArtbeatInput(
                                  controller: _confirmPasswordController,
                                  label: 'auth_register_confirm_password'.tr(),
                                  obscureText: _obscureConfirmPassword,
                                  prefixIcon: const Icon(Icons.lock_outlined),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: Colors.white.withValues(
                                        alpha: 0.70,
                                      ),
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureConfirmPassword =
                                          !_obscureConfirmPassword,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'auth_register_confirm_password_required'
                                          .tr();
                                    }
                                    if (value != _passwordController.text) {
                                      return 'auth_register_passwords_mismatch'
                                          .tr();
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 14),

                              _TermsRow(
                                value: _agreedToTerms,
                                onChanged: _isLoading
                                    ? null
                                    : (v) => setState(() => _agreedToTerms = v),
                                onTapTerms: _navigateToTerms,
                                onTapPrivacy: _navigateToPrivacyPolicy,
                              ),

                              const SizedBox(height: 14),

                              // Primary CTA (quest sweep)
                              SizedBox(
                                height: 54,
                                child: AnimatedBuilder(
                                  animation: _loop,
                                  builder: (_, __) {
                                    final t = (_loop.value + 0.08) % 1.0;
                                    final power = (1.0 - (t - 0.55).abs() * 4.5)
                                        .clamp(0.0, 1.0);
                                    return _QuestPrimaryButton(
                                      width: w,
                                      power: power,
                                      isLoading: _isLoading,
                                      label: 'auth_register_button'.tr(),
                                      onTap: _isLoading
                                          ? null
                                          : _handleRegister,
                                    );
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),

                              _QuestChipButton(
                                label: 'auth_register_login_link'.tr(),
                                icon: Icons.login_rounded,
                                glow: const Color(0xFF22D3EE),
                                onTap: _isLoading
                                    ? null
                                    : () => Navigator.pushReplacementNamed(
                                        context,
                                        AuthRoutes.login,
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
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Small UI helpers (same system as Login)
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

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF3D8D).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFF3D8D).withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.white.withValues(alpha: 0.90),
          ),
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

class _TermsRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final VoidCallback onTapTerms;
  final VoidCallback onTapPrivacy;

  const _TermsRow({
    required this.value,
    required this.onChanged,
    required this.onTapTerms,
    required this.onTapPrivacy,
  });

  @override
  Widget build(BuildContext context) {
    const link = Color(0xFF22D3EE);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: value,
              onChanged: onChanged == null
                  ? null
                  : (v) => onChanged!(v ?? false),
              activeColor: link,
              checkColor: const Color(0xFF07060F),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.30)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              TextSpan(
                text: 'auth_register_agree_prefix'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
                children: [
                  TextSpan(
                    text: 'auth_register_terms_link'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: link,
                      fontWeight: FontWeight.w900,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onTapTerms,
                  ),
                  TextSpan(
                    text: ' ${'auth_register_and'.tr()} ',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.78),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: 'auth_register_privacy_link'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: link,
                      fontWeight: FontWeight.w900,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = onTapPrivacy,
                  ),
                ],
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
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
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
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
                    Icon(
                      icon,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
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

/// Background painter (shared look)
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
