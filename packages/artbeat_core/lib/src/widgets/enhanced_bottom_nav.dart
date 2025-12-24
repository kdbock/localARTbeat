// ignore_for_file: deprecated_member_use, duplicate_ignore

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/artbeat_colors.dart';
import '../providers/community_provider.dart';

/// Enhanced Bottom Navigation (Quest HUD reskin)
/// - Keeps indices + onTap behavior the same
/// - Keeps CommunityProvider unreadCount badge
/// - Keeps capture (index 2) special button
/// - Adds subtle scan + neon rim + reticle for active tab
class EnhancedBottomNav extends StatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;
  final bool showLabels;
  final List<BottomNavItem> items;
  final Color? backgroundColor;
  final Color? activeColor;
  final Color? inactiveColor;
  final double? elevation;

  const EnhancedBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showLabels = true,
    this.items = const [],
    this.backgroundColor,
    this.activeColor,
    this.inactiveColor,
    this.elevation,
  });

  @override
  State<EnhancedBottomNav> createState() => _EnhancedBottomNavState();
}

class _EnhancedBottomNavState extends State<EnhancedBottomNav>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  // Drives scanline + subtle HUD motion (gaming vibe)
  late final AnimationController _hudController;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    _hudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  void _initializeAnimations() {
    const itemCount = 5; // keep hard-coded to 5 items
    _controllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 220),
        vsync: this,
      ),
    );

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    if (widget.currentIndex >= 0 && widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].value = 1.0;
    }
  }

  @override
  void didUpdateWidget(EnhancedBottomNav oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      if (oldWidget.currentIndex >= 0 &&
          oldWidget.currentIndex < _controllers.length) {
        _controllers[oldWidget.currentIndex].reverse();
      }
      if (widget.currentIndex >= 0 &&
          widget.currentIndex < _controllers.length) {
        _controllers[widget.currentIndex].forward();
      }
    }
  }

  @override
  void dispose() {
    _hudController.dispose();
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<BottomNavItem> _getDefaultItems(BuildContext context) {
    return widget.items.isNotEmpty
        ? widget.items
        : [
            // Index 0: Home
            const BottomNavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Home',
              semanticLabel: 'Home - Main dashboard',
            ),
            // Index 1: Art Walk
            const BottomNavItem(
              icon: Icons.map_outlined,
              activeIcon: Icons.map_rounded,
              label: 'Art Walk',
              semanticLabel: 'Art Walk - Explore art locations',
            ),
            // Index 2: Capture (special)
            const BottomNavItem(
              icon: Icons.camera_alt_outlined,
              activeIcon: Icons.camera_alt_rounded,
              label: 'Capture',
              semanticLabel: 'Capture - Take photos of art',
              isSpecial: true,
            ),
            // Index 3: Community
            BottomNavItem(
              icon: Icons.people_outline_rounded,
              activeIcon: Icons.people_rounded,
              label: 'Community',
              semanticLabel: 'Community - Connect with other users',
              badgeCount: context.watch<CommunityProvider>().unreadCount,
            ),
            // Index 4: Events
            const BottomNavItem(
              icon: Icons.event_outlined,
              activeIcon: Icons.event_rounded,
              label: 'Events',
              semanticLabel: 'Events - Discover art events',
            ),
          ];
  }

  @override
  Widget build(BuildContext context) {
    final items = _getDefaultItems(context);

    final activeColor = widget.activeColor ?? const Color(0xFF22D3EE); // neon
    // ignore: deprecated_member_use
    final inactiveColor = widget.inactiveColor ?? Colors.white.withOpacity(0.55);

    return AnimatedBuilder(
      animation: _hudController,
      builder: (context, _) {
        final t = _hudController.value;

        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Stack(
                  children: [
                    // Base HUD panel
                    Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: (widget.backgroundColor ??
                                const Color(0xFF0A0B14))
                            // ignore: deprecated_member_use
                            .withOpacity(0.62),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: Colors.white.withOpacity(0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 26,
                            offset: const Offset(0, 14),
                          ),
                          BoxShadow(
                            color: activeColor.withOpacity(0.10),
                            blurRadius: 28,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),

                    // Subtle scan sweep across the whole bar (gaming HUD feel)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Opacity(
                          opacity: 0.55,
                          child: Transform.translate(
                            offset: Offset((t * 2 - 1) * 220, 0),
                            child: Transform.rotate(
                              angle: -0.55,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withOpacity(0.10),
                                      activeColor.withOpacity(0.08),
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.45, 0.58, 1.0],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Content row
                    SizedBox(
                      height: 76,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return Expanded(
                            child: _buildNavItem(
                              context,
                              index,
                              item,
                              activeColor,
                              inactiveColor,
                              t,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    BottomNavItem item,
    Color activeColor,
    Color inactiveColor,
    double t,
  ) {
    final isActive = widget.currentIndex == index;

    if (item.isSpecial) {
      return _buildSpecialCaptureButton(
        context,
        index,
        item,
        isActive,
        activeColor,
        inactiveColor,
        t,
      );
    }

    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: item.semanticLabel ?? item.label,
        selected: isActive,
        child: AnimatedBuilder(
          animation: _animations[index],
          builder: (context, _) {
            final anim = _animations[index].value;

            // Active reticle pulse (each index slightly out of phase)
            final phase = index * 0.18;
            final reticle = isActive
                ? (0.55 + 0.45 * (0.5 + 0.5 * math.sin((t + phase) * 2 * math.pi)))
                : 0.0;

            final iconColor = Color.lerp(inactiveColor, activeColor, anim)!;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    // Reticle ring behind active icon (gaming)
                    if (isActive)
                      CustomPaint(
                        painter: _ReticleRingPainter(
                          progress: reticle,
                          color: activeColor,
                        ),
                        size: const Size(44, 44),
                      ),

                    // Icon capsule
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive
                            ? activeColor.withOpacity(0.10)
                            : Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive
                              ? activeColor.withOpacity(0.22)
                              : Colors.white.withOpacity(0.10),
                        ),
                        boxShadow: [
                          if (isActive)
                            BoxShadow(
                              color: activeColor.withOpacity(0.16),
                              blurRadius: 18,
                              spreadRadius: 1,
                            ),
                        ],
                      ),
                      child: Icon(
                        isActive ? item.activeIcon : item.icon,
                        color: iconColor,
                        size: 22 + (anim * 2),
                      ),
                    ),

                    // Badge (kept)
                    if (item.badgeCount > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: _Badge(count: item.badgeCount),
                      ),
                  ],
                ),

                if (widget.showLabels) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                      letterSpacing: 0.6,
                      color: Color.lerp(inactiveColor, Colors.white, anim),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSpecialCaptureButton(
    BuildContext context,
    int index,
    BottomNavItem item,
    bool isActive,
    Color activeColor,
    Color inactiveColor,
    double t,
  ) {
    return GestureDetector(
      onTap: () => _handleTap(index),
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        label: item.semanticLabel ?? item.label,
        selected: isActive,
        child: AnimatedBuilder(
          animation: _animations[index],
          builder: (context, _) {
            final anim = _animations[index].value;

            // Energy pulse (always subtle, stronger when active)
            final pulse = 0.5 + 0.5 * math.sin((t * 2 * math.pi) + 1.4);
            final scale = 1.0 + (anim * 0.08) + (0.03 * pulse);

            // Rotating attention: scan highlight on the core
            final sweep = (t * 1.0) % 1.0;

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Transform.scale(
                  scale: scale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer neon ring
                      CustomPaint(
                        painter: _CaptureRingPainter(
                          t: t,
                          neon: const Color(0xFFFF3D8D),
                          cyan: activeColor,
                        ),
                        size: const Size(54, 54),
                      ),

                      // Button body
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                          child: Container(
                            width: 52,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(
                                colors: [
                                  ArtbeatColors.primaryPurple.withOpacity(0.95),
                                  activeColor.withOpacity(0.85),
                                  ArtbeatColors.primaryGreen.withOpacity(0.70),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: activeColor.withOpacity(0.22 + 0.10 * anim),
                                  blurRadius: 18 + 10 * anim,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.white.withOpacity(0.14),
                              ),
                            ),
                            child: Stack(
                              children: [
                                // moving highlight sweep
                                Positioned.fill(
                                  child: IgnorePointer(
                                    child: Opacity(
                                      opacity: 0.55,
                                      child: Transform.translate(
                                        offset: Offset((sweep * 2 - 1) * 40, 0),
                                        child: Transform.rotate(
                                          angle: -0.6,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.transparent,
                                                  Colors.white.withOpacity(0.24),
                                                  Colors.transparent,
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // icon
                                Center(
                                  child: Icon(
                                    isActive ? item.activeIcon : item.icon,
                                    color: Colors.white,
                                    size: 24 + (anim * 2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (widget.showLabels) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.label.toUpperCase(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: isActive
                          ? Colors.white.withOpacity(0.92)
                          : inactiveColor.withOpacity(0.90),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _handleTap(int index) {
    HapticFeedback.lightImpact();

    // Keep existing logic: mark community as visited
    if (index == 3) {
      context.read<CommunityProvider>().markCommunityAsVisited();
    }

    if (index != widget.currentIndex) {
      widget.onTap(index);
    }
  }
}

/// =======================
/// Badge
/// =======================

class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final text = count > 99 ? '99+' : count.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: ArtbeatColors.error,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: ArtbeatColors.error.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// =======================
/// Reticle ring (active tabs)
/// =======================

class _ReticleRingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _ReticleRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.46;

    const start = -math.pi / 2;
    final sweep = 2 * math.pi * (0.35 + 0.55 * progress);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.10 + 0.16 * progress);

    canvas.drawArc(Rect.fromCircle(center: center, radius: r), start, sweep, false, paint);

    // ticks
    final tick = Paint()
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.06 + 0.08 * progress);

    for (int i = 0; i < 8; i++) {
      final a = (i / 8.0) * 2 * math.pi;
      final p1 = Offset(center.dx + math.cos(a) * (r * 0.78), center.dy + math.sin(a) * (r * 0.78));
      final p2 = Offset(center.dx + math.cos(a) * (r * 0.92), center.dy + math.sin(a) * (r * 0.92));
      canvas.drawLine(p1, p2, tick);
    }
  }

  @override
  bool shouldRepaint(covariant _ReticleRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// =======================
/// Capture ring painter (special button)
/// =======================

class _CaptureRingPainter extends CustomPainter {
  final double t;
  final Color neon;
  final Color cyan;

  _CaptureRingPainter({
    required this.t,
    required this.neon,
    required this.cyan,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = math.min(size.width, size.height) * 0.48;

    final angle = t * 2 * math.pi;

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          neon.withOpacity(0.00),
          neon.withOpacity(0.28),
          cyan.withOpacity(0.24),
          neon.withOpacity(0.00),
        ],
        stops: const [0.12, 0.40, 0.62, 0.92],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: r));

    // partial arcs for "energy"
    canvas.drawArc(Rect.fromCircle(center: center, radius: r), angle, 2.1, false, arcPaint);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..color = cyan.withOpacity(0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    canvas.drawCircle(center, r, glow);
  }

  @override
  bool shouldRepaint(covariant _CaptureRingPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.neon != neon || oldDelegate.cyan != cyan;
}

/// Data class for bottom navigation items (unchanged)
class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final String? semanticLabel;
  final bool isSpecial;
  final int badgeCount;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.semanticLabel,
    this.isSpecial = false,
    this.badgeCount = 0,
  });
}
