import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:async';
import '../widgets/secure_network_image.dart';
import '../utils/logger.dart';

/// Comprehensive image management service to prevent buffer overflow
/// and optimize image loading across the app
class ImageManagementService {
  static final ImageManagementService _instance =
      ImageManagementService._internal();
  factory ImageManagementService() => _instance;
  ImageManagementService._internal();

  // Configuration constants
  static const int maxConcurrentLoads =
      10; // Increased from 2 to prevent queue blocking
  static const int maxCacheSize = 250; // MB
  static const int thumbnailSize = 300;
  static const int profileImageSize = 200;
  static const Duration cacheDuration = Duration(days: 7);
  static const int largeImageDimensionThreshold = 2048;
  static const int largeImagePixelThreshold = 3000000;

  // Active loading tracking
  int _activeLoads = 0;
  final List<Completer<void>> _queue = [];
  final Set<String> _loadingUrls = <String>{};
  final Set<String> _loggedLargeImages = <String>{};

  // Custom cache manager with optimized settings
  CacheManager? _cacheManager;
  bool _isInitialized = false;

  /// Get the cache manager (public accessor)
  CacheManager? get cacheManager => _cacheManager;

  /// Check if we're in a test environment
  bool get _isTestEnvironment {
    // Only skip in actual test environments, not debug mode
    return const bool.fromEnvironment('FLUTTER_TEST') ||
        (Zone.current[#test] != null);
  }

  /// Initialize the image management service
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.info(
        '🖼️ ImageManagementService already initialized, skipping',
      );
      return;
    }

    AppLogger.info('🖼️ ImageManagementService initializing...');
    AppLogger.info('🖼️ Is test environment: $_isTestEnvironment');

    // Skip cache manager initialization in test environments
    if (_isTestEnvironment) {
      debugPrint(
        '🖼️ ImageManagementService skipping cache manager in test environment',
      );
      _isInitialized = true;
      return;
    }

    AppLogger.info('🖼️ ImageManagementService initializing cache manager...');

    // Configure global image cache limits
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.maximumSizeBytes = maxCacheSize * 1024 * 1024;
    imageCache.maximumSize = 500; // Match maxNrOfCacheObjects

    _cacheManager = CacheManager(
      Config(
        'artbeat_optimized_cache',
        stalePeriod: cacheDuration,
        maxNrOfCacheObjects:
            500, // Increased from 200 for better global caching
      ),
    );

    _isInitialized = true;
    AppLogger.info(
      '🖼️ ImageManagementService initialized with cache manager: ${_cacheManager != null}',
    );
    AppLogger.analytics('📊 Max concurrent loads: $maxConcurrentLoads');
    AppLogger.info('💾 Cache duration: ${cacheDuration.inDays} days');
  }

  /// Get an optimized image widget with proper buffer management and Firebase Storage auth
  Widget getOptimizedImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    bool isProfile = false,
    bool isThumbnail = false,
    Widget? placeholder,
    Widget? errorWidget,
    bool enableMemoryCache = true,
    bool enableDiskCache = true,
    bool useSecureLoading = true,
  }) {
    // Determine optimal dimensions
    int? memCacheWidth;
    int? memCacheHeight;

    if (isProfile) {
      memCacheWidth = profileImageSize;
      memCacheHeight = profileImageSize;
    } else if (isThumbnail) {
      memCacheWidth = thumbnailSize;
      memCacheHeight = thumbnailSize;
    } else if (width != null && height != null) {
      // Guard against NaN, Infinity, or negative values
      if (width.isFinite && !width.isNaN && width > 0) {
        memCacheWidth = width.toInt();
      } else {
        memCacheWidth = thumbnailSize; // fallback
      }
      if (height.isFinite && !height.isNaN && height > 0) {
        memCacheHeight = height.toInt();
      } else {
        memCacheHeight = thumbnailSize; // fallback
      }
    }

    _logLargeDecode(imageUrl, memCacheWidth, memCacheHeight, width, height);

    // Guard against invalid URLs that crash CachedNetworkImage
    final uri = Uri.tryParse(imageUrl);
    final isValidNetworkUrl =
        uri != null && uri.hasScheme && uri.host.isNotEmpty;

    // Debug: Print URL validation info
    AppLogger.info('🖼️ ImageManagementService validating URL: $imageUrl');
    AppLogger.info('🖼️ URI parsed: $uri');
    AppLogger.info('🖼️ Has scheme: ${uri?.hasScheme}');
    AppLogger.info('🖼️ Host: ${uri?.host}');
    AppLogger.network('🖼️ Is valid network URL: $isValidNetworkUrl');

    // More permissive validation - allow any non-empty URL that looks like it might be a network URL
    final isLikelyValidUrl =
        imageUrl.isNotEmpty &&
        (isValidNetworkUrl ||
            imageUrl.startsWith('http') ||
            imageUrl.contains('firebasestorage'));

    if (!isLikelyValidUrl) {
      AppLogger.error('🖼️ URL failed validation, showing error widget');
      // Fallback placeholder/error container without network call
      return Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: errorWidget ?? _buildErrorWidget(width, height),
      );
    }

    // Use secure loading for Firebase Storage URLs or when explicitly requested
    final isFirebaseStorageUrl = imageUrl.contains(
      'firebasestorage.googleapis.com',
    );
    if (useSecureLoading && isFirebaseStorageUrl) {
      return SecureNetworkImage(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: placeholder ?? _buildPlaceholder(width, height),
        errorWidget: errorWidget ?? _buildErrorWidget(width, height),
        enableThumbnailFallback:
            true, // Enable fallback to thumbnails and path corrections
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      cacheManager: _cacheManager,
      placeholder: placeholder != null
          ? (context, url) => placeholder
          : (context, url) => _buildPlaceholder(width, height),
      errorWidget: errorWidget != null
          ? (context, url, error) => errorWidget
          : (context, url, error) => _buildErrorWidget(width, height),
      fadeInDuration: const Duration(milliseconds: 200),
      fadeOutDuration: const Duration(milliseconds: 100),
      useOldImageOnUrlChange: true,
      cacheKey: _generateCacheKey(imageUrl, memCacheWidth, memCacheHeight),
      // Note: maxWidthDiskCache and maxHeightDiskCache removed as they require ImageCacheManager
    );
  }

  /// Acquire a slot for image loading to prevent head-of-line blocking
  Future<void> acquireLoadSlot() async {
    if (_activeLoads < maxConcurrentLoads) {
      _activeLoads++;
      return;
    }

    final completer = Completer<void>();
    _queue.add(completer);
    return completer.future;
  }

  /// Release a load slot and process next in queue
  void releaseLoadSlot() {
    _activeLoads--;
    if (_queue.isNotEmpty && _activeLoads < maxConcurrentLoads) {
      _activeLoads++;
      final completer = _queue.removeAt(0);
      completer.complete();
    }
  }

  /// Load image with queue management to prevent buffer overflow
  /// DEPRECATED: Use acquireLoadSlot and releaseLoadSlot instead
  Future<void> loadImageWithQueue(
    String imageUrl,
    VoidCallback onComplete,
  ) async {
    await acquireLoadSlot();

    // Check if already loading
    if (_loadingUrls.contains(imageUrl)) {
      AppLogger.info('🔄 Image already loading: $imageUrl');
      releaseLoadSlot();
      onComplete();
      return;
    }

    // Add to loading set
    _loadingUrls.add(imageUrl);
    _executeLoad(imageUrl, onComplete);
  }

  /// Execute image load with proper resource management
  void _executeLoad(String imageUrl, VoidCallback onComplete) {
    debugPrint(
      '🔄 Loading image ($_activeLoads/$maxConcurrentLoads): $imageUrl',
    );

    // Preload the image
    if (_cacheManager != null) {
      _cacheManager!
          .getSingleFile(imageUrl)
          .then((file) {
            AppLogger.info('✅ Image loaded successfully: $imageUrl');
            _completeLoad(imageUrl, onComplete);
          })
          .catchError((dynamic error) {
            AppLogger.error('❌ Image load failed: $imageUrl - $error');
            _completeLoad(imageUrl, onComplete);
          });
    } else {
      // In test environments where cache manager is not available,
      // simulate successful load completion
      AppLogger.info('✅ Image loaded successfully (simulated): $imageUrl');
      _completeLoad(imageUrl, onComplete);
    }
  }

  /// Complete image load and process queue
  void _completeLoad(String imageUrl, VoidCallback onComplete) {
    _loadingUrls.remove(imageUrl);
    releaseLoadSlot();
    onComplete();
  }

  /// Generate cache key for image with dimensions
  String _generateCacheKey(String imageUrl, int? width, int? height) {
    if (width != null && height != null) {
      return '${imageUrl}_${width}x$height';
    }
    return imageUrl;
  }

  /// Build placeholder widget
  Widget _buildPlaceholder(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  /// Build error widget
  Widget _buildErrorWidget(double? width, double? height) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[100],
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 24),
      ),
    );
  }

  /// Preload critical images
  Future<void> preloadCriticalImages(List<String> imageUrls) async {
    AppLogger.info('🔄 Preloading ${imageUrls.length} critical images');

    if (_cacheManager == null) {
      // In test environments, just return without doing anything
      AppLogger.info('🖼️ Skipping preload in test environment');
      return;
    }

    for (final url in imageUrls.take(maxConcurrentLoads)) {
      if (!_loadingUrls.contains(url)) {
        _cacheManager!.getSingleFile(url).catchError((dynamic error) {
          AppLogger.error('❌ Preload failed for: $url');
          throw error as Object;
        });
      }
    }
  }

  /// Clear old cache entries
  Future<void> clearOldCache() async {
    try {
      await _cacheManager?.emptyCache();
      AppLogger.info('🧹 Image cache cleared');
    } catch (e) {
      AppLogger.error('❌ Error clearing cache: $e');
    }
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getCacheStats() async {
    try {
      return {
        'fileCount': 0, // Directory access not available
        'totalSize': 0,
        'totalSizeMB': '0.00',
        'activeLoads': _activeLoads,
        'queuedLoads': _queue.length,
      };
    } catch (e) {
      AppLogger.error('❌ Error getting cache stats: $e');
      return {
        'error': e.toString(),
        'activeLoads': _activeLoads,
        'queuedLoads': _queue.length,
      };
    }
  }

  /// Log in-memory cache stats (debug/profile only)
  void logCacheStats({String label = 'image_cache'}) {
    if (kReleaseMode) return;
    final cache = PaintingBinding.instance.imageCache;
    final stats = {
      'label': label,
      'entries': cache.currentSize,
      'bytes': cache.currentSizeBytes,
      'maxEntries': cache.maximumSize,
      'maxBytes': cache.maximumSizeBytes,
      'activeLoads': _activeLoads,
      'queuedLoads': _queue.length,
    };
    developer.Timeline.instantSync('Image.CacheStats', arguments: stats);
    AppLogger.info(
      '🖼️ Cache stats [$label] entries=${cache.currentSize}/${cache.maximumSize} '
      'bytes=${cache.currentSizeBytes}/${cache.maximumSizeBytes} '
      'active=${_activeLoads} queued=${_queue.length}',
    );
  }

  void _logLargeDecode(
    String imageUrl,
    int? memCacheWidth,
    int? memCacheHeight,
    double? width,
    double? height,
  ) {
    if (kReleaseMode) return;
    if (_loggedLargeImages.contains(imageUrl)) return;

    final decodeWidth = memCacheWidth ?? _safeRoundedDimension(width);
    final decodeHeight = memCacheHeight ?? _safeRoundedDimension(height);
    if (decodeWidth == null || decodeHeight == null) return;

    final pixels = decodeWidth * decodeHeight;
    if (decodeWidth < largeImageDimensionThreshold &&
        decodeHeight < largeImageDimensionThreshold &&
        pixels < largeImagePixelThreshold) {
      return;
    }

    _loggedLargeImages.add(imageUrl);
    developer.Timeline.instantSync(
      'Image.LargeDecode',
      arguments: {
        'width': decodeWidth,
        'height': decodeHeight,
        'pixels': pixels,
      },
    );
    AppLogger.warning(
      '⚠️ Large decode requested: ${decodeWidth}x${decodeHeight} '
      '(${(pixels / 1000000).toStringAsFixed(1)}MP)',
    );
  }

  /// Log decode size request for UI instrumentation
  void logDecodeDimensions({
    required String label,
    double? width,
    double? height,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    if (kReleaseMode) return;
    final decodeWidth = cacheWidth ?? _safeRoundedDimension(width);
    final decodeHeight = cacheHeight ?? _safeRoundedDimension(height);
    if (decodeWidth == null || decodeHeight == null) return;
    if (decodeWidth <= 0 || decodeHeight <= 0) return;

    final pixels = decodeWidth * decodeHeight;
    developer.Timeline.instantSync(
      'Image.DecodeSize',
      arguments: {
        'label': label,
        'width': decodeWidth,
        'height': decodeHeight,
        'pixels': pixels,
      },
    );
    AppLogger.debug(
      '🖼️ Decode request "$label": ${decodeWidth}x${decodeHeight} '
      '(${(pixels / 1000000).toStringAsFixed(1)}MP)',
    );
  }

  int? _safeRoundedDimension(double? value) {
    if (value == null) return null;
    if (!value.isFinite) return null;
    final rounded = value.round();
    if (rounded <= 0) return null;
    return rounded;
  }

  /// Dispose of resources
  void dispose() {
    _queue.clear();
    _loadingUrls.clear();
    _activeLoads = 0;
  }
}
