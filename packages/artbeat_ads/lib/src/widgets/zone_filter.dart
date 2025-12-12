import 'package:flutter/material.dart';
import '../models/index.dart';

class ZoneFilter extends StatelessWidget {
  final LocalAdZone selectedZone;
  final void Function(LocalAdZone) onZoneChanged;

  const ZoneFilter({
    Key? key,
    required this.selectedZone,
    required this.onZoneChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: LocalAdZone.values
            .map(
              (zone) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  label: Text(zone.displayName),
                  selected: selectedZone == zone,
                  onSelected: (_) => onZoneChanged(zone),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
