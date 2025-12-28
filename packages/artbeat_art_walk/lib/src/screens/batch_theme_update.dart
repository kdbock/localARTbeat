// This file contains the standardized theme updates for all Art Walk screens
// It serves as a reference for the design patterns to be applied

import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';

/// Standard screen structure template for all Art Walk screens
class ArtWalkScreenTemplate {
  /// Standard app bar for all screens
  static PreferredSizeWidget buildStandardAppBar({
    required String title,
    bool showBackButton = true,
    List<Widget>? actions,
    GlobalKey<ScaffoldState>? scaffoldKey,
  }) {
    return ArtWalkDesignSystem.buildAppBar(
      title: title,
      showBackButton: showBackButton,
      actions: actions,
      scaffoldKey: scaffoldKey,
    );
  }

  /// Standard body container with gradient background
  static Widget buildStandardBody({
    required Widget child,
    EdgeInsets? padding,
  }) {
    return ArtWalkDesignSystem.buildScreenContainer(
      padding: padding,
      child: child,
    );
  }

  /// Standard loading state
  static Widget buildLoadingState({String message = 'Loading...'}) {
    return Center(
      child: ArtWalkDesignSystem.buildGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                ArtWalkDesignSystem.primaryTeal,
              ),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingM),
            Text(message, style: ArtWalkDesignSystem.cardTitleStyle),
          ],
        ),
      ),
    );
  }

  /// Standard empty state
  static Widget buildEmptyState({
    required String title,
    required String subtitle,
    IconData icon = Icons.art_track,
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Center(
      child: ArtWalkDesignSystem.buildGlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(ArtWalkDesignSystem.paddingL),
              decoration: ArtWalkDesignSystem.iconContainerDecoration(
                color: ArtWalkDesignSystem.primaryTeal,
                borderRadius: ArtWalkDesignSystem.radiusXL,
              ),
              child: Icon(
                icon,
                size: 48,
                color: ArtWalkDesignSystem.primaryTeal,
              ),
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingL),
            Text(
              title,
              style: ArtWalkDesignSystem.cardTitleStyle,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: ArtWalkDesignSystem.paddingS),
            Text(
              subtitle,
              style: ArtWalkDesignSystem.cardSubtitleStyle,
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: ArtWalkDesignSystem.paddingL),
              ArtWalkDesignSystem.buildActionButton(
                text: actionText,
                onPressed: onAction,
                icon: Icons.add,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Standard floating action button
  static Widget buildStandardFAB({
    required VoidCallback onPressed,
    IconData icon = Icons.add,
    String? tooltip,
  }) {
    return ArtWalkDesignSystem.buildFloatingActionButton(
      onPressed: onPressed,
      icon: icon,
      tooltip: tooltip,
    );
  }

  /// Standard form field
  static Widget buildFormField({
    required String label,
    String? hint,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: ArtWalkDesignSystem.cardTitleStyle),
        const SizedBox(height: ArtWalkDesignSystem.paddingS),
        Container(
          decoration: ArtWalkDesignSystem.cardDecoration(),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: ArtWalkDesignSystem.cardTitleStyle,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: ArtWalkDesignSystem.cardSubtitleStyle,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(
                ArtWalkDesignSystem.paddingM,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Standard list item
  static Widget buildListItem({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: ArtWalkDesignSystem.paddingS),
      decoration: ArtWalkDesignSystem.glassDecoration(),
      child: ListTile(
        leading: leading,
        title: Text(title, style: ArtWalkDesignSystem.cardTitleStyle),
        subtitle: subtitle != null
            ? Text(subtitle, style: ArtWalkDesignSystem.cardSubtitleStyle)
            : null,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }
}

/// Common imports needed for all screens
const String standardImports = '''
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_drawer.dart';
''';

/// Standard MainLayout wrapper
const String standardMainLayout = '''
return MainLayout(
  currentIndex: 1,
  drawer: const ArtWalkDrawer(),
  scaffoldKey: _scaffoldKey,
  child: Scaffold(
    appBar: ArtWalkDesignSystem.buildAppBar(
      title: 'SCREEN_TITLE',
      showBackButton: true,
      scaffoldKey: _scaffoldKey,
    ),
    body: ArtWalkDesignSystem.buildScreenContainer(
      child: SCREEN_CONTENT,
    ),
    floatingActionButton: FLOATING_ACTION_BUTTON,
  ),
);
''';
