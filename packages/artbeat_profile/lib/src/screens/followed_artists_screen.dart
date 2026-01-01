import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart' hide HudTopBar;
import 'package:artbeat_profile/widgets/widgets.dart';

class FollowedArtistsScreen extends StatefulWidget {
  final String userId;
  final bool embedInMainLayout;

  const FollowedArtistsScreen({
    super.key,
    required this.userId,
    this.embedInMainLayout = true,
  });

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
          'profile_followed_artists_screen_text_unfollow_artist'.tr(
            namedArgs: {'artistDisplayName': artist.displayName},
          ),
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
    final content = WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                HudTopBar(
                  title: 'profile_followed_artists_title'.tr(),
                  onBackPressed: () => Navigator.of(context).maybePop(),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: Colors.white),
                      onPressed: _loadFollowedArtists,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHeadline(),
                const SizedBox(height: 12),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF22D3EE),
                            ),
                          )
                        : _artists.isEmpty
                            ? _buildEmptyState()
                            : _buildArtistList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.embedInMainLayout) {
      return MainLayout(
        currentIndex: -1,
        child: content,
      );
    }

    return content;
  }

  Widget _buildHeadline() {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF22D3EE).withValues(alpha: 0.16),
            ),
            child: const Icon(Icons.palette, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'profile_followed_artists_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${_artists.length} following',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.refresh,
                      size: 14,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pull to refresh',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistList() {
    return RefreshIndicator(
      color: const Color(0xFF22D3EE),
      backgroundColor: Colors.black,
      onRefresh: _loadFollowedArtists,
      child: ListView.separated(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 12, top: 4),
        itemCount: _artists.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final artist = _artists[index];
          final isCurrentUser = artist.userId == _authUser?.uid;

          return GlassCard(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: UserListTile(
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
                            ArtbeatColors.primaryPurple.withAlpha(28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: ArtbeatColors.primaryPurple.withAlpha(90),
                          ),
                        ),
                        minimumSize: const Size(96, 36),
                      ),
                      child: Text(
                        'Following',
                        style: GoogleFonts.spaceGrotesk(
                          color: ArtbeatColors.primaryPurple,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      color: const Color(0xFF22D3EE),
      backgroundColor: Colors.black,
      onRefresh: _loadFollowedArtists,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 40, bottom: 32),
        children: [
          GlassCard(
            padding:
                const EdgeInsets.symmetric(horizontal: 18.0, vertical: 26.0),
            margin: EdgeInsets.zero,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(
                    Icons.palette_outlined,
                    size: 30,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'profile_followed_artists_screen_empty_message'.tr(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 10),
                HudButton(
                  text: 'discover_creators'.tr(),
                  onPressed: () =>
                      Navigator.of(context).pushNamed('/artist/discover'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
