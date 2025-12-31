import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/glass_card.dart';
import '../../widgets/gradient_badge.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';
import 'sponsorship_review_screen.dart';

class TitleSponsorshipScreen extends StatefulWidget {
  const TitleSponsorshipScreen({super.key});

  @override
  State<TitleSponsorshipScreen> createState() => _TitleSponsorshipScreenState();
}

class _TitleSponsorshipScreenState extends State<TitleSponsorshipScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final AnimationController _heroLoop;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _heroLoop = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    _heroLoop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            HudTopBar(
              title: 'Title Sponsorship',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                children: [
                  _AnimatedSection(
                    controller: _controller,
                    index: 0,
                    child: _HeroCard(loop: _heroLoop),
                  ),
                  _AnimatedSection(
                    controller: _controller,
                    index: 1,
                    child: _StoryCard(loop: _heroLoop),
                  ),
                  _AnimatedSection(
                    controller: _controller,
                    index: 2,
                    child: _BenefitsCard(loop: _heroLoop),
                  ),
                  _AnimatedSection(
                    controller: _controller,
                    index: 3,
                    child: _VisibilityCard(loop: _heroLoop),
                  ),
                  _AnimatedSection(
                    controller: _controller,
                    index: 4,
                    child: const _PriceCard(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _FloatingCTA(),
    ),
  );
}

/* ───────────────────────── HERO ───────────────────────── */

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) => GlassCard(
    padding: const EdgeInsets.all(24),
    child: Stack(
      children: [
        Positioned.fill(
          child: AnimatedBuilder(
            animation: loop,
            builder: (_, __) => DecoratedBox(
              decoration: BoxDecoration(
                gradient: SweepGradient(
                  colors: [
                    const Color(
                      0xFF7C4DFF,
                    ).withValues(alpha: 0.18 + loop.value * 0.05),
                    const Color(0xFF22D3EE).withValues(alpha: 0.14),
                    const Color(
                      0xFF34D399,
                    ).withValues(alpha: 0.18 - loop.value * 0.04),
                    const Color(
                      0xFF7C4DFF,
                    ).withValues(alpha: 0.18 + loop.value * 0.05),
                  ],
                  transform: GradientRotation(loop.value * math.pi * 2),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  radius: 1.1 + loop.value * 0.08,
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                GradientBadge(
                  size: 48,
                  child: Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 22,
                  ),
                  label: 'title',
                  icon: Icons.auto_awesome,
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TITLE SPONSORSHIP',
                      style: TextStyle(
                        letterSpacing: 1.2,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Flagship visibility • Founder-led care',
                      style: TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                  fontSize: 30,
                ),
                children: const [
                  TextSpan(
                    text: 'Local ',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'ART',
                    style: TextStyle(color: Color(0xFFFFD700)), // Gold color
                  ),
                  TextSpan(
                    text: 'beat • ',
                    style: TextStyle(color: Colors.white),
                  ),
                  TextSpan(
                    text: 'Presented by you',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The Title Sponsor is the sole name attached to the Local ARTbeat app shell, splash, and HUD. Tour stops still credit their on-the-ground partners—your role is to welcome people into the ecosystem.',
              style: TextStyle(fontSize: 16, height: 1.55),
            ),
            const SizedBox(height: 10),
            const Text(
              'Whenever Local ARTbeat is shown, it will display "brought to you by" with your name. Tours have their own sponsors, but you receive equal billing as the Title Sponsor.',
              style: TextStyle(fontSize: 15, height: 1.55),
            ),
            const SizedBox(height: 18),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _HeroPill(
                  icon: Icons.spa_rounded,
                  label: 'Always-on app shell',
                ),
                _HeroPill(icon: Icons.map_rounded, label: 'ENC tour inclusion'),
                _HeroPill(
                  icon: Icons.event_available_rounded,
                  label: 'April 2026 launch event',
                ),
                _HeroPill(
                  icon: Icons.handshake_rounded,
                  label: 'Founder stewardship',
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: _heroMetrics
                  .map(
                    (metric) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: _HeroMetricTile(data: metric),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ],
    ),
  );
}

/* ───────────────────────── STORY ───────────────────────── */

class _StoryCard extends StatelessWidget {
  const _StoryCard({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: AnimatedBuilder(
      animation: loop,
      builder: (_, __) {
        final accent =
            Color.lerp(
              const Color(0xFF22D3EE),
              const Color(0xFF34D399),
              loop.value,
            ) ??
            const Color(0xFF22D3EE);
        return SponsorshipSection(
          title: 'Why this exists',
          subtitle:
              'Small towns are not obsolete—they are waiting to circulate joy again.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Local ARTbeat is a founder-built app for Kinston and neighboring towns. It invites residents to walk, notice murals, and support businesses without relying on extractive industries.',
                style: TextStyle(fontSize: 16, height: 1.6),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                ),
                child: const Text(
                  'Title Sponsorship keeps the app independent. You are the presenting name that appears across the product while individual tours and events continue to highlight their own local sponsors.',
                  style: TextStyle(fontSize: 15.5, height: 1.6),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ENC tours have their own sponsors, but as Title Sponsor, you receive equal billing whenever Local ARTbeat is presented.',
                style: TextStyle(fontSize: 15, height: 1.55),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _StoryTag(label: 'Single presenting partner'),
                  _StoryTag(label: 'Equal billing with tour sponsors'),
                  _StoryTag(label: 'April 2026 launch'),
                ],
              ),
            ],
          ),
        );
      },
    ),
  );
}

/* ───────────────────────── BENEFITS ───────────────────────── */

class _BenefitsCard extends StatelessWidget {
  const _BenefitsCard({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: SponsorshipSection(
      title: 'What you unlock',
      subtitle:
          'Visibility rooted in the app shell, splash, HUD, and launch moment—without overriding tour sponsors.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _benefitTiles
                .asMap()
                .entries
                .map(
                  (entry) => _BenefitTile(
                    data: entry.value,
                    loop: loop,
                    index: entry.key,
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: const Text(
              'ENC tours list their own sponsors, but as Title Sponsor, you receive equal billing across the app, launch events, and editorial mentions.',
              style: TextStyle(fontSize: 13.5, height: 1.5),
            ),
          ),
        ],
      ),
    ),
  );
}

/* ───────────────────────── VISIBILITY ───────────────────────── */

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({required this.loop});

  final Animation<double> loop;

  @override
  Widget build(BuildContext context) => GlassCard(
    child: SponsorshipSection(
      title: 'How you’re experienced',
      subtitle:
          'From launch screen to on-street signage, your name anchors the journey.',
      child: Column(
        children: List.generate(_timelineSteps.length, (index) {
          final step = _timelineSteps[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == _timelineSteps.length - 1 ? 0 : 18,
            ),
            child: _TimelineRow(
              step: step,
              loop: loop,
              index: index,
              isLast: index == _timelineSteps.length - 1,
            ),
          );
        }),
      ),
    ),
  );
}

/* ───────────────────────── PRICE ───────────────────────── */

class _PriceCard extends StatelessWidget {
  const _PriceCard();

  @override
  Widget build(BuildContext context) => GlassCard(
    child: SponsorshipSection(
      title: 'Investment',
      subtitle: 'One market • 12 months • personal stewardship',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SponsorshipPriceSummary(
            price: r'$25,000',
            duration: '12 months',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _priceAssurances
                .map((label) => _PricePill(label: label))
                .toList(),
          ),
          const SizedBox(height: 16),
          Text(
            'Underwrites the Local ARTbeat platform, splash + HUD creative, April 2026 launch production, and monthly founder stewardship, with equal billing on all tours.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white, height: 1.6),
          ),
        ],
      ),
    ),
  );
}

/* ───────────────────────── CTA ───────────────────────── */

class _FloatingCTA extends StatelessWidget {
  const _FloatingCTA();

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        height: 86,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.02),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 26,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GradientCtaButton(
                  label: 'Become Title Sponsor',
                  icon: Icons.star,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SponsorshipReviewScreen(
                          type: 'Title Sponsor',
                          duration: '12 months',
                          price: r'$25,000',
                        ),
                      ),
                    );
                  },
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                const Text(
                  'Founder reply within 24 hours',
                  style: TextStyle(fontSize: 12.5, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

/* ───────────────────────── ANIMATION WRAPPER ───────────────────────── */

class _AnimatedSection extends StatelessWidget {
  const _AnimatedSection({
    required this.child,
    required this.controller,
    required this.index,
  });

  final Widget child;
  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        0.15 * index,
        0.15 * index + 0.6,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(animation),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: child,
        ),
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      color: Colors.white.withValues(alpha: 0.08),
      border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.white),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

class _HeroMetricTile extends StatelessWidget {
  const _HeroMetricTile({required this.data});

  final _HeroMetricData data;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (data.display != null)
        Text(
          data.display!,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        )
      else
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: data.value),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (_, value, __) => Text(
            '${value.toStringAsFixed(0)}${data.suffix}',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ),
      const SizedBox(height: 4),
      Text(
        data.label,
        style: const TextStyle(fontSize: 12.5, color: Colors.white70),
      ),
      const SizedBox(height: 4),
      Text(
        data.detail,
        style: const TextStyle(fontSize: 11.5, color: Colors.white54),
      ),
    ],
  );
}

class _StoryTag extends StatelessWidget {
  const _StoryTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(18),
      color: Colors.white.withValues(alpha: 0.06),
      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
    ),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
    ),
  );
}

class _BenefitTile extends StatelessWidget {
  const _BenefitTile({
    required this.data,
    required this.loop,
    required this.index,
  });

  final _BenefitTileData data;
  final Animation<double> loop;
  final int index;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: loop,
    builder: (_, __) {
      final pulse =
          (math.sin((loop.value + index * 0.2) * math.pi * 2) + 1) / 2;
      final gradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFF7C4DFF).withValues(alpha: 0.12 + pulse * 0.08),
          const Color(0xFF22D3EE).withValues(alpha: 0.06 + pulse * 0.04),
        ],
      );
      return GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SponsorshipReviewScreen(
                type: 'Title Sponsor',
                duration: '12 months',
                price: r'$25,000',
              ),
            ),
          );
        },
        child: Container(
          constraints: const BoxConstraints(minWidth: 150, maxWidth: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: gradient,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12 + pulse * 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(data.icon, color: Colors.white, size: 20),
              const SizedBox(height: 12),
              Text(
                data.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                data.detail,
                style: const TextStyle(fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: 10),
              Text(
                data.metric,
                style: const TextStyle(
                  fontSize: 12,
                  letterSpacing: 0.4,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.step,
    required this.loop,
    required this.index,
    required this.isLast,
  });

  final _TimelineStep step;
  final Animation<double> loop;
  final int index;
  final bool isLast;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          AnimatedBuilder(
            animation: loop,
            builder: (_, __) {
              final pulse =
                  (math.sin((loop.value + index * 0.25) * math.pi * 2) + 1) / 2;
              final color =
                  Color.lerp(
                    const Color(0xFF22D3EE),
                    const Color(0xFF7C4DFF),
                    pulse,
                  ) ??
                  const Color(0xFF22D3EE);
              return Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.6),
                      blurRadius: 14 + pulse * 6,
                    ),
                  ],
                ),
              );
            },
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 60,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.white.withValues(alpha: 0.04),
                  ],
                ),
              ),
            ),
        ],
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.white.withValues(alpha: 0.04),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(step.icon, size: 18, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    step.label,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text(
                    step.tag,
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                step.detail,
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

class _PricePill extends StatelessWidget {
  const _PricePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(999),
      gradient: const LinearGradient(
        colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
      ),
    ),
    child: Text(
      label,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
    ),
  );
}

class _HeroMetricData {
  const _HeroMetricData({
    required this.label,
    this.value,
    this.display,
    this.suffix = '',
    required this.detail,
  }) : assert((value != null) ^ (display != null));

  final String label;
  final double? value;
  final String? display;
  final String suffix;
  final String detail;
}

const List<_HeroMetricData> _heroMetrics = [
  _HeroMetricData(
    label: 'ENC tours',
    display: 'Included',
    detail: 'with equal billing as Title Sponsor',
  ),
  _HeroMetricData(
    label: 'Launch window',
    display: 'APR 2026',
    detail: 'community block party + media preview',
  ),
  _HeroMetricData(
    label: 'Term',
    display: '12 months',
    detail: 'exclusive presenting rights',
  ),
];

class _BenefitTileData {
  const _BenefitTileData({
    required this.icon,
    required this.title,
    required this.detail,
    required this.metric,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String metric;
}

const List<_BenefitTileData> _benefitTiles = [
  _BenefitTileData(
    icon: Icons.waves_rounded,
    title: 'App splash + HUD',
    detail:
        '“Local ARTbeat • brought to you by …” appears on splash, login, and HUD surfaces year-round.',
    metric: 'Every app open',
  ),
  _BenefitTileData(
    icon: Icons.layers_rounded,
    title: 'Navigation chrome',
    detail:
        'Name lockup in the drawer, settings, and core screens so residents always know who backed the platform.',
    metric: 'Core app shell',
  ),
  _BenefitTileData(
    icon: Icons.event_available_rounded,
    title: 'April 2026 launch spotlight',
    detail:
        'Stage mention, printed program credit, and signage at the launch party. Individual tours still list their own sponsors.',
    metric: 'Launch party',
  ),
  _BenefitTileData(
    icon: Icons.mic_rounded,
    title: 'Editorial mentions',
    detail:
        'Founder videos, newsletters, and brief audio cues reference you as the presenting supporter.',
    metric: 'Monthly updates',
  ),
  _BenefitTileData(
    icon: Icons.handshake_rounded,
    title: 'Founder stewardship',
    detail:
        'Monthly check-ins, reporting snapshots, and placement reviews to keep messaging aligned.',
    metric: '12 touchpoints',
  ),
];

class _TimelineStep {
  const _TimelineStep({
    required this.label,
    required this.detail,
    required this.tag,
    required this.icon,
  });

  final String label;
  final String detail;
  final String tag;
  final IconData icon;
}

const List<_TimelineStep> _timelineSteps = [
  _TimelineStep(
    label: 'App splash + HUD',
    detail:
        'Every open begins with your lockup before users see tours, rewards, or ads.',
    tag: 'App shell',
    icon: Icons.smartphone_rounded,
  ),
  _TimelineStep(
    label: 'Navigation + drawer',
    detail:
        'Drawer header, settings, and business resources carry “Local ARTbeat • brought to you by …” copy.',
    tag: 'Always-on',
    icon: Icons.dashboard_customize_rounded,
  ),
  _TimelineStep(
    label: 'Editorial mentions',
    detail:
        'Founder updates and media callouts thank the Title Sponsor while still crediting tour-specific partners separately.',
    tag: 'Media',
    icon: Icons.mic_rounded,
  ),
  _TimelineStep(
    label: 'April 2026 launch party',
    detail:
        'Live stage intro, program credit, and signage that announce the app is presented by you, with equal billing alongside tour sponsors.',
    tag: 'Launch event',
    icon: Icons.celebration_rounded,
  ),
  _TimelineStep(
    label: 'Founder stewardship',
    detail:
        'Monthly check-ins, reporting, and on-site walkthroughs keep messaging honest and grounded.',
    tag: '12 touchpoints',
    icon: Icons.handshake_rounded,
  ),
];

const List<String> _priceAssurances = [
  'App shell creative refresh',
  'Splash + HUD integration',
  'Launch party production',
  'Founder stewardship + reporting',
  'Media + pitch materials',
];
