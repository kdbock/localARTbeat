import 'package:flutter/material.dart';

class TourStep {
  final GlobalKey targetKey;
  final String title;
  final String description;
  final List<String> details;
  final Color accentColor;

  TourStep({
    required this.targetKey,
    required this.title,
    required this.description,
    required this.details,
    required this.accentColor,
  });
}
