import 'package:flutter/material.dart';
import 'package:artbeat_core/shared_widgets.dart';

class GlassTextField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;

  const GlassTextField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      cursorColor: const Color(0xFF22D3EE),
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 14,
      ),
      decoration: GlassInputDecoration(
        labelText: label,
        prefixIcon:
            icon != null ? Icon(icon, color: Colors.white70, size: 18) : null,
      ),
    );
  }
}
