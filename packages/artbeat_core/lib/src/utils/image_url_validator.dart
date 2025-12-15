import 'package:flutter/material.dart';

/// Utility class for validating image URLs before using with NetworkImage
class ImageUrlValidator {
  /// Validates if an image URL is safe to use with NetworkImage
  ///
  /// Returns true if the URL is valid and can be used with NetworkImage,
  /// false otherwise.
  ///
  /// This prevents the common error:
  /// "Invalid argument(s): No host specified in URI file:///"
  static bool isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;

    final trimmedUrl = url.trim();

    // Check for common invalid patterns that cause NetworkImage errors
    if (trimmedUrl == 'file:///' ||
        trimmedUrl == '' ||
        trimmedUrl == 'null' ||
        trimmedUrl == 'undefined') {
      return false;
    }

    // Basic URL validation - should start with http:// or https://
    return trimmedUrl.startsWith('http://') ||
        trimmedUrl.startsWith('https://');
  }

  /// Creates a safe NetworkImage with error handling
  ///
  /// Returns a NetworkImage if the URL is valid, or null if invalid.
  /// Use this when you need to conditionally create a NetworkImage.
  static NetworkImage? safeNetworkImage(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmedUrl = url.trim();
    return isValidImageUrl(trimmedUrl) ? NetworkImage(trimmedUrl) : null;
  }

  /// Creates a corrected NetworkImage for old artwork paths
  ///
  /// Automatically corrects 'artwork/' paths to 'artwork_images/' paths
  /// to handle legacy Firebase Storage URLs.
  static NetworkImage? safeCorrectedNetworkImage(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final trimmedUrl = url.trim();
    if (!isValidImageUrl(trimmedUrl)) {
      return null;
    }

    final correctedUrl = _generateCorrectedArtworkUrl(trimmedUrl);
    return NetworkImage(correctedUrl);
  }

  /// Generate corrected URL from old artwork path to new artwork_images path
  static String _generateCorrectedArtworkUrl(String originalUrl) {
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
      // If correction fails, return original URL
      return originalUrl;
    }
  }
}
