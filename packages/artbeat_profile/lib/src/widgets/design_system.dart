import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientBadge extends StatelessWidget {
  final Widget child;
  final LinearGradient gradient;
  final EdgeInsetsGeometry padding;
  final double radius;

  const GradientBadge({
    super.key,
    required this.child,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF00fd8a), Color(0xFF8c52ff)],
    ),
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class HudButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final IconData? icon;
  final double? width;

  const HudButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFF00fd8a)
              : Colors.white.withValues(alpha: 0.1),
          foregroundColor: isPrimary ? Colors.black : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                text,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PulsingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration duration;

  const PulsingButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.duration = const Duration(seconds: 2),
  });

  @override
  State<PulsingButton> createState() => _PulsingButtonState();
}

class _PulsingButtonState extends State<PulsingButton>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(onTap: widget.onPressed, child: widget.child),
        );
      },
    );
  }
}

class GradientCircularProgress extends StatelessWidget {
  final double value;
  final double size;
  final LinearGradient gradient;

  const GradientCircularProgress({
    super.key,
    required this.value,
    this.size = 48,
    this.gradient = const LinearGradient(
      colors: [Color(0xFF00fd8a), Color(0xFF8c52ff)],
    ),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        value: value,
        strokeWidth: 4,
        valueColor: AlwaysStoppedAnimation<Color>(gradient.colors.first),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
      ),
    );
  }
}

class ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ToggleTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: Colors.white.withValues(alpha: 0.7),
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFF00fd8a),
      inactiveThumbColor: Colors.white,
      inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
    );
  }
}
