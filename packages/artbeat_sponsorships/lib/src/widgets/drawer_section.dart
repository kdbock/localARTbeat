import 'package:flutter/material.dart';

class DrawerSection extends StatelessWidget {
  const DrawerSection({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
    child: Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Colors.white70,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
