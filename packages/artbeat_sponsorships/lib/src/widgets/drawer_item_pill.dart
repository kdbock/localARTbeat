import 'package:flutter/material.dart';

class DrawerItemPill extends StatelessWidget {
  const DrawerItemPill({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected
              ? const Color(0xFF22D3EE).withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.06),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Text(label),
          ],
        ),
      ),
    );
}
