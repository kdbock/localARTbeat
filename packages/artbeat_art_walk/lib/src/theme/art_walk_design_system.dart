import 'package:flutter/material.dart';

/// Comprehensive Art Walk Design System
/// Based on the modern dashboard design with glassmorphism and gradient themes
class ArtWalkDesignSystem {
  // ==================== COLOR PALETTE ====================
  // Updated to match main app colors (purple/green scheme)

  /// Primary color palette - using app's purple/green scheme
  static const Color primaryTeal = Color(0xFF8C52FF); // Primary Purple
  static const Color primaryTealLight = Color(0xFF00BF63); // Primary Green
  static const Color primaryTealDark = Color(0xFF6C3ACC); // Darker Purple

  /// Accent color palette
  static const Color accentOrange = Color(0xFF00BFA5); // Secondary Teal
  static const Color accentOrangeLight = Color(0xFF4DD0BF); // Lighter Teal

  /// Background colors
  static const Color backgroundGradientStart = Color(0xFFF8F9FA);
  static const Color backgroundGradientEnd = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);

  /// Text colors
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Colors.white;

  /// Glass effect colors
  static const Color glassBackground = Colors.white;
  static const Color glassBorder = Colors.white;

  // ==================== GRADIENTS ====================

  /// Main background gradient used across all screens
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF), // White
      Color(0xFFF8F9FA), // Light gray
      Color(0xFFFFFFFF), // White
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Header gradient for app bars - purple to green
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.topRight,
    colors: [primaryTeal, primaryTealLight], // Purple to Green
  );

  /// Title gradient for text
  static const LinearGradient titleGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.topRight,
    colors: [primaryTeal, primaryTealLight], // Purple to Green
  );

  /// Button gradient - purple gradient
  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTeal, primaryTealDark], // Purple shades
  );

  /// Accent button gradient - green gradient
  static const LinearGradient accentButtonGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryTealLight, accentOrange], // Green to teal
  );

  // ==================== DECORATIONS ====================

  /// Glass morphism decoration for cards and containers
  static BoxDecoration glassDecoration({
    double borderRadius = 20,
    double alpha = 0.15,
    double borderAlpha = 0.2,
    double shadowAlpha = 0.1,
  }) {
    return BoxDecoration(
      color: glassBackground.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glassBorder.withValues(alpha: borderAlpha)),
      boxShadow: [
        BoxShadow(
          color: primaryTeal.withValues(alpha: shadowAlpha),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Card decoration for smaller elements
  static BoxDecoration cardDecoration({
    double borderRadius = 16,
    Color? backgroundColor,
    double alpha = 0.1,
    double borderAlpha = 0.2,
  }) {
    return BoxDecoration(
      color: (backgroundColor ?? glassBackground).withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glassBorder.withValues(alpha: borderAlpha)),
    );
  }

  /// Stat card decoration
  static BoxDecoration statCardDecoration({
    double borderRadius = 16,
    double alpha = 0.1,
    double borderAlpha = 0.2,
  }) {
    return BoxDecoration(
      color: glassBackground.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(color: glassBorder.withValues(alpha: borderAlpha)),
    );
  }

  /// Icon container decoration
  static BoxDecoration iconContainerDecoration({
    required Color color,
    double borderRadius = 12,
    double alpha = 0.2,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: alpha),
      borderRadius: BorderRadius.circular(borderRadius),
    );
  }

  // ==================== TEXT STYLES ====================

  /// Hero title style
  static const TextStyle heroTitleStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: textLight,
    height: 1.2,
  );

  /// Hero subtitle style
  static TextStyle heroSubtitleStyle = TextStyle(
    fontSize: 16,
    color: textLight.withValues(alpha: 0.9),
    fontWeight: FontWeight.w500,
  );

  /// Section title style
  static const TextStyle sectionTitleStyle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textLight,
  );

  /// Card title style
  static const TextStyle cardTitleStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  /// Card subtitle style
  static const TextStyle cardSubtitleStyle = TextStyle(
    fontSize: 14,
    color: textSecondary,
    fontWeight: FontWeight.w500,
  );

  /// Stat value style
  static const TextStyle statValueStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textLight,
  );

  /// Stat label style
  static TextStyle statLabelStyle = TextStyle(
    fontSize: 12,
    color: textLight.withValues(alpha: 0.8),
    fontWeight: FontWeight.w500,
  );

  /// Button text style
  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textLight,
  );

  /// Small button text style
  static const TextStyle smallButtonTextStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: textLight,
  );

  // ==================== SPACING ====================

  /// Standard padding values
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 20.0;
  static const double paddingXL = 24.0;
  static const double paddingXXL = 32.0;

  /// Standard margin values
  static const double marginXS = 4.0;
  static const double marginS = 8.0;
  static const double marginM = 16.0;
  static const double marginL = 20.0;
  static const double marginXL = 24.0;
  static const double marginXXL = 32.0;

  /// Border radius values
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;

  // ==================== COMPONENT BUILDERS ====================

  /// Build a standard screen container with background gradient
  static Widget buildScreenContainer({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return Container(
      decoration: const BoxDecoration(gradient: backgroundGradient),
      child: SingleChildScrollView(
        padding: padding ?? const EdgeInsets.all(paddingM),
        child: child,
      ),
    );
  }

  /// Build a glass card container
  static Widget buildGlassCard({
    required Widget child,
    EdgeInsets? padding,
    double borderRadius = radiusXL,
  }) {
    return Container(
      decoration: glassDecoration(borderRadius: borderRadius),
      padding: padding ?? const EdgeInsets.all(paddingXL),
      child: child,
    );
  }

  /// Build a stat card
  static Widget buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(paddingM),
        decoration: statCardDecoration(),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(paddingS),
              decoration: iconContainerDecoration(color: color),
              child: Icon(icon, size: 24, color: color),
            ),
            const SizedBox(height: paddingS),
            Text(value, style: statValueStyle),
            Text(title, style: statLabelStyle),
          ],
        ),
      ),
    );
  }

  /// Build an action button with gradient
  static Widget buildActionButton({
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    bool isAccent = false,
    bool isSmall = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isAccent ? accentButtonGradient : buttonGradient,
        borderRadius: BorderRadius.circular(radiusM),
        boxShadow: [
          BoxShadow(
            color: (isAccent ? accentOrange : primaryTeal).withValues(
              alpha: 0.3,
            ),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(radiusM),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmall ? paddingM : paddingL,
              vertical: isSmall ? paddingS : paddingM,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, color: textLight, size: isSmall ? 18 : 20),
                  SizedBox(width: isSmall ? paddingXS : paddingS),
                ],
                Text(
                  text,
                  style: isSmall ? smallButtonTextStyle : buttonTextStyle,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a section header
  static Widget buildSectionHeader({
    required String title,
    String? subtitle,
    IconData? icon,
    Widget? action,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(paddingS),
            decoration: iconContainerDecoration(
              color: primaryTeal,
              borderRadius: radiusM,
            ),
            child: Icon(icon, size: 20, color: primaryTeal),
          ),
          const SizedBox(width: paddingM),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: sectionTitleStyle),
              if (subtitle != null) Text(subtitle, style: heroSubtitleStyle),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }

  /// Build a floating action button with gradient
  static Widget buildFloatingActionButton({
    required VoidCallback onPressed,
    IconData icon = Icons.add,
    String? tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: buttonGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: primaryTeal.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        tooltip: tooltip,
        child: Icon(icon, color: textLight, size: 28),
      ),
    );
  }

  /// Build an enhanced app bar
  static PreferredSizeWidget buildAppBar({
    required String title,
    bool showBackButton = true,
    List<Widget>? actions,
    GlobalKey<ScaffoldState>? scaffoldKey,
  }) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(gradient: headerGradient),
      ),
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: textLight),
              onPressed: () {
                final context = scaffoldKey?.currentContext;
                if (context != null && Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            )
          : (scaffoldKey != null
                ? IconButton(
                    icon: const Icon(Icons.menu, color: textLight),
                    onPressed: () => scaffoldKey.currentState?.openDrawer(),
                  )
                : null),
      actions: actions,
    );
  }
}

/// Screen templates for common patterns
class ArtWalkScreenTemplate {
  /// Build loading state with glass card
  static Widget buildLoadingState({String message = 'Loading...'}) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingXL),
        decoration: ArtWalkDesignSystem.glassDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ArtWalkDesignSystem.primaryTeal,
              ),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingL),
            Text(
              message,
              style: const TextStyle(
                color: ArtWalkDesignSystem.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty state with action
  static Widget buildEmptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.info_outline,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingXL),
        decoration: ArtWalkDesignSystem.glassDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: ArtWalkDesignSystem.primaryTeal.withValues(alpha: 0.6),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ArtWalkDesignSystem.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingM),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 16,
                color: ArtWalkDesignSystem.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ArtWalkDesignSystem.paddingL),
              ArtWalkDesignSystem.buildActionButton(
                text: actionText,
                onPressed: onAction,
                isAccent: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build form field with glass styling
  static Widget buildFormField({
    required String label,
    String? hint,
    TextEditingController? controller,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Container(
      decoration: ArtWalkDesignSystem.glassDecoration(),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        maxLines: maxLines,
        style: const TextStyle(color: ArtWalkDesignSystem.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: ArtWalkDesignSystem.textSecondary),
          hintStyle: TextStyle(
            color: ArtWalkDesignSystem.textSecondary.withValues(alpha: 0.7),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(ArtWalkDesignSystem.radiusL),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
        ),
      ),
    );
  }

  /// Build list item with glass styling
  static Widget buildListItem({required Widget child, VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: ArtWalkDesignSystem.paddingS),
      decoration: ArtWalkDesignSystem.glassDecoration(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ArtWalkDesignSystem.radiusL),
          child: Padding(
            padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Legacy color class for backward compatibility
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
