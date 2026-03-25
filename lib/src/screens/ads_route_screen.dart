import 'dart:ui';

import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdsRouteScreen extends StatefulWidget {
  const AdsRouteScreen({super.key, this.showAppBar = true});

  final bool showAppBar;

  @override
  State<AdsRouteScreen> createState() => _AdsRouteScreenState();
}

class _AdsRouteScreenState extends State<AdsRouteScreen> {
  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        _buildWorldBackground(),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              widget.showAppBar ? 96 : 32,
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

    if (!widget.showAppBar) {
      return body;
    }

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

  Widget _buildHeroSection() => ClipRRect(
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
              const SizedBox(height: 24),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _AdsFeatureChip(
                    icon: Icons.public,
                    label: 'Local discovery',
                  ),
                  _AdsFeatureChip(
                    icon: Icons.palette,
                    label: 'Artist funding',
                  ),
                  _AdsFeatureChip(
                    icon: Icons.repeat,
                    label: 'Monthly placements',
                  ),
                  _AdsFeatureChip(
                    icon: Icons.verified_outlined,
                    label: 'Review before live',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

  Widget _buildAdPackagesSection() => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Launch a simple local ad',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a banner or inline ad request for your business, or browse active local promotions already running in the app.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Monthly ad subscriptions are paid through Apple, then reviewed before they go live.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Available placements: Community feed, Artists and artwork, and Events.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'After you submit, Apple checkout opens. Approved ads then publish into the placement you selected.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: _openCreateAdFlow,
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Submit local ad'),
              ),
              OutlinedButton.icon(
                onPressed: _openBrowseAdsFlow,
                icon: const Icon(Icons.storefront_outlined),
                label: const Text('Browse local ads'),
              ),
            ],
          ),
        ],
      ),
    );

  Future<void> _openCreateAdFlow() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const CreateLocalAdScreen(),
      ),
    );
  }

  Future<void> _openBrowseAdsFlow() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => const LocalAdsListScreen(),
      ),
    );
  }

  Widget _buildWorldBackground() => DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF020617),
            Color(0xFF0F172A),
            Color(0xFF111827),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            left: -40,
            child: _buildGlowOrb(
              size: 280,
              colors: const [Color(0x44F97316), Color(0x0022D3EE)],
            ),
          ),
          Positioned(
            right: -80,
            bottom: -120,
            child: _buildGlowOrb(
              size: 320,
              colors: const [Color(0x4422D3EE), Color(0x00F97316)],
            ),
          ),
        ],
      ),
    );

  Widget _buildGlowOrb({
    required double size,
    required List<Color> colors,
  }) => IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: colors),
        ),
      ),
    );
}

class _AdsFeatureChip extends StatelessWidget {
  const _AdsFeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF22D3EE)),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
}
