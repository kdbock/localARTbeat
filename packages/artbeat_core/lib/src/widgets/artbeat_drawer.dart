import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import '../theme/artbeat_colors.dart';
import '../theme/artbeat_typography.dart';
import '../services/user_service.dart';
import '../models/user_model.dart' as core;
import 'artbeat_drawer_items.dart';
import 'user_avatar.dart';
import '../utils/logger.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';

// Define main navigation routes that should use pushReplacement
// Only include true top-level destinations that should replace the current screen
const Set<String> mainRoutes = {
  '/dashboard',
  '/browse',
  '/community/feed',
  '/events/discover',
  '/artist/dashboard',
  '/gallery/artists-management',
  '/admin/dashboard',
};

class ArtbeatDrawer extends StatefulWidget {
  const ArtbeatDrawer({super.key});

  @override
  State<ArtbeatDrawer> createState() => _ArtbeatDrawerState();
}

class _ArtbeatDrawerState extends State<ArtbeatDrawer> {
  core.UserModel? _cachedUserModel;
  StreamSubscription<User?>? _authSubscription;
  String? _roleOverride; // For admin role switching

  @override
  void initState() {
    super.initState();
    _loadUserModel();
    // Listen for auth state changes to refresh user model
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user != null && _cachedUserModel == null) {
        _loadUserModel();
      } else if (user == null && _cachedUserModel != null) {
        if (mounted) {
          setState(() {
            _cachedUserModel = null;
            _roleOverride = null; // Reset role override when signing out
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadUserModel() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final model = await userService.getUserById(user.uid);
        if (mounted) {
          setState(() => _cachedUserModel = model);
        }

        // Process daily login for streak tracking
        try {
          final rewardsService = RewardsService();
          await rewardsService.processDailyLogin(user.uid);
        } catch (e) {
          AppLogger.error('❌ Error processing daily login: $e');
        }
      }
    } catch (error) {
      AppLogger.error('❌ Error loading user model: $error');
    }
  }

  void _handleNavigation(
    BuildContext context,
    BuildContext snackBarContext,
    String route,
    bool isMainRoute,
  ) {
    // Ensure the provided snackBarContext is still valid before doing
    // navigation that will rely on it. Guard the BuildContext usage across
    // async gaps to avoid use_build_context_synchronously lints.
    if (!snackBarContext.mounted) return;
    // List of implemented routes based on app_router.dart
    final implementedRoutes = {
      '/dashboard',
      '/profile',
      '/profile/edit',
      '/login',
      '/register',
      '/browse', // ✅ Full browse screen with all content types
      '/artist/dashboard',
      '/artist/onboarding',
      '/artist/profile-edit',
      '/artist/public-profile',
      '/artist/analytics',
      '/artist/artwork',
      '/artist/browse',
      '/artist/earnings',
      '/artist/payout-request',
      '/artist/payout-accounts',
      '/artist/featured',
      '/artist/approved-ads',
      '/artwork/upload',
      '/artwork/browse',
      '/artwork/edit',
      '/artwork/detail',
      '/artwork/featured',
      '/artwork/search',
      '/artwork/recent',
      '/artwork/trending',
      '/gallery/artists-management',
      '/gallery/analytics',
      '/gallery/commissions',
      '/commission/hub',
      '/commission/request',
      '/community/feed',
      '/community/dashboard',
      '/community/artists',
      '/community/search',
      '/community/posts',
      '/community/studios',
      '/community/gifts',
      '/community/portfolios',
      '/community/moderation',
      '/community/sponsorships',
      '/community/settings',
      '/community/create',
      '/community/messaging',
      '/community/trending',
      '/community/featured',
      '/community/hub',
      '/community',
      '/art-walk/map',
      '/art-walk/list',
      '/art-walk/detail',
      '/art-walk/create',
      '/art-walk/experience', // Consolidated route (was /enhanced-art-walk-experience)
      '/art-walk/search',
      '/art-walk/explore',
      '/art-walk/start',
      '/art-walk/nearby',
      '/art-walk/dashboard',
      '/messaging',
      '/messaging/new',
      '/messaging/chat',
      '/messaging/user-chat',
      '/events/discover',
      '/events/dashboard',
      '/events/artist-dashboard',
      '/events/create',
      '/events/my-events',
      '/events/my-tickets',
      '/events/detail',
      '/admin/dashboard',
      '/admin/settings',
      '/settings', // ✅ Generic settings route
      '/settings/account',
      '/settings/notifications',
      '/settings/privacy',
      '/settings/security',
      '/payment/methods',
      '/payment/refund',
      '/payment/screen',
      '/subscription/plans',
      '/subscription/comparison',
      '/captures',
      '/capture/camera',
      '/capture/dashboard',
      '/capture/search',
      '/capture/nearby',
      '/capture/popular',
      '/capture/my-captures',
      '/capture/pending',
      '/capture/map',
      '/capture/browse',
      '/capture/approved',
      '/capture/settings',
      '/capture/admin/moderation',
      '/capture/gallery',
      '/capture/edit',
      '/capture/create',
      '/capture/public',
      '/artwalk/admin/moderation',
      '/ads/create',
      '/ads/management',
      '/ads/statistics',
      '/ads/payment',
      '/achievements',
      '/achievements/info',
      '/notifications',
      '/search',
      '/search/results',
      '/feedback',
      '/favorites',
      '/developer-feedback-admin',
      '/system/info',
      '/support',
      '/profile/following',
      '/profile/followers',
      '/quest-history',
      '/weekly-goals',
    };

    // Add Artbeat Store route
    if (route == '/store') {
      Navigator.of(snackBarContext, rootNavigator: true).pushNamed('/store');
      return;
    }
    if (implementedRoutes.contains(route)) {
      try {
        AppLogger.info('🔄 Navigating to: $route (isMainRoute: $isMainRoute)');

        // Use push for most routes to maintain navigation stack
        // Only use pushReplacementNamed for true top-level destinations
        if (isMainRoute && mainRoutes.contains(route)) {
          Navigator.of(
            snackBarContext,
            rootNavigator: true,
          ).pushReplacementNamed(route);
        } else {
          // Use regular push to maintain back button functionality
          Navigator.of(snackBarContext, rootNavigator: true).pushNamed(route);
        }
      } catch (error) {
        AppLogger.error('⚠️ Navigation error for route $route: $error');
        _showError(snackBarContext, error.toString());
      }
    } else {
      // Show "Coming Soon" dialog for unimplemented routes
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('drawer_coming_soon'.tr()),
          content: Text(
            'drawer_coming_soon_message'.tr(namedArgs: {'route': route}),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('drawer_ok'.tr()),
            ),
          ],
        ),
      );
    }
  }

  void _showError(BuildContext context, String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'drawer_navigation_error'.tr(
              namedArgs: {'error': error.toString()},
            ),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String? _getUserRole() {
    // If admin is using role override, return the override
    if (_roleOverride != null && _isCurrentUserAdmin()) {
      // If override is 'user', return null to show regular user view
      if (_roleOverride == 'user') {
        return null;
      }
      return _roleOverride;
    }

    final userModel = _cachedUserModel;
    if (userModel != null) {
      // Use the proper role detection methods from UserModel
      if (userModel.isAdmin) return 'admin';
      if (userModel.isArtist) return 'artist';
      if (userModel.isGallery) return 'gallery';
      if (userModel.isModerator) return 'moderator';
    }
    return null; // Regular user
  }

  bool _isCurrentUserAdmin() {
    final userModel = _cachedUserModel;
    return userModel?.isAdmin ?? false;
  }

  void _toggleRoleOverride() {
    if (!_isCurrentUserAdmin()) return;

    setState(() {
      switch (_roleOverride) {
        case null:
          _roleOverride = 'user';
          break;
        case 'user':
          _roleOverride = 'artist';
          break;
        case 'artist':
          _roleOverride = 'gallery';
          break;
        case 'gallery':
          _roleOverride = 'moderator';
          break;
        case 'moderator':
          _roleOverride = null; // Back to admin view
          break;
        default:
          _roleOverride = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = _getUserRole();
    final drawerSections = ArtbeatDrawerItems.getSectionsForRole(userRole);

    return Drawer(
      backgroundColor: Colors.white,
      elevation: 2.0,
      child: SafeArea(
        child: Container(
          decoration: const BoxDecoration(color: Colors.white),
          child: Column(
            children: [
              // Header
              _buildDrawerHeader(),

              // Navigation Items
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _calculateTotalItems(drawerSections),
                  itemBuilder: (context, index) {
                    return _buildDrawerItemAtIndex(
                      context,
                      drawerSections,
                      index,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _calculateTotalItems(List<DrawerSection> sections) {
    int total = 0;
    for (final section in sections) {
      if (section.title != null) total++; // Header
      total += section.items.length;
      if (section.showDivider) total++; // Divider
    }
    return total;
  }

  Widget _buildDrawerItemAtIndex(
    BuildContext context,
    List<DrawerSection> sections,
    int index,
  ) {
    int currentIndex = 0;

    for (final section in sections) {
      // Add section header if it exists
      if (section.title != null) {
        if (currentIndex == index) {
          return _buildSectionHeader(section.title!);
        }
        currentIndex++;
      }

      // Add section items
      for (final item in section.items) {
        if (currentIndex == index) {
          // Add divider before sign out
          if (item.route == '/login') {
            return Column(
              children: [
                const Divider(height: 1),
                const SizedBox(height: 8),
                _buildDrawerItem(context, item),
              ],
            );
          }
          return _buildDrawerItem(context, item);
        }
        currentIndex++;
      }

      // Add divider if specified
      if (section.showDivider) {
        if (currentIndex == index) {
          return const Divider(height: 1);
        }
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildDrawerHeader() {
    return Container(
      height: _isCurrentUserAdmin()
          ? 170
          : 145, // Increased height for admin toggle
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            ArtbeatColors.primaryPurple.withValues(alpha: 0.15),
            const Color(0xFF4A90E2).withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.95),
            ArtbeatColors.primaryGreen.withValues(alpha: 0.12),
            Colors.white,
          ],
          stops: const [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // Logo on the right side
          Positioned(
            right: 0,
            top: 8,
            child: Opacity(
              opacity: 0.25,
              child: Image.asset(
                'assets/images/artbeat_logo.png',
                width: 50,
                height: 50,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // User info section
          StreamBuilder<User?>(
            stream: FirebaseAuth.instance.userChanges(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              if (user == null) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16, right: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const UserAvatar(displayName: 'Guest', radius: 14),
                      const SizedBox(height: 4),
                      Text(
                        'Guest User',
                        style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                          color: ArtbeatColors.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Not signed in',
                        style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
                          color: ArtbeatColors.textSecondary,
                          fontSize: 8,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                );
              }

              // Use cached user model to prevent repeated queries
              final userModel = _cachedUserModel;
              final displayName =
                  userModel?.fullName ?? user.displayName ?? 'User';
              final profileImageUrl = userModel?.profileImageUrl;

              return Padding(
                padding: const EdgeInsets.only(left: 16, right: 80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    UserAvatar(
                      imageUrl: profileImageUrl,
                      displayName: displayName,
                      radius: 13, // Slightly smaller avatar
                    ),
                    const SizedBox(height: 3), // Reduced spacing
                    Text(
                      displayName,
                      style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
                        color: ArtbeatColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 1), // Reduced spacing
                    Text(
                      user.email ?? '',
                      style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
                        color: ArtbeatColors.textSecondary,
                        fontSize: 8,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    // Show user role badge if applicable
                    if (_getUserRole() != null) ...[
                      const SizedBox(height: 2), // Reduced spacing
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1, // Reduced padding
                        ),
                        decoration: BoxDecoration(
                          color: ArtbeatColors.primaryPurple.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getUserRole()!.toUpperCase(),
                          style: ArtbeatTypography.textTheme.bodySmall
                              ?.copyWith(
                                color: ArtbeatColors.primaryPurple,
                                fontWeight: FontWeight.bold,
                                fontSize: 6,
                              ),
                        ),
                      ),
                    ],

                    // Admin role toggle
                    if (_isCurrentUserAdmin()) ...[
                      const SizedBox(height: 4), // Reduced spacing
                      _buildRoleToggle(),
                    ],
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRoleToggle() {
    final currentViewRole = _roleOverride ?? 'admin';
    String displayText;
    Color badgeColor;
    IconData icon;

    switch (currentViewRole) {
      case 'admin':
        displayText = 'ADMIN';
        badgeColor = ArtbeatColors.primaryPurple;
        icon = Icons.admin_panel_settings;
        break;
      case 'user':
        displayText = 'USER';
        badgeColor = ArtbeatColors.textSecondary;
        icon = Icons.person;
        break;
      case 'artist':
        displayText = 'ARTIST';
        badgeColor = ArtbeatColors.primaryGreen;
        icon = Icons.palette;
        break;
      case 'gallery':
        displayText = 'GALLERY';
        badgeColor = const Color(0xFF2196F3);
        icon = Icons.business;
        break;
      case 'moderator':
        displayText = 'MOD';
        badgeColor = const Color(0xFFFF9800);
        icon = Icons.gavel;
        break;
      default:
        displayText = 'ADMIN';
        badgeColor = ArtbeatColors.primaryPurple;
        icon = Icons.admin_panel_settings;
    }

    return GestureDetector(
      onTap: _toggleRoleOverride,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 2,
        ), // Further reduced padding
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8), // Smaller radius
          border: Border.all(
            color: badgeColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 8, color: badgeColor), // Smaller icon
            const SizedBox(width: 1.5), // Further reduced spacing
            Flexible(
              child: Text(
                displayText,
                style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
                  color: badgeColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 6, // Smaller text
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 1), // Minimal spacing
            Icon(
              Icons.swap_horiz,
              size: 6, // Smaller swap icon
              color: badgeColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.tr().toUpperCase(),
        style: ArtbeatTypography.textTheme.bodySmall?.copyWith(
          color: ArtbeatColors.textSecondary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, ArtbeatDrawerItem item) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isCurrentRoute = currentRoute == item.route;
    final bool isMainNavigationRoute = mainRoutes.contains(item.route);

    return Builder(
      builder: (snackBarContext) => ListTile(
        leading: item.supportsBadge
            ? _buildIconWithBadge(item, isCurrentRoute)
            : Icon(
                item.icon,
                color: isCurrentRoute
                    ? ArtbeatColors.primaryGreen
                    : (item.color ?? ArtbeatColors.primaryPurple),
              ),
        title: Text(
          item.title.tr(),
          style: ArtbeatTypography.textTheme.bodyMedium?.copyWith(
            fontWeight: isCurrentRoute ? FontWeight.w600 : FontWeight.w500,
            color: isCurrentRoute ? ArtbeatColors.primaryGreen : item.color,
          ),
        ),
        selected: isCurrentRoute,
        onTap: () async {
          // Handle sign out specially
          if (item.route == '/login' && item.title == 'drawer_sign_out') {
            Navigator.pop(context); // Close drawer
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              setState(() => _cachedUserModel = null);
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/login');
            }
            return;
          }

          // Close drawer first
          Navigator.pop(context);

          if (!isCurrentRoute) {
            // Add a small delay to ensure drawer is fully closed
            await Future<void>.delayed(const Duration(milliseconds: 250));
            if (mounted) {
              try {
                _handleNavigation(
                  // ignore: use_build_context_synchronously
                  context,
                  // ignore: use_build_context_synchronously
                  snackBarContext,
                  item.route,
                  isMainNavigationRoute,
                );
              } catch (error) {
                AppLogger.error('⚠️ Error in drawer navigation: $error');
                // ignore: use_build_context_synchronously
                _showError(context, 'Navigation failed: ${error.toString()}');
              }
            }
          }
        },
      ),
    );
  }

  Widget _buildIconWithBadge(ArtbeatDrawerItem item, bool isCurrentRoute) {
    // For messaging item, show unread count badge
    if (item.route == '/messaging') {
      return StreamBuilder<int>(
        stream: ChatService().getTotalUnreadCount(),
        builder: (context, snapshot) {
          final unreadCount = snapshot.data ?? 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                item.icon,
                color: isCurrentRoute
                    ? ArtbeatColors.primaryGreen
                    : (item.color ?? ArtbeatColors.primaryPurple),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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

    // For other items that support badges, return regular icon for now
    return Icon(
      item.icon,
      color: isCurrentRoute
          ? ArtbeatColors.primaryGreen
          : (item.color ?? ArtbeatColors.primaryPurple),
    );
  }
}
