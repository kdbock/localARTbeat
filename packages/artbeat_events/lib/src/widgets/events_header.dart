import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

class EventsHeader extends StatelessWidget implements PreferredSizeWidget {
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

  const EventsHeader({
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
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  static const Color _accentTeal = Color(0xFF1CDBA0);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: SafeBackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: kToolbarHeight + 6,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                _buildLeading(context),
                Expanded(child: _buildTitle()),
                ..._buildActions(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      child: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed ?? () => Navigator.maybePop(context),
              tooltip: 'events_back'.tr(),
            )
          : IconButton(
              icon: const Icon(Icons.menu, color: Colors.white),
              onPressed: onMenuPressed ?? () => _openMenu(context),
              tooltip: 'events_menu'.tr(),
            ),
    );
  }

  Widget _buildTitle() {
    return Center(
      child: Text(
        title ?? 'events_title'.tr(),
        style: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.w900,
          fontSize: 18,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final widgets = <Widget>[];

    if (showSearch) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'events_search'.tr(),
          onPressed:
              onSearchPressed ?? () => Navigator.pushNamed(context, '/search'),
        ),
      );
    }

    if (showChat) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
          tooltip: 'events_chat'.tr(),
          onPressed:
              onChatPressed ?? () => Navigator.pushNamed(context, '/messaging'),
        ),
      );
    }

    if (showDeveloper) {
      widgets.add(
        IconButton(
          icon: const Icon(Icons.developer_mode, color: Colors.white),
          tooltip: 'events_dev'.tr(),
          onPressed: onDeveloperPressed ?? () => _showDeveloper(context),
        ),
      );
    }

    if (actions != null) widgets.addAll(actions!);

    return widgets;
  }

  // ------- MENUS -------

  void _openMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        child: SafeBackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 4,
                  width: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'events_menu_header'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),

                _menuItem(
                  context,
                  icon: Icons.event,
                  label: 'events_browse_events'.tr(),
                  onTap: () => Navigator.pushNamed(context, '/events/browse'),
                ),
                _menuItem(
                  context,
                  icon: Icons.add_circle,
                  label: 'events_create_event'.tr(),
                  onTap: () => Navigator.pushNamed(context, '/events/create'),
                ),
                _menuItem(
                  context,
                  icon: Icons.confirmation_number,
                  label: 'events_my_tickets'.tr(),
                  onTap: () => Navigator.pushNamed(context, '/events/tickets'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: _accentTeal),
      title: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  void _showDeveloper(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0C0C16),
        title: Text(
          'events_developer_tools'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'events_test_creation'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text(
                'events_clear_cache'.tr(),
                style: const TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('events_close'.tr()),
          ),
        ],
      ),
    );
  }
}
