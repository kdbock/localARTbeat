import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'hud_top_bar.dart';

class CommunityHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool showSearchIcon;
  final bool showMessagingIcon;
  final bool showDeveloperIcon;
  final VoidCallback? onSearchPressed;
  final VoidCallback? onMessagingPressed;
  final VoidCallback? onDeveloperPressed;
  final VoidCallback? onBackPressed;

  const CommunityHeader({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.showSearchIcon = true,
    this.showMessagingIcon = true,
    this.showDeveloperIcon = true,
    this.onSearchPressed,
    this.onMessagingPressed,
    this.onDeveloperPressed,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return HudTopBar(
      title: title,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,
      actions: [
        if (showSearchIcon)
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: onSearchPressed ?? () => _navigateToSearch(context),
          ),
        if (showMessagingIcon)
          IconButton(
            icon: const Icon(Icons.message, color: Colors.white),
            onPressed:
                onMessagingPressed ?? () => _navigateToMessaging(context),
          ),
        if (showDeveloperIcon)
          IconButton(
            icon: const Icon(Icons.developer_mode, color: Colors.white),
            onPressed: onDeveloperPressed ?? () => _openDeveloperTools(context),
          ),
        const SizedBox(width: 8), // Small padding from right edge
      ],
      glassBackground: true,
    );
  }

  void _navigateToSearch(BuildContext context) {
    Navigator.pushNamed(context, '/community/search');
  }

  void _navigateToMessaging(BuildContext context) {
    Navigator.pushNamed(context, '/community/messaging');
  }

  void _openDeveloperTools(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('developer_tools'.tr()),
        content: Text('developer_tools_future'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('ok'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
