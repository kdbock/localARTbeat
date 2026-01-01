import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'user_avatar_badge.dart';

class UserListTile extends StatelessWidget {
  final String id;
  final String displayName;
  final String handle;
  final String avatarUrl;
  final bool isVerified;
  final VoidCallback? onTap;
  final Widget? trailing;

  const UserListTile({
    super.key,
    required this.id,
    required this.displayName,
    required this.handle,
    required this.avatarUrl,
    this.isVerified = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = GoogleFonts.spaceGrotesk(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: Colors.white,
    );
    final subtitleStyle = GoogleFonts.spaceGrotesk(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.65),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              UserAvatarBadge(
                imageUrl: avatarUrl,
                size: 56,
                heroTag: 'user_avatar_$id',
                badge: isVerified ? _buildVerifiedBadge() : null,
                onTap: null,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: titleStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isVerified) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.verified,
                            color: Colors.white,
                            size: 18,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('@$handle', style: subtitleStyle),
                  ],
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 72),
                  child: trailing!,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifiedBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFF22D3EE), Color(0xFF7C4DFF)],
        ),
      ),
      child: const Icon(Icons.check, size: 12, color: Colors.white),
    );
  }
}
