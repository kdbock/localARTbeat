// 📁 lib/artbeat_profile/widgets/custom_multiline_text_field.dart
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class CustomMultilineTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? initialValue;
  final String? hintText;
  final int maxLines;
  final String? Function(String?)? validator;
  final void Function(String?)? onSaved;
  final void Function(String)? onChanged;

  const CustomMultilineTextField({
    super.key,
    this.controller,
    required this.label,
    this.initialValue,
    this.hintText,
    this.maxLines = 4,
    this.validator,
    this.onSaved,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      maxLines: maxLines,
      validator: validator,
      onSaved: onSaved,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: ArtbeatColors.primaryPurple,
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
