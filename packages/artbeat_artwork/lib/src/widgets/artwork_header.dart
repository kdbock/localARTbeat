import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

/// Artwork Package Specific Header
///
/// Color: #5497cf (84, 151, 207)
/// Text/Icon Color: #00bf63
/// Font: Limelight
class ArtworkHeader extends StatefulWidget implements PreferredSizeWidget {
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

  const ArtworkHeader({
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
  State<ArtworkHeader> createState() => _ArtworkHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ArtworkHeaderState extends State<ArtworkHeader> {
  static const Color _headerColor = Color(0xFF5497CF); // Artwork header color
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
        widget.title ?? 'Artwork',
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
                'Artwork Menu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Limelight',
                ),
              ),
            ),

            // Menu items for artwork package
            ListTile(
              leading: const Icon(Icons.image, color: _headerColor),
              title: Text('art_walk_browse_artwork'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/artwork/featured');
              },
            ),
            ListTile(
              leading: const Icon(Icons.upload, color: _headerColor),
              title: Text('art_walk_upload_artwork'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/artwork/upload');
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: _headerColor),
              title: Text('art_walk_my_favorites'.tr()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/artwork/favorites');
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
    // Show developer tools specific to artwork package
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('art_walk_artwork_developer_tools'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('art_walk_test_image_upload'.tr()),
              onTap: () {
                Navigator.pop(context);
                // Implement image upload testing
              },
            ),
            ListTile(
              title: Text('art_walk_clear_artwork_cache'.tr()),
              onTap: () {
                Navigator.pop(context);
                // Implement artwork cache clearing
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('art_walk_close'.tr()),
          ),
        ],
      ),
    );
  }
}
