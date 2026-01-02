import 'dart:math';
import 'package:flutter/material.dart';

class WorldBackground extends StatefulWidget {
  const WorldBackground({super.key, required this.child});

  final Widget child;

  @override
  State<WorldBackground> createState() => _WorldBackgroundState();
}

class _WorldBackgroundState extends State<WorldBackground>
    with TickerProviderStateMixin {
  late AnimationController _blobController;
  late Animation<double> _blobAnimation1;
  late Animation<double> _blobAnimation2;
  late Animation<double> _blobAnimation3;

  @override
  void initState() {
    super.initState();
    _blobController = AnimationController(
      duration: const Duration(seconds: 12),
      vsync: this,
    )..repeat(reverse: true);

    _blobAnimation1 = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _blobController, curve: Curves.easeInOut),
    );
    _blobAnimation2 = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _blobController,
        curve: const Interval(0.2, 1, curve: Curves.easeInOut),
      ),
    );
    _blobAnimation3 = Tween<double>(begin: 0, end: 2 * 3.14159).animate(
      CurvedAnimation(
        parent: _blobController,
        curve: const Interval(0.4, 1, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _blobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      // Animated blobs
      AnimatedBuilder(
        animation: _blobController,
        builder: (context, child) => Stack(
          children: [
            Positioned(
              top: 100 + 50 * sin(_blobAnimation1.value),
              left: 50 + 30 * cos(_blobAnimation1.value * 0.5),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF22D3EE).withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 300 + 40 * sin(_blobAnimation2.value),
              right: 80 + 25 * cos(_blobAnimation2.value * 0.7),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF7C4DFF).withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 200 + 35 * sin(_blobAnimation3.value),
              left: 100 + 20 * cos(_blobAnimation3.value * 0.6),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF3D8D).withValues(alpha: 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Colors.transparent, Color.fromRGBO(0, 0, 0, 0.7)],
            ),
          ),
        ),
      ),
      widget.child,
    ],
  );
}
