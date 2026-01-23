import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../theme/design_system.dart';
import '../../viewmodels/artist_onboarding/artist_onboarding_view_model.dart';
import 'artist_onboarding_navigator.dart';
import 'onboarding_widgets.dart';

/// Screen 7: Tier Selection
///
/// Features:
/// - Tier cards (FREE pre-selected)
/// - IAP integration (placeholder)
/// - Celebration animation on completion
class TierSelectionScreen extends StatefulWidget {
  const TierSelectionScreen({super.key});

  @override
  State<TierSelectionScreen> createState() => _TierSelectionScreenState();
}

class _TierSelectionScreenState extends State<TierSelectionScreen> {
  String? _selectedTier = 'FREE';
  bool _isProcessing = false;

  final List<TierCard> _tierCards = [
    TierCard(
      name: 'FREE',
      sku: null,
      price: 'Free forever',
      icon: Icons.palette,
      topFeatures: [
        'Artist profile with custom URL',
        'Upload up to 10 artworks',
        'Basic analytics',
      ],
    ),
    TierCard(
      name: 'STARTER',
      sku: 'artbeat_starter_monthly',
      price: '\$4.99/month',
      icon: Icons.star,
      topFeatures: ['25 artworks', '5GB storage', 'Artwork Auctions'],
    ),
    TierCard(
      name: 'CREATOR',
      sku: 'artbeat_creator_monthly',
      price: '\$12.99/month',
      icon: Icons.auto_awesome,
      badge: 'MOST POPULAR',
      topFeatures: ['100 artworks', 'Advanced analytics', 'Priority placement'],
    ),
    TierCard(
      name: 'BUSINESS',
      sku: 'artbeat_business_monthly',
      price: '\$29.99/month',
      icon: Icons.business_center,
      topFeatures: [
        'Unlimited artworks',
        'Team features',
        'Virtual exhibitions',
      ],
    ),
    TierCard(
      name: 'ENTERPRISE',
      sku: 'artbeat_enterprise_monthly',
      price: '\$79.99/month',
      icon: Icons.diamond,
      topFeatures: ['White-label options', 'Account manager', '0% commission'],
    ),
  ];

  @override
  void initState() {
    super.initState();

    // Load saved selection
    final viewModel = context.read<ArtistOnboardingViewModel>();
    _selectedTier = viewModel.data.selectedTier ?? 'FREE';
  }

  Future<void> _selectTier(String tier, String? sku) async {
    setState(() => _selectedTier = tier);

    final viewModel = context.read<ArtistOnboardingViewModel>();
    viewModel.selectTier(tier);

    // If paid tier, would trigger IAP here
    if (sku != null) {
      // TODO: Integrate IAP
      // For now, just simulate selection
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }

  Future<void> _completeOnboarding() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    // Show progress dialog
    if (mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFF0A0E27),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00F5FF)),
                ),
                const SizedBox(height: 24),
                Text(
                  'Setting up your artist profile...',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Uploading images and saving your data',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    try {
      final viewModel = context.read<ArtistOnboardingViewModel>();
      await viewModel.completeOnboarding();

      if (mounted) {
        Navigator.of(context).pop(); // Dismiss progress dialog
        ArtistOnboardingNavigator.navigateToCompletion(context);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss progress dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete onboarding: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScaffold(
      currentStep: 6,
      nextButtonText: _isProcessing ? 'Processing...' : 'Complete Setup',
      canProceed: !_isProcessing && _selectedTier != null,
      onNext: _completeOnboarding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeader(
            title: 'Choose Your Artist Package',
            subtitle: 'Step 6 of 6 - Final Step!',
          ),

          // Reassurance
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF00F5FF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'You can change your plan anytime from settings',
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

          // Tier cards
          ..._tierCards.map((card) {
            final isSelected = _selectedTier == card.name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildTierCard(card, isSelected),
            );
          }).toList(),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTierCard(TierCard card, bool isSelected) {
    return GestureDetector(
      onTap: () => _selectTier(card.name, card.sku),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00F5FF).withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00F5FF)
                : Colors.white.withValues(alpha: 0.2),
            width: isSelected ? 3 : 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00F5FF).withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    card.icon,
                    color: const Color(0xFF00F5FF),
                    size: 24,
                  ),
                ),

                const SizedBox(width: 16),

                // Name and price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            card.name,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (card.badge != null) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                card.badge!,
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        card.price,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          color: const Color(0xFF00F5FF),
                        ),
                      ),
                    ],
                  ),
                ),

                // Selection indicator
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF00F5FF),
                    size: 32,
                  )
                else
                  Icon(
                    Icons.circle_outlined,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 32,
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Top features
            ...card.topFeatures.map((feature) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check, color: Color(0xFF00F5FF), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      feature,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            // CTA button
            const SizedBox(height: 12),
            HudButton(
              text: isSelected
                  ? 'Selected'
                  : card.sku == null
                  ? 'Start with Free'
                  : 'Upgrade Now',
              onPressed: isSelected
                  ? null
                  : () => _selectTier(card.name, card.sku),
              isPrimary: isSelected || card.sku == null,
            ),
          ],
        ),
      ),
    );
  }
}

class TierCard {
  final String name;
  final String? sku;
  final String price;
  final IconData icon;
  final String? badge;
  final List<String> topFeatures;

  TierCard({
    required this.name,
    required this.sku,
    required this.price,
    required this.icon,
    this.badge,
    required this.topFeatures,
  });
}
