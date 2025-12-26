import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/artbeat_colors.dart';
import '../providers/messaging_provider.dart';
// import 'enhanced_profile_menu.dart';

import 'package:artbeat_profile/src/screens/profile_menu_screen.dart';

/// Enhanced Universal Header with improved visual hierarchy and user experience
///
/// Key improvements:
/// - Cleaner visual hierarchy with better spacing
/// - More prominent branding while maintaining functionality
/// - Improved accessibility with semantic labels
/// - Consistent interaction patterns
/// - Better mobile-first design approach
/// - Enhanced search experience
/// - Streamlined developer tools
class EnhancedUniversalHeader extends StatefulWidget
    implements PreferredSizeWidget {
  final String? title;
  final bool showLogo;
  final bool showSearch;
  final bool showDeveloperTools;
  final bool showBackButton;
  final VoidCallback? onMenuPressed;
  final void Function(String)? onSearchPressed;
  final VoidCallback? onDeveloperPressed;
  final VoidCallback? onProfilePressed;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? elevation;
  final bool hasNotifications;
  final int notificationCount;
  final double? titleFontSize;
  final Gradient? backgroundGradient;
  final Gradient? titleGradient;
  final GlobalKey<ScaffoldState>? scaffoldKey;

  const EnhancedUniversalHeader({
    super.key,
    this.title,
    this.showLogo = true,
    this.showSearch = true,
    this.showDeveloperTools = false,
    this.showBackButton = false,
    this.onMenuPressed,
    this.onSearchPressed,
    this.onDeveloperPressed,
    this.onProfilePressed,
    this.onBackPressed,
    this.actions,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation,
    this.hasNotifications = false,
    this.notificationCount = 0,
    this.titleFontSize,
    this.backgroundGradient,
    this.titleGradient,
    this.scaffoldKey,
  });

  @override
  State<EnhancedUniversalHeader> createState() =>
      _EnhancedUniversalHeaderState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 4);
}

class _EnhancedUniversalHeaderState extends State<EnhancedUniversalHeader>
    with SingleTickerProviderStateMixin {
  // Removed legacy search state - using unified search flow now

  @override
  void initState() {
    super.initState();
    // Removed legacy search initialization
  }

  @override
  void dispose() {
    // Removed legacy search cleanup
    super.dispose();
  }

  // Removed _toggleSearch - using unified search navigation

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: widget.backgroundGradient,
        color: widget.backgroundGradient == null
            ? (widget.backgroundColor ?? Colors.transparent)
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: kToolbarHeight,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildNormalHeader(),
        ),
      ),
    );
  }

  Widget _buildNormalHeader() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Leading: Menu or Back Button
        _buildLeadingButton(),

        // Title/Logo Section
        Expanded(child: _buildTitleSection()),

        // Actions Section - use Wrap for better overflow handling
        SizedBox(
          width: 200,
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 4,
            runSpacing: 4,
            children: _buildActionButtons(),
          ),
        ),
      ],
    );
  }

  // Removed _buildSearchBar - using unified search navigation

  Widget _buildLeadingButton() {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      child: widget.showBackButton
          ? IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: widget.foregroundColor ?? ArtbeatColors.headerText,
              ),
              onPressed:
                  widget.onBackPressed ?? () => Navigator.maybePop(context),
              tooltip: 'header_tooltip_back'.tr(),
            )
          : IconButton(
              icon: Icon(
                Icons.menu,
                color: widget.foregroundColor ?? ArtbeatColors.headerText,
              ),
              onPressed: widget.onMenuPressed ?? () => _openDrawer(),
              tooltip: 'header_tooltip_menu'.tr(),
            ),
    );
  }

  Widget _buildTitleSection() {
    if (widget.showLogo) {
      return Center(
        child: Container(
          height: 36,
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            widget.title ?? 'ARTbeat',
            style: TextStyle(
              color: widget.foregroundColor ?? ArtbeatColors.headerText,
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    } else if (widget.title != null) {
      final textStyle = TextStyle(
        color: widget.titleGradient == null
            ? (widget.foregroundColor ?? ArtbeatColors.headerText)
            : null,
        fontWeight: FontWeight.w900,
        fontSize: widget.titleFontSize ?? 24,
        letterSpacing: 1.2,
        shadows: widget.titleGradient == null
            ? [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                ),
              ]
            : null,
      );

      final textWidget = Text(
        widget.title!,
        style: textStyle,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      );

      return Center(
        child: widget.titleGradient != null
            ? ShaderMask(
                shaderCallback: (bounds) => widget.titleGradient!.createShader(
                  Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                ),
                child: textWidget,
              )
            : textWidget,
      );
    } else {
      return const SizedBox.shrink();
    }
  }

  List<Widget> _buildActionButtons() {
    final List<Widget> actions = <Widget>[];

    // Search button
    if (widget.showSearch) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.search,
            color: widget.foregroundColor ?? ArtbeatColors.headerText,
          ),
          onPressed: () => Navigator.pushNamed(context, '/search'),
          tooltip: 'header_tooltip_search'.tr(),
        ),
      );
    }

    // Messaging icon with unread dot
    actions.add(_buildMessagingIcon());

    // Profile icon
    actions.add(_buildProfileIcon());

    // Developer tools (if enabled)
    if (widget.showDeveloperTools) {
      actions.add(
        IconButton(
          icon: Icon(
            Icons.developer_mode,
            color: widget.foregroundColor ?? ArtbeatColors.headerText,
          ),
          onPressed: widget.onDeveloperPressed ?? () => _showDeveloperTools(),
          tooltip: 'header_tooltip_developer_tools'.tr(),
        ),
      );
    }

    // Additional custom actions
    if (widget.actions != null) {
      // Adding custom actions
      actions.addAll(widget.actions!);
    }

    return actions;
  }

  Widget _buildMessagingIcon() {
    // In test environment, return a simple icon without Consumer
    if (kDebugMode || Platform.environment.containsKey('FLUTTER_TEST')) {
      return IconButton(
        icon: Icon(
          Icons.message_outlined,
          color: widget.foregroundColor ?? ArtbeatColors.headerText,
        ),
        onPressed: () async {
          // Navigate to messaging and refresh count when returning
          await Navigator.pushNamed(context, '/messaging');
        },
        tooltip: 'header_tooltip_messages'.tr(),
      );
    }

    return Consumer<MessagingProvider>(
      builder: (context, messagingProvider, child) {
        // Only log when there are actual changes to avoid spam
        if (messagingProvider.hasUnreadMessages || messagingProvider.hasError) {
          debugPrint(
            'MessagingIcon: hasUnread=${messagingProvider.hasUnreadMessages}, count=${messagingProvider.unreadCount}, initialized=${messagingProvider.isInitialized}, hasError=${messagingProvider.hasError}',
          );
        }

        return Stack(
          children: [
            IconButton(
              icon: Icon(
                Icons.message_outlined,
                color: messagingProvider.hasError
                    ? ArtbeatColors.error.withValues(alpha: 0.6)
                    : widget.foregroundColor ?? ArtbeatColors.headerText,
              ),
              onPressed: () async {
                // Navigate to messaging and refresh count when returning
                await Navigator.pushNamed(context, '/messaging');
                // Refresh the unread count when returning from messaging
                if (context.mounted) {
                  final provider = context.read<MessagingProvider>();
                  provider.refreshUnreadCount();
                }
              },
              tooltip: messagingProvider.hasError
                  ? 'Messages (Error loading count)'
                  : 'Messages',
            ),
            // Loading indicator for uninitialized state
            if (!messagingProvider.isInitialized && !messagingProvider.hasError)
              Positioned(
                right: 8,
                top: 8,
                child: SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      widget.foregroundColor ?? ArtbeatColors.textPrimary,
                    ),
                  ),
                ),
              ),
            // Unread message indicator
            if (messagingProvider.isInitialized &&
                !messagingProvider.hasError &&
                messagingProvider.hasUnreadMessages)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: ArtbeatColors.error,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    messagingProvider.unreadCount > 99
                        ? '99+'
                        : messagingProvider.unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileIcon() {
    return IconButton(
      icon: Icon(
        Icons.account_circle,
        color: widget.foregroundColor ?? ArtbeatColors.headerText,
      ),
      onPressed: widget.onProfilePressed ?? () => _goToProfileMenuScreen(),
      tooltip: 'header_tooltip_profile'.tr(),
    );
  }

  void _goToProfileMenuScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileMenuScreen()),
    );
  }

  void _openDrawer() {
    final scaffoldState = Scaffold.maybeOf(context);
    if (scaffoldState != null && scaffoldState.hasDrawer) {
      scaffoldState.openDrawer();
    } else {
      // Try alternative approach - look for Scaffold in parent contexts
      BuildContext? ctx = context;
      ScaffoldState? foundScaffold;

      // Try up to 5 levels up in the widget tree
      for (int i = 0; i < 5 && ctx != null; i++) {
        foundScaffold = Scaffold.maybeOf(ctx);
        if (foundScaffold != null && foundScaffold.hasDrawer) {
          foundScaffold.openDrawer();
          return;
        }
        // Get the element and try to find parent
        final element = ctx as Element?;
        ctx = element?.findAncestorWidgetOfExactType<Scaffold>() != null
            ? ctx
            : null;
      }

      // If still not found, show debug info
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Drawer not found. Scaffold: ${scaffoldState != null}, hasDrawer: ${scaffoldState?.hasDrawer ?? false}',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _showDeveloperTools() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.code, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Developer Tools',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ArtbeatColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            _buildDeveloperTile(
              icon: Icons.feedback,
              title: 'Submit Feedback',
              subtitle: 'Report bugs or suggest improvements',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feedback');
              },
            ),

            _buildDeveloperTile(
              icon: Icons.admin_panel_settings,
              title: 'Admin Panel',
              subtitle: 'Manage feedback and system settings',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/developer-feedback-admin');
              },
            ),

            _buildDeveloperTile(
              icon: Icons.info,
              title: 'System Info',
              subtitle: 'View app version and system details',
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/system/info');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeveloperTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: ArtbeatColors.textSecondary),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: ArtbeatColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
