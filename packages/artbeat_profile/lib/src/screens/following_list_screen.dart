import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';

class FollowingListScreen extends StatefulWidget {
  final String userId;

  const FollowingListScreen({super.key, required this.userId});

  @override
  State<FollowingListScreen> createState() => _FollowingListScreenState();
}

class _FollowingListScreenState extends State<FollowingListScreen> {
  final UserService _userService = UserService();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  List<UserModel> _following = [];
  bool _isLoading = true;

  bool get _isViewingOwnProfile => _currentUserId == widget.userId;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getFollowing(widget.userId);
      if (mounted) {
        setState(() {
          _following = users;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_following_list_screen_error_error_loading_following'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _confirmUnfollow(UserModel user) async {
    if (!_isViewingOwnProfile) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'profile_following_list_screen_text_unfollow_user'.tr(
            namedArgs: {'followedUserUsername': user.username},
          ),
        ),
        content: Text('profile_following_confirm_unfollow'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('profile_following_list_screen_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('profile_following_unfollow_button'.tr()),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _unfollow(user);
    }
  }

  Future<void> _unfollow(UserModel user) async {
    try {
      await _userService.unfollowUser(user.id);
      if (mounted) {
        setState(() => _following.removeWhere((u) => u.id == user.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_following_list_screen_success_you_unfollowed_user'.tr(
                namedArgs: {'followedUserFullName': user.fullName},
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_following_list_screen_error_error_unfollowing_user'.tr(
                namedArgs: {'error': e.toString()},
              ),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _following.isEmpty
                  ? EmptyState(
                      icon: Icons.group_outlined,
                      message: 'profile_no_followers'.tr(),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadFollowing,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _following.length,
                        itemBuilder: (context, index) {
                          final user = _following[index];
                          final isViewer = user.id == _currentUserId;

                          return GlassCard(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: EdgeInsets.zero,
                            child: UserListTile(
                              id: user.id,
                              displayName: user.fullName,
                              handle: user.username,
                              avatarUrl: user.profileImageUrl,
                              isVerified: user.isVerified,
                              trailing: (!_isViewingOwnProfile || isViewer)
                                  ? null
                                  : FollowButton(
                                      isFollowing: true,
                                      onTap: () => _confirmUnfollow(user),
                                    ),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/profile/view',
                                  arguments: {
                                    'userId': user.id,
                                    'isCurrentUser': isViewer,
                                  },
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
