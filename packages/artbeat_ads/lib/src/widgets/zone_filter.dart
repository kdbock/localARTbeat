import 'package:flutter/material.dart';
import '../models/index.dart';

class PlacementFilter extends StatelessWidget {
  final LocalAdZone selectedPlacement;
  final void Function(LocalAdZone) onPlacementChanged;

  const PlacementFilter({
    Key? key,
    required this.selectedPlacement,
    required this.onPlacementChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: LocalAdZoneExtension.launchPlacements
            .map(
              (zone) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(_placementLabel(zone)),
                  selected: selectedPlacement == zone,
                  onSelected: (_) => onPlacementChanged(zone),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  String _placementLabel(LocalAdZone zone) => zone.displayName;
}
