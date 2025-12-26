// import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';

class HudButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final AnimationController? loop;
  final double radius;

  const HudButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.loop,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation:
          loop ??
          AnimationController.unbounded(vsync: const _FakeTickerProvider()),
      builder: (_, __) {
        final t = loop?.value ?? 0.0;
        final sweep = (t * 1.15) % 1.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(52, 211, 153, 0.22),
                          blurRadius: 18,
                          offset: Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: const Color.fromRGBO(255, 255, 255, 0.16),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.22),
                            ),
                          ),
                          child: Icon(icon, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          fit: FlexFit.loose,
                          child: Text(
                            label.toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.55,
                    child: Transform.translate(
                      offset: Offset((sweep * 2 - 1) * 240, 0),
                      child: Transform.rotate(
                        angle: -0.55,
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                Color.fromRGBO(255, 255, 255, 0.22),
                                Colors.transparent,
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A fake ticker provider to make AnimatedBuilder work without crashing when `loop` is null
class _FakeTickerProvider extends TickerProvider {
  const _FakeTickerProvider();
  @override
  Ticker createTicker(TickerCallback onTick) => Ticker(onTick);
}
