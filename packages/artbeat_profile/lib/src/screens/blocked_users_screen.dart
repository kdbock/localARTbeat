import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/widgets/widgets.dart';

class BlockedUsersScreen extends StatelessWidget {
  final List<UserModel> blockedUsers;

  const BlockedUsersScreen({super.key, required this.blockedUsers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WorldBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: blockedUsers.isEmpty
                ? const EmptyState(
                    icon: Icons.block,
                    message: 'You have not blocked any users.',
                    iconColor: Colors.white,
                  )
                : ListView.builder(
                    itemCount: blockedUsers.length,
                    itemBuilder: (context, index) {
                      final user = blockedUsers[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GlassCard(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          child: UserListTile(
                            id: user.id,
                            displayName: user.fullName,
                            handle: user.username,
                            avatarUrl: user.profileImageUrl,
                            isVerified: user.isVerified,
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.block,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                // Unblock logic goes here
                              },
                            ),
                          ),
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
