import 'package:flutter/material.dart';
import 'package:artbeat_art_walk/src/widgets/glass_card.dart';

class MapButtonRow extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onRecenter;

  const MapButtonRow({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onRecenter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        GlassCard(
          padding: const EdgeInsets.all(10),
          borderRadius: 50.0,
          child: IconButton(
            icon: const Icon(Icons.zoom_in),
            onPressed: onZoomIn,
          ),
        ),
        const SizedBox(width: 8),
        GlassCard(
          padding: const EdgeInsets.all(10),
          borderRadius: 50.0,
          child: IconButton(
            icon: const Icon(Icons.zoom_out),
            onPressed: onZoomOut,
          ),
        ),
        const SizedBox(width: 8),
        GlassCard(
          padding: const EdgeInsets.all(10),
          borderRadius: 50.0,
          child: IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: onRecenter,
          ),
        ),
      ],
    );
  }
}
