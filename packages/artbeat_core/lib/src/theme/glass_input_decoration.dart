import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Glass Input Decoration - Themed text inputs for Local ARTbeat
class GlassInputDecoration extends InputDecoration {
  GlassInputDecoration({
    super.hintText,
    super.labelText,
    super.errorText,
    super.prefixIcon,
    super.suffixIcon,
    super.prefix,
    super.prefixText,
    super.prefixStyle,
    super.suffix,
    super.suffixText,
    super.suffixStyle,
    super.contentPadding = const EdgeInsets.all(16),
    super.disabledBorder,
    super.filled = true,
    super.floatingLabelBehavior = FloatingLabelBehavior.never,
    super.isDense,
    InputBorder? border,
    InputBorder? enabledBorder,
    InputBorder? focusedBorder,
    InputBorder? errorBorder,
    InputBorder? focusedErrorBorder,
    Color? fillColor,
    TextStyle? hintStyle,
    TextStyle? labelStyle,
    TextStyle? errorStyle,
  }) : super(
          fillColor: fillColor ?? Colors.white.withAlpha(15),
          hintStyle:
              hintStyle ??
              GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(179),
              ),
          labelStyle:
              labelStyle ??
              GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white.withAlpha(179),
                letterSpacing: 0.5,
              ),
          errorStyle:
              errorStyle ??
              GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF3D8D),
              ),
          border:
              border ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha(31),
                  width: 1,
                ),
              ),
          enabledBorder:
              enabledBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withAlpha(31),
                  width: 1,
                ),
              ),
          focusedBorder:
              focusedBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 2),
              ),
          errorBorder:
              errorBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFFFF3D8D),
                  width: 1.5,
                ),
              ),
          focusedErrorBorder:
              focusedErrorBorder ??
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFFFF3D8D), width: 2),
              ),
        );

  /// Creates a glass input decoration with custom styling
  factory GlassInputDecoration.glass({
    String? hintText,
    String? labelText,
    String? errorText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsets? contentPadding,
    bool isDense = false,
  }) {
    return GlassInputDecoration(
      hintText: hintText,
      labelText: labelText,
      errorText: errorText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      contentPadding: contentPadding ?? const EdgeInsets.all(16),
      isDense: isDense,
    );
  }

  /// Creates a search input decoration
  factory GlassInputDecoration.search({
    String? hintText = 'Search...',
    Widget? prefixIcon,
    Widget? suffixIcon,
    EdgeInsets? contentPadding,
  }) {
    return GlassInputDecoration(
      hintText: hintText,
      prefixIcon:
          prefixIcon ??
          Icon(Icons.search, color: Colors.white.withAlpha(179), size: 20),
      suffixIcon: suffixIcon,
      contentPadding: contentPadding ?? const EdgeInsets.all(14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withAlpha(31), width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide(color: Colors.white.withAlpha(31), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 2),
      ),
    );
  }
}

/// Glass Text Field - Pre-styled TextField with glass decoration
class GlassTextField extends StatelessWidget {
  const GlassTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.obscureText = false,
    this.maxLines = 1,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.autofocus = false,
    this.enabled = true,
    this.focusNode,
    this.decoration,
  });

  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? errorText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final int? maxLines;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FormFieldValidator<String>? validator;
  final bool autofocus;
  final bool enabled;
  final FocusNode? focusNode;
  final InputDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      autofocus: autofocus,
      enabled: enabled,
      focusNode: focusNode,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      cursorColor: const Color(0xFF22D3EE),
      decoration: decoration ??
          GlassInputDecoration(
            hintText: hintText,
            labelText: labelText,
            errorText: errorText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ),
    );
  }
}
