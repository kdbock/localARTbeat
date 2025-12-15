import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;

  const FollowersListScreen({super.key, required this.userId});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  bool _isLoading = true;
  bool _isUpdating = false;
  List<UserModel> _followers = [];
  bool _isCurrentUser = false;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _isCurrentUser = widget.userId == FirebaseAuth.instance.currentUser?.uid;
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    if (!mounted) return;

    try {
      setState(() {
        _isLoading = true;
      });

      final followers = await _userService.getFollowers(widget.userId);

      if (mounted) {
        setState(() {
          _followers = followers;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_error_followers'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFollow(UserModel follower) async {
    if (_isUpdating) return; // Prevent multiple simultaneous updates

    try {
      setState(() {
        _isUpdating = true;
      });

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('Must be logged in to follow/unfollow users');
      }

      final isFollowing = await _userService.isFollowing(follower.id);

      if (isFollowing) {
        await _userService.unfollowUser(follower.id);
      } else {
        await _userService.followUser(follower.id);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFollowing
                  ? 'profile_unfollowed'.tr(
                      namedArgs: {'fullName': follower.fullName},
                    )
                  : 'profile_now_following'.tr(
                      namedArgs: {'fullName': follower.fullName},
                    ),
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
              'profile_error_unfollow'.tr(namedArgs: {'error': e.toString()}),
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return MainLayout(
      currentIndex: -1,
      child: Scaffold(
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _followers.isEmpty
            ? Center(
                child: Text(
                  'profile_no_followers'.tr(),
                  style: const TextStyle(fontSize: 16),
                ),
              )
            : ListView.builder(
                itemCount: _followers.length,
                itemBuilder: (context, index) {
                  final follower = _followers[index];
                  final isCurrentUser = follower.id == currentUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: ImageUrlValidator.safeNetworkImage(
                        follower.profileImageUrl,
                      ),
                      child:
                          !ImageUrlValidator.isValidImageUrl(
                            follower.profileImageUrl,
                          )
                          ? Text(
                              follower.fullName[0].toUpperCase(),
                              style: const TextStyle(color: Colors.grey),
                            )
                          : null,
                    ),
                    title: Text(
                      follower.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(follower.username),
                    trailing: !_isCurrentUser || isCurrentUser
                        ? null
                        : FutureBuilder<bool>(
                            future: _userService.isFollowing(follower.id),
                            builder: (context, snapshot) {
                              final isFollowing = snapshot.data ?? false;

                              return TextButton(
                                onPressed: () => _toggleFollow(follower),
                                style: TextButton.styleFrom(
                                  backgroundColor: isFollowing
                                      ? Colors.grey.shade200
                                      : theme.primaryColor.withAlpha(25),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                    side: isFollowing
                                        ? BorderSide.none
                                        : BorderSide(color: theme.primaryColor),
                                  ),
                                  minimumSize: const Size(80, 30),
                                ),
                                child: Text(
                                  isFollowing ? 'Following' : 'Follow',
                                  style: TextStyle(
                                    color: isFollowing
                                        ? Colors.black
                                        : theme.primaryColor,
                                  ),
                                ),
                              );
                            },
                          ),
                    onTap: () {
                      // Navigate to the follower's profile
                      Navigator.pushNamed(
                        context,
                        '/profile/view',
                        arguments: {
                          'userId': follower.id,
                          'isCurrentUser': isCurrentUser,
                        },
                      );
                    },
                  );
                },
              ),
      ),
    );
  }
}
