import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import '../utils/logger.dart';
import '../services/image_management_service.dart';

/// A secure network image widget that handles Firebase Storage authentication
/// and App Check token issues gracefully
class SecureNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;
  final bool enableRetry;
  final int maxRetries;
  final bool enableThumbnailFallback;

  const SecureNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
    this.enableRetry = true,
    this.maxRetries = 3,
    this.enableThumbnailFallback = false,
  });

  @override
  State<SecureNetworkImage> createState() => _SecureNetworkImageState();
}

class _SecureNetworkImageState extends State<SecureNetworkImage> {
  static final _logger = Logger('SecureNetworkImage');
  int _retryCount = 0;
  bool _isRetrying = false;
  String? _authenticatedUrl;
  bool _usingThumbnailFallback = false;

  @override
  void initState() {
    super.initState();
    _authenticatedUrl = widget.imageUrl;
  }

  /// Generate thumbnail URL from main artwork URL
  String _generateThumbnailUrl(String originalUrl) {
    try {
      // Look for artwork patterns like: artwork/{userId}/{fileName}.jpg
      if (originalUrl.contains('artwork') && originalUrl.contains('.jpg')) {
        // Extract the part after 'artwork/' and before the file name
        final artworkIndex = originalUrl.indexOf('artwork/');
        if (artworkIndex != -1) {
          final beforeArtwork = originalUrl.substring(
            0,
            artworkIndex + 8,
          ); // Include 'artwork/'
          final afterArtwork = originalUrl.substring(artworkIndex + 8);

          // Find the next slash to separate userId from filename
          final slashIndex = afterArtwork.indexOf('/');
          if (slashIndex != -1) {
            final userId = afterArtwork.substring(0, slashIndex);
            final fileName = afterArtwork.substring(slashIndex + 1);

            // Convert filename.jpg to filename_thumb.jpg
            final nameWithoutExt = fileName.replaceAll('.jpg', '');
            final thumbnailFileName = '${nameWithoutExt}_thumb.jpg';

            return '${beforeArtwork}${userId}/thumbnails/$thumbnailFileName';
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Error generating thumbnail URL: $e');
      }
    }
    return originalUrl; // Return original if can't generate thumbnail
  }

  /// Attempts to refresh authentication tokens and retry loading
  Future<void> _retryWithFreshTokens() async {
    if (_isRetrying || _retryCount >= widget.maxRetries) return;

    setState(() {
      _isRetrying = true;
    });

    try {
      // Refresh Firebase Auth token
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.getIdToken(true); // Force refresh
        if (kDebugMode) {
          AppLogger.firebase(
            '🔄 Refreshed Firebase Auth token for image retry',
          );
        }
      }

      // Refresh App Check token
      try {
        await FirebaseAppCheck.instance.getToken(true); // Force refresh
        if (kDebugMode) {
          AppLogger.info('🔄 Refreshed App Check token for image retry');
        }
      } catch (e) {
        if (kDebugMode) {
          AppLogger.warning('⚠️ Could not refresh App Check token: $e');
        }
      }

      // Add a small delay to allow tokens to propagate
      await Future<void>.delayed(const Duration(milliseconds: 500));

      _retryCount++;

      // Force widget rebuild with fresh tokens
      setState(() {
        _authenticatedUrl =
            '${widget.imageUrl}?retry=$_retryCount&t=${DateTime.now().millisecondsSinceEpoch}';
        _isRetrying = false;
      });

      if (kDebugMode) {
        print(
          '🔄 Retrying image load (attempt $_retryCount/${widget.maxRetries}): ${widget.imageUrl}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Error during token refresh: $e');
      }
      setState(() {
        _isRetrying = false;
      });
    }
  }

  /// Generate corrected URL from old artwork path to new artwork_images path
  String _generateCorrectedArtworkUrl(String originalUrl) {
    try {
      // Replace old 'artwork/' path with correct 'artwork_images/' path
      // Handle both regular and URL-encoded versions
      String correctedUrl = originalUrl;
      if (originalUrl.contains('artwork/') &&
          !originalUrl.contains('artwork_images/')) {
        correctedUrl = originalUrl.replaceAll('artwork/', 'artwork_images/');
      } else if (originalUrl.contains('artwork%2F') &&
          !originalUrl.contains('artwork_images%2F')) {
        correctedUrl = originalUrl.replaceAll(
          'artwork%2F',
          'artwork_images%2F',
        );
      }
      return correctedUrl;
    } catch (e) {
      if (kDebugMode) {
        AppLogger.error('❌ Error generating corrected artwork URL: $e');
      }
    }
    return originalUrl; // Return original if can't generate corrected URL
  }

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    final isAuthError =
        error.toString().contains('403') ||
        error.toString().contains('HTTP request failed, statusCode: 403');

    final is404Error =
        error.toString().contains('404') ||
        error.toString().contains('HTTP request failed, statusCode: 404');

    if (kDebugMode) {
      _logger.fine(
        '🖼️ SecureNetworkImage _buildErrorWidget called for: ${widget.imageUrl}',
      );
      _logger.fine('🖼️ Error type: $error');
      _logger.fine(
        '🖼️ Is 404: $is404Error, enableThumbnailFallback: ${widget.enableThumbnailFallback}, usingFallback: $_usingThumbnailFallback',
      );
    }

    // Only log errors if they're not common 404s (which are expected for missing artwork)
    if (kDebugMode && !is404Error) {
      _logger.warning(
        '❌ SecureNetworkImage error for ${widget.imageUrl}: $error',
      );
    } else if (kDebugMode && is404Error) {
      _logger.info(
        '🖼️ SecureNetworkImage: Missing image (404) ${widget.imageUrl}',
      );
    }

    // If 404 error and the URL contains old 'artwork/' path (URL-encoded or not), try corrected 'artwork_images/' path
    if (kDebugMode) {
      _logger.info(
        '🔍 Checking fallback conditions: is404Error=$is404Error, contains artwork/=${widget.imageUrl.contains('artwork/')}, contains artwork%2F=${widget.imageUrl.contains('artwork%2F')}, contains artwork_images/=${widget.imageUrl.contains('artwork_images/')}',
      );
    }
    if (is404Error &&
        (widget.imageUrl.contains('artwork/') ||
            widget.imageUrl.contains('artwork%2F')) &&
        !widget.imageUrl.contains('artwork_images/') &&
        widget.imageUrl != _generateCorrectedArtworkUrl(widget.imageUrl)) {
      final correctedUrl = _generateCorrectedArtworkUrl(widget.imageUrl);
      if (kDebugMode) {
        _logger.info(
          '🔄 Attempting path correction fallback for: ${widget.imageUrl}',
        );
        _logger.info('🔄 Generated corrected URL: $correctedUrl');
      }

      // Try loading with corrected path
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _authenticatedUrl = correctedUrl;
            });
          }
        });
      }

      // Return loading indicator while trying corrected URL
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // If 404 error and thumbnail fallback is enabled and we haven't tried it yet
    if (is404Error &&
        widget.enableThumbnailFallback &&
        !_usingThumbnailFallback &&
        widget.imageUrl != _generateThumbnailUrl(widget.imageUrl)) {
      final thumbnailUrl = _generateThumbnailUrl(widget.imageUrl);
      if (kDebugMode) {
        _logger.info(
          '🔄 Attempting thumbnail fallback for: ${widget.imageUrl}',
        );
        _logger.info('🔄 Generated thumbnail URL: $thumbnailUrl');
      }

      // Try loading thumbnail
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _usingThumbnailFallback = true;
              _authenticatedUrl = thumbnailUrl;
            });
          }
        });
      }

      // Return loading indicator while switching to thumbnail
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    // Custom error widget or default
    Widget errorChild =
        widget.errorWidget ??
        Container(
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, color: Colors.grey, size: 48),
        );

    // If it's a 404 error, show a "missing image" icon instead of retrying
    if (is404Error) {
      errorChild = Container(
        color: Colors.grey[100],
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 32,
        ),
      );
    }
    // If it's an auth error and retry is enabled, show retry button
    else if (isAuthError &&
        widget.enableRetry &&
        _retryCount < widget.maxRetries &&
        !_isRetrying) {
      errorChild = Container(
        color: Colors.grey[200],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.refresh, color: Colors.grey, size: 32),
            const SizedBox(height: 8),
            Text(
              'Tap to retry',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap:
          isAuthError &&
              widget.enableRetry &&
              _retryCount < widget.maxRetries &&
              !_isRetrying
          ? _retryWithFreshTokens
          : null,
      child: errorChild,
    );
  }

  Widget _buildPlaceholder(BuildContext context, String url) {
    if (_isRetrying) {
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return widget.placeholder ??
        Container(
          color: Colors.grey[200],
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Early validation to prevent empty or invalid URLs from reaching NetworkImage
    final urlToCheck = _authenticatedUrl ?? widget.imageUrl;

    // Check for empty or whitespace-only URLs
    if (urlToCheck.trim().isEmpty) {
      AppLogger.network('🖼️ SecureNetworkImage: Empty URL');
      return _buildErrorWidget(context, 'Empty URL', null);
    }

    // Validate URL structure - more permissive
    final uri = Uri.tryParse(urlToCheck);
    final isValidUrl = uri != null && uri.hasScheme && uri.host.isNotEmpty;
    final isLikelyValidUrl =
        isValidUrl ||
        urlToCheck.startsWith('http') ||
        urlToCheck.contains('firebasestorage');

    AppLogger.network('🖼️ SecureNetworkImage validating URL: $urlToCheck');
    // Removed excessive debugPrint to prevent terminal scrolling

    final cacheManager = ImageManagementService().cacheManager;
    AppLogger.network(
      '🖼️ SecureNetworkImage using cache manager: ${cacheManager != null}',
    );

    if (!isLikelyValidUrl) {
      AppLogger.network('🖼️ SecureNetworkImage: URL failed validation');
      return _buildErrorWidget(context, 'Invalid URL', null);
    }

    ImageManagementService().logDecodeDimensions(
      label: 'SecureNetworkImage',
      width: widget.width,
      height: widget.height,
    );

    Widget imageWidget = CachedNetworkImage(
      imageUrl: urlToCheck,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      cacheManager:
          cacheManager, // Will be null if not initialized, which is fine
      placeholder: _buildPlaceholder,
      errorWidget: (context, url, error) {
        // Catch and handle the error to prevent it from bubbling up
        try {
          return _buildErrorWidget(context, error, null);
        } catch (e) {
          // Fallback error widget if even error handling fails
          return Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[300],
            child: const Icon(Icons.image_not_supported, color: Colors.grey),
          );
        }
      },
      // Add headers for Firebase Storage
      httpHeaders: const {'Cache-Control': 'no-cache'},
      errorListener: (error) {
        // Only log significant errors in debug mode, suppress 404s to reduce noise
        final is404Error =
            error.toString().contains('404') ||
            error.toString().contains('HTTP request failed, statusCode: 404');

        if (kDebugMode && !is404Error) {
          AppLogger.error('🔇 CachedNetworkImage error suppressed: $error');
          AppLogger.error(
            '🔇 CachedNetworkImage error for $urlToCheck: $error',
          );
        }

        // Handle thumbnail fallback for 404 errors via errorListener as well
        if (is404Error &&
            widget.enableThumbnailFallback &&
            !_usingThumbnailFallback &&
            widget.imageUrl != _generateThumbnailUrl(widget.imageUrl)) {
          final thumbnailUrl = _generateThumbnailUrl(widget.imageUrl);
          if (kDebugMode) {
            print(
              '🔄 ErrorListener: Attempting thumbnail fallback for: ${widget.imageUrl}',
            );
            AppLogger.error(
              '🔄 ErrorListener: Generated thumbnail URL: $thumbnailUrl',
            );
          }

          // Try loading thumbnail
          if (mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _usingThumbnailFallback = true;
                  _authenticatedUrl = thumbnailUrl;
                });
              }
            });
          }
        }
      },
    );

    // Apply border radius if specified
    if (widget.borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: widget.borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Extension to easily replace Image.network calls
extension SecureImageExtension on Image {
  static Widget secureNetwork(
    String src, {
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
    bool enableRetry = true,
    int maxRetries = 3,
    bool enableThumbnailFallback = false,
  }) {
    return SecureNetworkImage(
      key: key,
      imageUrl: src,
      width: width,
      height: height,
      fit: fit,
      placeholder: placeholder,
      errorWidget: errorWidget,
      borderRadius: borderRadius,
      enableRetry: enableRetry,
      maxRetries: maxRetries,
      enableThumbnailFallback: enableThumbnailFallback,
    );
  }
}
