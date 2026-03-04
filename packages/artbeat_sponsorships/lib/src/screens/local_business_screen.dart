import 'dart:math' as math;

import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../widgets/gradient_cta_button.dart';
import '../widgets/sponsorship_cta_tile.dart';
import '../widgets/sponsorship_section.dart';

class LocalBusinessScreen extends StatefulWidget {
  const LocalBusinessScreen({super.key});

  @override
  State<LocalBusinessScreen> createState() => _LocalBusinessScreenState();
}

class _LocalBusinessScreenState extends State<LocalBusinessScreen>
    with TickerProviderStateMixin {
  late final AnimationController _loop; // world animation
  late final AnimationController _intro; // entrance

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

  @override
  Widget build(BuildContext context) => _AnimatedWorldBackground(
    loop: _loop,
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            HudTopBar(
              title: 'sponsorship_hub_title'.tr(),
              onBackPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _StampFadeIn(
                    intro: _intro,
                    delay: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _HeroCard(
                        loop: _loop,
                        onSponsor: () => Navigator.pushNamed(
                          context,
                          AppRoutes.sponsorshipCreate,
                        ),
                        onExplore: () =>
                            Navigator.pushNamed(context, AppRoutes.artWalkList),
                      ),
                    ),
                  ),
                  _StampFadeIn(
                    intro: _intro,
                    delay: 0.15,
                    child: SponsorshipSection(
                      title: 'sponsorship_hub_why_title'.tr(),
                      child: Column(
                        children: [
                          for (var i = 0; i < _quickSignals.length; i++) ...[
                            _AnimatedSignalCard(
                              signal: _quickSignals[i],
                              loop: _loop,
                              index: i,
                            ),
                            if (i < _quickSignals.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _StampFadeIn(
                    intro: _intro,
                    delay: 0.30,
                    child: SponsorshipSection(
                      title: 'sponsorship_hub_choose_title'.tr(),
                      subtitle: 'sponsorship_hub_choose_subtitle'.tr(),
                      child: Column(
                        children: [
                          for (
                            var i = 0;
                            i < _sponsorshipOptions.length;
                            i++
                          ) ...[
                            _AnimatedSponsorshipOptionCard(
                              option: _sponsorshipOptions[i],
                              loop: _loop,
                              index: i,
                            ),
                            if (i < _sponsorshipOptions.length - 1)
                              const SizedBox(height: 16),
                          ],
                        ],
                      ),
                    ),
                  ),
                  _StampFadeIn(
                    intro: _intro,
                    delay: 0.45,
                    child: SponsorshipSection(
                      title: 'sponsorship_hub_support_title'.tr(),
                      child: Column(
                        children: [
                          for (var i = 0; i < _supportCtas.length; i++) ...[
                            SponsorshipCtaTile(
                              icon: _supportCtas[i].icon,
                              title: _supportCtas[i].titleKey.tr(),
                              subtitle: _supportCtas[i].subtitleKey.tr(),
                              onTap: () => Navigator.pushNamed(
                                context,
                                _supportCtas[i].route,
                              ),
                            ),
                            if (i < _supportCtas.length - 1)
                              const SizedBox(height: 12),
                          ],
                          const SizedBox(height: 16),
                          GradientCtaButton(
                            label: 'sponsorship_hub_submit_proposal'.tr(),
                            icon: Icons.star_outline,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRoutes.sponsorshipCreate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

const _quickSignals = [
  _QuickSignal(
    labelKey: 'sponsorship_hub_signal_local_impact_title',
    detailKey: 'sponsorship_hub_signal_local_impact_detail',
    icon: Icons.bolt,
  ),
  _QuickSignal(
    labelKey: 'sponsorship_hub_signal_active_explorers_title',
    detailKey: 'sponsorship_hub_signal_active_explorers_detail',
    icon: Icons.podcasts,
  ),
  _QuickSignal(
    labelKey: 'sponsorship_hub_signal_simple_setup_title',
    detailKey: 'sponsorship_hub_signal_simple_setup_detail',
    icon: Icons.verified_user,
  ),
];

const _sponsorshipOptions = [
  _SponsorshipOption(
    icon: Icons.map,
    titleKey: 'sponsorship_hub_option_art_walk_title',
    priceKey: 'sponsorship_hub_option_art_walk_price',
    durationKey: 'sponsorship_hub_option_duration_monthly',
    descriptionKey: 'sponsorship_hub_option_art_walk_description',
    perks: [
      'sponsorship_hub_option_art_walk_perk_route',
      'sponsorship_hub_option_art_walk_perk_badge',
      'sponsorship_hub_option_art_walk_perk_report',
    ],
    route: AppRoutes.sponsorshipArtWalk,
  ),
  _SponsorshipOption(
    icon: Icons.camera_alt,
    titleKey: 'sponsorship_hub_option_capture_title',
    priceKey: 'sponsorship_hub_option_capture_price',
    durationKey: 'sponsorship_hub_option_duration_monthly',
    descriptionKey: 'sponsorship_hub_option_capture_description',
    perks: [
      'sponsorship_hub_option_capture_perk_visibility',
      'sponsorship_hub_option_capture_perk_message',
      'sponsorship_hub_option_capture_perk_report',
    ],
    route: AppRoutes.sponsorshipCapture,
  ),
  _SponsorshipOption(
    icon: Icons.radar,
    titleKey: 'sponsorship_hub_option_discovery_title',
    priceKey: 'sponsorship_hub_option_discovery_price',
    durationKey: 'sponsorship_hub_option_duration_monthly',
    descriptionKey: 'sponsorship_hub_option_discovery_description',
    perks: [
      'sponsorship_hub_option_discovery_perk_pin',
      'sponsorship_hub_option_discovery_perk_badge',
      'sponsorship_hub_option_discovery_perk_report',
    ],
    route: AppRoutes.sponsorshipDiscover,
  ),
];

const _supportCtas = [
  _SupportCta(
    titleKey: 'sponsorship_hub_support_cta_title',
    subtitleKey: 'sponsorship_hub_support_cta_subtitle',
    icon: Icons.chat_bubble_outline,
    route: AppRoutes.sponsorshipCreate,
  ),
];

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.loop,
    required this.onSponsor,
    required this.onExplore,
  });

  final Animation<double> loop;
  final VoidCallback onSponsor;
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (context, child) {
      final sweep = loop.value % 1.0;
      final power = (1.0 - (sweep - 0.55).abs() * 4.5).clamp(0.0, 1.0);
      final breathe = 1.0 + 0.012 * math.sin(loop.value * 2 * math.pi);

      return Transform.scale(
        scale: breathe,
        child: GlassCard(
          padding: const EdgeInsets.all(26),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.70,
                    child: Transform.translate(
                      offset: Offset((sweep * 2 - 1) * 400 * 0.55, 0),
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
                                const Color(
                                  0xFF34D399,
                                ).withValues(alpha: 0.10 + 0.08 * power),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedBuilder(
                        animation: loop,
                        builder: (_, __) {
                          final pulse =
                              (math.sin(loop.value * math.pi * 2) + 1) / 2;
                          return Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(
                                    0xFF7C4DFF,
                                  ).withValues(alpha: 0.8 + pulse * 0.2),
                                  const Color(
                                    0xFF22D3EE,
                                  ).withValues(alpha: 0.8 + pulse * 0.2),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF22D3EE,
                                  ).withValues(alpha: 0.4 + pulse * 0.3),
                                  blurRadius: 20 + pulse * 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.handshake,
                              color: Colors.white,
                              size: 30,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'sponsorship_hub_hero_title'.tr(),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'sponsorship_hub_hero_subtitle'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _HeroBadge(labelKey: 'sponsorship_hub_hero_badge_review'),
                      _HeroBadge(
                        labelKey: 'sponsorship_hub_hero_badge_monthly',
                      ),
                      _HeroBadge(labelKey: 'sponsorship_hub_hero_badge_cancel'),
                    ],
                  ),
                  const SizedBox(height: 22),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 420;

                      final exploreButton = GestureDetector(
                        onTap: onExplore,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'sponsorship_hub_hero_explore_button'.tr(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                            ),
                          ),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          children: [
                            GradientCtaButton(
                              label: 'sponsorship_hub_hero_start_button'.tr(),
                              icon: Icons.workspace_premium_outlined,
                              onPressed: onSponsor,
                            ),
                            const SizedBox(height: 10),
                            exploreButton,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: GradientCtaButton(
                              label: 'sponsorship_hub_hero_start_button'.tr(),
                              icon: Icons.workspace_premium_outlined,
                              onPressed: onSponsor,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: exploreButton),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withValues(alpha: 0.08),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Text(
      labelKey.tr(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.labelKey});

  final String labelKey;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white.withValues(alpha: 0.07),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Text(
      labelKey.tr(),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
    ),
  );
}

class _StampFadeIn extends StatelessWidget {
  const _StampFadeIn({
    required this.intro,
    required this.delay,
    required this.child,
  });

  final AnimationController intro;
  final double delay;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: intro,
      curve: Interval(delay, delay + 0.4, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.04),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }
}

class _AnimatedWorldBackground extends StatelessWidget {
  const _AnimatedWorldBackground({required this.loop, required this.child});

  final AnimationController loop;
  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      AnimatedBuilder(
        animation: loop,
        builder: (_, __) => CustomPaint(
          painter: _SponsorshipWorldPainter(t: loop.value),
          size: Size.infinite,
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.30)],
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _SponsorshipWorldPainter extends CustomPainter {
  _SponsorshipWorldPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark gradient
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF0F1C2E), Color(0xFF153655), Color(0xFF1A4C42)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Ambient paint blobs
    _blob(canvas, size, const Color(0xFFFF3D8D), 0.18, 0.18, 0.34, phase: 0);
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
        colors: [color.withValues(alpha: 0.26), color.withValues(alpha: 0)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _SponsorshipWorldPainter oldDelegate) =>
      oldDelegate.t != t;
}

class _AnimatedSignalCard extends StatelessWidget {
  const _AnimatedSignalCard({
    required this.signal,
    required this.loop,
    required this.index,
  });

  final _QuickSignal signal;
  final Animation<double> loop;
  final int index;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (context, child) {
      final phase = index * 0.15;
      final sweep = loop.value % 1.0;
      final power = (1.0 - (sweep - 0.55).abs() * 4.5).clamp(0.0, 1.0);
      final breathe =
          1.0 + 0.012 * math.sin((loop.value + phase) * 2 * math.pi);
      final edgeGlow = 0.10 + 0.22 * power;

      return Transform.scale(
        scale: breathe,
        child: GlassCard(
          padding: const EdgeInsets.all(18),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.70,
                    child: Transform.translate(
                      offset: Offset((sweep * 2 - 1) * 200 * 0.55, 0),
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
                                const Color(
                                  0xFF22D3EE,
                                ).withValues(alpha: 0.10 + 0.08 * power),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.08),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF22D3EE,
                          ).withValues(alpha: edgeGlow),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(signal.icon, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          signal.labelKey.tr(),
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          signal.detailKey.tr(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _AnimatedSponsorshipOptionCard extends StatelessWidget {
  const _AnimatedSponsorshipOptionCard({
    required this.option,
    required this.loop,
    required this.index,
  });

  final _SponsorshipOption option;
  final Animation<double> loop;
  final int index;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (context, child) {
      final phase = index * 0.12;
      final sweep = loop.value % 1.0;
      final power = (1.0 - (sweep - 0.55).abs() * 4.5).clamp(0.0, 1.0);
      final breathe =
          1.0 + 0.012 * math.sin((loop.value + phase) * 2 * math.pi);

      return Transform.scale(
        scale: breathe,
        child: GlassCard(
          padding: const EdgeInsets.all(22),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.70,
                    child: Transform.translate(
                      offset: Offset((sweep * 2 - 1) * 300 * 0.55, 0),
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
                                const Color(
                                  0xFF7C4DFF,
                                ).withValues(alpha: 0.10 + 0.08 * power),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                          ),
                        ),
                        child: Icon(option.icon, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              option.titleKey.tr(),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              option.descriptionKey.tr(),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        option.priceKey.tr(),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,

                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        option.durationKey.tr(),
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white60),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final perk in option.perks)
                        _PerkChip(labelKey: perk),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GradientCtaButton(
                    label: 'sponsorship_hub_option_start_button'.tr(
                      namedArgs: {'plan': option.titleKey.tr()},
                    ),
                    onPressed: () => Navigator.pushNamed(context, option.route),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _QuickSignal {
  const _QuickSignal({
    required this.labelKey,
    required this.detailKey,
    required this.icon,
  });

  final String labelKey;
  final String detailKey;
  final IconData icon;
}

class _SponsorshipOption {
  const _SponsorshipOption({
    required this.icon,
    required this.titleKey,
    required this.priceKey,
    required this.durationKey,
    required this.descriptionKey,
    required this.perks,
    required this.route,
  });

  final IconData icon;
  final String titleKey;
  final String priceKey;
  final String durationKey;
  final String descriptionKey;
  final List<String> perks;
  final String route;
}

class _SupportCta {
  const _SupportCta({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.route,
  });

  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final String route;
}
