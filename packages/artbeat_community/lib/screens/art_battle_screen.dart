import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/art_battle_match.dart';
import '../services/art_battle_service.dart';

class ArtBattleScreen extends StatefulWidget {
  const ArtBattleScreen({super.key});

  @override
  State<ArtBattleScreen> createState() => _ArtBattleScreenState();
}

class _ArtBattleScreenState extends State<ArtBattleScreen> {
  final ArtBattleService _battleService = ArtBattleService();
  ArtBattleMatch? _currentMatch;
  ArtBattleMatch? _nextMatch; // Pre-fetched next match
  bool _isLoading = true;
  ArtworkModel? _artworkA;
  ArtworkModel? _artworkB;
  ArtworkModel? _nextArtworkA;
  ArtworkModel? _nextArtworkB;

  @override
  void initState() {
    super.initState();
    _loadNextMatch();
  }

  Future<void> _loadNextMatch() async {
    debugPrint(
      '[ArtBattle] Loading next match (current: ${_currentMatch?.id ?? 'none'})',
    );
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint(
        '[ArtBattle] No authenticated user; prompting sign-in for Art Battle.',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view Art Battles.')),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use pre-fetched match if available
      if (_nextMatch != null) {
        debugPrint('[ArtBattle] Using prefetched match ${_nextMatch?.id}');
        setState(() {
          _currentMatch = _nextMatch;
          _artworkA = _nextArtworkA;
          _artworkB = _nextArtworkB;
          _nextMatch = null;
          _nextArtworkA = null;
          _nextArtworkB = null;
          _isLoading = false;
        });
        // Start pre-fetching the next match
        _preFetchNextMatch();
        return;
      }

      final match = await _battleService.generateMatchup();
      if (match != null) {
        debugPrint(
          '[ArtBattle] Generated match ${match.id} between ${match.artworkAId} and ${match.artworkBId}',
        );
        // Load artwork details
        final artworkA = await _loadArtwork(match.artworkAId);
        final artworkB = await _loadArtwork(match.artworkBId);
        debugPrint(
          '[ArtBattle] Loaded artwork docs A:${artworkA?.id ?? 'null'} B:${artworkB?.id ?? 'null'}',
        );

        setState(() {
          _currentMatch = match;
          _artworkA = artworkA;
          _artworkB = artworkB;
          _isLoading = false;
        });

        // Start pre-fetching the next match
        _preFetchNextMatch();
      } else {
        setState(() => _isLoading = false);
        // Show no matches available
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No battles available right now')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('permission-denied')
                  ? 'Access denied. Please sign in or check your permissions.'
                  : 'Error loading battle: $e',
            ),
          ),
        );
      }
      debugPrint('[ArtBattle] Error loading match: $e');
    }
  }

  Future<ArtworkModel?> _loadArtwork(String id) async {
    try {
      // Try primary 'artwork' collection first
      final doc = await FirebaseFirestore.instance
          .collection('artwork')
          .doc(id)
          .get();
      if (doc.exists) {
        return ArtworkModel.fromFirestore(doc);
      }

      // Fallback to 'artworks' collection (legacy/analytics)
      final docPlural = await FirebaseFirestore.instance
          .collection('artworks')
          .doc(id)
          .get();
      if (docPlural.exists) {
        return ArtworkModel.fromFirestore(docPlural);
      }
    } catch (e) {
      debugPrint('[ArtBattle] Error loading artwork $id: $e');
    }
    return null;
  }

  // Pre-fetch the next match in the background
  Future<void> _preFetchNextMatch() async {
    try {
      final match = await _battleService.generateMatchup();
      if (match != null) {
        debugPrint('[ArtBattle] Prefetching next match ${match.id}');
        final artworkA = await _loadArtwork(match.artworkAId);
        final artworkB = await _loadArtwork(match.artworkBId);

        if (mounted) {
          setState(() {
            _nextMatch = match;
            _nextArtworkA = artworkA;
            _nextArtworkB = artworkB;
          });
        }
      }
    } catch (e) {
      // Silently fail pre-fetching
      debugPrint('[ArtBattle] Error pre-fetching next match: $e');
    }
  }

  Future<void> _submitVote(String chosenArtworkId) async {
    if (_currentMatch == null) {
      debugPrint('[ArtBattle] Attempted vote with no active match');
      return;
    }

    try {
      debugPrint(
        '[ArtBattle] Submitting vote match=${_currentMatch!.id} choice=$chosenArtworkId user=${FirebaseAuth.instance.currentUser?.uid ?? 'anon'}',
      );
      await _battleService.submitVote(
        matchId: _currentMatch!.id,
        chosenArtworkId: chosenArtworkId,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      // Show winner briefly
      final winner = chosenArtworkId == _artworkA?.id ? _artworkA : _artworkB;
      if (mounted) {
        debugPrint('[ArtBattle] Vote submitted successfully for ${winner?.id}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('You chose: ${winner?.artistName ?? 'Unknown'}'),
          ),
        );
      }

      // Load next match
      await Future<void>.delayed(const Duration(seconds: 2));
      if (mounted) {
        _loadNextMatch();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error submitting vote: $e')));
      }
      debugPrint('[ArtBattle] Error submitting vote: $e');
    }
  }

  void _openLocalBusiness() {
    Navigator.of(context).pushNamed(AppRoutes.localBusiness);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_currentMatch == null || _artworkA == null || _artworkB == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Art Battle')),
        body: const Center(child: Text('No battles available')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const _WorldBackground(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      _GlassIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Art Battle',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withValues(alpha: 0.92),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      if (_currentMatch?.isSponsored == true) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: _SponsorPill(
                                sponsorId: _currentMatch?.sponsorId,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        Expanded(
                          flex: 7,
                          child: Row(
                            children: [
                              Expanded(
                                child: _ArtworkCard(
                                  artwork: _artworkA!,
                                  onTap: () => _submitVote(_artworkA!.id),
                                  label: 'Left',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _ArtworkCard(
                                  artwork: _artworkB!,
                                  onTap: () => _submitVote(_artworkB!.id),
                                  label: 'Right',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SponsorCTA(
                          sponsorId: _currentMatch?.sponsorId,
                          isSponsored: _currentMatch?.isSponsored ?? false,
                          onTap: _openLocalBusiness,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkCard extends StatelessWidget {
  final ArtworkModel artwork;
  final VoidCallback onTap;
  final String label;

  const _ArtworkCard({
    required this.artwork,
    required this.onTap,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: const Color(0xFF07060F)),
            SecureNetworkImage(
              imageUrl: artwork.imageUrl,
              fit: BoxFit.cover,
              enableThumbnailFallback: true,
              placeholder: const Center(child: CircularProgressIndicator()),
              errorWidget: const Center(
                child: Icon(Icons.error, color: Colors.white),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
            Positioned(top: 12, left: 12, child: _LabelChip(text: label)),
            Positioned(
              left: 16,
              bottom: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to choose',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artwork.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 28,
                      offset: const Offset(0, 16),
                    ),
                    BoxShadow(
                      color: const Color(0xFF22D3EE).withValues(alpha: 0.08),
                      blurRadius: 34,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SponsorCTA extends StatelessWidget {
  const _SponsorCTA({
    required this.sponsorId,
    required this.isSponsored,
    required this.onTap,
  });

  final String? sponsorId;
  final bool isSponsored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = isSponsored
        ? 'Sponsored by ${sponsorId ?? 'Partner'}'
        : 'Want to sponsor this battle?';

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.business_center,
                    color: Color(0xFF22D3EE),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      text,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    isSponsored ? 'Learn more' : 'Become a sponsor',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WorldBackground extends StatelessWidget {
  const _WorldBackground();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF07060F), Color(0xFF0A1330), Color(0xFF071C18)],
        ),
      ),
      child: Stack(
        children: [
          _blob(const Offset(-60, -40), const Color(0xFF7C4DFF), 220),
          _blob(const Offset(40, 180), const Color(0xFF22D3EE), 200),
          _blob(const Offset(260, 120), const Color(0xFFFF3D8D), 200),
          _blob(const Offset(120, 420), const Color(0xFF34D399), 240),
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.1),
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
                stops: const [0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(Offset offset, Color color, double size) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 80,
              spreadRadius: 30,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.icon, required this.onPressed});
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Material(
          color: Colors.white.withValues(alpha: 0.08),
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _LabelChip extends StatelessWidget {
  const _LabelChip({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SponsorPill extends StatelessWidget {
  const _SponsorPill({this.sponsorId});
  final String? sponsorId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, color: Color(0xFF22D3EE), size: 18),
          const SizedBox(width: 6),
          Text(
            'Sponsored by ${sponsorId ?? 'Partner'}',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
