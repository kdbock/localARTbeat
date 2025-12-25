import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';

class FollowersListScreen extends StatefulWidget {
  final String userId;

  const FollowersListScreen({super.key, required this.userId});

  @override
  State<FollowersListScreen> createState() => _FollowersListScreenState();
}

class _FollowersListScreenState extends State<FollowersListScreen> {
  final UserService _userService = UserService();
  List<UserModel> _followers = [];
  bool _isLoading = true;
  bool _isCurrentUser = false;

  @override
  void initState() {
    super.initState();
    _isCurrentUser = FirebaseAuth.instance.currentUser?.uid == widget.userId;
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userService.getFollowers(widget.userId);
      if (mounted) setState(() => _followers = users);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'profile_error_followers'.tr(namedArgs: {'error': e.toString()}),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refresh() async {
    await _loadFollowers();
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
                  : _followers.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      message: 'profile_no_followers'.tr(),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        itemCount: _followers.length,
                        itemBuilder: (context, index) {
                          final user = _followers[index];
                          final isViewer =
                              user.id == FirebaseAuth.instance.currentUser?.uid;

                          return FutureBuilder<bool>(
                            future: _userService.isFollowing(user.id),
                            builder: (context, snapshot) {
                              final isFollowing = snapshot.data ?? false;

                              return UserListTile(
                                id: user.id,
                                displayName: user.fullName,
                                handle: user.username,
                                avatarUrl: user.profileImageUrl,
                                isVerified: user.isVerified,
                                trailing: !_isCurrentUser || isViewer
                                    ? null
                                    : FollowButton(
                                        isFollowing: isFollowing,
                                        onTap: () async {
                                          if (isFollowing) {
                                            await _userService.unfollowUser(
                                              user.id,
                                            );
                                          } else {
                                            await _userService.followUser(
                                              user.id,
                                            );
                                          }
                                          setState(() {});
                                        },
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
                              );
                            },
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
