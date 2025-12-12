import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

/// Admin Package Specific Header
///
/// Color: #8c52ff (140, 82, 255)
/// Text/Icon Color: #00bf63
/// Font: Limelight
class AdminHeader extends StatefulWidget implements PreferredSizeWidget {
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

  const AdminHeader({
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
  State<AdminHeader> createState() => _AdminHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _AdminHeaderState extends State<AdminHeader> {
  static const Color _headerColor = Color(0xFF8C52FF); // Admin header color
  static const Color _iconTextColor = Color(0xFF00BF63); // Text/Icon color

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: _headerColor,
      ),
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
              icon: const Icon(
                Icons.arrow_back,
                color: _iconTextColor,
              ),
              onPressed:
                  widget.onBackPressed ?? () => Navigator.maybePop(context),
              tooltip: 'Back',
            )
          : IconButton(
              icon: const Icon(
                Icons.menu,
                color: _iconTextColor,
              ),
              onPressed: widget.onMenuPressed ?? () => _openDrawer(),
              tooltip: 'Package Drawer',
            ),
    );
  }

  Widget _buildTitleSection() {
    return Center(
      child: Text(
        widget.title ?? 'Admin',
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
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.search,
              color: _iconTextColor,
            ),
          ),
          onPressed: widget.onSearchPressed ?? () => _navigateToSearch(),
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
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.chat_bubble_outline,
              color: _iconTextColor,
            ),
          ),
          onPressed: widget.onChatPressed ?? () => _openMessaging(),
          tooltip: 'Messages',
        ),
      );
    }

    // Developer Icon
    if (widget.showDeveloper) {
      actions.add(
        IconButton(
          icon: const Icon(
            Icons.developer_mode,
            color: _iconTextColor,
          ),
          onPressed: widget.onDeveloperPressed ?? () => _showDeveloperMenu(),
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
                'Admin Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Limelight',
                ),
              ),
            ),

            // Menu items for admin package
            ListTile(
              leading: const Icon(Icons.dashboard, color: _headerColor),
              title: Text('admin_header_menu_dashboard'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/dashboard');
              },
            ),
            ListTile(
              leading: const Icon(Icons.people, color: _headerColor),
              title: Text('admin_header_menu_user_management'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/user-management');
              },
            ),
            ListTile(
              leading: const Icon(Icons.report, color: _headerColor),
              title: Text('admin_header_menu_content_review'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/content-management-suite');
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: _headerColor),
              title: Text('admin_header_menu_analytics'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin/analytics');
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
    // Navigate to a full screen developer menu to avoid overflow issues
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(
              'Developer Tools',
              style: TextStyle(
                fontFamily: 'Limelight',
                color: _headerColor,
              ),
            ),
            backgroundColor: Colors.white,
            elevation: 1,
            iconTheme: const IconThemeData(color: _headerColor),
          ),
          body: const DeveloperMenu(),
        ),
      ),
    );
  }
}
