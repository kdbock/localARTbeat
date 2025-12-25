import 'package:flutter/material.dart';

/// A widget to display user profile header with avatar, name, handle, level, badges
class ProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final String? displayName;
  final String? handle;
  final int? xpLevel;
  final List<String>? badges;
  final String? userId;
  final dynamic user;

  const ProfileHeader({
    super.key,
    this.avatarUrl,
    this.displayName,
    this.handle,
    this.xpLevel,
    this.badges,
    this.userId,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null ? const Icon(Icons.person) : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName ?? 'Unknown',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (handle != null)
                Text(
                  '@$handle',
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                ),
              if (xpLevel != null)
                Text(
                  'Level $xpLevel',
                  style: const TextStyle(fontSize: 12, color: Colors.yellow),
                ),
              if (badges != null && badges!.isNotEmpty)
                Row(
                  children: badges!
                      .map((badge) => Chip(label: Text(badge)))
                      .toList(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
