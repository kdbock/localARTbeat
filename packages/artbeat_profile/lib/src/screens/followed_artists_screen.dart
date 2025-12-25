import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';

class FollowedArtistsScreen extends StatefulWidget {
  final String userId;

  const FollowedArtistsScreen({super.key, required this.userId});

  @override
  State<FollowedArtistsScreen> createState() => _FollowedArtistsScreenState();
}

class _FollowedArtistsScreenState extends State<FollowedArtistsScreen> {
  final _userService = UserService();
  final _authUser = FirebaseAuth.instance.currentUser;
  List<ArtistProfileModel> _artists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowedArtists();
  }

  Future<void> _loadFollowedArtists() async {
    setState(() => _isLoading = true);
    try {
      final results = await _userService.getFollowedArtists();
      if (mounted) {
        setState(() {
          _artists = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'profile_followed_artists_screen_error_error_loading_followed_artists'
                .tr(namedArgs: {'error': e.toString()}),
          ),
        ),
      );
    }
  }

  Future<void> _unfollow(ArtistProfileModel artist) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'profile_followed_artists_screen_text_unfollow_artist'
              .tr(namedArgs: {'artistDisplayName': artist.displayName}),
        ),
        content: Text('profile_followers_confirm_unfollow'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('profile_followed_artists_screen_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('profile_followers_unfollow_button'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('artistFollows')
            .doc('${_authUser?.uid}_${artist.id}')
            .delete();

        await FirebaseFirestore.instance
            .collection('artistProfiles')
            .doc(artist.id)
            .update({'followersCount': FieldValue.increment(-1)});

        if (mounted) {
          setState(() {
            _artists.removeWhere((a) => a.id == artist.id);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_followed_artists_screen_success_you_unfollowed_artist'
                    .tr(namedArgs: {'artistDisplayName': artist.displayName}),
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'profile_followed_artists_screen_error_error_unfollowing_artist'
                    .tr(namedArgs: {'error': e.toString()}),
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
        appBar: EnhancedUniversalHeader(
          title: 'profile_followed_artists_title'.tr(),
          showBackButton: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _artists.isEmpty
                ? EmptyState(
                    icon: Icons.palette_outlined,
                    message: 'profile_followed_artists_screen_empty_message'.tr(),
                  )
                : RefreshIndicator(
                    onRefresh: _loadFollowedArtists,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _artists.length,
                      itemBuilder: (context, index) {
                        final artist = _artists[index];
                        final isCurrentUser = artist.userId == _authUser?.uid;

                        return UserListTile(
                          id: artist.id,
                          displayName: artist.displayName,
                          handle: artist.username,
                          avatarUrl: artist.profileImageUrl ?? '',
                          isVerified: artist.isVerified,
                          trailing: isCurrentUser
                              ? null
                              : TextButton(
                                  onPressed: () => _unfollow(artist),
                                  style: TextButton.styleFrom(
                                    backgroundColor:
                                        ArtbeatColors.primaryPurple.withAlpha(25),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: ArtbeatColors.primaryPurple.withAlpha(77),
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
                            Navigator.pushNamed(
                              context,
                              '/artist/profile',
                              arguments: {
                                'artistId': artist.id,
                                'userId': artist.userId,
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
