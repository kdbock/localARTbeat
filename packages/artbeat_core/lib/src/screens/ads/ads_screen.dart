import 'package:flutter/material.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import '../../theme/artbeat_colors.dart';

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen> {
  final LocalAdIapService _iapService = LocalAdIapService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeIAP();
  }

  Future<void> _initializeIAP() async {
    try {
      await _iapService.initIap();
      await _iapService.fetchProducts();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInitialized = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load ad packages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ArtbeatColors.backgroundPrimary, Color(0xFFF8F9FA)],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(),
            const SizedBox(height: 32),

            // Ad Packages Section
            _buildAdPackagesSection(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArtbeatColors.primary, ArtbeatColors.primaryPurple],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.campaign,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promote Your Business',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Reach local art lovers and customers with targeted advertising',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Choose from various ad sizes and durations to fit your business needs',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdPackagesSection() {
    if (!_isInitialized) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(48),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Your Ad Package',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select the perfect package to promote your business',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          _buildAdCategory('Small Ads', [
            {
              'size': LocalAdSize.small,
              'duration': LocalAdDuration.oneWeek,
              'displayDuration': '1 Week',
              'impressions': '~5,000',
            },
            {
              'size': LocalAdSize.small,
              'duration': LocalAdDuration.oneMonth,
              'displayDuration': '1 Month',
              'impressions': '~20,000',
              'isPopular': true,
            },
            {
              'size': LocalAdSize.small,
              'duration': LocalAdDuration.threeMonths,
              'displayDuration': '3 Months',
              'impressions': '~60,000',
            },
          ]),
          const SizedBox(height: 24),
          _buildAdCategory('Large Ads', [
            {
              'size': LocalAdSize.big,
              'duration': LocalAdDuration.oneWeek,
              'displayDuration': '1 Week',
              'impressions': '~15,000',
            },
            {
              'size': LocalAdSize.big,
              'duration': LocalAdDuration.oneMonth,
              'displayDuration': '1 Month',
              'impressions': '~60,000',
              'isPopular': true,
            },
            {
              'size': LocalAdSize.big,
              'duration': LocalAdDuration.threeMonths,
              'displayDuration': '3 Months',
              'impressions': '~180,000',
            },
          ]),
        ],
      ),
    );
  }

  Widget _buildAdCategory(String title, List<Map<String, dynamic>> ads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...ads.map((ad) {
          final isPopular = ad['isPopular'] as bool? ?? false;
          final size = ad['size'] as LocalAdSize;
          final duration = ad['duration'] as LocalAdDuration;
          final price = AdPricingMatrix.getPrice(size, duration) ?? 0.0;

          return Column(
            children: [
              Card(
                elevation: isPopular ? 8 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: isPopular
                      ? const BorderSide(color: ArtbeatColors.primary, width: 2)
                      : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.campaign,
                                    color: ArtbeatColors.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        ad['displayDuration'] as String,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${price.toStringAsFixed(2)}',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: ArtbeatColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              if (isPopular)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: ArtbeatColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Popular',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => _handleAdPurchase(size, duration),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isPopular
                                ? ArtbeatColors.primary
                                : Colors.grey[300],
                            foregroundColor: isPopular
                                ? Colors.white
                                : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Create Ad'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          );
        }).toList(),
      ],
    );
  }

  Future<void> _handleAdPurchase(
    LocalAdSize size,
    LocalAdDuration duration,
  ) async {
    try {
      await Navigator.push<CreateLocalAdScreen>(
        context,
        MaterialPageRoute<CreateLocalAdScreen>(
          builder: (context) =>
              CreateLocalAdScreen(initialSize: size, initialDuration: duration),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
