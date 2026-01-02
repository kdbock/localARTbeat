import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/post_model.dart';
import '../services/community_service.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Horizontal scrolling slider displaying art awaiting critique
class ArtCritiqueSlider extends StatefulWidget {
  final VoidCallback? onViewAllPressed;
  final void Function(PostModel)? onPostSelected;

  const ArtCritiqueSlider({
    super.key,
    this.onViewAllPressed,
    this.onPostSelected,
  });

  @override
  State<ArtCritiqueSlider> createState() => _ArtCritiqueSliderState();
}

class _ArtCritiqueSliderState extends State<ArtCritiqueSlider> {
  final CommunityService _communityService = CommunityService();
  List<PostModel> _artPosts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadArtPosts();
  }

  Future<void> _loadArtPosts() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load posts with images for critique
      final posts = await _communityService.getPosts(limit: 20);

      // Filter to only include posts with images
      final artPosts = posts
          .where((post) => post.imageUrls.isNotEmpty)
          .toList();

      setState(() {
        _artPosts = artPosts;
        _isLoading = false;
      });
    } catch (e) {
      AppLogger.error('Error loading art posts for critique: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'art_critique_slider_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              HudButton(
                text: 'view_all'.tr(),
                onPressed: widget.onViewAllPressed,
              ),
            ],
          ),
        ),

        // Scrollable art slider
        SizedBox(
          height: 200,
          child: _isLoading
              ? _buildLoadingSlider()
              : _artPosts.isEmpty
              ? _buildEmptyState()
              : _buildArtSlider(),
        ),
      ],
    );
  }

  Widget _buildLoadingSlider() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 3, // Show 3 loading placeholders
      itemBuilder: (context, index) {
        return Container(
          width: 160,
          height: 200,
          margin: const EdgeInsets.only(right: 16),
          child: const GlassCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                Expanded(child: Center(child: CircularProgressIndicator())),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Loading...'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.palette_outlined,
            size: 48,
            color: Colors.white.withValues(alpha: 0.45),
          ),
          const SizedBox(height: 8),
          Text(
            'art_critique_empty_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'art_critique_empty_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtSlider() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: _artPosts.length,
      itemBuilder: (context, index) {
        final post = _artPosts[index];
        return _buildArtCard(post);
      },
    );
  }

  Widget _buildArtCard(PostModel post) {
    return Container(
      width: 160,
      height: 200,
      margin: const EdgeInsets.only(right: 16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: InkWell(
          onTap: () => widget.onPostSelected?.call(post),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  child: post.imageUrls.isNotEmpty
                      ? ImageManagementService().getOptimizedImage(
                          imageUrl: post.imageUrls.first,
                          fit: BoxFit.cover,
                          isThumbnail: true,
                          errorWidget: Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 32,
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.image,
                            color: Colors.grey,
                            size: 32,
                          ),
                        ),
                ),
              ),

              // Content section
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.content.isNotEmpty
                          ? post.content
                          : 'untitled_artwork'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '@${post.authorUsername}',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              Icons.comment_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${post.commentCount}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.45),
                              ),
                            ),
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
