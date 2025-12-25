import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Local ARTbeat Design System Widgets
/// Based on the design guide: dark world background + glass surfaces + gradient accents

/// World Background with animated blobs
class WorldBackground extends StatefulWidget {
  final Widget child;
  final bool animated;

  const WorldBackground({
    super.key,
    required this.child,
    this.animated = true,
  });

  @override
  State<WorldBackground> createState() => _WorldBackgroundState();
}

class _WorldBackgroundState extends State<WorldBackground>
    with TickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );
    if (widget.animated) {
      _animationController.repeat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF07060F), // nearly-black purple
                Color(0xFF0A1330), // darker blue
                Color(0xFF071C18), // dark teal
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        // Animated blobs
        if (widget.animated)
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _WorldBlobsPainter(_animationController.value),
                size: Size.infinite,
              );
            },
          ),
        // Vignette overlay
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.65),
              ],
            ),
          ),
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class _WorldBlobsPainter extends CustomPainter {
  final double t;

  _WorldBlobsPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    _drawBlob(canvas, size, const Color(0xFF22D3EE), 0.18, 0.20, 0.36,
        phase: 0.0);
    _drawBlob(canvas, size, const Color(0xFF7C4DFF), 0.84, 0.22, 0.30,
        phase: 0.2);
    _drawBlob(canvas, size, const Color(0xFFFF3D8D), 0.78, 0.76, 0.42,
        phase: 0.45);
    _drawBlob(canvas, size, const Color(0xFF34D399), 0.16, 0.78, 0.34,
        phase: 0.62);
  }

  void _drawBlob(
    Canvas canvas,
    Size size,
    Color color,
    double ax,
    double ay,
    double r, {
    required double phase,
  }) {
    final dx = 0.03 * math.sin((t + phase) * 2 * math.pi);
    final dy = 0.03 * math.cos((t + phase) * 2 * math.pi);

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
  bool shouldRepaint(covariant _WorldBlobsPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Glass Card / Panel with blur effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blur;
  final Color? glassColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 24,
    this.blur = 16,
    this.glassColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glassColor ?? Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.12),
            ),
            boxShadow: shadows ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 16),
                  ),
                ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Gradient Badge for premium features, verification, etc.
class GradientBadge extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GradientBadge({
    super.key,
    required this.child,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Top HUD Bar (replaces standard AppBar)
class HudTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onMenu;
  final VoidCallback? onSearch;
  final VoidCallback? onProfile;
  final bool showLogo;

  const HudTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.onMenu,
    this.onSearch,
    this.onProfile,
    this.showLogo = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        child: GlassCard(
          radius: 18,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              if (onMenu != null)
                IconButton(
                  onPressed: onMenu,
                  icon: const Icon(Icons.menu_rounded, color: Colors.white),
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onSearch != null)
                IconButton(
                  onPressed: onSearch,
                  icon: const Icon(Icons.search_rounded, color: Colors.white),
                ),
              if (onProfile != null)
                IconButton(
                  onPressed: onProfile,
                  icon: const Icon(Icons.person_rounded, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Primary CTA Button with gradient
class HudButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final LinearGradient? gradient;
  final double height;
  final double radius;

  const HudButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.gradient,
    this.height = 52,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    final buttonGradient = gradient ??
        const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: buttonGradient,
              boxShadow: [
                BoxShadow(
                  color: buttonGradient.colors.first.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                ],
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary button with glass outline
class GlassButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color accentColor;
  final double height;
  final double radius;

  const GlassButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.accentColor = const Color(0xFF22D3EE),
    this.height = 52,
    this.radius = 26,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: GlassCard(
            radius: radius,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: SizedBox(
              height: height,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Glass Input Decoration for text fields
class GlassInputDecoration extends InputDecoration {
  const GlassInputDecoration({
    super.hintText,
    super.labelText,
    super.prefixIcon,
    super.suffixIcon,
    super.errorText,
    super.helperText,
    super.contentPadding =
        const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  }) : super(
          filled: true,
          fillColor: const Color.fromRGBO(255, 255, 255, 0.06),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.12)),
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.3)),
          ),
          errorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color.fromRGBO(255, 107, 107, 0.5)),
          ),
          focusedErrorBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
            borderSide: BorderSide(color: Color.fromRGBO(255, 107, 107, 0.7)),
          ),
          hintStyle: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.5),
            fontSize: 14,
          ),
          labelStyle: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          errorStyle: const TextStyle(
            color: Color.fromRGBO(255, 107, 107, 0.9),
            fontSize: 12,
          ),
          helperStyle: const TextStyle(
            color: Color.fromRGBO(255, 255, 255, 0.6),
            fontSize: 12,
          ),
        );
}

/// Section Header with accent dot
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Color accentColor;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.accentColor = const Color(0xFF34D399),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.95),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.25),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          fit: FlexFit.loose,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Engagement Button for actions like Gift, Message, Commission
class EngagementButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const EngagementButton({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
