import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class MapFloatingMenu extends StatelessWidget {
  final VoidCallback onViewArtWalks;
  final VoidCallback onCreateArtWalk;
  final VoidCallback onViewAttractions;

  const MapFloatingMenu({
    super.key,
    required this.onViewArtWalks,
    required this.onCreateArtWalk,
    required this.onViewAttractions,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'art_walk_map_floating_menu_label'.tr(),
      container: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          color: Colors.black.withValues(alpha: 0.42),
          border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x99000000),
              blurRadius: 20,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _FloatingMenuButton(
              label: 'art_walk_map_floating_menu_button_walks'.tr(),
              icon: Icons.route,
              onTap: onViewArtWalks,
            ),
            const SizedBox(height: 16),
            _FloatingMenuButton(
              label: 'art_walk_map_floating_menu_button_create'.tr(),
              icon: Icons.add_location_alt,
              onTap: onCreateArtWalk,
            ),
            const SizedBox(height: 16),
            _FloatingMenuButton(
              label: 'art_walk_map_floating_menu_button_attractions'.tr(),
              icon: Icons.auto_awesome,
              onTap: onViewAttractions,
            ),
          ],
        ),
      ),
    );
  }
}

class _FloatingMenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FloatingMenuButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                ),
                border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x4D22D3EE),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTypography.badge(Colors.white.withValues(alpha: 0.92)),
            ),
          ],
        ),
      ),
    );
  }
}
