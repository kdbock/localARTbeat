import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

class FollowButton extends StatelessWidget {
  final bool isFollowing;
  final VoidCallback onTap;

  const FollowButton({
    super.key,
    required this.isFollowing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        backgroundColor: isFollowing
            ? Colors.grey.shade200
            : ArtbeatColors.primaryPurple.withAlpha(25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isFollowing
              ? BorderSide.none
              : BorderSide(color: ArtbeatColors.primaryPurple.withAlpha(128)),
        ),
        minimumSize: const Size(80, 32),
      ),
      child: Text(
        isFollowing ? 'Following' : 'Follow',
        style: TextStyle(
          color: isFollowing ? Colors.black : ArtbeatColors.primaryPurple,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
