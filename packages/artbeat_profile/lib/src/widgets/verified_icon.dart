// 📁 lib/artbeat_profile/widgets/verified_icon.dart
import 'package:flutter/material.dart';

class VerifiedIcon extends StatelessWidget {
  final double size;

  const VerifiedIcon({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.verified, size: size, color: Colors.blueAccent);
  }
}
