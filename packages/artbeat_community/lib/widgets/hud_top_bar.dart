import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// HUD Top Bar - Local ARTbeat top navigation bar
/// Replaces standard AppBar with branded design
class HudTopBar extends StatelessWidget implements PreferredSizeWidget {
  const HudTopBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.backgroundColor = Colors.transparent,
    this.glassBackground = false,
    this.elevation = 0,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final Color backgroundColor;
  final bool glassBackground;
  final double elevation;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: elevation,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      automaticallyImplyLeading: false,
      flexibleSpace: glassBackground
          ? Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                ),
              ),
            )
          : null,
      title: title != null
          ? Text(
              title!,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            )
          : null,
      centerTitle: centerTitle,
      leading:
          leading ??
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
      actions: actions,
      toolbarHeight: kToolbarHeight,
    );
  }
}

/// HUD Top Bar with Safe Area - Includes safe area padding
class HudTopBarSafe extends StatelessWidget implements PreferredSizeWidget {
  const HudTopBarSafe({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
    this.glassBackground = false,
  });

  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool centerTitle;
  final bool glassBackground;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: HudTopBar(
        title: title,
        leading: leading,
        actions: actions,
        centerTitle: centerTitle,
        glassBackground: glassBackground,
      ),
    );
  }
}
