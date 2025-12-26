import 'dart:ui';

import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    return Stack(
      children: [
        _buildWorldBackground(),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 40),
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
  }

  Widget _buildHeroSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
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
                    child: const Icon(Icons.campaign, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Turn gifts into promo fuel',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Visibility gifts unlock ad credits so artists can feature themselves, their artwork, and events without leaving Artbeat.',
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
                  _HeroBadge(label: 'Story takeovers'),
                  _HeroBadge(label: 'Discovery banners'),
                  _HeroBadge(label: 'Event push alerts'),
                  _HeroBadge(label: 'Neighborhood feed boosts'),
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
          'Choose your package',
          'Pick a placement size and duration that fits your launch.',
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
    final accent = isPopular ? const Color(0xFF22D3EE) : const Color(0xFF7C4DFF);

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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                  child: Icon(Icons.campaign, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
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
                    'Optimized for artist discovery, story placements, and event pushes.',
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
                  'Build Promo',
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
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
            colors: [
              Color(0xFF05030D),
              Color(0xFF0B1330),
              Color(0xFF041C16),
            ],
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

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
