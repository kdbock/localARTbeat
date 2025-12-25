import 'package:flutter/material.dart';

class UserAvatarBadge extends StatelessWidget {
  final String imageUrl;
  final double size;
  final Widget? badge;
  final VoidCallback? onTap;
  final String? heroTag;

  const UserAvatarBadge({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.badge,
    this.onTap,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Icon(Icons.person, size: size * 0.6, color: Colors.grey[700]),
        ),
      ),
    );

    final avatarWithHero = heroTag != null
        ? Hero(tag: heroTag!, child: avatar)
        : avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          avatarWithHero,
          if (badge != null) Positioned(bottom: 0, right: 0, child: badge!),
        ],
      ),
    );
  }
}
