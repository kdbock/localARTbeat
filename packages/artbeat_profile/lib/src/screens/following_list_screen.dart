import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;

  const FollowingListScreen({super.key, required this.userId});

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  bool _isLoading = true;
  List<UserModel> _following = [];
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final following = await _userService.getFollowing(widget.userId);

      if (mounted) {
        setState(() {
          _following = following;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('profile_following_list_screen_error_error_loading_following'.tr().replaceAll('{error}', e.toString()))),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unfollow(int index) async {
    final followedUser = _following[index];

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('profile_following_list_screen_text_unfollow_user'.tr().replaceAll('{followedUserUsername}', followedUser.username)),
          content: Text('profile_following_confirm_unfollow'.tr()),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('profile_following_list_screen_text_cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('profile_following_unfollow_button'.tr()),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await _userService.unfollowUser(followedUser.id);

        setState(() {
          _following.removeAt(index);
        });

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile_following_list_screen_success_you_unfollowed_user'.tr().replaceAll('{followedUserFullName}', followedUser.fullName)),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('profile_following_list_screen_error_error_unfollowing_user'.tr().replaceAll('{error}', e.toString())),
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
                : _following.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 80,
                          color: ArtbeatColors.textSecondary,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Not following anyone yet',
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
                    itemCount: _following.length,
                    itemBuilder: (context, index) {
                      final followedUser = _following[index];
                      final isCurrentUser =
                          followedUser.id == _currentUser?.uid;

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
                            backgroundImage:
                                followedUser.profileImageUrl.isNotEmpty
                                ? NetworkImage(followedUser.profileImageUrl)
                                : null,
                            child: followedUser.profileImageUrl.isEmpty
                                ? Text(
                                    followedUser.fullName.isNotEmpty
                                        ? followedUser.fullName[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            followedUser.username,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: ArtbeatColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            followedUser.fullName,
                            style: const TextStyle(
                              color: ArtbeatColors.textSecondary,
                            ),
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
                            // Navigate to the followed user's profile
                            Navigator.pushNamed(
                              context,
                              '/profile/view',
                              arguments: {
                                'userId': followedUser.id,
                                'isCurrentUser': isCurrentUser,
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
