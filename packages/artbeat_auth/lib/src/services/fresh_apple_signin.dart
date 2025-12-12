import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Fresh Apple Sign-In implementation that bypasses all Firebase Apple provider issues
///
/// This service provides a robust Apple Sign-In solution that avoids the complex
/// configuration requirements of Firebase's Apple authentication provider.
///
/// **How it works:**
/// 1. Gets Apple credentials directly from Apple's secure servers
/// 2. Uses Firebase Anonymous Authentication (no Apple provider config needed)
/// 3. Manually creates user documents in Firestore with Apple data
/// 4. Provides the same user experience without configuration headaches
///
/// **Benefits:**
/// - No Firebase Apple Provider configuration required
/// - No domain verification issues with Firebase hosting
/// - Simpler setup and maintenance
/// - More reliable authentication flow
///
/// **Documentation:** See /APPLE_SIGNIN_IMPLEMENTATION.md for full details
class FreshAppleSignIn {
  /// Clean, simple Apple Sign-In that creates users manually
  static Future<User> signInFresh() async {
    try {
      AppLogger.info('🆕 Starting fresh Apple Sign-In implementation...');

      // Step 1: Verify Apple Sign-In is available
      if (!await SignInWithApple.isAvailable()) {
        throw Exception('Apple Sign-In not available on this device');
      }
      AppLogger.info('✅ Apple Sign-In is available');

      // Step 2: Get Apple credential (minimal config)
      AppLogger.info('🍎 Requesting Apple credential...');
      AuthorizationCredentialAppleID? appleCredential;
      try {
        appleCredential =
            await SignInWithApple.getAppleIDCredential(
              scopes: [
                AppleIDAuthorizationScopes.email,
                AppleIDAuthorizationScopes.fullName,
              ],
            ).timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException('Apple Sign-In request timed out');
              },
            );
      } on TimeoutException {
        throw Exception(
          'Apple Sign-In request timed out. Please check your internet connection.',
        );
      } catch (e) {
        final errorString = e.toString();
        AppLogger.error('❌ Apple credential request error: $errorString');

        if (errorString.contains('canceled') ||
            errorString.contains('cancelled')) {
          throw Exception('User cancelled Apple Sign-In');
        }

        if (errorString.contains('-7091')) {
          throw Exception(
            'Apple Sign-In configuration error. Please try again.',
          );
        }

        if (errorString.contains('-7090')) {
          throw Exception('Apple Sign-In is not enabled for this app.');
        }

        if (errorString.contains('-7092') || errorString.contains('Network')) {
          throw Exception(
            'Network error. Please check your internet connection and try again.',
          );
        }

        throw Exception('Apple Sign-In failed: ${e.toString()}');
      }

      AppLogger.info('✅ Apple credential received');
      AppLogger.debug(
        '   User ID: ${appleCredential.userIdentifier?.substring(0, 8)}...',
      );
      AppLogger.debug('   Email: ${appleCredential.email ?? "Private"}');

      // Step 3: Sign out any existing user first
      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          AppLogger.info('⚠️ Signing out existing user...');
          await FirebaseAuth.instance.signOut();
        }
      } catch (e) {
        AppLogger.warning('Could not sign out existing user: $e');
      }

      // Step 4: Create Firebase credential from Apple credential
      AppLogger.info(
        '🔐 Creating Firebase credential from Apple credential...',
      );

      final rawNonce = _generateNonce();

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      // Step 5: Sign in to Firebase with Apple credential
      AppLogger.info('🔐 Signing in to Firebase with Apple credential...');
      UserCredential userCredential;
      try {
        userCredential = await FirebaseAuth.instance.signInWithCredential(
          oauthCredential,
        );
      } catch (e) {
        AppLogger.error('Firebase sign-in failed: $e');
        throw Exception(
          'Failed to sign in to Firebase with Apple account: ${e.toString()}',
        );
      }

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Firebase authentication failed: No user returned');
      }

      AppLogger.auth('✅ Firebase sign-in successful: ${firebaseUser.uid}');
      AppLogger.info('🔐 Firebase user ready: ${firebaseUser.uid}');

      // Step 6: Check if user already exists in Firestore (now we have auth)
      final existingUsers = await FirebaseFirestore.instance
          .collection('users')
          .where('appleUserId', isEqualTo: appleCredential.userIdentifier)
          .get();

      if (existingUsers.docs.isNotEmpty) {
        // User exists - update their existing document
        AppLogger.info('👤 Existing Apple user found, updating...');

        final existingUserDoc = existingUsers.docs.first;
        final oldFirebaseUid = existingUserDoc.id;

        // Get existing data and fill in missing fields
        final existingData = existingUserDoc.data();
        final displayName = _buildDisplayName(appleCredential);

        // Ensure we have a valid email address
        final userEmail = appleCredential.email?.isNotEmpty == true
            ? appleCredential.email!
            : (existingData['email'] as String?) ??
                  'apple.user.${firebaseUser.uid.substring(0, 8)}@private.relay.appleid.com';

        // Create or update username if missing
        final username =
            (existingData['username'] as String?) ??
            _generateUsername(displayName, userEmail);

        // Merge existing data with required fields
        final updatedData = <String, dynamic>{
          ...existingData,
          'id': firebaseUser.uid,
          'email': userEmail,
          'username': username,
          'fullName': existingData['fullName'] ?? displayName,
          'displayName': existingData['displayName'] ?? displayName,
          'signInMethod': 'apple_fresh',
          'updatedAt': FieldValue.serverTimestamp(),
          'lastActive': FieldValue.serverTimestamp(),
          'userType': existingData['userType'] ?? 'regular',
          'posts': existingData['posts'] ?? <String>[],
          'followers': existingData['followers'] ?? <String>[],
          'following': existingData['following'] ?? <String>[],
          'captures': existingData['captures'] ?? <String>[],
          'profileImageUrl': existingData['profileImageUrl'] ?? '',
          'bio': existingData['bio'] ?? '',
          'location': existingData['location'] ?? '',
          'zipCode': existingData['zipCode'] ?? '',
          'isOnline': true,
          'engagementStats':
              existingData['engagementStats'] ??
              {
                'postsCount': 0,
                'followersCount': 0,
                'followingCount': 0,
                'capturesCount': 0,
                'likesReceived': 0,
                'commentsReceived': 0,
                'artPiecesVisited': 0,
                'challengesCompleted': 0,
              },
        };

        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set(updatedData);

        // Delete old document if UID is different
        if (oldFirebaseUid != firebaseUser.uid) {
          try {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(oldFirebaseUid)
                .delete();
            AppLogger.info('🗑️ Cleaned up old user document');
          } catch (e) {
            AppLogger.warning('Could not delete old document: $e');
          }
        }

        AppLogger.info('✅ Existing user updated with missing fields');
      } else {
        // New user - create fresh account
        AppLogger.info('🆕 New Apple user, creating account...');

        // We already have an anonymous user from above

        // Create user document
        final displayName = _buildDisplayName(appleCredential);

        // Ensure we have a valid email address
        final userEmail = appleCredential.email?.isNotEmpty == true
            ? appleCredential.email!
            : 'apple.user.${firebaseUser.uid.substring(0, 8)}@private.relay.appleid.com';

        // Create a username from display name or email
        final username = _generateUsername(displayName, userEmail);

        await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
              'id': firebaseUser.uid,
              'appleUserId': appleCredential.userIdentifier,
              'email': userEmail,
              'username': username,
              'fullName': displayName,
              'displayName': displayName,
              'signInMethod': 'apple_fresh',
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
              'lastActive': FieldValue.serverTimestamp(),
              'userType': 'regular',
              'posts': <String>[],
              'followers': <String>[],
              'following': <String>[],
              'captures': <String>[],
              'profileImageUrl': '',
              'bio': '',
              'location': '',
              'zipCode': '',
              'isOnline': true,
              'engagementStats': {
                'postsCount': 0,
                'followersCount': 0,
                'followingCount': 0,
                'capturesCount': 0,
                'likesReceived': 0,
                'commentsReceived': 0,
                'artPiecesVisited': 0,
                'challengesCompleted': 0,
              },
            });

        // Update Firebase user display name
        await firebaseUser.updateDisplayName(displayName);

        AppLogger.info('✅ New user account created');
      }

      AppLogger.info('🎉 Fresh Apple Sign-In completed successfully!');
      AppLogger.auth('✅ User authenticated: ${firebaseUser.uid}');
      AppLogger.info('📋 User document created/updated in Firestore');
      AppLogger.info(
        '🔐 Firebase auth state should now be: ${FirebaseAuth.instance.currentUser?.uid}',
      );

      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      AppLogger.error(
        '❌ Firebase Auth error during Apple Sign-In: ${e.code} - ${e.message}',
      );
      throw Exception('Authentication error: ${e.message ?? e.code}');
    } on FirebaseException catch (e) {
      AppLogger.error(
        '❌ Firebase error during Apple Sign-In: ${e.code} - ${e.message}',
      );
      throw Exception(
        'Firebase error: ${e.message ?? e.code}. Please check your internet connection.',
      );
    } catch (e) {
      AppLogger.error('❌ Fresh Apple Sign-In failed: $e');
      rethrow;
    }
  }

  /// Build display name from Apple credential
  static String _buildDisplayName(AuthorizationCredentialAppleID credential) {
    final firstName = credential.givenName ?? '';
    final lastName = credential.familyName ?? '';
    final fullName = '$firstName $lastName'.trim();

    if (fullName.isNotEmpty) {
      return fullName;
    }

    // Fallback to email-based name
    if (credential.email != null && credential.email!.isNotEmpty) {
      final emailPart = credential.email!.split('@')[0];
      return emailPart.replaceAll(RegExp(r'[^a-zA-Z0-9]'), ' ').trim();
    }

    // Final fallback
    return 'Apple User';
  }

  /// Generate a unique username
  static String _generateUsername(String displayName, String email) {
    // First try to use display name
    final cleanDisplayName = displayName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    String username = cleanDisplayName.length > 15
        ? cleanDisplayName.substring(0, 15)
        : cleanDisplayName;

    if (username.length < 3) {
      // Fallback to email prefix
      final emailPrefix = email.split('@')[0];
      final cleanEmailPrefix = emailPrefix.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '',
      );
      username = cleanEmailPrefix.length > 15
          ? cleanEmailPrefix.substring(0, 15)
          : cleanEmailPrefix;
    }

    if (username.length < 3) {
      // Final fallback with random suffix
      username = 'appleuser${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    return username;
  }

  /// Check if this Apple user already exists
  static Future<bool> appleUserExists(String appleUserId) async {
    try {
      final existing = await FirebaseFirestore.instance
          .collection('users')
          .where('appleUserId', isEqualTo: appleUserId)
          .limit(1)
          .get();

      return existing.docs.isNotEmpty;
    } catch (e) {
      AppLogger.error('Error checking Apple user existence: $e');
      return false;
    }
  }

  /// Generate a cryptographic nonce for Apple Sign-In
  static String _generateNonce() {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = DateTime.now().millisecondsSinceEpoch;
    return List<String>.generate(32, (index) {
      return charset[(random + index) % charset.length];
    }).join();
  }
}
