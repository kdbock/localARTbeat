import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/src/theme/artbeat_colors.dart';

class AnimatedDashboardScreen extends StatefulWidget {
  const AnimatedDashboardScreen({super.key});

  @override
  State<AnimatedDashboardScreen> createState() =>
      _AnimatedDashboardScreenState();
}

class _AnimatedDashboardScreenState extends State<AnimatedDashboardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loop; // world animation
  late final AnimationController _intro; // entrance
  // Fake HUD values (wire these to your user profile later)
  final int _level = 7;
  final double _xpProgress = 0.62; // 0..1
  final int _streakDays = 4;

  @override
  void initState() {
    super.initState();
    _loop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
  }

  @override
  void dispose() {
    _loop.dispose();
    _intro.dispose();
    super.dispose();
  }

  void _showProfileMenu() {
    Navigator.of(context).pushNamed('/profile/menu');
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: ArtbeatColors.backgroundDark,
      body: Stack(
        children: [
          // GAME WORLD BACKGROUND
          AnimatedBuilder(
            animation: _loop,
            builder: (_, __) => CustomPaint(
              painter: _QuestWorldPainter(t: _loop.value),
              size: Size.infinite,
            ),
          ),

          // Foreground vignette to focus buttons
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Column(
                children: [
                  _StampFadeIn(
                    intro: _intro,
                    delay: 0.0,
                    child: _GameHUD(
                      level: _level,
                      xpProgress: _xpProgress,
                      streakDays: _streakDays,
                      onProfile: _showProfileMenu,
                      onSettings: () {}, // hook later
                    ),
                  ),

                  const SizedBox(height: 14),

                  _StampFadeIn(
                    intro: _intro,
                    delay: 0.10,
                    child: _TitleBlock(
                      loop: _loop,
                      onTap: () =>
                          Navigator.pushNamed(context, '/old-dashboard'),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // The QUEST BUTTONS (focal point)
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          _StampPopIn(
                            intro: _intro,
                            index: 0,
                            child: _QuestButton(
                              loop: _loop,
                              index: 0,
                              width: w,
                              title: 'animated_dashboard_capture_title'.tr(),
                              subtitle: 'animated_dashboard_capture_subtitle'
                                  .tr(),
                              tag: 'animated_dashboard_capture_tag'.tr(),
                              icon: Icons.camera_alt_rounded,
                              palette: const _QuestPalette(
                                base: ArtbeatColors.primaryPurple,
                                neon: ArtbeatColors.secondaryTeal,
                                accent: ArtbeatColors.accentYellow,
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/capture/dashboard',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _StampPopIn(
                            intro: _intro,
                            index: 1,
                            child: _QuestButton(
                              loop: _loop,
                              index: 1,
                              width: w,
                              title: 'animated_dashboard_discover_title'.tr(),
                              subtitle: 'animated_dashboard_discover_subtitle'
                                  .tr(),
                              tag: 'animated_dashboard_discover_tag'.tr(),
                              icon: Icons.radar_rounded,
                              palette: const _QuestPalette(
                                base: ArtbeatColors.primaryBlue,
                                neon: ArtbeatColors.primaryGreen,
                                accent: ArtbeatColors.accentOrange,
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/art-walk/dashboard',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _StampPopIn(
                            intro: _intro,
                            index: 2,
                            child: _QuestButton(
                              loop: _loop,
                              index: 2,
                              width: w,
                              title: 'animated_dashboard_explore_title'.tr(),
                              subtitle: 'animated_dashboard_explore_subtitle'
                                  .tr(),
                              tag: 'animated_dashboard_explore_tag'.tr(),
                              icon: Icons.explore_rounded,
                              palette: const _QuestPalette(
                                base: ArtbeatColors.primaryGreen,
                                neon: ArtbeatColors.accentYellow,
                                accent: ArtbeatColors.secondaryTeal,
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/old-dashboard',
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          _StampPopIn(
                            intro: _intro,
                            index: 3,
                            child: _QuestButton(
                              loop: _loop,
                              index: 3,
                              width: w,
                              title: 'animated_dashboard_connect_title'.tr(),
                              subtitle: 'animated_dashboard_connect_subtitle'
                                  .tr(),
                              tag: 'animated_dashboard_connect_tag'.tr(),
                              icon: Icons.people_alt_rounded,
                              palette: const _QuestPalette(
                                base: ArtbeatColors.accentOrange,
                                neon: ArtbeatColors.primaryPurple,
                                accent: ArtbeatColors.primaryGreen,
                              ),
                              onTap: () => Navigator.pushNamed(
                                context,
                                '/community/hub',
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Keep your bottom CTAs but make them “game chips”
                          _StampPopIn(
                            intro: _intro,
                            index: 4,
                            child: _BottomChips(
                              onArtist: () => Navigator.pushNamed(
                                context,
                                '/2025_modern_onboarding',
                              ),
                              onBusiness: () =>
                                  Navigator.pushNamed(context, '/iap/ads'),
                            ),
                          ),

                          const SizedBox(height: 26),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// HUD + Title
/// =======================

class _GameHUD extends StatelessWidget {
  final int level;
  final double xpProgress;
  final int streakDays;
  final VoidCallback onProfile;
  final VoidCallback onSettings;

  const _GameHUD({
    required this.level,
    required this.xpProgress,
    required this.streakDays,
    required this.onProfile,
    required this.onSettings,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _HUDPill(
          child: Row(
            children: [
              _LevelBadge(level: level),
              const SizedBox(width: 10),
              Expanded(child: _XPBar(progress: xpProgress)),
              const SizedBox(width: 10),
              _Streak(streakDays: streakDays),
            ],
          ),
        ),
        const SizedBox(width: 10),
        _IconPill(icon: Icons.person_rounded, onTap: onProfile),
        const SizedBox(width: 10),
        _IconPill(icon: Icons.settings_rounded, onTap: onSettings),
      ],
    );
  }
}

class _TitleBlock extends StatelessWidget {
  final AnimationController loop;
  final VoidCallback? onTap;
  const _TitleBlock({required this.loop, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: loop,
        builder: (_, __) {
          final t = loop.value;
          final pulse = 0.65 + 0.35 * (0.5 + 0.5 * math.sin(t * 2 * math.pi));
          return ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            ArtbeatColors.secondaryTeal.withValues(alpha: 0.75),
                            ArtbeatColors.accentOrange.withValues(alpha: 0.65),
                            ArtbeatColors.accentYellow.withValues(alpha: 0.55),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22D3EE,
                            ).withValues(alpha: 0.16 * pulse),
                            blurRadius: 18,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.explore_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'animated_dashboard_title_local'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                            TextSpan(
                              text: 'animated_dashboard_title_art'.tr(),
                              style: GoogleFonts.dmSerifDisplay(
                                color: const Color(0xFFFFC857),
                                fontSize: 20,
                                fontWeight: FontWeight.w400,
                                letterSpacing: -0.2,
                              ),
                            ),
                            TextSpan(
                              text: 'animated_dashboard_title_beat'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.88),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      'animated_dashboard_quest_hub'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.62),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// =======================
/// Main Quest Buttons
/// =======================

class _QuestPalette {
  final Color base;
  final Color neon;
  final Color accent;
  const _QuestPalette({
    required this.base,
    required this.neon,
    required this.accent,
  });
}

class _QuestButton extends StatefulWidget {
  final AnimationController loop;
  final int index;
  final double width;
  final String title;
  final String subtitle;
  final String tag;
  final IconData icon;
  final _QuestPalette palette;
  final VoidCallback onTap;

  const _QuestButton({
    required this.loop,
    required this.index,
    required this.width,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.icon,
    required this.palette,
    required this.onTap,
  });

  @override
  State<_QuestButton> createState() => _QuestButtonState();
}

class _QuestButtonState extends State<_QuestButton> {
  bool _pressed = false;

  double get _phase => widget.index * 0.23;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.loop,
      builder: (_, __) {
        final t = widget.loop.value;

        // “Rotating attention”: each card peaks at different times.
        final sweep = (t + _phase) % 1.0;

        // A gated “power up” window (one-at-a-time feel)
        final power = (1.0 - (sweep - 0.55).abs() * 4.5).clamp(0.0, 1.0);

        // arrow pulses only when power is strong
        final arrowPulse = 1.0 + 0.18 * power;

        // subtle card breathe (not synchronized)
        final breathe = 1.0 + 0.012 * math.sin((t + _phase) * 2 * math.pi);

        // neon edge intensity
        final edgeGlow = 0.10 + 0.22 * power;

        return Transform.scale(
          scale: (_pressed ? 0.985 : 1.0) * breathe,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Base glass panel
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: widget.width,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 28,
                          offset: const Offset(0, 18),
                        ),
                        // neon edge aura (gaming vibe)
                        BoxShadow(
                          color: widget.palette.neon.withValues(
                            alpha: edgeGlow,
                          ),
                          blurRadius: 34,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Tag chip
                            _TagChip(
                              text: widget.tag,
                              color: widget.palette.accent,
                            ),

                            const Spacer(),

                            // Power icon capsule
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                gradient: LinearGradient(
                                  colors: [
                                    widget.palette.base.withValues(alpha: 0.95),
                                    widget.palette.neon.withValues(alpha: 0.80),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: widget.palette.base.withValues(
                                      alpha: 0.30,
                                    ),
                                    blurRadius: 18,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Icon(
                                widget.icon,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.title,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white.withValues(
                                        alpha: 0.95,
                                      ),
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    widget.subtitle,
                                    style: GoogleFonts.spaceGrotesk(
                                      color: Colors.white.withValues(
                                        alpha: 0.70,
                                      ),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Arrow button (pulses sequentially)
                            Transform.scale(
                              scale: arrowPulse,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white.withValues(alpha: 0.08),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.14),
                                  ),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white.withValues(alpha: 0.92),
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // SCANLINE + SPOTLIGHT SWEEP (animated gradient light)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.70,
                      child: Transform.translate(
                        offset: Offset(
                          (sweep * 2 - 1) * widget.width * 0.55,
                          0,
                        ),
                        child: Transform.rotate(
                          angle: -0.55,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.transparent,
                                  Colors.white.withValues(
                                    alpha: 0.16 + 0.12 * power,
                                  ),
                                  widget.palette.neon.withValues(
                                    alpha: 0.10 + 0.08 * power,
                                  ),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.46, 0.58, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // RUNE RING / TARGET reticle overlay (gaming vibe)
                Positioned.fill(
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ReticlePainter(
                        t: (t + _phase) % 1.0,
                        neon: widget.palette.neon,
                        accent: widget.palette.accent,
                      ),
                    ),
                  ),
                ),

                // Tap layer
                Positioned.fill(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(28),
                      onTap: widget.onTap,
                      onTapDown: (_) => setState(() => _pressed = true),
                      onTapUp: (_) => setState(() => _pressed = false),
                      onTapCancel: () => setState(() => _pressed = false),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  final Color color;
  const _TagChip({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          gradient: LinearGradient(
            colors: [color, Colors.white.withValues(alpha: 0.35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          text,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.black.withValues(alpha: 0.85),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

/// =======================
/// Bottom chips (kept)
/// =======================

class _BottomChips extends StatelessWidget {
  final VoidCallback onArtist;
  final VoidCallback onBusiness;

  const _BottomChips({required this.onArtist, required this.onBusiness});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ChipButton(
            icon: Icons.palette_outlined,
            label: 'animated_dashboard_artist_label'.tr(),
            glow: ArtbeatColors.accentYellow,
            onTap: onArtist,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ChipButton(
            icon: Icons.storefront_outlined,
            label: 'animated_dashboard_business_label'.tr(),
            glow: ArtbeatColors.primaryGreen,
            onTap: onBusiness,
          ),
        ),
      ],
    );
  }
}

class _ChipButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color glow;
  final VoidCallback onTap;

  const _ChipButton({
    required this.icon,
    required this.label,
    required this.glow,
    required this.onTap,
  });

  @override
  State<_ChipButton> createState() => _ChipButtonState();
}

class _ChipButtonState extends State<_ChipButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 120),
      scale: _pressed ? 0.985 : 1,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Material(
            color: Colors.white.withValues(alpha: 0.06),
            child: InkWell(
              onTap: widget.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapUp: (_) => setState(() => _pressed = false),
              onTapCancel: () => setState(() => _pressed = false),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.glow.withValues(alpha: 0.10),
                      blurRadius: 18,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: widget.glow.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: widget.glow.withValues(alpha: 0.26),
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: Colors.white.withValues(alpha: 0.92),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// =======================
/// HUD Components
/// =======================

class _HUDPill extends StatelessWidget {
  final Widget child;
  const _HUDPill({required this.child});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _IconPill extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconPill({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: Colors.white.withValues(alpha: 0.06),
          child: InkWell(
            onTap: onTap,
            child: Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              ),
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: 0.85),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFC857).withValues(alpha: 0.95),
            const Color(0xFFFF3D8D).withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Text(
        '${'animated_dashboard_level_prefix'.tr()}$level',
        style: GoogleFonts.spaceGrotesk(
          color: Colors.black.withValues(alpha: 0.86),
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _XPBar extends StatelessWidget {
  final double progress;
  const _XPBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'animated_dashboard_xp_label'.tr(),
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 10,
            color: Colors.white.withValues(alpha: 0.08),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF22D3EE),
                      Color(0xFF7C4DFF),
                      Color(0xFFFF3D8D),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Streak extends StatelessWidget {
  final int streakDays;
  const _Streak({required this.streakDays});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.08),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: const Color(0xFFFFC857).withValues(alpha: 0.95),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            '$streakDays${'animated_dashboard_streak_suffix'.tr()}',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// =======================
/// Background: Quest world painter
/// - radar sweep
/// - node rings
/// - dotted “quest path”
/// =======================

class _QuestWorldPainter extends CustomPainter {
  final double t;
  _QuestWorldPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark gradient (night street)
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Big radar circle area behind buttons
    final center = Offset(size.width * 0.5, size.height * 0.46);
    final maxR = size.width * 0.62;

    // Radar rings
    for (int i = 1; i <= 4; i++) {
      final r = maxR * (i / 4.0);
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withValues(alpha: 0.045);
      canvas.drawCircle(center, r, p);
    }

    // Sweeping radar arc
    final angle = (t * 2 * math.pi);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 22
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: maxR * 0.95),
      angle - 0.55,
      0.75,
      false,
      arcPaint,
    );

    // Quest path (marching dots)
    final path = Path()
      ..moveTo(size.width * 0.10, size.height * 0.70)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.54,
        size.width * 0.52,
        size.height * 0.82,
        size.width * 0.88,
        size.height * 0.60,
      );

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withValues(alpha: 0.05);
    canvas.drawPath(path, linePaint);

    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final m = metrics.first;
      final len = m.length;
      final baseOffset = (t * 1.3) % 1.0 * len;

      for (int i = 0; i < 28; i++) {
        final d = (baseOffset + i * (len / 28)) % len;
        final pos = m.getTangentForOffset(d)?.position;
        if (pos == null) continue;

        final isNode = i % 7 == 0;
        final dotPaint = Paint()
          ..color = (isNode ? const Color(0xFFFFC857) : Colors.white)
              .withValues(alpha: isNode ? 0.14 : 0.10)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

        canvas.drawCircle(pos, isNode ? 4.0 : 2.1, dotPaint);

        if (isNode) {
          // node ring that “traces” gently
          final local = ((t + i * 0.09) % 1.0);
          final sweep = (0.2 + 0.7 * (local * local * (3 - 2 * local))).clamp(
            0.0,
            1.0,
          );
          final ringPaint = Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6
            ..strokeCap = StrokeCap.round
            ..color = const Color(0xFFFF3D8D).withValues(alpha: 0.08);

          canvas.drawArc(
            Rect.fromCircle(center: pos, radius: 12),
            local * 2 * math.pi,
            2 * math.pi * sweep,
            false,
            ringPaint,
          );
        }
      }
    }

    // Ambient paint blobs (art energy)
    _blob(canvas, size, const Color(0xFFFF3D8D), 0.18, 0.18, 0.34, phase: 0.0);
    _blob(canvas, size, const Color(0xFF7C4DFF), 0.80, 0.20, 0.28, phase: 0.2);
    _blob(canvas, size, const Color(0xFFFFC857), 0.74, 0.78, 0.38, phase: 0.45);
    _blob(canvas, size, const Color(0xFF34D399), 0.16, 0.78, 0.34, phase: 0.62);
  }

  void _blob(
    Canvas canvas,
    Size size,
    Color color,
    double ax,
    double ay,
    double r, {
    required double phase,
  }) {
    final dx = math.sin((t + phase) * 2 * math.pi) * 0.035;
    final dy = math.cos((t + phase) * 2 * math.pi) * 0.035;

    final center = Offset(size.width * (ax + dx), size.height * (ay + dy));
    final radius = size.width * r;

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0.0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _QuestWorldPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Reticle overlay for each button (rune ring + ticks)
class _ReticlePainter extends CustomPainter {
  final double t;
  final Color neon;
  final Color accent;

  _ReticlePainter({required this.t, required this.neon, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final r = math.min(size.width, size.height) * 0.52;
    final center = Offset(size.width * 0.5, size.height * 0.52);

    // Make reticle “trace” during the power window
    final power = (1.0 - (t - 0.55).abs() * 4.5).clamp(0.0, 1.0);
    if (power <= 0.02) return;

    final start = (t * 2 * math.pi) - math.pi / 2;
    final sweep = 2 * math.pi * (0.35 + 0.55 * power);

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 1.6
      ..color = neon.withValues(alpha: 0.06 + 0.08 * power);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: r),
      start,
      sweep,
      false,
      ringPaint,
    );

    // ticks
    final tickPaint = Paint()
      ..strokeWidth = 1.0
      ..color = accent.withValues(alpha: 0.05 + 0.06 * power);

    for (int i = 0; i < 10; i++) {
      final a = (i / 10.0) * 2 * math.pi + t * 0.6;
      final p1 = Offset(
        center.dx + math.cos(a) * (r * 0.78),
        center.dy + math.sin(a) * (r * 0.78),
      );
      final p2 = Offset(
        center.dx + math.cos(a) * (r * 0.88),
        center.dy + math.sin(a) * (r * 0.88),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ReticlePainter oldDelegate) =>
      oldDelegate.t != t;
}

/// =======================
/// Entrance Animations
/// =======================

class _StampFadeIn extends StatelessWidget {
  final AnimationController intro;
  final double delay;
  final Widget child;

  const _StampFadeIn({
    required this.intro,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(
      parent: intro,
      curve: Interval(
        delay,
        (delay + 0.45).clamp(0.0, 1.0),
        curve: Curves.easeOut,
      ),
    );
    final slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: intro,
            curve: Interval(
              delay,
              (delay + 0.65).clamp(0.0, 1.0),
              curve: Curves.easeOutCubic,
            ),
          ),
        );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}

class _StampPopIn extends StatelessWidget {
  final AnimationController intro;
  final int index;
  final Widget child;

  const _StampPopIn({
    required this.intro,
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = 0.18 + index * 0.09;
    final end = start + 0.42;

    final fade = CurvedAnimation(
      parent: intro,
      curve: Interval(start, end, curve: Curves.easeOut),
    );
    final pop = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: intro,
        curve: Interval(start, end, curve: Curves.easeOutBack),
      ),
    );
    final tilt = Tween<double>(begin: (index.isEven ? -0.03 : 0.03), end: 0.0)
        .animate(
          CurvedAnimation(
            parent: intro,
            curve: Interval(start, end, curve: Curves.easeOutCubic),
          ),
        );

    return FadeTransition(
      opacity: fade,
      child: AnimatedBuilder(
        animation: intro,
        builder: (_, __) => Transform.rotate(
          angle: tilt.value,
          child: Transform.scale(scale: pop.value, child: child),
        ),
      ),
    );
  }
}
