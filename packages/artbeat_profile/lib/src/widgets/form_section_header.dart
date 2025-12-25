// 📁 lib/artbeat_profile/widgets/form_section_header.dart
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class FormSectionHeader extends StatelessWidget {
  final String title;

  const FormSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          color: ArtbeatColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
