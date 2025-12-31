import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/glass_card.dart';
import '../widgets/gradient_cta_button.dart';
import '../widgets/hud_top_bar.dart';
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
              title: 'Local Sponsorships',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  _StampFadeIn(
                    intro: _intro,
                    delay: 0.0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _HeroCard(
                        loop: _loop,
                        onPrimary: () =>
                            Navigator.pushNamed(context, '/title-sponsorship'),
                        onSecondary: () => Navigator.pushNamed(
                          context,
                          '/art-walk-sponsorship',
                        ),
                      ),
                    ),
                  ),
                  _StampFadeIn(
                    intro: _intro,
                    delay: 0.15,
                    child: SponsorshipSection(
                      title: 'Why sponsor with us',
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
                      title: 'Choose your placement',
                      subtitle:
                          'Every tier includes manual review and reporting',
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
                      title: 'Need support?',
                      child: Column(
                        children: [
                          for (var i = 0; i < _supportCtas.length; i++) ...[
                            SponsorshipCtaTile(
                              icon: _supportCtas[i].icon,
                              title: _supportCtas[i].title,
                              subtitle: _supportCtas[i].subtitle,
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
                            label: 'Submit sponsorship proposal',
                            icon: Icons.star_outline,
                            onPressed: () => Navigator.pushNamed(
                              context,
                              '/sponsorship-dashboard',
                            ),
                            onTap: () {},
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
    label: 'Priority placement',
    detail: 'Appears ahead of ads across splash, dashboards, and maps',
    icon: Icons.bolt,
  ),
  _QuickSignal(
    label: 'Radius targeting',
    detail: 'Lock sponsorships to the neighborhoods you serve',
    icon: Icons.podcasts,
  ),
  _QuickSignal(
    label: 'Manual approval',
    detail: 'Concierge review keeps the experience premium',
    icon: Icons.verified_user,
  ),
];

const _sponsorshipOptions = [
  _SponsorshipOption(
    icon: Icons.workspace_premium,
    title: 'Title Sponsor',
    price: r'$25,000',
    duration: '12 months',
    description:
        'Own Local ARTbeat for the season with hero placements and story takeovers.',
    perks: [
      'Splash + dashboard hero exclusivity',
      'All modules badge your brand',
      'Dedicated concierge + creative',
    ],
    route: '/title-sponsorship',
  ),
  _SponsorshipOption(
    icon: Icons.event_available,
    title: 'Event Sponsor',
    price: r'$1,000',
    duration: 'Per event',
    description:
        'Co-host a Local ARTbeat tour or pop-up with shared branding and content.',
    perks: [
      'Equal billing on promos',
      'On-site signage kit',
      'Video + recap mentions',
    ],
    route: '/event-sponsorship',
  ),
  _SponsorshipOption(
    icon: Icons.map,
    title: 'Art Walk Sponsor',
    price: r'$500',
    duration: '30 days',
    description:
        'Design a quest that routes explorers past your storefront with XP boosts.',
    perks: [
      'Custom walk branding',
      'XP reward callouts',
      'Stop analytics dashboard',
    ],
    route: '/art-walk-sponsorship',
  ),
  _SponsorshipOption(
    icon: Icons.camera_alt,
    title: 'Capture Sponsor',
    price: r'$250',
    duration: '30 days',
    description:
        'Brand the capture HUD whenever nearby murals are photographed.',
    perks: [
      'Radius targeting (1–5 miles)',
      'Branded capture frames',
      'Auto follow-up prompts',
    ],
    route: '/capture-sponsorship',
  ),
  _SponsorshipOption(
    icon: Icons.radar,
    title: 'Discover Sponsor',
    price: r'$250',
    duration: '30 days',
    description:
        'Own the discovery radar banner when fans scan for art around you.',
    perks: [
      'Always-on radar badge',
      'Tap-through insights',
      'Featured in instant finds',
    ],
    route: '/discover-sponsorship',
  ),
];

const _supportCtas = [
  _SupportCta(
    title: 'Get more information',
    subtitle: 'Get a guided walkthrough of sponsorship tiers',
    icon: Icons.chat_bubble_outline,
    route: '/sponsorship-dashboard',
  ),
];

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.loop,
    required this.onPrimary,
    required this.onSecondary,
  });

  final Animation<double> loop;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
                                'Partner with discovery, not feeds',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Local ARTbeat sponsors power quests, captures, and radar moments across the city. No auctions, no bidding wars—just curated placements with concierge review.',
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
                        _HeroBadge(label: 'Manual approval'),
                        _HeroBadge(label: 'Premium glass UI'),
                        _HeroBadge(label: 'Radius targeting'),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: GradientCtaButton(
                            label: 'Become a sponsor',
                            icon: Icons.workspace_premium_outlined,
                            onPressed: onPrimary,
                            onTap: () {},
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: onSecondary,
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
                                  'Explore art walks',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
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
      },
    );
  }
}

class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withValues(alpha: 0.08),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white.withValues(alpha: 0.07),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Text(
      label,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
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
              colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.55)],
            ),
          ),
        ),
      ),
      child,
    ],
  );
}

class _SponsorshipWorldPainter extends CustomPainter {
  final double t;
  _SponsorshipWorldPainter({required this.t});

  @override
  void paint(Canvas canvas, Size size) {
    // Base dark gradient
    final base = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    // Ambient paint blobs
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
                            signal.label,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            signal.detail,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: Colors.white70),
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
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
                                option.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                option.description,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
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
                          option.price,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,

                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          option.duration,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.white60),
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
                        for (final perk in option.perks) _PerkChip(label: perk),
                      ],
                    ),
                    const SizedBox(height: 18),
                    GradientCtaButton(
                      label: 'Start ${option.title.toLowerCase()}',
                      onPressed: () =>
                          Navigator.pushNamed(context, option.route),
                      onTap: () {},
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
}

class _QuickSignal {
  const _QuickSignal({
    required this.label,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String detail;
  final IconData icon;
}

class _SponsorshipOption {
  const _SponsorshipOption({
    required this.icon,
    required this.title,
    required this.price,
    required this.duration,
    required this.description,
    required this.perks,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String price;
  final String duration;
  final String description;
  final List<String> perks;
  final String route;
}

class _SupportCta {
  const _SupportCta({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}
