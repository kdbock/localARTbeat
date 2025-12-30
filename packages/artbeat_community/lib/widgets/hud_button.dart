import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HUD Button - Local ARTbeat branded buttons
enum HudButtonType { primary, secondary, destructive }

class HudButton extends StatelessWidget {
  const HudButton({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.type = HudButtonType.primary,
    this.width,
    this.height = 48,
    this.borderRadius = 24,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = 0.5,
    this.isLoading = false,
  });

  const HudButton.primary({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius = 24,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = 0.5,
    this.isLoading = false,
  }) : type = HudButtonType.primary;

  const HudButton.secondary({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius = 24,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing = 0.3,
    this.isLoading = false,
  }) : type = HudButtonType.secondary;

  const HudButton.destructive({
    super.key,
    required this.onPressed,
    required this.text,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius = 24,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing = 0.3,
    this.isLoading = false,
  }) : type = HudButtonType.destructive;

  final VoidCallback? onPressed;
  final String text;
  final IconData? icon;
  final HudButtonType type;
  final double? width;
  final double height;
  final double borderRadius;
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return SizedBox(
      width: width,
      height: height,
      child: AnimatedOpacity(
        opacity: isEnabled ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: _buildButton(context, isEnabled),
      ),
    );
  }

  Widget _buildButton(BuildContext context, bool isEnabled) {
    switch (type) {
      case HudButtonType.primary:
        return _buildPrimaryButton(isEnabled);
      case HudButtonType.secondary:
        return _buildSecondaryButton(isEnabled);
      case HudButtonType.destructive:
        return _buildDestructiveButton(isEnabled);
    }
  }

  Widget _buildPrimaryButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF7C4DFF), // Purple
              Color(0xFF22D3EE), // Teal
              Color(0xFF34D399), // Green
            ],
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C4DFF).withAlpha(77),
              blurRadius: 12,
              spreadRadius: 1,
            ),
          ],
        ),
        child: _buildButtonContent(Colors.white),
      ),
    );
  }

  Widget _buildSecondaryButton(bool isEnabled) {
    return OutlinedButton(
      onPressed: isEnabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white, width: 1.5),
        backgroundColor: Colors.white.withAlpha(15),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: _buildButtonContent(Colors.white),
      ),
    );
  }

  Widget _buildDestructiveButton(bool isEnabled) {
    return ElevatedButton(
      onPressed: isEnabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFFF3D8D).withAlpha(26),
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: const Color(0xFFFF3D8D), width: 1.5),
        ),
        child: _buildButtonContent(const Color(0xFFFF3D8D)),
      ),
    );
  }

  Widget _buildButtonContent(Color textColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(textColor),
            ),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 8),
        ],
        Text(
          text.toUpperCase(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor,
            letterSpacing: letterSpacing,
          ),
        ),
      ],
    );
  }
}
