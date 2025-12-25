import 'package:flutter/material.dart';

/// Dummy class for BadgeTier
class BadgeTier {
  final String name;
  final String label;
  final String description;
  final Color color;

  BadgeTier(this.name, {Color? color})
    : label = name,
      description = 'Description for $name',
      color = color ?? Colors.grey;
}
