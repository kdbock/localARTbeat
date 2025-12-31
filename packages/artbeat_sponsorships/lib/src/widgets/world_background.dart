import 'package:flutter/material.dart';

class WorldBackground extends StatelessWidget {
  const WorldBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF07060F),
                Color(0xFF0A1330),
                Color(0xFF071C18),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  Color.fromRGBO(0, 0, 0, 0.7),
                ],
              ),
            ),
          ),
        ),
        child,
      ],
    );
}
