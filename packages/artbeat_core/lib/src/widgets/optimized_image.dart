import 'package:flutter/material.dart';
import '../services/image_management_service.dart';
import '../theme/artbeat_colors.dart';

/// Optimized image widget that prevents buffer overflow and manages resources
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool isProfile;
  final bool isThumbnail;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableHeroAnimation;
  final String? heroTag;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.isProfile = false,
    this.isThumbnail = false,
    this.placeholder,
    this.errorWidget,
    this.enableHeroAnimation = false,
    this.heroTag,
    this.onTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    ImageManagementService().logDecodeDimensions(
      label: 'OptimizedImage',
      width: width,
      height: height,
    );
    Widget imageWidget = ImageManagementService().getOptimizedImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      isProfile: isProfile,
      isThumbnail: isThumbnail,
      placeholder: placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: errorWidget ?? _buildDefaultErrorWidget(),
    );

    // Apply border radius if specified
    if (borderRadius != null) {
      imageWidget = ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    // Add hero animation if enabled
    if (enableHeroAnimation && heroTag != null) {
      imageWidget = Hero(tag: heroTag!, child: imageWidget);
    }

    // Add tap functionality if specified
    if (onTap != null) {
      imageWidget = GestureDetector(onTap: onTap, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: ArtbeatColors.backgroundSecondary,
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              ArtbeatColors.primaryPurple,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: ArtbeatColors.backgroundSecondary,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: ArtbeatColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}

/// Optimized image for grid displays with built-in loading management
class OptimizedGridImage extends StatelessWidget {
  final String imageUrl;
  final String? thumbnailUrl;
  final VoidCallback? onTap;
  final String? heroTag;
  final Widget? overlay;

  const OptimizedGridImage({
    super.key,
    required this.imageUrl,
    this.thumbnailUrl,
    this.onTap,
    this.heroTag,
    this.overlay,
  });

  @override
  Widget build(BuildContext context) {
    final displayUrl = thumbnailUrl ?? imageUrl;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Hero(
            tag: heroTag ?? 'image_$displayUrl',
            child: ImageManagementService().getOptimizedImage(
              imageUrl: displayUrl,
              fit: BoxFit.cover,
              isThumbnail: true,
              placeholder: Container(
                color: ArtbeatColors.backgroundSecondary,
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ArtbeatColors.primaryPurple,
                    ),
                  ),
                ),
              ),
              errorWidget: Container(
                color: ArtbeatColors.backgroundSecondary,
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        color: ArtbeatColors.textSecondary,
                        size: 24,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Error',
                        style: TextStyle(
                          fontSize: 10,
                          color: ArtbeatColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

/// Avatar widget specifically optimized for profile images
class OptimizedAvatar extends StatelessWidget {
  final String? imageUrl;
  final String displayName;
  final double radius;
  final bool isVerified;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? textColor;

  const OptimizedAvatar({
    super.key,
    this.imageUrl,
    required this.displayName,
    this.radius = 20.0,
    this.isVerified = false,
    this.onTap,
    this.backgroundColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: backgroundColor ?? ArtbeatColors.backgroundSecondary,
            ),
            child: ClipOval(
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? ImageManagementService().getOptimizedImage(
                      imageUrl: imageUrl!,
                      width: radius * 2,
                      height: radius * 2,
                      fit: BoxFit.cover,
                      isProfile: true,
                      placeholder: _buildFallbackAvatar(),
                      errorWidget: _buildFallbackAvatar(),
                    )
                  : _buildFallbackAvatar(),
            ),
          ),
          if (isVerified)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: ArtbeatColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.check,
                  size: radius * 0.6,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackAvatar() {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: backgroundColor ?? ArtbeatColors.primaryPurple,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          _getInitials(displayName),
          style: TextStyle(
            fontSize: radius * 0.8,
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';

    final words = name.trim().split(' ');
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }

    return name[0].toUpperCase();
  }
}
