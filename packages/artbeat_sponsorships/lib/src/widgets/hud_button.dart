import 'package:flutter/material.dart';

class HudButton extends StatelessWidget {
  const HudButton({super.key, required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      IconButton(onPressed: onPressed, icon: Icon(icon));
}
