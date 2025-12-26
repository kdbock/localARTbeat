import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/subscription_tier.dart';
import 'subscription_purchase_screen.dart';

class SimpleSubscriptionPlansScreen extends StatefulWidget {
  const SimpleSubscriptionPlansScreen({super.key});

  @override
  State<SimpleSubscriptionPlansScreen> createState() =>
      _SimpleSubscriptionPlansScreenState();
}

class _SimpleSubscriptionPlansScreenState
    extends State<SimpleSubscriptionPlansScreen> {
  bool _isYearly = false;

  List<SubscriptionTier> get _tiers => const [
    SubscriptionTier.starter,
    SubscriptionTier.creator,
    SubscriptionTier.business,
    SubscriptionTier.enterprise,
    SubscriptionTier.free,
  ];

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
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 28),
              child: Column(
                children: [
                  _buildIntroCard(),
                  const SizedBox(height: 16),
                  _buildCompactToggle(),
                  const SizedBox(height: 20),
                  _buildCompactList(),
                  const SizedBox(height: 18),
                  Text(
                    'subscription_plans_nav_working'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.maybePop(context),
                    child: Text(
                      'core_subscription_cancel'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
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

  Widget _buildIntroCard() {
    return _buildGlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'subscription_plans_cta'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Designed for quick comparisons across visibility tiers.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Row(
        children: [
          _buildToggleChip(
            'Monthly',
            !_isYearly,
            () => setState(() => _isYearly = false),
          ),
          _buildToggleChip(
            'Yearly',
            _isYearly,
            () => setState(() => _isYearly = true),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: selected
                ? const LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                  )
                : null,
            color: selected ? null : Colors.transparent,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactList() {
    return _buildGlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Column(
        children: _tiers.map((tier) => _buildCompactRow(tier)).toList(),
      ),
    );
  }

  Widget _buildCompactRow(SubscriptionTier tier) {
    final price = _isYearly ? tier.yearlyPrice : tier.monthlyPrice;
    final cadence = _isYearly ? '/year' : '/month';
    final highlight = tier == SubscriptionTier.creator;
    final textColor = highlight ? Colors.white : Colors.white;
    final subtitle = tier.features.first;

    return GestureDetector(
      onTap: () => _openPurchase(tier),
      child: Container(
        margin: const EdgeInsets.only(left: 6, right: 6, bottom: 8, top: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          color: highlight
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.02),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: Icon(_tierIcon(tier), color: textColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tier.displayName,
                        style: GoogleFonts.spaceGrotesk(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (highlight)
                        const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price > 0 ? '\$${price.toStringAsFixed(2)} $cadence' : 'Free',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Tap to select',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.white54),
          ],
        ),
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
        return Icons.work;
      case SubscriptionTier.enterprise:
        return Icons.public;
    }
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            color: Colors.white.withValues(alpha: 0.04),
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
            _buildGlow(const Offset(-120, -60), Colors.purpleAccent),
            _buildGlow(const Offset(110, 240), Colors.cyanAccent),
            _buildGlow(const Offset(-30, 400), Colors.pinkAccent),
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
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 100,
              spreadRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
