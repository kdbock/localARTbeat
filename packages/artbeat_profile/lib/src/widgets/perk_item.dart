import 'package:flutter/material.dart';

/// Dummy widget for PerkItem
class PerkItem extends StatelessWidget {
  final dynamic perk;

  const PerkItem({super.key, required this.perk});

  @override
  Widget build(BuildContext context) {
    return Text('Perk $perk');
  }
}
