import 'dart:ui';

import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdsScreen extends StatefulWidget {
  final bool isPreview;
  final bool? showAppBar;
  const AdsScreen({super.key, this.isPreview = false, this.showAppBar = true});

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
    if (widget.isPreview) {
      return _buildPreview();
    }
    final body = Stack(
      children: [
        _buildWorldBackground(),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              widget.showAppBar ?? true ? 96 : 32,
              16,
              40,
            ),
            child: Column(
              children: [
                _buildHeroSection(),
                const SizedBox(height: 24),
                _buildAdPackagesSection(),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.showAppBar ?? true) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Local Ads',
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

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF22D3EE),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.ads_click_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Local Ads',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Promote your local business and help fund art in your city.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white54),
        ],
      ),
    );
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
                        colors: [Color(0xFFFFA074), Color(0xFF22D3EE)],
                      ),
                    ),
                    child: const Icon(
                      Icons.campaign,
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
                          'Support local art with local business ads',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a simple local ad that helps fund artists and keeps your business visible in the Artbeat community.',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdPackagesSection() {
    if (!_isInitialized) {
      return _buildGlassPanel(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Fetching promo inventory...',
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Choose your ad package',
          'Select a placement size and run length that fits your business.',
        ),
        const SizedBox(height: 18),
        _buildAdCategory('Spotlight Ads', [
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
        const SizedBox(height: 20),
        _buildAdCategory('Billboard Ads', [
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
    );
  }

  Widget _buildAdCategory(String title, List<Map<String, dynamic>> ads) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ...ads.map((ad) => _buildAdCard(ad)).toList(),
      ],
    );
  }

  Widget _buildAdCard(Map<String, dynamic> ad) {
    final isPopular = ad['isPopular'] as bool? ?? false;
    final size = ad['size'] as LocalAdSize;
    final duration = ad['duration'] as LocalAdDuration;
    final price = AdPricingMatrix.getPrice(size, duration) ?? 0.0;
    final accent = isPopular
        ? const Color(0xFF22D3EE)
        : const Color(0xFF7C4DFF);

    // Determine the image asset based on size and duration
    String imageAsset;
    if (size == LocalAdSize.big) {
      // Billboard ads
      if (duration == LocalAdDuration.oneWeek) {
        imageAsset = 'assets/images/ad_big_1w.png';
      } else if (duration == LocalAdDuration.oneMonth) {
        imageAsset = 'assets/images/ad_big_1m.png';
      } else {
        imageAsset = 'assets/images/ad_big_3m.png';
      }
    } else {
      // Spotlight ads
      if (duration == LocalAdDuration.oneWeek) {
        imageAsset = 'assets/images/ad_small_1w.png';
      } else if (duration == LocalAdDuration.oneMonth) {
        imageAsset = 'assets/images/ad_small_1m.png';
      } else {
        imageAsset = 'assets/images/ad_small_3m.png';
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _buildGlassPanel(
        borderColor: isPopular
            ? accent.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.15),
        gradient: LinearGradient(
          colors: [
            accent.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display the promotional image
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset(
                imageAsset,
                height: size == LocalAdSize.big ? 280 : 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback to icon if image fails to load
                  return Container(
                    height: size == LocalAdSize.big ? 280 : 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: Icon(Icons.campaign, color: accent, size: 48),
                  );
                },
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ad['displayDuration'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        ad['impressions'] as String,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.7),
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
                      '\$${price.toStringAsFixed(2)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    if (isPopular)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Popular',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Icon(Icons.auto_graph, color: accent, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Designed for local businesses that want to support artists and reach nearby art lovers.',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _handleAdPurchase(size, duration),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Create Local Ad',
                  style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    Gradient? gradient,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor ?? Colors.white24),
            color: gradient == null
                ? Colors.white.withValues(alpha: 0.04)
                : null,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 28,
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
            colors: [Color(0xFF05030D), Color(0xFF0B1330), Color(0xFF041C16)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-120, -60), Colors.orangeAccent),
            _buildGlow(const Offset(140, 120), Colors.tealAccent),
            _buildGlow(const Offset(-30, 320), Colors.purpleAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.05,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.55),
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
        width: 180,
        height: 180,
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
