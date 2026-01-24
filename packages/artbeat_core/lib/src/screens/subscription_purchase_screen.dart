import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/subscription_tier.dart';
import '../services/in_app_subscription_service.dart';

class SubscriptionPurchaseScreen extends StatefulWidget {
  final SubscriptionTier tier;
  final bool isUpgrade;

  const SubscriptionPurchaseScreen({
    super.key,
    required this.tier,
    this.isUpgrade = false,
  });

  @override
  State<SubscriptionPurchaseScreen> createState() =>
      _SubscriptionPurchaseScreenState();
}

class _SubscriptionPurchaseScreenState
    extends State<SubscriptionPurchaseScreen> {
  final InAppSubscriptionService _subscriptionService =
      InAppSubscriptionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  bool _isYearlyPlan = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final planPrice = _isYearlyPlan
        ? widget.tier.yearlyPrice
        : widget.tier.monthlyPrice;
    final savings = (widget.tier.monthlyPrice * 12) - widget.tier.yearlyPrice;
    final titlePrefix = widget.isUpgrade ? 'Upgrade' : 'Subscribe';

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '$titlePrefix ${_getTierName(widget.tier)}',
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
              padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
              child: Column(
                children: [
                  _buildTierHero(),
                  const SizedBox(height: 20),
                  _buildPlanSelector(planPrice, savings),
                  const SizedBox(height: 20),
                  _buildFeatureDeck(),
                  const SizedBox(height: 20),
                  _buildPaymentDetails(),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 20),
                    _buildErrorToast(),
                  ],
                  const SizedBox(height: 24),
                  _buildPrimaryCta(planPrice),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
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

  Widget _buildTierHero() {
    final badges = [
      'Visibility boosts',
      'Promo ad credits',
      'Fan subscription perks',
    ];

    return _buildGlassPanel(
      padding: const EdgeInsets.all(28),
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
                child: Icon(
                  _getTierIcon(widget.tier),
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
                      '${_getTierName(widget.tier)} Plan',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Bundle fan subscriptions with automatic featuring, boosted drops, and credits that turn boosts into promos.',
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
                        color: Colors.white.withValues(alpha: 0.16),
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

  Widget _buildPlanSelector(double planPrice, double savings) {
    final monthly = widget.tier.monthlyPrice;
    final yearly = widget.tier.yearlyPrice;

    Widget buildOption({
      required bool selected,
      required String title,
      required String subtitle,
      required String price,
      required VoidCallback onTap,
    }) {
      final gradientColors = selected
          ? const [Color(0xFF7C4DFF), Color(0xFF22D3EE)]
          : const [Color(0xFFFFFFFF), Color(0xFFFFFFFF)];

      return Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: selected
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.white.withValues(alpha: 0.1),
              ),
              gradient: selected
                  ? LinearGradient(
                      colors: [
                        gradientColors[0].withValues(alpha: 0.35),
                        gradientColors[1].withValues(alpha: 0.3),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: selected ? null : Colors.white.withValues(alpha: 0.02),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      selected ? Icons.radio_button_checked : Icons.circle,
                      size: 18,
                      color: selected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  price,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return _buildGlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your cadence',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              buildOption(
                selected: !_isYearlyPlan,
                title: 'Monthly',
                subtitle: 'Flexible subscription',
                price: '\$${monthly.toStringAsFixed(2)}',
                onTap: () {
                  setState(() => _isYearlyPlan = false);
                },
              ),
              const SizedBox(width: 12),
              buildOption(
                selected: _isYearlyPlan,
                title: 'Yearly',
                subtitle:
                    'Saves ${savings > 0 ? '\$${savings.toStringAsFixed(0)} per year' : 'vs monthly'}',
                price: '\$${yearly.toStringAsFixed(2)}',
                onTap: () {
                  setState(() => _isYearlyPlan = true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureDeck() {
    final features = _getTierFeatures(widget.tier);

    return _buildGlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What you unlock',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                  const SizedBox(width: 12),
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
        ],
      ),
    );
  }

  Widget _buildPaymentDetails() {
    return _buildGlassPanel(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Billing overview',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.lock_outline,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Payments run through the App Store with encrypted checkout and easy cancellation in device settings.',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/terms-of-service'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Terms of Service',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/privacy-policy'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    'Privacy Policy',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorToast() {
    return _buildGlassPanel(
      borderColor: Colors.redAccent.withValues(alpha: 0.5),
      gradient: LinearGradient(
        colors: [
          Colors.redAccent.withValues(alpha: 0.25),
          Colors.white.withValues(alpha: 0.02),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage ?? '',
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCta(double planPrice) {
    final label = _isYearlyPlan
        ? 'Activate yearly plan'
        : 'Activate monthly plan';
    final priceSuffix = _isYearlyPlan
        ? '\$${planPrice.toStringAsFixed(2)} / year'
        : '\$${planPrice.toStringAsFixed(2)} / month';

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: _isLoading ? null : _handleSubscription,
        borderRadius: BorderRadius.circular(28),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 30,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                      strokeWidth: 3,
                    ),
                  )
                : Text(
                    '$label · $priceSuffix',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
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
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.14),
            ),
            color: gradient == null
                ? Colors.white.withValues(alpha: 0.05)
                : null,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 36,
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
            _buildGlow(const Offset(120, 200), Colors.blueAccent),
            _buildGlow(const Offset(-40, 360), Colors.pinkAccent),
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
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.18),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 120,
              spreadRadius: 20,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubscription() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() {
        _errorMessage = 'User not authenticated. Please log in.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _subscriptionService.subscribeToTier(
        widget.tier,
        isYearly: _isYearlyPlan,
      );

      if (success) {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              widget.isUpgrade ? 'Upgrade Successful!' : 'Subscription Active!',
            ),
            content: Text(
              widget.isUpgrade
                  ? 'Your account now includes ${_getTierName(widget.tier)} perks.'
                  : 'Welcome to ${_getTierName(widget.tier)}. Your plan is live.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) {
          Navigator.pop(context, true);
        }
      } else {
        throw Exception('Failed to initiate subscription purchase');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Subscription failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getTierName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return 'Starter';
      case SubscriptionTier.creator:
        return 'Creator';
      case SubscriptionTier.business:
        return 'Business';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
      case SubscriptionTier.free:
        return 'Free';
    }
  }

  IconData _getTierIcon(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return Icons.palette;
      case SubscriptionTier.creator:
        return Icons.star;
      case SubscriptionTier.business:
        return Icons.business_center;
      case SubscriptionTier.enterprise:
        return Icons.workspace_premium;
      case SubscriptionTier.free:
        return Icons.person;
    }
  }

  List<String> _getTierFeatures(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.starter:
        return [
          'Up to 25 artworks',
          '5GB storage',
          '50 AI credits each month',
          'Basic analytics',
          'Community features',
          'Email support',
        ];
      case SubscriptionTier.creator:
        return [
          'Up to 100 artworks',
          '25GB storage',
          '200 AI credits each month',
          'Advanced analytics',
          'Featured placement and event creation',
          'Priority support',
        ];
      case SubscriptionTier.business:
        return [
          'Unlimited artworks',
          '100GB storage',
          '500 AI credits each month',
          'Team collaboration (5 users)',
          'Custom branding and API access',
          'Dedicated support',
        ];
      case SubscriptionTier.enterprise:
        return [
          'Unlimited everything',
          'Custom integrations',
          'White-label options',
          'Enterprise security',
          'Dedicated account manager',
        ];
      case SubscriptionTier.free:
        return [
          'Up to 3 artworks',
          '0.5GB storage',
          '5 AI credits per month',
          'Basic community access',
        ];
    }
  }
}
