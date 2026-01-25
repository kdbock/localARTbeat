import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:artbeat_core/shared_widgets.dart';

class ArtWalkInfoCard extends StatefulWidget {
  final VoidCallback onDismiss;

  const ArtWalkInfoCard({super.key, required this.onDismiss});

  @override
  State<ArtWalkInfoCard> createState() => _ArtWalkInfoCardState();
}

class _ArtWalkInfoCardState extends State<ArtWalkInfoCard> {
  static const String _prefKey = 'art_walk_info_dismissed';
  bool _showCard = true;

  @override
  void initState() {
    super.initState();
    _checkIfShouldShow();
  }

  Future<void> _checkIfShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final isDismissed = prefs.getBool(_prefKey) ?? false;

    if (mounted && isDismissed) {
      setState(() => _showCard = false);
      widget.onDismiss();
    }
  }

  Future<void> _dismissForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
    _hideCard();
  }

  void _hideCard() {
    if (!mounted) return;
    setState(() => _showCard = false);
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showCard) return const SizedBox.shrink();

    final featurePills = [
      _FeaturePill(
        icon: Icons.photo_camera_outlined,
        label: 'art_walk_art_walk_info_card_feature_capture'.tr(),
      ),
      _FeaturePill(
        icon: Icons.map_outlined,
        label: 'art_walk_art_walk_info_card_feature_map'.tr(),
      ),
      _FeaturePill(
        icon: Icons.alt_route,
        label: 'art_walk_art_walk_info_card_feature_routes'.tr(),
      ),
      _FeaturePill(
        icon: Icons.travel_explore,
        label: 'art_walk_art_walk_info_card_feature_explore'.tr(),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        borderRadius: 28,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _GradientIconBadge(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'art_walk_art_walk_info_card_title'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'art_walk_art_walk_info_card_subtitle'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  tooltip: 'art_walk_art_walk_info_card_tooltip_close'.tr(),
                  onPressed: _hideCard,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'art_walk_art_walk_info_card_body'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.78),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Wrap(spacing: 12, runSpacing: 12, children: featurePills),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.24),
                        ),
                      ),
                    ),
                    onPressed: _dismissForever,
                    child: Text(
                      'art_walk_art_walk_info_card_text_dont_show_again'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientCTAButton(
                    label: 'art_walk_art_walk_info_card_button_got_it'.tr(),
                    icon: Icons.bolt,
                    onPressed: _hideCard,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientIconBadge extends StatelessWidget {
  const _GradientIconBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C4DFF).withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Icon(Icons.route, color: Colors.white, size: 28),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
