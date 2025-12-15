import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

class FollowedArtistsScreen extends StatefulWidget {
  final String userId;

  const FollowedArtistsScreen({super.key, required this.userId});

  @override
  State<FollowedArtistsScreen> createState() => _FollowedArtistsScreenState();
}

class _FollowedArtistsScreenState extends State<FollowedArtistsScreen> {
  bool _isLoading = true;
  List<ArtistProfileModel> _followedArtists = [];
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadFollowedArtists();
  }

  Future<void> _loadFollowedArtists() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final followedArtists = await _userService.getFollowedArtists();

      if (mounted) {
        setState(() {
          _followedArtists = followedArtists;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_followed_artists_screen_error_error_loading_followed_artists'
                  .tr()
                  .replaceAll('{error}', e.toString()),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unfollow(int index) async {
    final artist = _followedArtists[index];

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'profile_followed_artists_screen_text_unfollow_artist'
                .tr()
                .replaceAll('{artistDisplayName}', artist.displayName),
          ),
          content: Text('profile_followers_confirm_unfollow'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('profile_followed_artists_screen_text_cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('profile_followers_unfollow_button'.tr()),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        // We need to remove from artistFollows collection
        final userId = _currentUser?.uid;
        if (userId != null) {
          await FirebaseFirestore.instance
              .collection('artistFollows')
              .doc('${userId}_${artist.id}')
              .delete();

          // Also decrement the artist's follower count
          await FirebaseFirestore.instance
              .collection('artistProfiles')
              .doc(artist.id)
              .update({'followersCount': FieldValue.increment(-1)});
        }

        setState(() {
          _followedArtists.removeAt(index);
        });

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_followed_artists_screen_success_you_unfollowed_artist'
                    .tr()
                    .replaceAll('{artistDisplayName}', artist.displayName),
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_followed_artists_screen_error_error_unfollowing_artist'
                    .tr()
                    .replaceAll('{error}', e.toString()),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ArtbeatColors.primaryPurple.withAlpha(13), // 0.05 opacity
                Colors.white,
                ArtbeatColors.primaryGreen.withAlpha(13), // 0.05 opacity
              ],
            ),
          ),
          child: SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ArtbeatColors.primaryPurple,
                    ),
                  )
                : _followedArtists.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 80,
                          color: ArtbeatColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Not following any artists yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _followedArtists.length,
                    itemBuilder: (context, index) {
                      final artist = _followedArtists[index];
                      final isCurrentUser = artist.userId == _currentUser?.uid;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: Colors.white.withAlpha(230),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: ArtbeatColors.border.withAlpha(128),
                          ),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: ArtbeatColors.primaryPurple,
                            backgroundImage: ImageUrlValidator.safeNetworkImage(
                              artist.profileImageUrl,
                            ),
                            child:
                                !ImageUrlValidator.isValidImageUrl(
                                  artist.profileImageUrl,
                                )
                                ? Text(
                                    artist.displayName.isNotEmpty
                                        ? artist.displayName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            artist.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (artist.bio?.isNotEmpty == true)
                                Text(
                                  artist.bio!,
                                  style: const TextStyle(
                                    color: ArtbeatColors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.people,
                                    size: 14,
                                    color: ArtbeatColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${artist.followersCount} followers',
                                    style: const TextStyle(
                                      color: ArtbeatColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: isCurrentUser
                              ? null
                              : TextButton(
                                  onPressed: () => _unfollow(index),
                                  style: TextButton.styleFrom(
                                    backgroundColor: ArtbeatColors.primaryPurple
                                        .withAlpha(25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: ArtbeatColors.primaryPurple
                                            .withAlpha(77),
                                      ),
                                    ),
                                    minimumSize: const Size(80, 32),
                                  ),
                                  child: const Text(
                                    'Following',
                                    style: TextStyle(
                                      color: ArtbeatColors.primaryPurple,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                          onTap: () {
                            // Navigate to the artist's profile
                            Navigator.pushNamed(
                              context,
                              '/artist/profile',
                              arguments: {
                                'artistId': artist.id,
                                'userId': artist.userId,
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
