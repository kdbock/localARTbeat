import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Capture specific drawer with focused navigation for capture features
/// Updated to match the new "Quest / Glass / Neon" theme.
class CaptureDrawer extends StatefulWidget {
  const CaptureDrawer({super.key});

  @override
  State<CaptureDrawer> createState() => _CaptureDrawerState();
}

class _CaptureDrawerState extends State<CaptureDrawer>
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
                      _buildSectionHeader('capture_drawer_quick_actions'.tr()),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_take_photo'.tr(),
                        Icons.camera_alt_rounded,
                        '/capture/camera',
                        const Color(0xFF34D399), // green
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_browse_captures'.tr(),
                        Icons.grid_view_rounded,
                        '/capture/browse',
                        const Color(0xFF22D3EE), // teal
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('capture_drawer_my_captures'.tr()),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_my_captures_item'.tr(),
                        Icons.photo_album_rounded,
                        '/capture/my-captures',
                        const Color(0xFF34D399),
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_pending_review'.tr(),
                        Icons.hourglass_top_rounded,
                        '/capture/pending',
                        const Color(0xFFFFC857), // yellow
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_approved_captures'.tr(),
                        Icons.verified_rounded,
                        '/capture/approved',
                        const Color(0xFF22D3EE),
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('capture_drawer_community'.tr()),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_public_captures'.tr(),
                        Icons.public_rounded,
                        '/capture/public',
                        const Color(0xFF7C4DFF), // purple
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_nearby_art'.tr(),
                        Icons.my_location_rounded,
                        '/capture/nearby',
                        const Color(0xFF22D3EE),
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_popular_captures'.tr(),
                        Icons.trending_up_rounded,
                        '/capture/popular',
                        const Color(0xFFFF3D8D), // pink
                      ),

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('capture_drawer_tools'.tr()),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_search_captures'.tr(),
                        Icons.search_rounded,
                        '/capture/search',
                        const Color(0xFF34D399),
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_capture_map'.tr(),
                        Icons.map_rounded,
                        '/capture/map',
                        const Color(0xFF7C4DFF),
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_capture_settings'.tr(),
                        Icons.settings_rounded,
                        '/capture/settings',
                        Colors.white.withValues(alpha: 0.65),
                      ),

                      // Moderation (admin)
                      if (_currentUser?.userType == UserType.admin) ...[
                        const SizedBox(height: 10),
                        const _QuestDivider(),
                        const SizedBox(height: 10),
                        _buildSectionHeader('capture_drawer_moderation'.tr()),
                        _buildDrawerItem(
                          context,
                          'capture_drawer_content_moderation'.tr(),
                          Icons.admin_panel_settings_rounded,
                          '/capture/admin/moderation',
                          const Color(0xFFFF3D8D),
                        ),
                      ],

                      const SizedBox(height: 10),
                      const _QuestDivider(),
                      const SizedBox(height: 10),

                      _buildSectionHeader('capture_drawer_navigation'.tr()),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_main_dashboard'.tr(),
                        Icons.dashboard_rounded,
                        '/dashboard',
                        Colors.white.withValues(alpha: 0.65),
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_art_walk'.tr(),
                        Icons.route_rounded,
                        '/art-walk/dashboard',
                        const Color(0xFF22D3EE),
                      ),
                      _buildDrawerItem(
                        context,
                        'capture_drawer_profile'.tr(),
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
        _currentUser?.fullName ?? user?.displayName ?? 'Art Capturer';
    final email = user?.email ?? '';
    final profileImageUrl = _currentUser?.profileImageUrl;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: _QuestGlass(
        radius: 22,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Stack(
          children: [
            // Animated scan band
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
                _NeonChip(
                  label: 'capture_drawer_art_capture'.tr().toUpperCase(),
                  accent: const Color(0xFF34D399),
                  icon: Icons.camera_alt_rounded,
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
                            'capture_drawer_ready_to_capture'.tr(),
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

                    // Camera capsule
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
                        Icons.camera_alt_rounded,
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
            _navigateToRoute(snackBarContext, route);
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
        onTap: () => _signOut(context),
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
              const _QuestIconCapsule(
                icon: Icons.logout_rounded,
                accent: Color(0xFFFF3D8D),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'capture_drawer_sign_out'.tr(),
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

  void _navigateToRoute(BuildContext context, String route) {
    Navigator.pop(context); // Close drawer

    // Keep your original behavior
    const mainRoutes = ['/dashboard', '/profile'];
    if (mainRoutes.contains(route)) {
      Navigator.pushReplacementNamed(context, route);
    } else {
      Navigator.pushNamed(context, route);
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        // ignore: use_build_context_synchronously
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      }
    } catch (e) {
      if (mounted) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_drawer_error_signing_out'.tr().replaceAll(
                    '{error}',
                    e.toString(),
                  ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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

    blob(const Color(0xFF34D399), 0.16, 0.16, 0.40, 0.00); // green
    blob(const Color(0xFF22D3EE), 0.82, 0.22, 0.34, 0.22); // teal
    blob(const Color(0xFFFF3D8D), 0.78, 0.78, 0.48, 0.48); // pink
    blob(const Color(0xFF7C4DFF), 0.14, 0.80, 0.36, 0.62); // purple

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
