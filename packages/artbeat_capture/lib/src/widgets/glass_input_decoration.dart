import 'package:flutter/material.dart';

InputDecoration glassInputDecoration({
  required String labelText,
  IconData? prefixIcon,
}) {
  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(
      color: Colors.white.withValues(alpha: 0.7),
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: prefixIcon != null
        ? Icon(prefixIcon, color: const Color(0xFF22D3EE))
        : null,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.14),
        width: 1.2,
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(
        color: Colors.white.withValues(alpha: 0.12),
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
    ),
  );
}
