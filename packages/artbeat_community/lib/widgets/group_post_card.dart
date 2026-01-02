import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'widgets.dart';
import 'package:artbeat_core/artbeat_core.dart'
    show AppLogger, ImageUrlValidator, ArtbeatColors;

import '../models/group_models.dart';

/// Card widget for displaying group posts with appropriate actions
class GroupPostCard extends StatelessWidget {
  final BaseGroupPost post;
  final GroupType groupType;
  final VoidCallback onAppreciate;
  final VoidCallback onComment;
  final VoidCallback onFeature;
  final VoidCallback onGift;
  final VoidCallback onShare;
  final bool isCompact;

  const GroupPostCard({
    super.key,
    required this.post,
    required this.groupType,
    required this.onAppreciate,
    required this.onComment,
    required this.onFeature,
    required this.onGift,
    required this.onShare,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildContent(),
          if (post.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildImages(),
          ],
          _buildSpecializedContent(),
          _buildHashtags(),
          const SizedBox(height: 16),
          _buildActions(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        // Author avatar
        CircleAvatar(
          radius: 20,
          backgroundImage: post.userPhotoUrl.isNotEmpty
              ? NetworkImage(post.userPhotoUrl)
              : null,
          child: post.userPhotoUrl.isEmpty
              ? Text(
                  post.userName.isNotEmpty
                      ? post.userName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(width: 12),
        // Author name and time
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.userName,
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                intl.DateFormat('MMM d, yyyy').format(post.createdAt),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        // Group type badge
        GradientBadge(
          text: groupType.name.toUpperCase(),
          gradient: const LinearGradient(
            colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    return Row(
      children: [
        // Appreciate button
        Expanded(
          child: HudButton(
            isPrimary: false,
            onPressed: onAppreciate,
            text: '${post.applauseCount}',
            icon: Icons.favorite_border,
          ),
        ),
        const SizedBox(width: 8),
        // Comment button
        Expanded(
          child: HudButton(
            isPrimary: false,
            onPressed: onComment,
            text: '${post.commentCount}',
            icon: Icons.comment_outlined,
          ),
        ),
        const SizedBox(width: 8),
        // Share button
        Expanded(
          child: HudButton(
            isPrimary: false,
            onPressed: onShare,
            text: '${post.shareCount}',
            icon: Icons.share_outlined,
          ),
        ),
        const SizedBox(width: 8),
        // Gift button
        Expanded(
          child: HudButton(
            isPrimary: true,
            onPressed: onGift,
            text: 'gift'.tr(),
            icon: Icons.card_giftcard,
          ),
        ),
      ],
    );
  }

  // Group badge and legacy action helpers removed - UI now uses UniversalContentCard

  Widget _buildContent() {
    if (post.content.isEmpty) return const SizedBox.shrink();

    return Text(
      post.content,
      style: GoogleFonts.spaceGrotesk(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
    );
  }

  Widget _buildImages() {
    if (post.imageUrls.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: post.imageUrls.length,
        itemBuilder: (context, index) {
          final imageUrl = post.imageUrls[index];

          // Debug: Print image URL to see what we're working with
          AppLogger.info('🖼️ Displaying image URL: $imageUrl');

          // More permissive validation - just check if it's not empty
          final isValidUrl = imageUrl.isNotEmpty;

          return Container(
            width: 160,
            margin: EdgeInsets.only(
              right: index < post.imageUrls.length - 1 ? 8 : 0,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: isValidUrl && ImageUrlValidator.isValidImageUrl(imageUrl)
                  ? ImageUrlValidator.safeNetworkImage(imageUrl) != null
                        ? DecorationImage(
                            image: ImageUrlValidator.safeNetworkImage(
                              imageUrl,
                            )!,
                            fit: BoxFit.cover,
                          )
                        : null
                  : null,
              color:
                  !isValidUrl ||
                      !ImageUrlValidator.isValidImageUrl(imageUrl) ||
                      ImageUrlValidator.safeNetworkImage(imageUrl) == null
                  ? Colors.grey[300]
                  : null,
            ),
            child:
                !isValidUrl ||
                    !ImageUrlValidator.isValidImageUrl(imageUrl) ||
                    ImageUrlValidator.safeNetworkImage(imageUrl) == null
                ? const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.grey,
                      size: 32,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  Widget _buildSpecializedContent() {
    switch (groupType) {
      case GroupType.artist:
        return _buildArtistContent(post as ArtistGroupPost);
      case GroupType.event:
        return _buildEventContent(post as EventGroupPost);
      case GroupType.artWalk:
        return _buildArtWalkContent(post as ArtWalkAdventurePost);
      case GroupType.artistWanted:
        return _buildArtistWantedContent(post as ArtistWantedPost);
    }
  }

  Widget _buildArtistContent(ArtistGroupPost artistPost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (artistPost.artworkTitle.isNotEmpty) ...[
          Text(
            artistPost.artworkTitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (artistPost.artworkDescription.isNotEmpty) ...[
          Text(
            artistPost.artworkDescription,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (artistPost.medium.isNotEmpty) ...[
              _buildInfoChip(Icons.brush, artistPost.medium),
              const SizedBox(width: 8),
            ],
            if (artistPost.style.isNotEmpty) ...[
              _buildInfoChip(Icons.style, artistPost.style),
              const SizedBox(width: 8),
            ],
            if (artistPost.isForSale && artistPost.price != null) ...[
              _buildInfoChip(
                Icons.attach_money,
                '\$${artistPost.price!.toStringAsFixed(0)}',
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildEventContent(EventGroupPost eventPost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eventPost.eventTitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          eventPost.eventDescription,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              Icons.calendar_today,
              intl.DateFormat('MMM d, y').format(eventPost.eventDate),
            ),
            const SizedBox(width: 8),
            _buildInfoChip(Icons.location_on, eventPost.eventLocation),
            const SizedBox(width: 8),
            _buildInfoChip(
              eventPost.eventType == 'hosting'
                  ? Icons.event_seat
                  : Icons.event_available,
              eventPost.eventType.toUpperCase(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildArtWalkContent(ArtWalkAdventurePost walkPost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          walkPost.routeName,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              Icons.straighten,
              '${walkPost.walkDistance.toStringAsFixed(1)} km',
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.access_time,
              '${walkPost.estimatedDuration} min',
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.trending_up,
              walkPost.difficulty.toUpperCase(),
            ),
          ],
        ),
        if (walkPost.artworkPhotos.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            '${walkPost.artworkPhotos.length} artwork photos',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildArtistWantedContent(ArtistWantedPost wantedPost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                wantedPost.projectTitle,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
            if (wantedPost.isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF7C4DFF),
                      Color(0xFF22D3EE),
                      Color(0xFF34D399),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'URGENT',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          wantedPost.projectDescription,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildInfoChip(
              Icons.attach_money,
              '\$${wantedPost.budget.toStringAsFixed(0)} ${wantedPost.budgetType}',
            ),
            const SizedBox(width: 8),
            _buildInfoChip(
              Icons.schedule,
              intl.DateFormat('MMM d').format(wantedPost.deadline),
            ),
            const SizedBox(width: 8),
            _buildInfoChip(Icons.star, wantedPost.experienceLevel),
          ],
        ),
        if (wantedPost.requiredSkills.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: wantedPost.requiredSkills
                .take(3)
                .map(
                  (skill) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      skill,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.8)),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHashtags() {
    if (post.tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: post.tags
            .map(
              (tag) => Text(
                '#$tag',
                style: const TextStyle(
                  color: ArtbeatColors.primaryPurple,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  // Legacy action row removed; engagement handled by UniversalEngagementBar

  // Removed legacy helpers - group visuals handled by UniversalContentCard/customContent
}
