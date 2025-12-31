import 'package:flutter/material.dart';

class GlassInputField extends StatelessWidget {
  const GlassInputField({
    super.key,
    required this.label,
    this.controller,
  });

  final String label;
  final TextEditingController? controller;

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: TextField(
        controller: controller,
        cursorColor: const Color(0xFF22D3EE),
        decoration: InputDecoration(
          border: InputBorder.none,
          labelText: label,
        ),
      ),
    );
}
