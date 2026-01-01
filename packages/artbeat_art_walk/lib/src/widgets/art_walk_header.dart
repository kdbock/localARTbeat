import 'dart:ui';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';

/// Art Walk HUD-style header that matches Local ARTbeat design guide
class ArtWalkHeader extends StatefulWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBackButton;
  final bool showSearch;
  final bool showChat;
  final bool showDeveloper;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onBackPressed;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onChatPressed;
  final VoidCallback? onDeveloperPressed;
  final List<Widget>? actions;

  const ArtWalkHeader({
    super.key,
    this.title,
    this.showBackButton = false,
    this.showSearch = true,
    this.showChat = true,
    this.showDeveloper = false,
    this.onMenuPressed,
    this.onBackPressed,
    this.onSearchPressed,
    this.onChatPressed,
    this.onDeveloperPressed,
    this.actions,
  });

  @override
  State<ArtWalkHeader> createState() => _ArtWalkHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(96);
}

class _ArtWalkHeaderState extends State<ArtWalkHeader> {
  static const _hudGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF07060F), Color(0xFF0A1330)],
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: _hudGradient),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HudIconButton(
                        icon: widget.showBackButton
                            ? Icons.arrow_back_ios_new_rounded
                            : Icons.menu_rounded,
                        tooltip: widget.showBackButton
                            ? 'art_walk_header_tooltip_back'.tr()
                            : 'art_walk_header_tooltip_menu'.tr(),
                        onTap: widget.showBackButton
                            ? (widget.onBackPressed ??
                                  () => Navigator.maybePop(context))
                            : (widget.onMenuPressed ?? _openDrawer),
                      ),
                      const SizedBox(width: 14),
                      Flexible(child: _TitleBlock(title: widget.title)),
                      const SizedBox(width: 14),
                      _ActionCluster(children: _buildActionButtons()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final buttons = <Widget>[];

    if (widget.showSearch) {
      buttons.add(
        _HudIconButton(
          icon: Icons.search_rounded,
          tooltip: 'art_walk_header_tooltip_search'.tr(),
          onTap: widget.onSearchPressed ?? _navigateToSearch,
        ),
      );
    }

    if (widget.showChat) {
      buttons.add(
        _HudIconButton(
          icon: Icons.chat_bubble_outline_rounded,
          tooltip: 'art_walk_header_tooltip_chat'.tr(),
          onTap: widget.onChatPressed ?? _openMessaging,
        ),
      );
    }

    if (widget.showDeveloper) {
      buttons.add(
        _HudIconButton(
          icon: Icons.auto_fix_high,
          tooltip: 'art_walk_header_text_art_walk_developer_tools'.tr(),
          onTap: widget.onDeveloperPressed ?? _showDeveloperMenu,
        ),
      );
    }

    if (widget.actions != null) buttons.addAll(widget.actions!);

    return buttons;
  }

  void _openDrawer() {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      _showPackageMenu();
    }
  }

  void _showPackageMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: GlassCard(
            borderRadius: 34,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'art_walk_header_text_art_walk_menu'.tr(),
                  style: AppTypography.screenTitle(),
                ),
                const SizedBox(height: 12),
                _MenuTile(
                  icon: Icons.map_rounded,
                  label: 'art_walk_header_text_explore_art_walks'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/art-walk/explore');
                  },
                ),
                _MenuTile(
                  icon: Icons.directions_walk_rounded,
                  label: 'art_walk_header_text_start_walking'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/art-walk/start');
                  },
                ),
                _MenuTile(
                  icon: Icons.location_on_rounded,
                  label: 'art_walk_header_text_nearby_art'.tr(),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, '/art-walk/nearby');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigateToSearch() => Navigator.pushNamed(context, '/search');

  void _openMessaging() => Navigator.pushNamed(context, '/messaging');

  void _showDeveloperMenu() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1026),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: Text('art_walk_header_text_art_walk_developer_tools'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.navigation_rounded,
                color: Color(0xFF22D3EE),
              ),
              title: Text('art_walk_header_text_test_gps_navigation'.tr()),
              onTap: () => Navigator.pop(dialogContext),
            ),
            ListTile(
              leading: const Icon(
                Icons.cleaning_services_rounded,
                color: Color(0xFFFFC857),
              ),
              title: Text('art_walk_header_text_clear_location_cache'.tr()),
              onTap: () => Navigator.pop(dialogContext),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('art_walk_button_close'.tr()),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final String? title;

  const _TitleBlock({required this.title});

  @override
  Widget build(BuildContext context) {
    final headline = title ?? 'art_walk_header_default_title'.tr();

    return ClipRect(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            headline,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'art_walk_header_text_explore_art_walks'.tr(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCluster extends StatelessWidget {
  final List<Widget> children;

  const _ActionCluster({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i != 0) const SizedBox(width: 10),
          children[i],
        ],
      ],
    );
  }
}

class _HudIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF22D3EE), Color(0xFF7C4DFF)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF22D3EE), Color(0xFF34D399)],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
