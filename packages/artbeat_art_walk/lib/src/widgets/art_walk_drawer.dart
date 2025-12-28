import 'package:artbeat_art_walk/src/widgets/glass_card.dart';
import 'package:artbeat_art_walk/src/widgets/gradient_cta_button.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:artbeat_art_walk/src/widgets/world_background.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtWalkDrawer extends StatefulWidget {
  const ArtWalkDrawer({super.key});

  @override
  State<ArtWalkDrawer> createState() => _ArtWalkDrawerState();
}

class _ArtWalkDrawerState extends State<ArtWalkDrawer> {
  UserModel? _currentUser;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final primaryActionItem = _drawerSections.first.items.first;

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: WorldBackground(
        child: SafeArea(
          child: Column(
            children: [
              _DrawerHeader(
                displayName:
                    _currentUser?.fullName ??
                    firebaseUser?.displayName ??
                    'art_walk_drawer_art_walker'.tr(),
                email: firebaseUser?.email,
                avatarUrl: _currentUser?.profileImageUrl,
                onCreateArtWalk: () =>
                    _handleNavigation(context, primaryActionItem, currentRoute),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _drawerSections.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    if (index == _drawerSections.length) {
                      return _SignOutCard(
                        onTap: () => _confirmSignOut(context),
                      );
                    }

                    final section = _drawerSections[index];
                    return _DrawerSectionCard(
                      section: section,
                      currentRoute: currentRoute,
                      onTap: (item) =>
                          _handleNavigation(context, item, currentRoute),
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

  Future<void> _handleNavigation(
    BuildContext context,
    _DrawerNavItem item,
    String? currentRoute,
  ) async {
    Navigator.of(context).pop();
    if (item.route == currentRoute) return;

    final navigator = Navigator.of(context, rootNavigator: true);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;

    AppLogger.info('ArtWalkDrawer: navigate to ${item.route}');
    if (_shouldPush(item.route)) {
      navigator.pushNamed(item.route);
    } else {
      navigator.pushReplacementNamed(item.route);
    }
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    Navigator.of(context).pop();
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF0B1026),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        title: Text(
          'art_walk_button_sign_out'.tr(),
          style: AppTypography.screenTitle(
            Colors.white.withValues(alpha: 0.92),
          ),
        ),
        content: Text(
          'art_walk_art_walk_drawer_text_are_you_sure_you_want_to_sign_out'
              .tr(),
          style: AppTypography.body(Colors.white.withValues(alpha: 0.75)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              'art_walk_button_cancel'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              'art_walk_button_sign_out'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                color: const Color(0xFFFF3D8D),
              ),
            ),
          ),
        ],
      ),
    );

    if (shouldSignOut != true) return;

    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    // ignore: use_build_context_synchronously
    Navigator.of(context, rootNavigator: true).pushReplacementNamed('/login');
  }

  bool _shouldPush(String route) {
    return route.startsWith('/art-walk/') ||
        route == '/capture/public' ||
        route == '/quest-history' ||
        route == '/weekly-goals';
  }
}

class _DrawerHeader extends StatelessWidget {
  final String displayName;
  final String? email;
  final String? avatarUrl;
  final VoidCallback onCreateArtWalk;

  const _DrawerHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.onCreateArtWalk,
  });

  @override
  Widget build(BuildContext context) {
    final avatarImage = ImageUrlValidator.safeNetworkImage(avatarUrl);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      child: GlassCard(
        borderRadius: 30,
        padding: const EdgeInsets.all(20),
        fillColor: Colors.white.withValues(alpha: 0.06),
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 30,
          offset: const Offset(0, 18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'art_walk_drawer_welcome_back'.tr().toUpperCase(),
              style: AppTypography.sectionLabel(
                Colors.white.withValues(alpha: 0.7),
              ).copyWith(letterSpacing: 0.8),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : 'A',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      if (email != null && email!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatusChip(
                  icon: Icons.auto_awesome,
                  label: 'art_walk_drawer_my_art_walks'.tr(),
                ),
                _StatusChip(
                  icon: Icons.radar,
                  label: 'art_walk_drawer_discover'.tr(),
                  accent: const Color(0xFF22D3EE),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GradientCTAButton(
              label: 'art_walk_drawer_create_art_walk'.tr(),
              icon: Icons.add_location_alt,
              onPressed: onCreateArtWalk,
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerSectionCard extends StatelessWidget {
  final _DrawerSectionConfig section;
  final String? currentRoute;
  final ValueChanged<_DrawerNavItem> onTap;

  const _DrawerSectionCard({
    required this.section,
    required this.currentRoute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      fillColor: Colors.white.withValues(alpha: 0.06),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            section.titleKey.tr().toUpperCase(),
            style: AppTypography.sectionLabel(
              Colors.white.withValues(alpha: 0.7),
            ).copyWith(letterSpacing: 0.9),
          ),
          const SizedBox(height: 12),
          ...section.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _DrawerNavTile(
                item: item,
                isActive: currentRoute == item.route,
                onTap: () => onTap(item),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerNavTile extends StatelessWidget {
  final _DrawerNavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerNavTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final background = isActive
        ? const Color(0xFF34D399).withValues(alpha: 0.16)
        : Colors.white.withValues(alpha: 0.04);
    final borderColor = isActive
        ? const Color(0xFF34D399).withValues(alpha: 0.32)
        : Colors.white.withValues(alpha: 0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: background,
            border: Border.all(color: borderColor),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: const Color(0xFF34D399).withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 12),
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              _IconBadge(icon: item.icon, accent: item.accent),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.titleKey.tr(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w900 : FontWeight.w700,
                    color: Colors.white.withValues(
                      alpha: isActive ? 0.95 : 0.82,
                    ),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignOutCard extends StatelessWidget {
  final VoidCallback onTap;

  const _SignOutCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: 28,
      fillColor: const Color(0xFFFF3D8D).withValues(alpha: 0.08),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Row(
              children: [
                const _IconBadge(
                  icon: Icons.logout_rounded,
                  accent: Color(0xFFFF3D8D),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'art_walk_drawer_sign_out'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;

  const _StatusChip({
    required this.icon,
    required this.label,
    this.accent = const Color(0xFF34D399),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
        color: accent.withValues(alpha: 0.10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color accent;

  const _IconBadge({required this.icon, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, const Color(0xFF22D3EE)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

class _DrawerNavItem {
  final String titleKey;
  final IconData icon;
  final String route;
  final Color accent;

  const _DrawerNavItem({
    required this.titleKey,
    required this.icon,
    required this.route,
    required this.accent,
  });
}

class _DrawerSectionConfig {
  final String titleKey;
  final List<_DrawerNavItem> items;

  const _DrawerSectionConfig({required this.titleKey, required this.items});
}

const _drawerSections = <_DrawerSectionConfig>[
  _DrawerSectionConfig(
    titleKey: 'art_walk_drawer_quick_actions',
    items: [
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_create_art_walk',
        icon: Icons.add_location_alt_rounded,
        route: '/art-walk/create',
        accent: Color(0xFFFFC857),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_explore_map',
        icon: Icons.map_rounded,
        route: '/art-walk/map',
        accent: Color(0xFF34D399),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_browse_walks',
        icon: Icons.route_rounded,
        route: '/art-walk/list',
        accent: Color(0xFF22D3EE),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_messages',
        icon: Icons.forum_rounded,
        route: '/messaging',
        accent: Color(0xFFFF3D8D),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_search',
        icon: Icons.search_rounded,
        route: '/search',
        accent: Color(0xFF7C4DFF),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_main_dashboard',
        icon: Icons.dashboard_rounded,
        route: '/dashboard',
        accent: Color(0xFF7C4DFF),
      ),
    ],
  ),
  _DrawerSectionConfig(
    titleKey: 'art_walk_drawer_my_art_walks',
    items: [
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_my_walks',
        icon: Icons.directions_walk_rounded,
        route: '/art-walk/my-walks',
        accent: Color(0xFF34D399),
      ),
    ],
  ),
  _DrawerSectionConfig(
    titleKey: 'art_walk_drawer_discover',
    items: [
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_nearby_art',
        icon: Icons.my_location_rounded,
        route: '/art-walk/nearby',
        accent: Color(0xFFFFC857),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_instant_discovery',
        icon: Icons.radar_rounded,
        route: '/instant-discovery',
        accent: Color(0xFF34D399),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_popular_walks',
        icon: Icons.trending_up_rounded,
        route: '/art-walk/popular',
        accent: Color(0xFFFF3D8D),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_achievements',
        icon: Icons.emoji_events_rounded,
        route: '/art-walk/achievements',
        accent: Color(0xFFFFC857),
      ),
    ],
  ),
  _DrawerSectionConfig(
    titleKey: 'art_walk_drawer_gamification',
    items: [
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_quest_history',
        icon: Icons.assignment_turned_in_rounded,
        route: '/quest-history',
        accent: Color(0xFF22D3EE),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_weekly_goals',
        icon: Icons.flag_rounded,
        route: '/weekly-goals',
        accent: Color(0xFFFFC857),
      ),
    ],
  ),
  _DrawerSectionConfig(
    titleKey: 'art_walk_drawer_tools',
    items: [
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_my_captures',
        icon: Icons.camera_alt_rounded,
        route: '/art-walk/my-captures',
        accent: Color(0xFF34D399),
      ),
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_art_walk_settings',
        icon: Icons.settings_rounded,
        route: '/art-walk/settings',
        accent: Color(0xFF7C7E91),
      ),
    ],
  ),
  _DrawerSectionConfig(
    titleKey: 'art_walk_drawer_navigation',
    items: [
      _DrawerNavItem(
        titleKey: 'art_walk_drawer_profile',
        icon: Icons.person_rounded,
        route: '/profile',
        accent: Color(0xFF7C7E91),
      ),
    ],
  ),
];
