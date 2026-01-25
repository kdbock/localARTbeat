import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/design_system.dart';
import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'onboarding_widgets.dart';

/// Screen 6: Benefits Discovery
///
/// Features:
/// - Tabbed interface for 5 tiers
/// - FREE tier pre-selected
/// - Tier details with icon-based benefits
/// - Compare All Tiers modal
/// - Track viewed tiers for analytics
class BenefitsScreen extends StatefulWidget {
  const BenefitsScreen({super.key});

  @override
  State<BenefitsScreen> createState() => _BenefitsScreenState();
}

class _BenefitsScreenState extends State<BenefitsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<TierInfo> _tiers = [
    TierInfo(
      name: 'FREE',
      sku: null,
      price: 'Free forever',
      icon: Icons.palette,
      features: [
        'Artist profile with custom URL',
        'Upload up to 10 artworks',
        'Connect with collectors',
        'Public gallery and search',
        'Basic analytics (views, likes)',
        'Sell artwork with standard commission',
      ],
    ),
    TierInfo(
      name: 'STARTER',
      sku: 'artbeat_starter_monthly',
      price: '\$4.99/month',
      icon: Icons.star,
      badge: null,
      features: [
        'Everything in FREE, plus:',
        'Upload up to 25 artworks',
        '5GB storage for high-res images',
        'Basic analytics dashboard',
        'Featured artist badge',
        'Artwork Auctions',
        'Priority email support',
      ],
    ),
    TierInfo(
      name: 'CREATOR',
      sku: 'artbeat_creator_monthly',
      price: '\$12.99/month',
      icon: Icons.auto_awesome,
      badge: 'MOST POPULAR',
      features: [
        'Everything in Starter, plus:',
        'Upload up to 100 artworks',
        '25GB storage',
        'Advanced analytics',
        'Priority search placement',
        'Artwork Auctions (featured)',
        'Exclusive community access',
        'Quarterly newsletter feature',
        'Custom profile themes',
      ],
    ),
    TierInfo(
      name: 'BUSINESS',
      sku: 'artbeat_business_monthly',
      price: '\$29.99/month',
      icon: Icons.business_center,
      features: [
        'Everything in Creator, plus:',
        'Unlimited artwork uploads',
        'Team collaboration features',
        'API access for website',
        'Advanced sales tools',
        'Artwork Auctions (premium)',
        'Virtual exhibition spaces',
        '0% commission on first 10 sales/month',
        'Priority phone support',
      ],
    ),
    TierInfo(
      name: 'ENTERPRISE',
      sku: 'artbeat_enterprise_monthly',
      price: '\$79.99/month',
      icon: Icons.diamond,
      features: [
        'Everything in Business, plus:',
        'White-label profile options',
        'Dedicated account manager',
        'Custom integrations',
        'Artwork Auctions (zero commission)',
        'Gallery partnership program',
        'Featured homepage placement',
        'Video production assistance',
        'Exclusive networking events',
        '0% commission on ALL sales',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tiers.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        // Track tier viewed
        final viewModel = context.read<ArtistOnboardingViewModel>();
        viewModel.trackTierViewed(_tiers[_tabController.index].name);
      }
    });

    // Track FREE tier as viewed on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ArtistOnboardingViewModel>().trackTierViewed('FREE');
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeader(
            title: 'Discover Your Artist Benefits',
            subtitle: 'Explore membership tiers and find what works for you',
          ),

          // Social proof
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups, color: Color(0xFF00F5FF), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '🎨 78% of artists start with FREE and upgrade as they grow',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tabs
          _buildTabs(),

          const SizedBox(height: 24),

          // Tab content
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: _tiers.map((tier) => _buildTierContent(tier)).toList(),
            ),
          ),

          const SizedBox(height: 24),

          // Compare button
          Center(
            child: HudButton.secondary(
              text: 'Compare All Tiers',
              icon: Icons.compare_arrows,
              onPressed: _showComparisonModal,
            ),
          ),

          const SizedBox(height: 16),

          // Reassurance text
          Center(
            child: Text(
              'You can change anytime from settings',
              style: GoogleFonts.poppins(fontSize: 14, color: Colors.white54),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          color: const Color(0xFF00F5FF),
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white70,
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        tabs: _tiers.map((tier) {
          return Tab(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tier.icon, size: 16),
                  const SizedBox(width: 4),
                  Text(tier.name, style: const TextStyle(fontSize: 12)),
                  if (tier.badge != null) ...[
                    const SizedBox(width: 2),
                    const Icon(Icons.star, size: 10, color: Colors.amber),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTierContent(TierInfo tier) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tier name and price
          Row(
            children: [
              Icon(tier.icon, color: const Color(0xFF00F5FF), size: 32),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.name,
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      tier.price,
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        color: const Color(0xFF00F5FF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Features
          ...tier.features.map((feature) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00F5FF),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showComparisonModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Color(0xFF0A0E27),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Compare All Tiers',
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),

            // Comparison table
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Comparison table coming soon...\n\nFor now, explore each tier using the tabs above.',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TierInfo {
  final String name;
  final String? sku;
  final String price;
  final IconData icon;
  final String? badge;
  final List<String> features;

  TierInfo({
    required this.name,
    required this.sku,
    required this.price,
    required this.icon,
    this.badge,
    required this.features,
  });
}
