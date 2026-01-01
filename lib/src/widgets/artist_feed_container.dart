import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_community/artbeat_community.dart' as community;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Container widget that loads the current user's artist profile
/// and displays their community feed with create post functionality
class ArtistFeedContainer extends StatefulWidget {
  const ArtistFeedContainer({super.key});

  @override
  State<ArtistFeedContainer> createState() => _ArtistFeedContainerState();
}

class _ArtistFeedContainerState extends State<ArtistFeedContainer> {
  core.ArtistProfileModel? _artistProfile;
  bool _isLoading = true;
  String? _errorMessage;
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();

  @override
  void initState() {
    super.initState();
    _loadArtistProfile();
  }

  Future<void> _loadArtistProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _errorMessage = 'You must be logged in to view your artist feed';
          _isLoading = false;
        });
        return;
      }

      final profile = await _subscriptionService.getArtistProfileByUserId(
        user.uid,
      );

      if (profile == null) {
        setState(() {
          _errorMessage =
              'You must have an artist profile to view your artist feed. Please create one first.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _artistProfile = profile as core.ArtistProfileModel?;
        _isLoading = false;
      });
    } on Exception catch (error) {
      setState(() {
        _errorMessage = 'Error loading artist profile: $error';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading your artist feed...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/artist/profile-edit');
              },
              child: const Text('Create Artist Profile'),
            ),
          ],
        ),
      );
    }

    if (_artistProfile == null) {
      return const Center(child: Text('Artist profile not found'));
    }

    // Show the artist community feed with the loaded profile
    return community.ArtistCommunityFeedScreen(artist: _artistProfile!);
  }
}
