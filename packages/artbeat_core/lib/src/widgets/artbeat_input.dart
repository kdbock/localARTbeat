import 'package:flutter/material.dart';
import '../theme/artbeat_components.dart';

class ArtbeatInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final bool autocorrect;
  final bool enableSuggestions;
  final Widget? suffixIcon;
  final Widget? prefixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;

  const ArtbeatInput({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.autocorrect = true,
    this.enableSuggestions = true,
    this.suffixIcon,
    this.prefixIcon,
    this.validator,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      autofillHints: autofillHints,
      onFieldSubmitted: onFieldSubmitted,
      autocorrect: autocorrect,
      enableSuggestions: enableSuggestions,
      validator: validator,
      maxLines: obscureText ? 1 : (maxLines ?? 1),
      decoration: ArtbeatComponents.inputDecoration(
        labelText: label,
        hintText: hint,
        suffixIcon: suffixIcon,
        prefixIcon: prefixIcon,
      ),
    );
  }
}
