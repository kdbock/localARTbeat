import 'package:flutter/material.dart';

InputDecoration glassInputDecoration({
  String? labelText,
  String? hintText,
  bool isDense = false,
}) {
  return InputDecoration(
    labelText: labelText,
    hintText: hintText,
    isDense: isDense,
    filled: true,
    fillColor: Colors.white.withOpacity(0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.14)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: const BorderSide(color: Colors.tealAccent),
    ),
  );
}
