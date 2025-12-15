import 'package:flutter/material.dart';

/// Utility class for safe image loading in admin screens
class ImageUtils {
  /// Creates a safe NetworkImage provider that handles null/empty URLs
  static ImageProvider? safeNetworkImage(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null;
    }
    final trimmedUrl = url.trim();
    if (Uri.tryParse(trimmedUrl)?.hasScheme != true) {
      return null;
    }
    // Additional check for valid HTTP/HTTPS scheme
    if (!trimmedUrl.startsWith('http://') &&
        !trimmedUrl.startsWith('https://')) {
      return null;
    }
    return NetworkImage(trimmedUrl);
  }

  /// Creates a safe Image.network widget with proper error handling
  static Widget safeNetworkImageWidget(
    String? url, {
    double? width,
    double? height,
    BoxFit? fit,
    Widget? errorWidget,
    Widget? placeholder,
  }) {
    if (url == null ||
        url.trim().isEmpty ||
        Uri.tryParse(url)?.hasScheme != true) {
      return errorWidget ?? placeholder ?? const SizedBox.shrink();
    }

    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Icon(
              Icons.broken_image,
              size: width ?? height ?? 40,
              color: Colors.grey,
            );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            SizedBox(
              width: width ?? 40,
              height: height ?? 40,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },
    );
  }

  /// Creates a safe CircleAvatar with network image
  static Widget safeCircleAvatar({
    required String? imageUrl,
    required String fallbackText,
    double radius = 20,
    Color? backgroundColor,
  }) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor,
      backgroundImage: safeNetworkImage(imageUrl),
      child: (imageUrl == null || imageUrl.trim().isEmpty)
          ? Text(
              fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: radius * 0.6,
                fontWeight: FontWeight.bold,
              ),
            )
          : null,
    );
  }
}
