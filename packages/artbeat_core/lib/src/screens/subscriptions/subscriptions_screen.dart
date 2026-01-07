import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/subscription_tier.dart';
import '../../services/in_app_purchase_manager.dart';
import '../../services/in_app_purchase_setup.dart';

class SubscriptionsScreen extends StatefulWidget {
  final bool showAppBar;
  const SubscriptionsScreen({Key? key, this.showAppBar = true})
    : super(key: key);

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final InAppPurchaseManager _purchaseManager = InAppPurchaseManager();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
  }

  Future<void> _initializePurchases() async {
    final setup = InAppPurchaseSetup();
    final initialized = await setup.initialize();
    if (mounted) {
      setState(() {
        _isInitialized = initialized;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        _buildWorldBackground(),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              widget.showAppBar ? 120 : 32,
              16,
              40,
            ),
            child: Column(
              children: [
                _buildHeroSection(),
                const SizedBox(height: 24),
                _buildSubscriptionTiers(),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Fan Subscriptions',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: body,
      );
    }

    return body;
  }

  Widget _buildHeroSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            color: Colors.white.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
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
                          'Bundle perks with guaranteed visibility',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Fan subscriptions pair exclusive drops with automatic featuring for new artwork, events, and ad placements.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HeroBadge(label: 'Premium drops'),
                  _HeroBadge(label: 'Priority featuring'),
                  _HeroBadge(label: 'Ad credits included'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionTiers() {
    final tiers = [
      {
        'name': 'Starter',
        'monthlyProductId': 'artbeat_starter_monthly',
        'yearlyProductId': 'artbeat_starter_yearly',
        'monthlyPrice': '\$4.99',
        'yearlyPrice': '\$49.99',
        'features': [
          '10 artwork uploads + basic insights',
          'Access to visibility gifts dashboard',
          'Standard support response',
        ],
      },
      {
        'name': 'Creator',
        'monthlyProductId': 'artbeat_creator_monthly',
        'yearlyProductId': 'artbeat_creator_yearly',
        'monthlyPrice': '\$9.99',
        'yearlyPrice': '\$99.99',
        'features': [
          'Unlimited uploads and deep analytics',
          'Automatic featuring for new drops',
          'Priority placement in discovery',
          'Monthly promo ad credits',
        ],
        'isPopular': true,
      },
      {
        'name': 'Business',
        'monthlyProductId': 'artbeat_business_monthly',
        'yearlyProductId': 'artbeat_business_yearly',
        'monthlyPrice': '\$19.99',
        'yearlyPrice': '\$199.99',
        'features': [
          'Creator tier + commission hub + API',
          'Custom storefront branding',
          'Quarterly event promo boosts',
        ],
      },
      {
        'name': 'Enterprise',
        'monthlyProductId': 'artbeat_enterprise_monthly',
        'yearlyProductId': 'artbeat_enterprise_yearly',
        'monthlyPrice': '\$49.99',
        'yearlyPrice': '\$499.99',
        'features': [
          'All Business perks with white-label options',
          'Dedicated partner manager',
          '24/7 launch and promo support',
        ],
      },
    ];

    return Column(children: tiers.map((tier) => _buildTierCard(tier)).toList());
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final isPopular = tier['isPopular'] as bool? ?? false;
    final accent = isPopular ? const Color(0xFF22D3EE) : Colors.white24;

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: _buildGlassPanel(
        borderColor: isPopular ? accent : Colors.white24,
        gradient: isPopular
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier['name'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tier['monthlyPrice'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'per month · ${tier['yearlyPrice']} per year',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Creator Favorite',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            ...(tier['features'] as List<String>).map(
              (feature) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () =>
                        _handleSubscription(tier['monthlyProductId'] as String),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Subscribe Monthly',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () =>
                        _handleSubscription(tier['yearlyProductId'] as String),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      'Subscribe Yearly',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    Gradient? gradient,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: borderColor ?? Colors.white24),
            color: gradient == null
                ? Colors.white.withValues(alpha: 0.04)
                : null,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
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
            _buildGlow(const Offset(-140, -80), Colors.greenAccent),
            _buildGlow(const Offset(120, 160), Colors.tealAccent),
            _buildGlow(const Offset(-40, 320), Colors.pinkAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
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
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 110,
              spreadRadius: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscription(String productId) async {
    if (!_isInitialized) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('In-app purchases not available. Please try again.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    try {
      final tier = _getTierFromProductId(productId);
      final isYearly = productId.contains('yearly');

      final success = await _purchaseManager.subscribeToTier(
        tier,
        isYearly: isYearly,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Subscription initiated!'
                  : 'Failed to complete subscription',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e, _) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  SubscriptionTier _getTierFromProductId(String productId) {
    if (productId.contains('starter')) return SubscriptionTier.starter;
    if (productId.contains('creator')) return SubscriptionTier.creator;
    if (productId.contains('business')) return SubscriptionTier.business;
    if (productId.contains('enterprise')) return SubscriptionTier.enterprise;
    return SubscriptionTier.starter;
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
