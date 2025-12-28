import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

import '../widgets/art_walk_header.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_cta_button.dart';
import '../widgets/world_background.dart';
import '../widgets/typography.dart';

/// Local ARTbeat aligned design system for the Art Walk module
class ArtWalkDesignSystem {
  // ==================== COLOR PALETTE ====================
  static const Color primaryTeal = Color(0xFF22D3EE);
  static const Color primaryTealLight = Color(0xFF34D399);
  static const Color primaryTealDark = Color(0xFF0D9BCF);

  static const Color accentOrange = Color(0xFFFFC857);
  static const Color accentOrangeLight = Color(0xFFFFE3A3);

  static const Color backgroundGradientStart = Color(0xFF07060F);
  static const Color backgroundGradientMid = Color(0xFF0A1330);
  static const Color backgroundGradientEnd = Color(0xFF071C18);
  static const Color cardBackground = Color(0x14000000);

  static const Color textPrimary = Color(0xFFEFEFFC);
  static const Color textSecondary = Color(0xFFB5B4D1);
  static const Color textLight = Colors.white;

  static const Color glassBackground = Colors.white;
  static const Color glassBorder = Colors.white;

  static const Color hudBackground = Color(0xFF07060F);
  static const Color hudActiveColor = Color(0xFF22D3EE);
  static const Color hudInactiveColor = Color(0xCCFFFFFF);
  static const Color hudBorder = Color(0x33FFFFFF);

  // ==================== GRADIENTS ====================
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      backgroundGradientStart,
      backgroundGradientMid,
      backgroundGradientEnd,
    ],
  );

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xAA07060F), Color(0x660A1330)],
  );

  static const LinearGradient titleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryTealLight],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [ArtbeatColors.primaryPurple, primaryTeal, primaryTealLight],
  );

  static const LinearGradient accentButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentOrange, primaryTeal],
  );

  static const LinearGradient hudHeaderGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [hudBackground, Color(0xFF121634)],
  );

  static const LinearGradient hudButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      ArtbeatColors.primaryPurple,
      hudActiveColor,
      ArtbeatColors.primaryGreen,
    ],
    stops: [0.0, 0.45, 1.0],
  );

  // ==================== DECORATIONS ====================
  static BoxDecoration glassDecoration({
    double borderRadius = 24,
    double alpha = 0.12,
    double borderAlpha = 0.18,
    double shadowAlpha = 0.45,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: shadowAlpha),
          blurRadius: 34,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: primaryTeal.withValues(alpha: 0.12),
          blurRadius: 40,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static BoxDecoration hudGlassDecoration({
    double borderRadius = 24,
    double alpha = 0.62,
    double borderAlpha = 0.12,
    double shadowAlpha = 0.25,
  }) {
    return BoxDecoration(
      color: hudBackground.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: hudBorder.withValues(alpha: borderAlpha)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: shadowAlpha),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: hudActiveColor.withValues(alpha: 0.12),
          blurRadius: 36,
          spreadRadius: 2,
        ),
      ],
    );
  }

  static BoxDecoration cardDecoration({
    double borderRadius = 20,
    Color? backgroundColor,
    double alpha = 0.12,
    double borderAlpha = 0.16,
  }) {
    return BoxDecoration(
      color: (backgroundColor ?? Colors.white).withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
    );
  }

  static BoxDecoration statCardDecoration({
    double borderRadius = 18,
    double alpha = 0.12,
    double borderAlpha = 0.16,
  }) {
    return BoxDecoration(
      color: Colors.white.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: Colors.white.withValues(alpha: borderAlpha)),
    );
  }

  static BoxDecoration iconContainerDecoration({
    required Color color,
    double borderRadius = 16,
    double alpha = 0.24,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // ==================== TYPOGRAPHY ====================
  static TextStyle heroTitleStyle = GoogleFonts.spaceGrotesk(
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: textLight,
    height: 1.2,
  );

  static TextStyle heroSubtitleStyle = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textLight.withValues(alpha: 0.85),
  );

  static TextStyle sectionTitleStyle = GoogleFonts.spaceGrotesk(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textLight,
  );

  static TextStyle cardTitleStyle = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static TextStyle cardSubtitleStyle = GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  static TextStyle statValueStyle = GoogleFonts.spaceGrotesk(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    color: textLight,
  );

  static TextStyle statLabelStyle = GoogleFonts.spaceGrotesk(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: textLight.withValues(alpha: 0.8),
  );

  static TextStyle buttonTextStyle = GoogleFonts.spaceGrotesk(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    color: textLight,
  );

  static TextStyle smallButtonTextStyle = GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: textLight,
  );

  static TextStyle hudCardTitleStyle = GoogleFonts.spaceGrotesk(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: hudInactiveColor,
  );

  static TextStyle hudCardSubtitleStyle = GoogleFonts.spaceGrotesk(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: hudInactiveColor.withValues(alpha: 0.7),
  );

  // ==================== SPACING ====================
  static const double paddingXS = 4;
  static const double paddingS = 8;
  static const double paddingM = 16;
  static const double paddingL = 24;
  static const double paddingXL = 32;
  static const double paddingXXL = 40;

  static const double radiusS = 12;
  static const double radiusM = 16;
  static const double radiusL = 20;
  static const double radiusXL = 24;
  static const double radiusXXL = 28;

  // ==================== COMPONENT BUILDERS ====================
  static Widget buildScreenContainer({
    required Widget child,
    EdgeInsets? padding,
    bool scrollable = true,
  }) {
    Widget content = Padding(
      padding:
          padding ??
          const EdgeInsets.symmetric(horizontal: paddingXL, vertical: paddingL),
      child: child,
    );

    if (scrollable) {
      content = SingleChildScrollView(
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        child: content,
      );
    }

    return WorldBackground(child: SafeArea(child: content));
  }

  static Widget buildGlassCard({
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = radiusXXL,
    EdgeInsets? margin,
  }) {
    return Container(
      margin: margin,
      child: GlassCard(
        padding: padding ?? const EdgeInsets.all(paddingXL),
        borderRadius: borderRadius,
        fillColor: Colors.black.withValues(alpha: 0.3),
        child: child,
      ),
    );
  }

  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    Color color = primaryTeal,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(radiusXXL),
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(paddingL),
          borderRadius: radiusXXL,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(paddingS),
                decoration: iconContainerDecoration(color: color),
                child: Icon(icon, size: 24, color: color),
              ),
              const SizedBox(height: paddingS),
              Text(value, style: statValueStyle, textAlign: TextAlign.center),
              const SizedBox(height: paddingXS),
              Text(title, style: statLabelStyle, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildActionButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isAccent = false,
    bool isSmall = false,
  }) {
    final gradient = isAccent ? accentButtonGradient : buttonGradient;
    final height = isSmall ? 44.0 : 52.0;
    final radius = isSmall ? 22.0 : 26.0;

    return GradientCTAButton(
      label: text,
      onPressed: onPressed,
      icon: icon,
      height: height,
      borderRadius: radius,
      gradient: gradient,
    );
  }

  static Widget buildSectionHeader({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(paddingS),
            decoration: iconContainerDecoration(color: primaryTeal),
            child: Icon(icon, size: 20, color: primaryTeal),
          ),
          const SizedBox(width: paddingM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.sectionLabel()),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    subtitle,
                    style: AppTypography.helper(
                      Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  static Widget buildFloatingActionButton({
    required VoidCallback onPressed,
    IconData icon = Icons.add,
    String? tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(32),
        onTap: onPressed,
        child: Ink(
          height: 64,
          width: 64,
          decoration: BoxDecoration(
            gradient: buttonGradient,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: primaryTeal.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Tooltip(
            message: tooltip ?? '',
            preferBelow: false,
            child: Icon(icon, color: textLight, size: 24),
          ),
        ),
      ),
    );
  }

  static PreferredSizeWidget buildAppBar({
    required String title,
    bool showBackButton = true,
    List<Widget>? actions,
    GlobalKey<ScaffoldState>? scaffoldKey,
    bool useHudStyle = true,
  }) {
    return ArtWalkHeader(
      title: title,
      showBackButton: showBackButton,
      actions: actions,
      onBackPressed: () {
        final context = scaffoldKey?.currentContext;
        if (context != null && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onMenuPressed: scaffoldKey != null
          ? () => scaffoldKey.currentState?.openDrawer()
          : null,
    );
  }
}

/// Screen templates for fast composition
class ArtWalkScreenTemplate {
  static Widget buildLoadingState({String message = 'Loading...'}) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ArtWalkDesignSystem.primaryTeal,
              ),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingM),
            Text(message, style: AppTypography.body()),
          ],
        ),
      ),
    );
  }

  static Widget buildEmptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.info_outline,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: ArtWalkDesignSystem.iconContainerDecoration(
                color: ArtWalkDesignSystem.primaryTeal,
                borderRadius: 22,
              ),
              child: Icon(
                icon,
                size: 40,
                color: ArtWalkDesignSystem.primaryTeal,
              ),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingL),
            Text(title, style: AppTypography.screenTitle()),
            const SizedBox(height: ArtWalkDesignSystem.paddingS),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.body(Colors.white.withValues(alpha: 0.7)),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ArtWalkDesignSystem.paddingL),
              ArtWalkDesignSystem.buildActionButton(
                text: actionText,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget buildFormField({
    required String label,
    String? hint,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.body()),
        const SizedBox(height: ArtWalkDesignSystem.paddingS),
        GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          borderRadius: ArtWalkDesignSystem.radiusXL,
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            maxLines: maxLines,
            style: AppTypography.body(),
            decoration: InputDecoration(
              hintText: hint,
              border: InputBorder.none,
              hintStyle: AppTypography.helper(),
            ),
          ),
        ),
      ],
    );
  }

  static Widget buildListItem({
    required Widget child,
    VoidCallback? onTap,
    EdgeInsets? margin,
  }) {
    return Container(
      margin:
          margin ?? const EdgeInsets.only(bottom: ArtWalkDesignSystem.paddingS),
      child: GlassCard(
        padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
        borderRadius: ArtWalkDesignSystem.radiusXXL,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(ArtWalkDesignSystem.radiusXXL),
            onTap: onTap,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Legacy color mapping for backwards compatibility
class ArtWalkColors {
  static const Color primaryTeal = ArtWalkDesignSystem.primaryTeal;
  static const Color primaryTealLight = ArtWalkDesignSystem.primaryTealLight;
  static const Color primaryTealDark = ArtWalkDesignSystem.primaryTealDark;
  static const Color accentOrange = ArtWalkDesignSystem.accentOrange;
  static const Color accentOrangeLight = ArtWalkDesignSystem.accentOrangeLight;
  static const Color backgroundGradientStart =
      ArtWalkDesignSystem.backgroundGradientStart;
  static const Color backgroundGradientEnd =
      ArtWalkDesignSystem.backgroundGradientEnd;
  static const Color cardBackground = ArtWalkDesignSystem.cardBackground;
  static const Color textPrimary = ArtWalkDesignSystem.textPrimary;
  static const Color textSecondary = ArtWalkDesignSystem.textSecondary;
}
