import 'dart:async';
import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:artbeat_messaging/artbeat_messaging.dart';

import '../theme/artbeat_colors.dart';
import '../services/user_service.dart';
import '../models/user_model.dart' as core;
import 'artbeat_drawer_items.dart';
import 'user_avatar.dart';
import '../utils/logger.dart';

// Define main navigation routes that should use pushReplacement
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

class _ArtbeatDrawerState extends State<ArtbeatDrawer>
    with TickerProviderStateMixin {
  core.UserModel? _cachedUserModel;
  StreamSubscription<User?>? _authSubscription;
  String? _roleOverride; // For admin role switching

  late final AnimationController _loop; // ambient animation

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _loadUserModel();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? user,
    ) {
      if (user != null && _cachedUserModel == null) {
        _loadUserModel();
      } else if (user == null && _cachedUserModel != null) {
        if (mounted) {
          setState(() {
            _cachedUserModel = null;
            _roleOverride = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _loop.dispose();
    super.dispose();
  }

  Future<void> _loadUserModel() async {
    try {
      final userService = Provider.of<UserService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final model = await userService.getUserById(user.uid);
        if (mounted) setState(() => _cachedUserModel = model);

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
    if (!snackBarContext.mounted) return;

    final implementedRoutes = {
      '/dashboard',
      '/profile',
      '/profile/edit',
      '/login',
      '/register',
      '/browse',
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
      '/art-walk/experience',
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
      '/settings',
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

    if (route == '/store') {
      Navigator.of(snackBarContext, rootNavigator: true).pushNamed('/store');
      return;
    }

    if (implementedRoutes.contains(route)) {
      try {
        AppLogger.info('🔄 Navigating to: $route (isMainRoute: $isMainRoute)');
        if (isMainRoute && mainRoutes.contains(route)) {
          Navigator.of(
            snackBarContext,
            rootNavigator: true,
          ).pushReplacementNamed(route);
        } else {
          Navigator.of(snackBarContext, rootNavigator: true).pushNamed(route);
        }
      } catch (error) {
        AppLogger.error('⚠️ Navigation error for route $route: $error');
        _showError(snackBarContext, error.toString());
      }
    } else {
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'drawer_navigation_error'.tr(namedArgs: {'error': error.toString()}),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String? _getUserRole() {
    if (_roleOverride != null && _isCurrentUserAdmin()) {
      if (_roleOverride == 'user') return null;
      return _roleOverride;
    }

    final userModel = _cachedUserModel;
    if (userModel != null) {
      if (userModel.isAdmin) return 'admin';
      if (userModel.isArtist) return 'artist';
      if (userModel.isGallery) return 'gallery';
      if (userModel.isModerator) return 'moderator';
    }
    return null;
  }

  bool _isCurrentUserAdmin() => _cachedUserModel?.isAdmin ?? false;

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
          _roleOverride = null;
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
      backgroundColor: const Color(0xFF07060F),
      elevation: 0,
      child: SafeArea(
        child: Stack(
          children: [
            // Ambient background inside drawer
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) => CustomPaint(
                  painter: _DrawerAmbientPainter(t: _loop.value),
                  size: Size.infinite,
                ),
              ),
            ),

            // Content
            Column(
              children: [
                _buildDrawerHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
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
          ],
        ),
      ),
    );
  }

  int _calculateTotalItems(List<DrawerSection> sections) {
    int total = 0;
    for (final section in sections) {
      if (section.title != null) total++;
      total += section.items.length;
      if (section.showDivider) total++;
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
      if (section.title != null) {
        if (currentIndex == index) return _buildSectionHeader(section.title!);
        currentIndex++;
      }

      for (final item in section.items) {
        if (currentIndex == index) {
          if (item.route == '/login') {
            return Column(
              children: [
                const SizedBox(height: 8),
                const _QuestDivider(),
                const SizedBox(height: 8),
                _buildDrawerItem(context, item),
              ],
            );
          }
          return _buildDrawerItem(context, item);
        }
        currentIndex++;
      }

      if (section.showDivider) {
        if (currentIndex == index) return const _QuestDivider();
        currentIndex++;
      }
    }

    return const SizedBox.shrink();
  }

  Widget _buildDrawerHeader() {
    final headerHeight = _isCurrentUserAdmin() ? 170.0 : 150.0;

    return SizedBox(
      height: headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: _QuestGlass(
          radius: 22,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Stack(
            children: [
              // Decorative logo watermark
              Positioned(
                right: -6,
                top: -6,
                child: Opacity(
                  opacity: 0.16,
                  child: Image.asset(
                    'assets/images/artbeat_logo.png',
                    width: 70,
                    height: 70,
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Subtle shimmer band
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _loop,
                    builder: (_, __) {
                      final sweep = (_loop.value * 1.15) % 1.0;
                      return Opacity(
                        opacity: 0.65,
                        child: Transform.translate(
                          offset: Offset((sweep * 2 - 1) * 220, 0),
                          child: Transform.rotate(
                            angle: -0.55,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.white.withValues(alpha: 0.14),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.5, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // User info
              StreamBuilder<User?>(
                stream: FirebaseAuth.instance.userChanges(),
                builder: (context, snapshot) {
                  final user = snapshot.data;

                  if (user == null) {
                    return const _HeaderUserBlock(
                      displayName: 'Guest User',
                      subtitle: 'Not signed in',
                      role: null,
                      profileUrl: null,
                      showRoleToggle: false,
                      roleToggle: null,
                      isAdmin: false,
                      modeChip: null,
                    );
                  }

                  final userModel = _cachedUserModel;
                  final displayName =
                      userModel?.fullName ?? user.displayName ?? 'User';
                  final profileImageUrl = userModel?.profileImageUrl;

                  final role = _getUserRole();
                  final isAdmin = _isCurrentUserAdmin();

                  return _HeaderUserBlock(
                    displayName: displayName,
                    subtitle: user.email ?? '',
                    role: role,
                    profileUrl: profileImageUrl,
                    showRoleToggle: isAdmin,
                    roleToggle: isAdmin ? _buildRoleToggleChip() : null,
                    isAdmin: isAdmin,
                    modeChip: _buildModeChip(role),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip(String? role) {
    // "Local ARTbeat" brand chip (always)
    final label = role == null
        ? "LOCAL ARTBEAT"
        : "LOCAL ARTBEAT • ${role.toUpperCase()}";
    return _NeonChip(
      label: label,
      accent: const Color(0xFF22D3EE),
      icon: Icons.radar_rounded,
    );
  }

  Widget _buildRoleToggleChip() {
    final currentViewRole = _roleOverride ?? 'admin';
    String displayText;
    Color badgeColor;
    IconData icon;

    switch (currentViewRole) {
      case 'admin':
        displayText = 'ADMIN MODE';
        badgeColor = ArtbeatColors.primaryPurple;
        icon = Icons.admin_panel_settings_rounded;
        break;
      case 'user':
        displayText = 'USER MODE';
        badgeColor = ArtbeatColors.textSecondary;
        icon = Icons.person_rounded;
        break;
      case 'artist':
        displayText = 'ARTIST MODE';
        badgeColor = ArtbeatColors.primaryGreen;
        icon = Icons.palette_rounded;
        break;
      case 'gallery':
        displayText = 'GALLERY MODE';
        badgeColor = const Color(0xFF2196F3);
        icon = Icons.business_rounded;
        break;
      case 'moderator':
        displayText = 'MOD MODE';
        badgeColor = const Color(0xFFFF9800);
        icon = Icons.gavel_rounded;
        break;
      default:
        displayText = 'ADMIN MODE';
        badgeColor = ArtbeatColors.primaryPurple;
        icon = Icons.admin_panel_settings_rounded;
    }

    return InkWell(
      onTap: _toggleRoleOverride,
      borderRadius: BorderRadius.circular(999),
      child: _NeonChip(
        label: displayText,
        accent: badgeColor,
        icon: icon,
        trailing: Icons.swap_horiz_rounded,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title.tr().toUpperCase(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.62),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(BuildContext context, ArtbeatDrawerItem item) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final bool isCurrentRoute = currentRoute == item.route;
    final bool isMainNavigationRoute = mainRoutes.contains(item.route);

    final Color accent = item.color ?? const Color(0xFF7C4DFF);
    const Color activeAccent = Color(0xFF34D399);

    return Builder(
      builder: (snackBarContext) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            // Handle sign out specially (keep same logic)
            if (item.route == '/login' && item.title == 'drawer_sign_out') {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                setState(() => _cachedUserModel = null);
                // ignore: use_build_context_synchronously
                Navigator.pushReplacementNamed(context, '/login');
              }
              return;
            }

            Navigator.pop(context);

            if (!isCurrentRoute) {
              await Future<void>.delayed(const Duration(milliseconds: 220));
              if (!mounted) return;

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
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isCurrentRoute
                  ? activeAccent.withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: isCurrentRoute
                    ? activeAccent.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.10),
              ),
              boxShadow: [
                if (isCurrentRoute)
                  BoxShadow(
                    color: activeAccent.withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Row(
              children: [
                // Icon capsule (with badge support)
                _QuestIconCapsule(
                  iconBuilder: item.supportsBadge
                      ? () => _buildIconWithBadge(item, isCurrentRoute)
                      : () => Icon(
                          item.icon,
                          color: Colors.white.withValues(alpha: 0.92),
                          size: 20,
                        ),
                  accent: isCurrentRoute ? activeAccent : accent,
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    item.title.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(
                        alpha: isCurrentRoute ? 0.95 : 0.82,
                      ),
                      fontWeight: isCurrentRoute
                          ? FontWeight.w900
                          : FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconWithBadge(ArtbeatDrawerItem item, bool isCurrentRoute) {
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
                color: Colors.white.withValues(alpha: 0.92),
                size: 20,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -7,
                  top: -7,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3D8D),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFFFF3D8D,
                          ).withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.black.withValues(alpha: 0.88),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );
    }

    return Icon(
      item.icon,
      color: Colors.white.withValues(alpha: 0.92),
      size: 20,
    );
  }
}

/// =======================
/// Header building blocks
/// =======================

class _HeaderUserBlock extends StatelessWidget {
  final String displayName;
  final String subtitle;
  final String? role;
  final String? profileUrl;

  final bool showRoleToggle;
  final Widget? roleToggle;

  final bool isAdmin;
  final Widget? modeChip;

  const _HeaderUserBlock({
    required this.displayName,
    required this.subtitle,
    required this.role,
    required this.profileUrl,
    required this.showRoleToggle,
    required this.roleToggle,
    required this.isAdmin,
    required this.modeChip,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 70),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (modeChip != null) ...[modeChip!, const SizedBox(height: 10)],
          Row(
            children: [
              UserAvatar(
                imageUrl: profileUrl,
                displayName: displayName,
                radius: 16,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Role badge row
          Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              if (role != null)
                Flexible(
                  child: _NeonChip(
                    label: role!.toUpperCase(),
                    accent: const Color(0xFF7C4DFF),
                    icon: Icons.verified_rounded,
                  ),
                ),
              if (role != null) const SizedBox(width: 8),
              if (showRoleToggle && roleToggle != null)
                Flexible(child: roleToggle!),
            ],
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Visual atoms
/// =======================

class _QuestDivider extends StatelessWidget {
  const _QuestDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: 0.14),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}

class _QuestIconCapsule extends StatelessWidget {
  final Widget Function() iconBuilder;
  final Color accent;

  const _QuestIconCapsule({required this.iconBuilder, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.95),
            const Color(0xFF22D3EE).withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(child: iconBuilder()),
    );
  }
}

class _NeonChip extends StatelessWidget {
  final String label;
  final Color accent;
  final IconData icon;
  final IconData? trailing;

  const _NeonChip({
    required this.label,
    required this.accent,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: accent.withValues(alpha: 0.14),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white.withValues(alpha: 0.92)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.92),
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Icon(
              trailing,
              size: 16,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ],
        ],
      ),
    );
  }
}

class _QuestGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  const _QuestGlass({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.40),
                blurRadius: 26,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Subtle ambient painter for the drawer background
class _DrawerAmbientPainter extends CustomPainter {
  final double t;
  _DrawerAmbientPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    void blob(Color c, double ax, double ay, double r, double phase) {
      final dx = math.sin((t + phase) * 2 * math.pi) * 0.03;
      final dy = math.cos((t + phase) * 2 * math.pi) * 0.03;
      final center = Offset(size.width * (ax + dx), size.height * (ay + dy));
      final radius = size.width * r;

      final paint = Paint()
        ..shader = RadialGradient(
          colors: [c.withValues(alpha: 0.20), c.withValues(alpha: 0.0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

      canvas.drawCircle(center, radius, paint);
    }

    blob(const Color(0xFF22D3EE), 0.18, 0.18, 0.38, 0.00);
    blob(const Color(0xFF7C4DFF), 0.82, 0.22, 0.32, 0.22);
    blob(const Color(0xFFFF3D8D), 0.76, 0.78, 0.46, 0.48);
    blob(const Color(0xFF34D399), 0.14, 0.80, 0.34, 0.62);

    // Mild vignette
    final vignette = Paint()
      ..shader = RadialGradient(
        radius: 1.15,
        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.62)],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, vignette);
  }

  @override
  bool shouldRepaint(covariant _DrawerAmbientPainter oldDelegate) =>
      oldDelegate.t != t;
}
