import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Events Package Specific Header
///
/// Color: #1cdba0 (28, 219, 160)
/// Text/Icon Color: #8c52ff
/// Font: Limelight
class EventsHeader extends StatefulWidget implements PreferredSizeWidget {
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
  State<EventsHeader> createState() => _EventsHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _EventsHeaderState extends State<EventsHeader> {
  static const Color _headerColor = Color(0xFF1CDBA0); // Events header color
  static const Color _iconTextColor = Color(0xFF8C52FF); // Text/Icon color

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: _headerColor),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              // Leading: Menu or Back Button
              _buildLeadingButton(),

              // Title Section
              Expanded(child: _buildTitleSection()),

              // Action Buttons
              ..._buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: widget.showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: _iconTextColor),
              onPressed:
                  widget.onBackPressed ?? () => Navigator.maybePop(context),
              tooltip: 'Back',
            )
          : IconButton(
              icon: const Icon(Icons.menu, color: _iconTextColor),
              onPressed: widget.onMenuPressed ?? _openDrawer,
              tooltip: 'Package Drawer',
            ),
    );
  }

  Widget _buildTitleSection() {
    return Center(
      child: Text(
        widget.title ?? 'Events',
        style: const TextStyle(
          color: _iconTextColor,
          fontFamily: 'Limelight',
          fontWeight: FontWeight.normal,
          fontSize: 20,
          letterSpacing: 1.2,
        ),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    final actions = <Widget>[];

    // Search Icon
    if (widget.showSearch) {
      actions.add(
        IconButton(
          icon: Image.asset(
            'assets/icons/search-icon@1x.png',
            width: 24,
            height: 24,
            color: _iconTextColor,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.search, color: _iconTextColor),
          ),
          onPressed: widget.onSearchPressed ?? _navigateToSearch,
          tooltip: 'Search',
        ),
      );
    }

    // Chat Icon
    if (widget.showChat) {
      actions.add(
        IconButton(
          icon: Image.asset(
            'assets/icons/chat-icon.png',
            width: 24,
            height: 24,
            color: _iconTextColor,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.chat_bubble_outline, color: _iconTextColor),
          ),
          onPressed: widget.onChatPressed ?? _openMessaging,
          tooltip: 'Messages',
        ),
      );
    }

    // Developer Icon
    if (widget.showDeveloper) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.developer_mode, color: _iconTextColor),
          onPressed: widget.onDeveloperPressed ?? _showDeveloperMenu,
          tooltip: 'Developer Tools',
        ),
      );
    }

    // Additional custom actions
    if (widget.actions != null) {
      actions.addAll(widget.actions!);
    }

    return actions;
  }

  void _openDrawer() {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      // Show package-specific drawer/menu
      _showPackageMenu();
    }
  }

  void _showPackageMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              child: const Text(
                'Events Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Limelight',
                ),
              ),
            ),

            // Menu items for events package
            ListTile(
              leading: const Icon(Icons.event, color: _headerColor),
              title: Text('events_browse_events'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/events/browse');
              },
            ),
            ListTile(
              leading: const Icon(Icons.add_circle, color: _headerColor),
              title: Text('events_create_event'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/events/create');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.confirmation_number,
                color: _headerColor,
              ),
              title: Text('events_my_tickets'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/events/tickets');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _navigateToSearch() {
    Navigator.pushNamed(context, '/search');
  }

  void _openMessaging() {
    Navigator.pushNamed(context, '/messaging');
  }

  void _showDeveloperMenu() {
    // Show developer tools specific to events package
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('events_developer_tools'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('events_test_creation'.tr()),
              onTap: () {
                Navigator.pop(context);
                // Implement event creation testing
              },
            ),
            ListTile(
              title: Text('events_clear_cache'.tr()),
              onTap: () {
                Navigator.pop(context);
                // Implement events cache clearing
              },
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
