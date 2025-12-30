import 'package:flutter/material.dart';

/// World Background - The signature Local ARTbeat background pattern
/// Features animated blob lights, vignette, and gradient base
class WorldBackground extends StatefulWidget {
  const WorldBackground({
    super.key,
    this.child,
    this.blobColors = const [
      Color(0xFF22D3EE), // Teal
      Color(0xFF7C4DFF), // Purple
      Color(0xFFFF3D8D), // Pink
      Color(0xFFFFC857), // Yellow
      Color(0xFF34D399), // Green
    ],
    this.animate = true,
  });

  final Widget? child;
  final List<Color> blobColors;
  final bool animate;

  @override
  State<WorldBackground> createState() => _WorldBackgroundState();
}

class _WorldBackgroundState extends State<WorldBackground>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.blobColors.length,
      (index) => AnimationController(
        duration: Duration(seconds: 9 + index * 2), // Staggered timing
        vsync: this,
      )..repeat(reverse: true),
    );

    _animations = _controllers
        .map(
          (controller) => Tween<double>(begin: 0.0, end: 1.0).animate(
            CurvedAnimation(parent: controller, curve: Curves.easeInOut),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF07060F), // Nearly-black purple
            Color(0xFF0A1330), // Dark blue-purple
            Color(0xFF071C18), // Dark teal-green
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated blob lights
          if (widget.animate)
            ...List.generate(widget.blobColors.length, (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  final progress = _animations[index].value;
                  final size = 200 + (index * 50) + (progress * 100);
                  final opacity = 0.03 + (progress * 0.05);

                  return Positioned(
                    left:
                        MediaQuery.of(context).size.width *
                        (0.1 + index * 0.15),
                    top:
                        MediaQuery.of(context).size.height *
                        (0.1 + index * 0.12),
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            widget.blobColors[index].withValues(alpha: opacity),
                            widget.blobColors[index].withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

          // Vignette overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.5,
                colors: [
                  Colors.transparent,
                  const Color(0xFF07060F).withValues(alpha: 0.35),
                ],
                stops: const [0.65, 1.0],
              ),
            ),
          ),

          // Child content
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
