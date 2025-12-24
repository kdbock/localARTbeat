import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/artbeat_art_walk.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';

/// Art Walk specific drawer with focused navigation for art walk features
class ArtWalkDrawer extends StatefulWidget {
  const ArtWalkDrawer({super.key});

  @override
  State<ArtWalkDrawer> createState() => _ArtWalkDrawerState();
}

class _ArtWalkDrawerState extends State<ArtWalkDrawer>
    with TickerProviderStateMixin {
  UserModel? _currentUser;
  final UserService _userService = UserService();

  late final AnimationController _loop;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _loadCurrentUser();
  }

  @override
  void dispose() {
    _loop.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _userService.getCurrentUserModel();
      if (mounted) setState(() => _currentUser = user);
    } catch (_) {
      // silent
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF07060F),
      elevation: 0,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _loop,
                builder: (_, __) => CustomPaint(
                  painter: _DrawerAmbientPainter(t: _loop.value),
                  size: Size.infinite,
                ),
              ),
            ),
            Column(
              children: [
                _buildDrawerHeader(context),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                    children: [
                      _buildSectionHeader('art_walk_drawer_quick_actions'.tr()),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_create_art_walk'.tr(),
                        Icons.add_location_alt_rounded,
                        '/art-walk/create',
                        const Color(0xFFFFC857),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_explore_map'.tr(),
                        Icons.map_rounded,
                        '/art-walk/map',
                        const Color(0xFF34D399),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_browse_walks'.tr(),
                        Icons.route_rounded,
                        '/art-walk/list',
                        const Color(0xFF22D3EE),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_messages'.tr(),
                        Icons.forum_rounded,
                        '/messaging/inbox',
                        const Color(0xFFFF3D8D),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_search'.tr(),
                        Icons.search_rounded,
                        '/search',
                        const Color(0xFF7C4DFF),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_main_dashboard'.tr(),
                        Icons.dashboard_rounded,
                        '/dashboard',
                        const Color(0xFF7C4DFF),
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('art_walk_drawer_my_art_walks'.tr()),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_my_walks'.tr(),
                        Icons.directions_walk_rounded,
                        '/art-walk/my-walks',
                        const Color(0xFF34D399),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_completed_walks'.tr(),
                        Icons.verified_rounded,
                        '/art-walk/completed',
                        const Color(0xFF22D3EE),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_saved_walks'.tr(),
                        Icons.bookmark_rounded,
                        '/art-walk/saved',
                        const Color(0xFFFFC857),
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('art_walk_drawer_discover'.tr()),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_nearby_art'.tr(),
                        Icons.my_location_rounded,
                        '/art-walk/nearby',
                        const Color(0xFFFFC857),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_instant_discovery'.tr(),
                        Icons.radar_rounded,
                        '/instant-discovery',
                        const Color(0xFF34D399),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_popular_walks'.tr(),
                        Icons.trending_up_rounded,
                        '/art-walk/popular',
                        const Color(0xFFFF3D8D),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_achievements'.tr(),
                        Icons.emoji_events_rounded,
                        '/art-walk/achievements',
                        const Color(0xFFFFC857),
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('art_walk_drawer_gamification'.tr()),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_quest_history'.tr(),
                        Icons.assignment_turned_in_rounded,
                        '/quest-history',
                        const Color(0xFF22D3EE),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_weekly_goals'.tr(),
                        Icons.flag_rounded,
                        '/weekly-goals',
                        const Color(0xFFFFC857),
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('art_walk_drawer_tools'.tr()),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_my_captures'.tr(),
                        Icons.camera_alt_rounded,
                        '/art-walk/my-captures',
                        const Color(0xFF34D399),
                      ),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_art_walk_settings'.tr(),
                        Icons.settings_rounded,
                        '/art-walk/settings',
                        Colors.white.withValues(alpha: 0.65),
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('art_walk_drawer_navigation'.tr()),
                      _buildDrawerItem(
                        context,
                        'art_walk_drawer_profile'.tr(),
                        Icons.person_rounded,
                        '/profile',
                        Colors.white.withValues(alpha: 0.65),
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSignOutItem(context),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName =
        _currentUser?.fullName ??
        user?.displayName ??
        'art_walk_drawer_art_walker'.tr();
    final email = user?.email ?? '';
    final profileImageUrl = _currentUser?.profileImageUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: _QuestGlass(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Stack(
          children: [
            // Shimmer band
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: _loop,
                  builder: (_, __) {
                    final sweep = (_loop.value * 1.1) % 1.0;
                    return Opacity(
                      opacity: 0.60,
                      child: Transform.translate(
                        offset: Offset((sweep * 2 - 1) * 240, 0),
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

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mode chip
                _NeonChip(
                  label: "ART WALKS • QUEST MENU",
                  accent: const Color(0xFF22D3EE),
                  icon: Icons.route_rounded,
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      backgroundImage:
                          ImageUrlValidator.safeNetworkImage(profileImageUrl),
                      child: (profileImageUrl == null ||
                              !ImageUrlValidator.isValidImageUrl(
                                profileImageUrl,
                              ))
                          ? Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'A',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'art_walk_drawer_welcome_back'.tr(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.62),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                            ),
                          ),
                          if (email.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Icon capsule
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF34D399).withValues(alpha: 0.95),
                            const Color(0xFF22D3EE).withValues(alpha: 0.75),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFF34D399).withValues(alpha: 0.20),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.directions_walk_rounded,
                        color: Colors.white.withValues(alpha: 0.92),
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
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
              title.toUpperCase(),
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

  Widget _buildDrawerItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    Color accent,
  ) {
    final currentRoute = ModalRoute.of(context)?.settings.name;
    final isCurrentRoute = currentRoute == route;

    return Builder(
      builder: (snackBarContext) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () async {
            Navigator.pop(context);
            if (route == currentRoute) return;

            await Future<void>.delayed(const Duration(milliseconds: 250));
            if (!mounted) return;
            if (!snackBarContext.mounted) return;

            // Keep your navigation rules EXACTLY
            AppLogger.info(
              'ArtWalkDrawer: navigate to $route (current: $currentRoute)',
            );
            if (route.startsWith('/art-walk/') ||
                route == '/capture/public' ||
                route == '/quest-history' ||
                route == '/weekly-goals') {
              Navigator.of(snackBarContext, rootNavigator: true).pushNamed(route);
            } else {
              Navigator.of(snackBarContext, rootNavigator: true)
                  .pushReplacementNamed(route);
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: isCurrentRoute
                  ? const Color(0xFF34D399).withValues(alpha: 0.14)
                  : Colors.white.withValues(alpha: 0.05),
              border: Border.all(
                color: isCurrentRoute
                    ? const Color(0xFF34D399).withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.10),
              ),
              boxShadow: [
                if (isCurrentRoute)
                  BoxShadow(
                    color: const Color(0xFF34D399).withValues(alpha: 0.18),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
              ],
            ),
            child: Row(
              children: [
                _QuestIconCapsule(
                  icon: icon,
                  accent: isCurrentRoute ? const Color(0xFF34D399) : accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(
                        alpha: isCurrentRoute ? 0.95 : 0.82,
                      ),
                      fontWeight:
                          isCurrentRoute ? FontWeight.w900 : FontWeight.w800,
                      fontSize: 14,
                      letterSpacing: -0.1,
                    ),
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

  Widget _buildSignOutItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          Navigator.pop(context);

          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: const Color(0xFF0B1026),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: Colors.white.withValues(alpha: 0.10),
                ),
              ),
              title: Text(
                'art_walk_button_sign_out'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w900,
                ),
              ),
              content: Text(
                'art_walk_art_walk_drawer_text_are_you_sure_you_want_to_sign_out'
                    .tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontWeight: FontWeight.w700,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'art_walk_button_cancel'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFF3D8D),
                  ),
                  child: Text(
                    'art_walk_button_sign_out'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await FirebaseAuth.instance.signOut();
            if (mounted) {
              // ignore: use_build_context_synchronously
              Navigator.pushReplacementNamed(context, '/login');
            }
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFFF3D8D).withValues(alpha: 0.10),
            border: Border.all(
              color: const Color(0xFFFF3D8D).withValues(alpha: 0.22),
            ),
          ),
          child: Row(
            children: [
              _QuestIconCapsule(
                icon: Icons.logout_rounded,
                accent: const Color(0xFFFF3D8D),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'art_walk_drawer_sign_out'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.90),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.1,
                  ),
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
    );
  }
}

/// =======================
/// Visual atoms + ambient background
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
  final IconData icon;
  final Color accent;

  const _QuestIconCapsule({required this.icon, required this.accent});

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
            const Color(0xFF22D3EE).withValues(alpha: 0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white.withValues(alpha: 0.92),
        size: 20,
      ),
    );
  }
}

class _NeonChip extends StatelessWidget {
  final String label;
  final Color accent;
  final IconData icon;

  const _NeonChip({
    required this.label,
    required this.accent,
    required this.icon,
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
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.6,
            ),
          ),
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

class _DrawerAmbientPainter extends CustomPainter {
  final double t;
  _DrawerAmbientPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
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
