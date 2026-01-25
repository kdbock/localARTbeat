import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/artwork_model.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

/// Service for cleaning up artwork data inconsistencies
class ArtworkCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Find and fix artwork with broken image URLs
  Future<void> cleanupBrokenArtworkImages({bool dryRun = true}) async {
    if (!kDebugMode) {
      AppLogger.warning('⚠️ Cleanup service only runs in debug mode');
      return;
    }

    AppLogger.debug('🔍 Starting artwork image cleanup (dryRun: $dryRun)...');

    try {
      // Get all artwork documents
      final snapshot = await _firestore.collection('artwork').get();

      final int totalArtwork = snapshot.docs.length;
      int brokenImages = 0;
      int fixedImages = 0;

      AppLogger.analytics('📊 Found $totalArtwork artwork documents to check');

      for (final doc in snapshot.docs) {
        try {
          final artwork = ArtworkModel.fromFirestore(doc);

          // Check if image URL is accessible
          final isAccessible = await _checkImageUrl(artwork.imageUrl);

          if (!isAccessible) {
            brokenImages++;
            AppLogger.error('❌ Broken image found:');
            AppLogger.info('   - ID: ${artwork.id}');
            AppLogger.info('   - Title: ${artwork.title}');
            AppLogger.info('   - Artist: ${artwork.userId}');
            AppLogger.info('   - URL: ${artwork.imageUrl}');

            if (!dryRun) {
              // Option 1: Set a placeholder image
              await _fixBrokenArtworkImage(doc.id, artwork);
              fixedImages++;
              AppLogger.info('✅ Fixed broken image for artwork ${artwork.id}');
            }
          } else {
            AppLogger.info('✅ Image OK: ${artwork.title}');
          }
        } catch (e) {
          AppLogger.error('❌ Error checking artwork ${doc.id}: $e');
        }
      }

      AppLogger.analytics('📊 Cleanup Summary:');
      AppLogger.info('   - Total artwork: $totalArtwork');
      AppLogger.info('   - Broken images: $brokenImages');
      AppLogger.info('   - Fixed images: $fixedImages');
      AppLogger.info('   - Dry run: $dryRun');
    } catch (e) {
      AppLogger.error('❌ Error during cleanup: $e');
    }
  }

  /// Check if an image URL is accessible
  Future<bool> _checkImageUrl(String imageUrl) async {
    try {
      final response = await http.head(Uri.parse(imageUrl));
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('❌ Image check failed for $imageUrl: $e');
      return false;
    }
  }

  /// Fix broken artwork image by setting a placeholder
  Future<void> _fixBrokenArtworkImage(
    String artworkId,
    ArtworkModel artwork,
  ) async {
    try {
      // Instead of using an external placeholder, we'll use a local asset or remove the image
      // For now, we'll set it to empty and mark it as needing a new image
      await _firestore.collection('artwork').doc(artworkId).update({
        'imageUrl': '', // Clear the broken URL
        'updatedAt': FieldValue.serverTimestamp(),
        'hasPlaceholderImage': true, // Flag to indicate this needs a new image
        'needsNewImage': true, // Additional flag for UI handling
        'originalBrokenUrl': artwork.imageUrl, // Keep reference to broken URL
      });

      AppLogger.info('✅ Cleared broken image URL for artwork $artworkId');
    } catch (e) {
      AppLogger.error('❌ Error fixing artwork $artworkId: $e');
      rethrow;
    }
  }

  /// Remove artwork with broken images (more aggressive cleanup)
  Future<void> removeBrokenArtwork({bool dryRun = true}) async {
    if (!kDebugMode) {
      AppLogger.warning('⚠️ Remove broken artwork only runs in debug mode');
      return;
    }

    AppLogger.info(
      '🗑️ Starting removal of broken artwork (dryRun: $dryRun)...',
    );

    try {
      final snapshot = await _firestore.collection('artwork').get();

      final int totalArtwork = snapshot.docs.length;
      int brokenArtwork = 0;
      int removedArtwork = 0;

      for (final doc in snapshot.docs) {
        try {
          final artwork = ArtworkModel.fromFirestore(doc);
          final isAccessible = await _checkImageUrl(artwork.imageUrl);

          if (!isAccessible) {
            brokenArtwork++;
            debugPrint(
              '❌ Would remove broken artwork: ${artwork.title} (${artwork.id})',
            );

            if (!dryRun) {
              await doc.reference.delete();
              removedArtwork++;
              AppLogger.info('🗑️ Removed broken artwork ${artwork.id}');
            }
          }
        } catch (e) {
          AppLogger.error('❌ Error checking artwork ${doc.id}: $e');
        }
      }

      AppLogger.analytics('📊 Removal Summary:');
      AppLogger.info('   - Total artwork: $totalArtwork');
      AppLogger.info('   - Broken artwork: $brokenArtwork');
      AppLogger.info('   - Removed artwork: $removedArtwork');
      AppLogger.info('   - Dry run: $dryRun');
    } catch (e) {
      AppLogger.error('❌ Error during removal: $e');
    }
  }

  /// Quick check for the specific problematic image
  Future<void> checkSpecificImage() async {
    const problematicUrl =
        'https://firebasestorage.googleapis.com/v0/b/wordnerd-artbeat.firebasestorage.app/o/artwork_images%2FEdH8MvWk4Ja6eoSZM59QtOaxEK43%2Fnew%2F1750961590495_EdH8MvWk4Ja6eoSZM59QtOaxEK43?alt=media&token=d9e1ed0b-e106-44e3-a9d4-5da43d0ff045';

    AppLogger.debug('🔍 Checking specific problematic image...');

    try {
      // Find artwork with this specific URL
      final snapshot = await _firestore
          .collection('artwork')
          .where('imageUrl', isEqualTo: problematicUrl)
          .get();

      AppLogger.analytics(
        '📊 Found ${snapshot.docs.length} artwork with this URL',
      );

      for (final doc in snapshot.docs) {
        final artwork = ArtworkModel.fromFirestore(doc);
        AppLogger.error('❌ Problematic artwork:');
        AppLogger.info('   - ID: ${artwork.id}');
        AppLogger.info('   - Title: ${artwork.title}');
        AppLogger.info('   - Artist: ${artwork.userId}');
        AppLogger.info('   - Created: ${artwork.createdAt}');

        // Check if image is accessible
        final isAccessible = await _checkImageUrl(problematicUrl);
        AppLogger.info('   - Image accessible: $isAccessible');

        // If image is not accessible, fix it immediately
        if (!isAccessible) {
          AppLogger.info('🔧 Fixing broken image for artwork ${artwork.id}...');
          await _fixBrokenArtworkImage(doc.id, artwork);
          AppLogger.info('✅ Fixed broken image for artwork ${artwork.id}');
        }
      }
    } catch (e) {
      AppLogger.error('❌ Error checking specific image: $e');
    }
  }
}
