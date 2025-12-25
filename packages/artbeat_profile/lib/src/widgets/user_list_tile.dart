import 'package:flutter/material.dart';

class UserListTile extends StatelessWidget {
  final String id;
  final String displayName;
  final String handle;
  final String avatarUrl;
  final bool isVerified;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserListTile({
    Key? key,
    required this.id,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
    this.isVerified = false,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Hero(
        tag: 'user_avatar_$id',
        child: CircleAvatar(
          backgroundImage: NetworkImage(avatarUrl),
          radius: 24,
          backgroundColor: Colors.grey[200],
          onBackgroundImageError: (_, __) {},
        ),
      ),
      title: Row(
        children: [
          Text(
            displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (isVerified) ...[
            const SizedBox(width: 4),
            const Icon(Icons.verified, size: 16, color: Colors.blueAccent),
          ],
        ],
      ),
      subtitle: Text('@$handle'),
      trailing: trailing,
    );
  }
}
