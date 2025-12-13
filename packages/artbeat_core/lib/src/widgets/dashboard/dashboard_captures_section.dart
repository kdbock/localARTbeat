import 'package:artbeat_community/screens/feed/create_post_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artbeat_core/artbeat_core.dart';

class DashboardCapturesSection extends StatelessWidget {
  final DashboardViewModel viewModel;

  const DashboardCapturesSection({Key? key, required this.viewModel})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ArtbeatColors.primaryGreen.withValues(alpha: 0.05),
            ArtbeatColors.primaryPurple.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context),
            const SizedBox(height: 16),
            _buildCapturesContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [ArtbeatColors.primaryGreen, ArtbeatColors.primaryPurple],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Local Captures',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: ArtbeatColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                'Discover amazing street art, murals, and sculptures found by our community',
                style: TextStyle(
                  fontSize: 14,
                  color: ArtbeatColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [ArtbeatColors.primaryPurple, ArtbeatColors.primaryGreen],
            ),
            borderRadius: BorderRadius.circular(25),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Navigate to captures browse screen to show all captures
                Navigator.pushNamed(context, '/capture/browse');
              },
              borderRadius: BorderRadius.circular(25),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.explore, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Explore All',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapturesContent(BuildContext context) {
    if (viewModel.isLoadingLocalCaptures) {
      return _buildLoadingState();
    }

    if (viewModel.localCapturesError != null) {
      return _buildErrorState();
    }

    final captures = viewModel.localCaptures;

    if (captures.isEmpty) {
      return _buildEmptyState(context);
    }

    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: captures.length,
        itemBuilder: (context, index) {
          final capture = captures[index];
          return Padding(
            padding: EdgeInsets.only(
              left: index == 0 ? 0 : 12,
              right: index == captures.length - 1 ? 0 : 0,
            ),
            child: _buildEnhancedCaptureCard(context, capture, index),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 280,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: 4,
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 16),
            child: _buildEnhancedSkeletonCard(),
          );
        },
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: ArtbeatColors.textSecondary,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              'Unable to load captures',
              style: TextStyle(color: ArtbeatColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: ArtbeatColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.photo_camera_outlined,
              color: ArtbeatColors.textSecondary,
              size: 44,
            ),
            const SizedBox(height: 12),
            const Text(
              'No captures yet',
              style: TextStyle(
                color: ArtbeatColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Be the first to discover and share amazing local art!',
              style: TextStyle(
                color: ArtbeatColors.textSecondary,
                fontSize: 14,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    ArtbeatColors.primaryPurple,
                    ArtbeatColors.primaryGreen,
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => Navigator.pushNamed(context, '/capture/create'),
                  borderRadius: BorderRadius.circular(25),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Add Capture',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Enhanced capture card with modern design and better engagement
  Widget _buildEnhancedCaptureCard(
    BuildContext context,
    CaptureModel capture,
    int index,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return TweenAnimationBuilder<double>(
          duration: Duration(
            milliseconds: 300 + (index * 100),
          ), // Staggered animation
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, 10 * (1 - value)),
              child: Opacity(
                opacity: value,
                child: SizedBox(
                  width: 200,
                  height: 280,
                  child: Hero(
                    tag: 'capture_${capture.id}',
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(16),
                      shadowColor: ArtbeatColors.primaryPurple.withValues(
                        alpha: 0.2,
                      ),
                      child: InkWell(
                        onTap: () => _showCaptureDetails(context, capture),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  height: 180,
                                  decoration: BoxDecoration(
                                    color: ArtbeatColors.backgroundSecondary,
                                    image:
                                        ImageUrlValidator.isValidImageUrl(
                                          capture.imageUrl,
                                        )
                                        ? DecorationImage(
                                            image: NetworkImage(
                                              capture.imageUrl,
                                            ),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child:
                                      !ImageUrlValidator.isValidImageUrl(
                                        capture.imageUrl,
                                      )
                                      ? const Icon(
                                          Icons.photo_camera,
                                          color: ArtbeatColors.primaryPurple,
                                          size: 48,
                                        )
                                      : null,
                                ),
                              ),

                              // Content
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        capture.title?.isNotEmpty == true
                                            ? capture.title!
                                            : 'Untitled Artwork',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: ArtbeatColors.textPrimary,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (capture.locationName?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.location_on,
                                              size: 12,
                                              color:
                                                  ArtbeatColors.textSecondary,
                                            ),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                capture.locationName!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: ArtbeatColors
                                                      .textSecondary,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const Spacer(),
                                      Row(
                                        children: [
                                          _buildFloatingActionButton(
                                            icon: Icons.favorite_border,
                                            label:
                                                '${capture.engagementStats.likeCount}',
                                            color: ArtbeatColors.primaryPurple,
                                            onPressed: () =>
                                                _handleLike(context, capture),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildFloatingActionButton(
                                            icon: Icons.share,
                                            label: '',
                                            color: ArtbeatColors.primaryGreen,
                                            onPressed: () =>
                                                _handleShare(context, capture),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Enhanced skeleton card for loading state
  Widget _buildEnhancedSkeletonCard() {
    return Container(
      width: 200,
      height: 280,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          Container(
            width: double.infinity,
            height: 180,
            decoration: BoxDecoration(
              color: ArtbeatColors.backgroundSecondary.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ArtbeatColors.primaryPurple,
                ),
              ),
            ),
          ),

          // Content skeleton
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: ArtbeatColors.backgroundSecondary.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 120,
                  decoration: BoxDecoration(
                    color: ArtbeatColors.backgroundSecondary.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      height: 32,
                      width: 60,
                      decoration: BoxDecoration(
                        color: ArtbeatColors.backgroundSecondary.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      height: 32,
                      width: 40,
                      decoration: BoxDecoration(
                        color: ArtbeatColors.backgroundSecondary.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a floating action button for capture actions
  Widget _buildFloatingActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            if (label.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Handle like action with haptic feedback and proper state management
  Future<void> _handleLike(BuildContext context, CaptureModel capture) async {
    try {
      // Provide immediate haptic feedback
      await HapticFeedback.lightImpact();

      // Toggle the like using the viewModel
      final isLiked = await viewModel.toggleCaptureLike(capture.id);

      // Show appropriate feedback message
      final message = isLiked
          ? 'Added "${capture.title ?? 'artwork'}" to your liked captures!'
          : 'Removed "${capture.title ?? 'artwork'}" from your liked captures';

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isLiked
              ? ArtbeatColors.primaryPurple
              : ArtbeatColors.textSecondary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // The UI will automatically update because the viewModel notifies listeners
      // and the capture cards will rebuild with the new like state
    } catch (e) {
      // Handle errors gracefully
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update like: ${e.toString()}'),
          backgroundColor: ArtbeatColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  /// Handle share action
  void _handleShare(BuildContext context, CaptureModel capture) async {
    try {
      // Create a pre-filled caption for the post
      final caption =
          'Check out this capture: "${capture.title ?? 'Untitled'}"\n\n'
          '${capture.description?.isNotEmpty == true ? capture.description : ''}';

      // Navigate to the CreatePostScreen
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (context) => CreatePostScreen(
            prefilledImageUrl: capture.imageUrl,
            prefilledCaption: caption,
          ),
        ),
      );
    } catch (e) {
      // Show error feedback
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share artwork: $e'),
            backgroundColor: ArtbeatColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _showCaptureDetails(BuildContext context, CaptureModel capture) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image
                      if (ImageUrlValidator.isValidImageUrl(capture.imageUrl))
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            capture.imageUrl,
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: double.infinity,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: ArtbeatColors.backgroundSecondary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.broken_image,
                                  color: ArtbeatColors.textSecondary,
                                  size: 48,
                                ),
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 16),

                      // Title
                      Text(
                        capture.title ?? 'Untitled Capture',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Location
                      if (capture.locationName?.isNotEmpty == true)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              size: 16,
                              color: ArtbeatColors.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                capture.locationName ?? 'Unknown Location',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: ArtbeatColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      // Description
                      if (capture.description?.isNotEmpty == true)
                        Text(
                          capture.description ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            color: ArtbeatColors.textPrimary,
                            height: 1.5,
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Action button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushNamed(
                              context,
                              '/art-walk/create',
                              arguments: {'captureId': capture.id},
                            );
                          },
                          icon: const Icon(Icons.directions_walk),
                          label: const Text('Create Art Walk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ArtbeatColors.primaryGreen,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stateful widget for the like button that properly handles state changes
class _LikeButtonWidget extends StatefulWidget {
  final DashboardViewModel viewModel;
  final CaptureModel capture;
  final VoidCallback onLike;

  const _LikeButtonWidget({
    required this.viewModel,
    required this.capture,
    required this.onLike,
  });

  @override
  State<_LikeButtonWidget> createState() => _LikeButtonWidgetState();
}

class _LikeButtonWidgetState extends State<_LikeButtonWidget> {
  bool? _isLiked;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLikeStatus();
  }

  @override
  void didUpdateWidget(_LikeButtonWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload like status if the capture changed
    if (oldWidget.capture.id != widget.capture.id) {
      _loadLikeStatus();
    }
  }

  Future<void> _loadLikeStatus() async {
    if (!mounted) return;

    setState(() => _isLoading = true);
    try {
      final isLiked = await widget.viewModel.hasUserLikedCapture(
        widget.capture.id,
      );
      if (mounted) {
        setState(() {
          _isLiked = isLiked;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLiked = false;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLiked = _isLiked ?? false;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading
              ? null
              : () async {
                  widget.onLike();
                  // Reload the like status after the action
                  await Future<void>.delayed(const Duration(milliseconds: 100));
                  _loadLikeStatus();
                },
          borderRadius: BorderRadius.circular(18),
          child: Icon(
            isLiked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: _isLoading
                ? ArtbeatColors.textSecondary
                : ArtbeatColors.error,
          ),
        ),
      ),
    );
  }
}
