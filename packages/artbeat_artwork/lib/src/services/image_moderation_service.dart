// filepath: /Users/kristybock/artbeat/packages/artbeat_artwork/lib/src/services/image_moderation_service.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;

class ImageModerationService {
  final String apiKey;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  ImageModerationService({required this.apiKey});

  // Check if image is appropriate using third-party API
  Future<Map<String, dynamic>> checkImage(File imageFile) async {
    try {
      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Call API (using placeholder API for demonstration)
      final response = await http.post(
        Uri.parse('https://api.moderatecontent.com/moderate'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Api-Key $apiKey',
        },
        body: jsonEncode({'image_base64': base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        // Log the moderation result
        await _logModerationResult(data, bytes.length);

        // Return formatted result
        return {
          'isAppropriate':
              data['rating_index'] <
              2, // 0-1 are appropriate, 2+ are inappropriate
          'confidence': data['rating_confidence'],
          'classification': data['rating_label'],
          'details': data,
        };
      } else {
        AppLogger.error('API error: ${response.statusCode} - ${response.body}');
        return {
          'isAppropriate': true, // Fail open - allow if API fails
          'confidence': 0,
          'classification': 'unknown',
          'error': 'API error: ${response.statusCode}',
        };
      }
    } catch (e) {
      AppLogger.error('Image moderation error: $e');
      return {
        'isAppropriate': true, // Fail open - allow if error occurs
        'confidence': 0,
        'classification': 'error',
        'error': e.toString(),
      };
    }
  }

  // Log moderation results for audit and improvement
  Future<void> _logModerationResult(
    Map<String, dynamic> result,
    int imageSize,
  ) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('moderation_logs').add({
        'userId': userId,
        'timestamp': FieldValue.serverTimestamp(),
        'result': result,
        'imageSize': imageSize,
      });
    } catch (e) {
      AppLogger.error('Error logging moderation result: $e');
    }
  }

  // Check batch of images
  Future<List<Map<String, dynamic>>> checkMultipleImages(
    List<File> images,
  ) async {
    final results = <Map<String, dynamic>>[];
    for (final image in images) {
      final result = await checkImage(image);
      results.add(result);

      // If any image is inappropriate, can return early
      if (!(result['isAppropriate'] as bool)) {
        break;
      }
    }
    return results;
  }
}
