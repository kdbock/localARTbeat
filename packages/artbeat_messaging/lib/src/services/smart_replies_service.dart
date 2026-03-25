import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:logging/logging.dart';

/// Service for generating AI-powered smart reply suggestions
class SmartRepliesService {
  FirebaseFirestore? _firestoreInstance;
  FirebaseAuth? _authInstance;
  final Logger _logger = Logger('SmartRepliesService');

  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;
  FirebaseAuth get _auth => _authInstance ??= FirebaseAuth.instance;

  static const String _openaiApiUrl =
      'https://api.openai.com/v1/chat/completions';
  static const String _apiKey =
      'your-openai-api-key-here'; // Should come from config

  /// Generate smart reply suggestions based on the last message in a chat
  Future<List<String>> generateSmartReplies({
    required String chatId,
    int maxSuggestions = 3,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      // Check if user has AI credits
      final canUseAI = await _checkAICredits(user.uid);
      if (!canUseAI) {
        return _getFallbackReplies();
      }

      // Get the last few messages from the chat
      final messagesQuery = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      if (messagesQuery.docs.isEmpty) return [];

      final messages = messagesQuery.docs.reversed.map((doc) {
        final data = doc.data();
        return {
          'text': data['text'] ?? '',
          'senderId': data['senderId'] ?? '',
          'timestamp': data['timestamp'],
        };
      }).toList();

      // Get chat context
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();
      final chatData = chatDoc.data();
      final isGroup = (chatData?['isGroup'] ?? false) as bool;

      // Generate replies using AI
      final replies = await _generateRepliesWithAI(
        messages: messages,
        isGroup: isGroup,
        maxSuggestions: maxSuggestions,
      );

      // Deduct AI credit
      await _deductAICredit(user.uid);

      return replies;
    } catch (e) {
      _logger.severe('Error generating smart replies', e);
      return _getFallbackReplies();
    }
  }

  /// Generate reply suggestions using OpenAI
  Future<List<String>> _generateRepliesWithAI({
    required List<Map<String, dynamic>> messages,
    required bool isGroup,
    required int maxSuggestions,
  }) async {
    try {
      // Build conversation context
      final conversationText = messages
          .map((msg) {
            final isFromCurrentUser = msg['senderId'] == _auth.currentUser?.uid;
            final prefix = isFromCurrentUser
                ? 'You'
                : (isGroup ? 'Other' : 'Friend');
            return '$prefix: ${msg['text']}';
          })
          .join('\n');

      final prompt =
          '''
Based on this conversation, suggest ${maxSuggestions} natural and appropriate reply options.
Consider the context, tone, and relationship.

Conversation:
$conversationText

Please provide ${maxSuggestions} reply suggestions that are:
- Natural and conversational
- Appropriate for the context
- Varied in length and style
- Not generic responses like "Okay" or "Thanks"

Return only the reply suggestions as a JSON array of strings, no other text.
Example: ["That's really interesting!", "I completely agree with you", "Tell me more about that"]
''';

      final response = await http.post(
        Uri.parse(_openaiApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: json.encode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 150,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Parse JSON response
        try {
          final replies = json.decode(content) as List<dynamic>;
          return replies.take(maxSuggestions).map((r) => r.toString()).toList();
        } catch (e) {
          // Fallback: extract replies from text
          final lines = content
              .split('\n')
              .where((line) => line.trim().isNotEmpty)
              .where((line) => !line.contains('[') && !line.contains(']'))
              .map((line) => line.replaceAll(RegExp(r'^[-\d.]+\s*'), '').trim())
              .where((line) => line.isNotEmpty)
              .take(maxSuggestions)
              .toList();
          return lines;
        }
      }

      return _getFallbackReplies();
    } catch (e) {
      _logger.severe('Error calling OpenAI API', e);
      return _getFallbackReplies();
    }
  }

  /// Get fallback reply suggestions when AI is unavailable
  List<String> _getFallbackReplies() {
    return [
      'Thanks for sharing!',
      'That sounds interesting',
      'I agree with you',
      'Tell me more about that',
      'Great to hear from you!',
    ];
  }

  /// Check if user has AI credits available
  Future<bool> _checkAICredits(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();

      if (userData == null) return false;

      // For now, allow unlimited smart replies (can be changed to use subscription limits)
      return true;
    } catch (e) {
      _logger.severe('Error checking AI credits', e);
      return false;
    }
  }

  /// Deduct an AI credit from user's account
  Future<void> _deductAICredit(String userId) async {
    // For now, no credit deduction for smart replies
    // Can be implemented later with subscription-based limits
  }

  /// Check if smart replies are enabled for a user
  Future<bool> isSmartRepliesEnabled(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data();
      return (userData?['smartRepliesEnabled'] as bool?) ??
          true; // Default to enabled
    } catch (e) {
      _logger.severe('Error checking smart replies setting', e);
      return true;
    }
  }

  /// Enable/disable smart replies for a user
  Future<void> setSmartRepliesEnabled(String userId, bool enabled) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'smartRepliesEnabled': enabled,
      });
    } catch (e) {
      _logger.severe('Error updating smart replies setting', e);
    }
  }
}
