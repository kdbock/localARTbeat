// 📁 lib/artbeat_profile/widgets/form_divider.dart
import 'package:flutter/material.dart';

class FormDivider extends StatelessWidget {
  const FormDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 32,
      thickness: 1,
      indent: 0,
      endIndent: 0,
      color: Color(0xFFE0E0E0),
    );
  }
}
