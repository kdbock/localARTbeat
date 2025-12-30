import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:artbeat_core/artbeat_core.dart';
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
    setState(() => _isLoading = true);

    try {
      // Use pre-fetched match if available
      if (_nextMatch != null) {
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
        // Load artwork details
        final artworkA = await _loadArtwork(match.artworkAId);
        final artworkB = await _loadArtwork(match.artworkBId);

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No battles available right now')),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading battle: $e')));
    }
  }

  Future<ArtworkModel?> _loadArtwork(String id) async {
    final doc = await FirebaseFirestore.instance
        .collection('artwork')
        .doc(id)
        .get();
    if (doc.exists) {
      return ArtworkModel.fromFirestore(doc);
    }
    return null;
  }

  // Pre-fetch the next match in the background
  Future<void> _preFetchNextMatch() async {
    try {
      final match = await _battleService.generateMatchup();
      if (match != null) {
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
      print('Error pre-fetching next match: $e');
    }
  }

  Future<void> _submitVote(String chosenArtworkId) async {
    if (_currentMatch == null) return;

    try {
      await _battleService.submitVote(
        matchId: _currentMatch!.id,
        chosenArtworkId: chosenArtworkId,
        userId: FirebaseAuth.instance.currentUser?.uid ?? '',
      );

      // Show winner briefly
      final winner = chosenArtworkId == _artworkA?.id ? _artworkA : _artworkB;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You chose: ${winner?.artistName ?? 'Unknown'}'),
        ),
      );

      // Load next match
      await Future.delayed(const Duration(seconds: 2));
      _loadNextMatch();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error submitting vote: $e')));
    }
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
      appBar: AppBar(
        title: const Text('Which one catches your eye?'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Sponsor banner
          if (_currentMatch?.isSponsored == true)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.blue.shade100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'Art Battle sponsored by ${_currentMatch?.sponsorId ?? 'Unknown'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: _ArtworkCard(
                    artwork: _artworkA!,
                    onTap: () => _submitVote(_artworkA!.id),
                  ),
                ),
                Container(width: 2, color: Colors.grey),
                Expanded(
                  child: _ArtworkCard(
                    artwork: _artworkB!,
                    onTap: () => _submitVote(_artworkB!.id),
                  ),
                ),
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

  const _ArtworkCard({required this.artwork, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black,
        child: CachedNetworkImage(
          imageUrl: artwork.imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              const Center(child: Icon(Icons.error)),
        ),
      ),
    );
  }
}
