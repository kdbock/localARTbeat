import 'dart:math' as math;

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:artbeat_core/artbeat_core.dart' show SecureNetworkImage;
import 'package:artbeat_art_walk/src/models/public_art_model.dart';

/// Full-screen overlay that celebrates the moment a user reaches an art stop.
///
/// Shows:
///  • The art image filling the screen with a parallax reveal
///  • Confetti from the top
///  • Animated "You found it!" banner with stop number
///  • Points earned count-up
///  • Auto-dismisses after [autoDismissAfter] or immediately on tap
///
/// Usage:
/// ```dart
/// await ArtDiscoveryCelebration.show(
///   context,
///   art: artPiece,
///   stopNumber: visitedCount,
///   totalStops: totalArtCount,
///   pointsEarned: 50,
/// );
/// ```
class ArtDiscoveryCelebration extends StatefulWidget {
  final PublicArtModel art;
  final int stopNumber;
  final int totalStops;
  final int pointsEarned;
  final Duration autoDismissAfter;

  const ArtDiscoveryCelebration({
    super.key,
    required this.art,
    required this.stopNumber,
    required this.totalStops,
    required this.pointsEarned,
    this.autoDismissAfter = const Duration(milliseconds: 2800),
  });

  /// Convenience helper — shows the overlay as a full-screen dialog and waits
  /// until it is dismissed before returning.
  static Future<void> show(
    BuildContext context, {
    required PublicArtModel art,
    required int stopNumber,
    required int totalStops,
    int pointsEarned = 50,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 380),
      pageBuilder: (_, __, ___) => ArtDiscoveryCelebration(
        art: art,
        stopNumber: stopNumber,
        totalStops: totalStops,
        pointsEarned: pointsEarned,
      ),
      transitionBuilder: (_, anim, __, child) => FadeTransition(
        opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
        child: child,
      ),
    );
  }

  @override
  State<ArtDiscoveryCelebration> createState() =>
      _ArtDiscoveryCelebrationState();
}

class _ArtDiscoveryCelebrationState extends State<ArtDiscoveryCelebration>
    with TickerProviderStateMixin {
  late final ConfettiController _confetti;
  late final AnimationController _imageReveal;
  late final AnimationController _bannerSlide;
  late final AnimationController _pointsCount;
  late final AnimationController _pulseRing;

  late final Animation<double> _imageScale;
  late final Animation<Offset> _bannerOffset;
  late final Animation<int> _pointsAnim;
  late final Animation<double> _ringScale;
  late final Animation<double> _ringOpacity;

  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // Confetti
    _confetti = ConfettiController(duration: const Duration(seconds: 3));

    // Art image — zooms gently in from slightly below
    _imageReveal = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _imageScale = Tween<double>(begin: 1.08, end: 1.0).animate(
      CurvedAnimation(parent: _imageReveal, curve: Curves.easeOutCubic),
    );

    // "You found it!" banner slides up from the bottom
    _bannerSlide = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bannerOffset = Tween<Offset>(
      begin: const Offset(0, 1.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _bannerSlide, curve: Curves.easeOutBack));

    // Points count-up
    _pointsCount = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pointsAnim = IntTween(
      begin: 0,
      end: widget.pointsEarned,
    ).animate(CurvedAnimation(parent: _pointsCount, curve: Curves.easeOut));

    // Expanding ring pulse around the stop badge
    _pulseRing = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _ringScale = Tween<double>(
      begin: 0.6,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _pulseRing, curve: Curves.easeOut));
    _ringOpacity = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _pulseRing, curve: Curves.easeOut));

    _runSequence();
  }

  Future<void> _runSequence() async {
    // Haptic pop the moment art is "found"
    await HapticFeedback.heavyImpact();

    _imageReveal.forward();
    _confetti.play();
    _pulseRing.forward();

    await Future<void>.delayed(const Duration(milliseconds: 280));
    if (!mounted) return;
    _bannerSlide.forward();

    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;
    _pointsCount.forward();

    // Auto-dismiss
    await Future<void>.delayed(widget.autoDismissAfter);
    if (!mounted || _dismissed) return;
    _dismiss();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _confetti.dispose();
    _imageReveal.dispose();
    _bannerSlide.dispose();
    _pointsCount.dispose();
    _pulseRing.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLastStop = widget.stopNumber == widget.totalStops;

    return GestureDetector(
      onTap: _dismiss,
      child: Material(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Art image (full-screen, gentle zoom reveal) ──────────────
            AnimatedBuilder(
              animation: _imageReveal,
              builder: (_, __) => Transform.scale(
                scale: _imageScale.value,
                child: _buildArtImage(size),
              ),
            ),

            // ── Dark gradient so text is always legible ───────────────────
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x55000000),
                    Color(0xCC000000),
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),

            // ── Confetti ─────────────────────────────────────────────────
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                blastDirection: math.pi / 2,
                numberOfParticles: 40,
                gravity: 0.25,
                emissionFrequency: 0.04,
                colors: const [
                  Color(0xFFFFC857),
                  Color(0xFF22D3EE),
                  Color(0xFF7C4DFF),
                  Color(0xFFFF3D8D),
                  Color(0xFF34D399),
                ],
              ),
            ),

            // ── Stop badge + pulse ring (top-centre) ─────────────────────
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Center(child: _buildStopBadge()),
            ),

            // ── Bottom celebration banner ─────────────────────────────────
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SlideTransition(
                position: _bannerOffset,
                child: _buildBanner(isLastStop),
              ),
            ),

            // ── Tap to continue hint ──────────────────────────────────────
            Positioned(
              bottom: 28,
              left: 0,
              right: 0,
              child: SlideTransition(
                position: _bannerOffset,
                child: const Center(
                  child: Text(
                    'Tap anywhere to continue',
                    style: TextStyle(
                      color: Color(0x99FFFFFF),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtImage(Size size) {
    final imageUrl = widget.art.imageUrl;
    if (imageUrl.isEmpty) {
      return Container(
        color: const Color(0xFF0A0E27),
        child: const Center(
          child: Icon(
            Icons.image_not_supported,
            color: Colors.white38,
            size: 64,
          ),
        ),
      );
    }
    return SecureNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: size.width,
      height: size.height,
    );
  }

  Widget _buildStopBadge() {
    return AnimatedBuilder(
      animation: _pulseRing,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Pulse ring
            Opacity(
              opacity: _ringOpacity.value,
              child: Transform.scale(
                scale: _ringScale.value,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFFC857),
                      width: 3,
                    ),
                  ),
                ),
              ),
            ),
            // Badge itself
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFC857), Color(0xFFFF8C42)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFC857).withValues(alpha: 0.55),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${widget.stopNumber}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    Text(
                      'of ${widget.totalStops}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBanner(bool isLastStop) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 52),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.55),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline
          Text(
            isLastStop ? '🎉 You found them all!' : '✨ You found it!',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 4),
          // Art title
          Text(
            widget.art.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.spaceGrotesk(
              color: const Color(0xFFFFC857),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.25,
            ),
          ),
          if (widget.art.artistName != null &&
              widget.art.artistName!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              'by ${widget.art.artistName}',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          // Points row
          Row(
            children: [
              _PointsChip(pointsAnim: _pointsAnim),
              const SizedBox(width: 10),
              if (isLastStop)
                const _Chip(label: 'Walk complete!', color: Color(0xFF34D399))
              else
                _Chip(
                  label:
                      '${widget.totalStops - widget.stopNumber} stop${widget.totalStops - widget.stopNumber == 1 ? '' : 's'} left',
                  color: const Color(0xFF22D3EE),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsChip extends StatelessWidget {
  final Animation<int> pointsAnim;
  const _PointsChip({required this.pointsAnim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: pointsAnim,
      builder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFC857), Color(0xFFFF8C42)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFC857).withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          '+${pointsAnim.value} XP',
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          color: color,
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
