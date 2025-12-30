import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/art_models.dart';
import 'glass_card.dart';
import 'gradient_badge.dart';

/// Compact mini artist card for 2-column grid layout
class MiniArtistCard extends StatefulWidget {
  final ArtistProfile artist;
  final VoidCallback? onTap;
  final void Function(bool isFollowing)? onFollow;

  const MiniArtistCard({
    super.key,
    required this.artist,
    this.onTap,
    this.onFollow,
  });

  @override
  State<MiniArtistCard> createState() => _MiniArtistCardState();
}

class _MiniArtistCardState extends State<MiniArtistCard> {
  late bool _isFollowing;
  late int _followersCount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isFollowing = widget.artist.isFollowedByCurrentUser;
    _followersCount = widget.artist.followersCount;
  }

  @override
  void didUpdateWidget(MiniArtistCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artist.isFollowedByCurrentUser !=
        widget.artist.isFollowedByCurrentUser) {
      _isFollowing = widget.artist.isFollowedByCurrentUser;
    }
    if (oldWidget.artist.followersCount != widget.artist.followersCount) {
      _followersCount = widget.artist.followersCount;
    }
  }

  void _handleFollowToggle() async {
    if (_isLoading) return;

    // Store original values in case we need to revert
    final originalFollowing = _isFollowing;
    final originalFollowersCount = _followersCount;

    setState(() {
      _isLoading = true;
      // Optimistic update
      _isFollowing = !_isFollowing;
      _followersCount = _isFollowing
          ? _followersCount + 1
          : _followersCount - 1;
    });

    try {
      // Call the parent callback
      if (widget.onFollow != null) {
        widget.onFollow!(_isFollowing);
      }
    } catch (e) {
      // If parent callback fails, revert optimistic update
      setState(() {
        _isFollowing = originalFollowing;
        _followersCount = originalFollowersCount;
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: GlassCard(
        borderRadius: 24,
        padding: EdgeInsets.zero,
        child: SizedBox(
          height: 140,
          child: Stack(
            children: [
              // Background image if available
              if (widget.artist.portfolioImages.isNotEmpty)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.network(
                      widget.artist.portfolioImages.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF7C4DFF).withAlpha(51),
                              const Color(0xFF34D399).withAlpha(51),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Overlay gradient for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar and follow button row
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: ClipOval(
                            child: widget.artist.avatarUrl.isNotEmpty
                                ? Image.network(
                                    widget.artist.avatarUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: const Color(
                                                0xFF7C4DFF,
                                              ).withAlpha(77),
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 16,
                                              ),
                                            ),
                                  )
                                : Container(
                                    color: const Color(
                                      0xFF7C4DFF,
                                    ).withAlpha(77),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const Spacer(),
                        // Follow button
                        if (widget.onFollow != null)
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _isFollowing
                                  ? const Color(0xFF34D399).withAlpha(77)
                                  : Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              onPressed: _isLoading
                                  ? null
                                  : _handleFollowToggle,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      _isFollowing
                                          ? Icons.person_remove
                                          : Icons.person_add,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                              tooltip: _isFollowing
                                  ? 'unfollow'.tr().replaceAll(
                                      '{user}',
                                      widget.artist.displayName,
                                    )
                                  : 'follow'.tr().replaceAll(
                                      '{user}',
                                      widget.artist.displayName,
                                    ),
                            ),
                          ),
                      ],
                    ),

                    const Spacer(),

                    // Artist info
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name
                        Text(
                          widget.artist.displayName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 2),

                        // Bio (truncated)
                        if (widget.artist.bio.isNotEmpty)
                          Text(
                            widget.artist.bio,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                        const SizedBox(height: 4),

                        // Stats
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$_followersCount',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            if (widget.artist.isVerified) ...[
                              const SizedBox(width: 4),
                              const GradientBadge(
                                text: 'VERIFIED',
                                fontSize: 8,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                borderRadius: 8,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
