import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/subscription_tier.dart';
import 'subscription_purchase_screen.dart';

class SubscriptionPlansScreen extends StatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  State<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends State<SubscriptionPlansScreen> {
  static const List<SubscriptionTier> _orderedTiers = [
    SubscriptionTier.creator,
    SubscriptionTier.business,
    SubscriptionTier.starter,
    SubscriptionTier.enterprise,
    SubscriptionTier.free,
  ];

  bool _isYearly = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'subscription_plans_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Stack(
        children: [
          _buildWorldBackground(),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 32),
              child: Column(
                children: [
                  _buildHeroSection(),
                  const SizedBox(height: 20),
                  _buildBillingToggle(),
                  const SizedBox(height: 20),
                  ..._orderedTiers.map(_buildPlanCard),
                  const SizedBox(height: 12),
                  _buildFaqPanel(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    final badges = [
      'Promo ads that convert to visibility gifts',
      'Fan subscriptions with instant boosts',
      'Unified billing across devices',
    ];

    return _buildGlassPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'subscription_plans_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'subscription_plans_cta'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 15,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: badges
                .map(
                  (badge) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.14),
                      ),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Row(
      children: [
        _buildToggleOption(
          label: 'Monthly',
          subtitle: 'Flexible billing',
          selected: !_isYearly,
          onTap: () => setState(() => _isYearly = false),
        ),
        const SizedBox(width: 12),
        _buildToggleOption(
          label: 'Yearly',
          subtitle: 'Save up to 20%',
          selected: _isYearly,
          onTap: () => setState(() => _isYearly = true),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.5)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  )
                : null,
            color: selected ? null : Colors.white.withValues(alpha: 0.03),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.75),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionTier tier) {
    final isHighlighted = tier == SubscriptionTier.creator;
    final price = _isYearly ? tier.yearlyPrice : tier.monthlyPrice;
    final cadence = _isYearly ? '/year' : '/month';
    final savings = (tier.monthlyPrice * 12) - tier.yearlyPrice;
    final features = tier.features;
    final preview = features.take(4).toList();

    final colors = _tierAccent(tier);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              gradient: isHighlighted
                  ? LinearGradient(
                      colors: [
                        colors[0].withValues(alpha: 0.45),
                        colors[1].withValues(alpha: 0.35),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isHighlighted
                  ? null
                  : Colors.white.withValues(alpha: 0.04),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 34,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isHighlighted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Text(
                      'Most popular',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                if (isHighlighted) const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(colors: colors),
                      ),
                      child: Icon(
                        _tierIcon(tier),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.displayName,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _tierSubtitle(tier),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      price > 0
                          ? '\$${price.toStringAsFixed(2)} $cadence'
                          : 'Free forever',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (savings > 0 && _isYearly)
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Text(
                          'Save \$${savings.toStringAsFixed(0)}',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 18),
                ...preview.map(
                  (feature) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            feature,
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (features.length > preview.length)
                  Text(
                    '+ ${features.length - preview.length} more benefits',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                const SizedBox(height: 20),
                _buildPlanButton(tier),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlanButton(SubscriptionTier tier) {
    final label = tier == SubscriptionTier.free
        ? 'Stay on Free'
        : 'Choose ${tier.displayName}';
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(26),
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: () => _openPurchase(tier),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFaqPanel() {
    const rows = [
      _FaqRow(
        title: 'How do promos and subscriptions connect?',
        description:
            'Each plan bundles fan subscriptions, promo ads, and gifting credits so every purchase fuels visibility.',
      ),
      _FaqRow(
        title: 'Can I switch plans later?',
        description:
            'Yes. Upgrading or downgrading prorates instantly and your remaining credits roll into the new plan.',
      ),
      _FaqRow(
        title: 'Do team plans support multiple creators?',
        description:
            'Business and Enterprise tiers unlock collaboration tools, shared analytics, and consolidated billing.',
      ),
    ];

    return _buildGlassPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      row.description,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _openPurchase(SubscriptionTier tier) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubscriptionPurchaseScreen(tier: tier),
      ),
    );
  }

  IconData _tierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return Icons.airline_stops;
      case SubscriptionTier.starter:
        return Icons.auto_awesome;
      case SubscriptionTier.creator:
        return Icons.palette;
      case SubscriptionTier.business:
        return Icons.workspaces;
      case SubscriptionTier.enterprise:
        return Icons.public;
    }
  }

  List<Color> _tierAccent(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return const [Color(0xFF374151), Color(0xFF111827)];
      case SubscriptionTier.starter:
        return const [Color(0xFF22D3EE), Color(0xFF2DD4BF)];
      case SubscriptionTier.creator:
        return const [Color(0xFF7C4DFF), Color(0xFFFF3D8D)];
      case SubscriptionTier.business:
        return const [Color(0xFF34D399), Color(0xFF22D3EE)];
      case SubscriptionTier.enterprise:
        return const [Color(0xFFFFC857), Color(0xFF7C4DFF)];
    }
  }

  String _tierSubtitle(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Explore the world background and publish a few drops.';
      case SubscriptionTier.starter:
        return 'Emerging creators ready to showcase more work.';
      case SubscriptionTier.creator:
        return 'Full visibility suite with featured placement and events.';
      case SubscriptionTier.business:
        return 'Studios and galleries coordinating teams and promos.';
      case SubscriptionTier.enterprise:
        return 'Institutions needing white-label, APIs, and dedicated support.';
    }
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            color: Colors.white.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 34,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWorldBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF03050F), Color(0xFF09122B), Color(0xFF021B17)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-140, -60), Colors.purpleAccent),
            _buildGlow(const Offset(120, 260), Colors.cyanAccent),
            _buildGlow(const Offset(-20, 420), Colors.pinkAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(Offset offset, Color color) {
    return Positioned(
      left: offset.dx < 0 ? null : offset.dx,
      right: offset.dx < 0 ? -offset.dx : null,
      top: offset.dy,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 110,
              spreadRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqRow {
  final String title;
  final String description;

  const _FaqRow({required this.title, required this.description});
}
