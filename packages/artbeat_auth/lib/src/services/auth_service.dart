import 'dart:convert';
import 'dart:math';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import './fresh_apple_signin.dart';

/// Authentication service for handling user authentication
class AuthService {
  late FirebaseAuth _auth;
  late FirebaseFirestore _firestore;
  static Future<void>? _googleSignInInitialization;

  /// Initialize Google Sign-In with proper error handling
  /// Now uses the singleton instance in 7.x
  gsi.GoogleSignIn get _googleSignIn => gsi.GoogleSignIn.instance;

  /// Constructor with optional dependencies for testing
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore}) {
    _auth = auth ?? FirebaseAuth.instance;
    _firestore = firestore ?? FirebaseFirestore.instance;
    // Note: initialize is now async, so we trigger it here
    // but individual methods will also ensure it's ready
    _initializeGoogleSignIn();
  }

  /// For dependency injection in tests (deprecated - use constructor)
  @deprecated
  void setDependenciesForTesting(
    FirebaseAuth auth,
    FirebaseFirestore firestore,
  ) {
    _auth = auth;
    _firestore = firestore;
  }

  /// Get the current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Get the current authenticated user (async)
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// Check if user is logged in
  bool get isLoggedIn => currentUser != null;

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Register with email, password, and name
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String fullName, {
    String? zipCode, // Optional - captured from location on-demand
  }) async {
    try {
      AppLogger.info('📝 Starting registration for email: $email');

      // Create user with email and password
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = userCredential.user?.uid;
      AppLogger.auth('✅ Authentication account created with UID: $uid');

      // Set display name
      await userCredential.user?.updateDisplayName(fullName);
      AppLogger.info('✅ Display name set to: $fullName');

      try {
        // Create user document in Firestore
        await _firestore.collection('users').doc(uid).set({
          'id': uid,
          'fullName': fullName,
          'email': email,
          'zipCode': zipCode ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userType': 'regular',
          'posts': <String>[],
          'followers': <String>[],
          'following': <String>[],
          'captures': <String>[],
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
          'capturesCount': 0,
          'isVerified': false,
        }, SetOptions(merge: true));

        AppLogger.info('✅ User document created in Firestore');
      } catch (firestoreError) {
        debugPrint(
          '❌ Failed to create user document in Firestore: $firestoreError',
        );
        // Continue to return the userCredential even if Firestore fails
        // The RegisterScreen will attempt to create the document as a fallback
      }

      return userCredential;
    } catch (e) {
      AppLogger.error('❌ Error in registerWithEmailAndPassword: $e');
      rethrow;
    }
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  /// Listen to auth state changes
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  /// Send email verification to current user
  Future<void> sendEmailVerification() async {
    try {
      final user = currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        AppLogger.info('✅ Email verification sent to ${user.email}');
      } else if (user?.emailVerified == true) {
        AppLogger.info('ℹ️ Email already verified');
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      AppLogger.error('❌ Error sending email verification: $e');
      rethrow;
    }
  }

  /// Check if current user's email is verified
  bool get isEmailVerified => currentUser?.emailVerified ?? false;

  /// Reload current user to get updated verification status
  Future<void> reloadUser() async {
    try {
      await currentUser?.reload();
      AppLogger.info('✅ User data reloaded');
    } catch (e) {
      AppLogger.error('❌ Error reloading user: $e');
      rethrow;
    }
  }

  /// Constructor with dependencies - ensures Google Sign-In is properly initialized
  Future<void> _initializeGoogleSignIn() async {
    final existingInitialization = _googleSignInInitialization;
    if (existingInitialization != null) {
      return existingInitialization;
    }

    final initialization = _googleSignIn
        .initialize()
        .then((_) {
          AppLogger.info('✅ Google Sign-In initialized');
        })
        .catchError((Object e, StackTrace st) {
          // Reset so a future attempt can re-try initialization.
          _googleSignInInitialization = null;
          AppLogger.error('⚠️ Error initializing Google Sign-In: $e', error: e);
          throw e;
        });

    _googleSignInInitialization = initialization;
    return initialization;
  }

  /// Sign in with Google
  /// This method includes comprehensive error handling to prevent native crashes
  /// in SignInHubActivity when configuration is missing
  Future<UserCredential> signInWithGoogle() async {
    try {
      AppLogger.info('🔄 Starting Google Sign-In process');

      // Pre-validate that we can proceed with Google Sign-In
      try {
        // Ensure initialized
        await _initializeGoogleSignIn();

        // Check if user is already signed in
        final event = await _googleSignIn.attemptLightweightAuthentication();
        if (event is gsi.GoogleSignInAuthenticationEventSignIn) {
          // Sign out first to get fresh credentials
          await _googleSignIn.signOut();
          AppLogger.info('ℹ️ Previous Google Sign-In session cleared');
        }
      } catch (e) {
        AppLogger.warning('Could not check Google Sign-In status: $e');
      }

      // Trigger the authentication flow with error handling
      // Returns a GoogleSignInAccount directly in 7.x authenticate()
      final googleUser = await _googleSignIn.authenticate();

      AppLogger.info('✅ Google Sign-In successful for: ${googleUser.email}');

      // Obtain the auth details (contains idToken)
      final googleAuth = await googleUser.authentication;

      // Obtain the authorization details (contains accessToken)
      // In 7.x, authentication and authorization are separate steps
      var clientAuth = await googleUser.authorizationClient
          .authorizationForScopes(['email', 'profile']);

      // If not already authorized, request scopes
      if (clientAuth == null) {
        AppLogger.info('🔄 Requesting authorization scopes for accessToken');
        clientAuth = await googleUser.authorizationClient.authorizeScopes([
          'email',
          'profile',
        ]);
      }

      final accessToken = clientAuth.accessToken;
      final idToken = googleAuth.idToken;

      // Validate we have required tokens
      if (accessToken.isEmpty || idToken == null) {
        AppLogger.error('Google authentication tokens are missing');
        throw Exception('Invalid Google authentication tokens received');
      }

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );

      // Sign in to Firebase with the Google credential
      UserCredential userCredential;
      try {
        userCredential = await _auth.signInWithCredential(credential);
      } catch (e) {
        AppLogger.error('Firebase sign-in with Google credential failed: $e');
        throw Exception('Failed to sign in to Firebase with Google account');
      }

      AppLogger.auth(
        '✅ Google Sign-In and Firebase authentication successful: ${userCredential.user?.uid}',
      );

      // Update Firebase user's displayName with Google profile name
      if (userCredential.user != null && googleUser.displayName != null) {
        try {
          await userCredential.user!.updateDisplayName(googleUser.displayName!);
          AppLogger.info(
            '✅ Display name set from Google profile: ${googleUser.displayName}',
          );
        } catch (e) {
          AppLogger.warning('⚠️ Could not update display name: $e');
        }
      }

      // Create user document if this is first sign-in
      await _createSocialUserDocument(userCredential.user!);

      return userCredential;
    } on gsi.GoogleSignInException catch (e) {
      final description = e.description ?? '';
      if (description.contains('No credential available')) {
        throw Exception(
          'Google Sign-In could not find a usable credential on this device. '
          'On emulator, add a Google account and verify Firebase OAuth SHA-1 '
          'for this debug keystore.',
        );
      }
      AppLogger.error('❌ Google Sign-In failed: $e', error: e);
      rethrow;
    } catch (e) {
      AppLogger.error('❌ Google Sign-In failed: $e', error: e);
      rethrow;
    }
  }

  /// Fresh Apple Sign-In that bypasses all Firebase configuration issues
  Future<User> signInWithAppleFresh() async {
    return FreshAppleSignIn.signInFresh();
  }

  /// Sign in with Apple using simplified app-only flow
  /// This method bypasses web authentication to avoid domain verification issues
  Future<User> signInWithAppleSimple() async {
    return FreshAppleSignIn.signInFresh();
  }

  /// Sign in with Apple
  /// Improved with better error handling and timeout protection
  Future<UserCredential> signInWithApple() async {
    try {
      AppLogger.info('🔄 Starting Apple Sign-In process');

      // Validate that Apple Sign-In is available on this platform
      if (!await SignInWithApple.isAvailable()) {
        AppLogger.error('❌ Apple Sign-In is not available on this device');
        throw Exception(
          'Apple Sign-In is not available on this device. Please use email sign-in instead.',
        );
      }

      // Generate a random nonce
      final rawNonce = _generateNonce();
      final nonce = sha256.convert(utf8.encode(rawNonce)).toString();
      AppLogger.debug(
        '🔐 Generated nonce for Apple Sign-In: ${nonce.substring(0, 8)}...',
      );

      // Request credential for the currently signed in Apple account with timeout
      AuthorizationCredentialAppleID? appleCredential;
      try {
        AppLogger.debug('🔄 Requesting Apple ID credential...');
        final webAuthOptions = kIsWeb
            ? WebAuthenticationOptions(
                clientId: 'com.wordnerd.artbeat',
                redirectUri: Uri.parse(
                  'https://wordnerd-artbeat.firebaseapp.com/__/auth/handler',
                ),
              )
            : null;
        appleCredential =
            await SignInWithApple.getAppleIDCredential(
              scopes: [
                AppleIDAuthorizationScopes.email,
                AppleIDAuthorizationScopes.fullName,
              ],
              nonce: nonce,
              // Web auth options are only required for web flows.
              webAuthenticationOptions: webAuthOptions,
            ).timeout(
              const Duration(
                seconds: 45,
              ), // Increased timeout for Apple servers
              onTimeout: () {
                AppLogger.error('❌ Apple Sign-In timeout after 45 seconds');
                throw TimeoutException(
                  'Apple Sign-In request timed out. Please check your network connection and try again.',
                );
              },
            );
      } on TimeoutException {
        rethrow;
      } catch (e) {
        AppLogger.error('❌ Apple ID credential request failed: $e');

        final errorString = e.toString();

        // Handle user cancellation
        if (errorString.contains('canceled') ||
            errorString.contains('cancelled')) {
          throw Exception('Apple Sign-In was cancelled by user.');
        }

        // Handle specific Apple error codes
        if (errorString.contains('-7091')) {
          AppLogger.error(
            '🔴 Apple Error -7091: Configuration mismatch detected',
          );
          AppLogger.error(
            '💡 This error typically means domain verification is incomplete',
          );
          AppLogger.info('🔄 Attempting fallback with app-only flow...');

          // Since our fresh Apple Sign-In works, just throw a more helpful error
          throw Exception(
            'Apple Sign-In configuration error (-7091). Please use the "Sign in with Apple" button which uses a more reliable method.',
          );
        }

        if (errorString.contains('-7090')) {
          throw Exception(
            'Apple Sign-In capability error (-7090). Apple Sign-In capability may not be enabled for this App ID.',
          );
        }

        if (errorString.contains('-7092')) {
          throw Exception(
            'Apple Sign-In network error (-7092). Please check your network connection and try again.',
          );
        }

        throw Exception('Failed to get Apple ID credential: $e');
      }

      // Validate that we have the required identity token
      if (appleCredential.identityToken == null ||
          appleCredential.identityToken!.isEmpty) {
        AppLogger.error('❌ Apple Sign-In failed: No identity token received');
        throw Exception(
          'Apple Sign-In failed: Identity token is missing. Please try again.',
        );
      }

      // Validate user identifier exists
      if (appleCredential.userIdentifier == null ||
          appleCredential.userIdentifier!.isEmpty) {
        AppLogger.error('❌ Apple Sign-In failed: No user identifier');
        throw Exception(
          'Apple Sign-In failed: Could not identify user. Please try again.',
        );
      }

      AppLogger.debug('✅ Apple credentials received successfully');
      AppLogger.debug(
        '   - User ID: ${appleCredential.userIdentifier?.substring(0, 8)}...',
      );
      AppLogger.debug('   - Email: ${appleCredential.email ?? "Private"}');
      AppLogger.debug(
        '   - Identity token length: ${appleCredential.identityToken?.length}',
      );

      // Create an OAuth credential from the credential returned by Apple
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken!,
        accessToken: appleCredential.authorizationCode,
        rawNonce: rawNonce,
      );

      AppLogger.debug('✅ OAuth credential created successfully');

      // Sign in to Firebase with the Apple credential with timeout
      UserCredential? userCredential;
      try {
        AppLogger.info('🔄 Sending OAuth credential to Firebase...');
        userCredential = await _auth
            .signInWithCredential(oauthCredential)
            .timeout(
              const Duration(seconds: 45), // Increased timeout for Firebase
              onTimeout: () {
                AppLogger.error('❌ Firebase sign-in timeout after 30 seconds');
                throw TimeoutException(
                  'Firebase authentication timed out. Please check your network connection and try again.',
                );
              },
            );
        AppLogger.info('✅ Firebase sign-in succeeded');
      } on TimeoutException {
        AppLogger.error('❌ Firebase sign-in timeout');
        rethrow;
      } catch (e) {
        AppLogger.error(
          '❌ Firebase sign-in failed - will be handled below: $e',
        );
        rethrow;
      }

      // Validate sign-in returned a user
      if (userCredential.user == null) {
        AppLogger.error('❌ Firebase sign-in returned null user');
        throw Exception('Sign in failed: No user returned. Please try again.');
      }

      AppLogger.auth('✅ Apple Sign-In successful: ${userCredential.user?.uid}');

      // Update Firebase user's displayName with Apple profile name
      try {
        if (userCredential.user != null) {
          final firstName = appleCredential.givenName ?? '';
          final lastName = appleCredential.familyName ?? '';
          final displayName = '$firstName $lastName'.trim();
          if (displayName.isNotEmpty) {
            await userCredential.user?.updateDisplayName(displayName);
            AppLogger.info(
              '✅ Display name set from Apple profile: $displayName',
            );
          }
        }
      } catch (e) {
        AppLogger.warning('⚠️ Could not update display name: $e');
      }

      // Create user document if this is first sign-in
      try {
        await _createSocialUserDocument(
          userCredential.user!,
          appleCredential: appleCredential,
        );
      } catch (e) {
        AppLogger.warning(
          '⚠️ Failed to create user document (non-critical): $e',
        );
        // Don't throw - user is already signed in, document creation is secondary
      }

      return userCredential;
    } on TimeoutException catch (e) {
      AppLogger.error('❌ Apple Sign-In timeout: $e');
      rethrow;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('❌ Firebase Auth Exception - Code: ${e.code}');
      AppLogger.error('❌ Firebase Auth Message: ${e.message}');
      AppLogger.error('❌ Firebase Auth Plugin: ${e.plugin}');

      if (e.code == 'invalid-credential') {
        if (e.message?.contains('invalid OAuth') == true ||
            e.message?.contains('OAuth') == true ||
            e.message?.contains('apple.com') == true) {
          AppLogger.error(
            '🔴 CRITICAL: Apple OAuth validation failed at Firebase',
          );
          AppLogger.error('💡 Configuration checklist - verify the following:');
          AppLogger.error(
            '  1) Firebase Console > Authentication > Sign-in method > Apple provider enabled',
          );
          AppLogger.error(
            '  2) Apple Service ID (com.wordnerd.artbeat) added to Firebase Apple config',
          );
          AppLogger.error(
            '  3) Apple Team ID (H49R32NPY6) matches Firebase config',
          );
          AppLogger.error(
            '  4) Apple Key ID (5G5237Z826) matches Firebase config',
          );
          AppLogger.error(
            '  5) Apple private key uploaded to Firebase correctly',
          );
          AppLogger.error(
            '  6) Bundle ID (com.wordnerd.artbeat) matches Apple Services ID config',
          );
          AppLogger.error(
            '  7) OAuth callback URL (https://wordnerd-artbeat.firebaseapp.com/__/auth/handler) added to Apple config',
          );
          AppLogger.error(
            '  8) Domain verification completed in Apple Developer Console',
          );

          throw Exception(
            'Apple Sign-In configuration error. Please check Firebase and Apple Developer Console settings.',
          );
        }
      }
      rethrow;
    } catch (e) {
      AppLogger.error('❌ Apple Sign-In failed: $e');
      rethrow;
    }
  }

  /// Create user document for social sign-in users
  Future<void> _createSocialUserDocument(
    User user, {
    AuthorizationCredentialAppleID? appleCredential,
  }) async {
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();

      if (!userDoc.exists) {
        // Extract display name
        String displayName = user.displayName ?? '';
        if (displayName.isEmpty && appleCredential != null) {
          final firstName = appleCredential.givenName ?? '';
          final lastName = appleCredential.familyName ?? '';
          displayName = '$firstName $lastName'.trim();
        }
        if (displayName.isEmpty) {
          displayName = 'User'; // Fallback
        }

        // Generate username from display name and email
        final username = _generateUsername(displayName, user.email ?? '');

        await _firestore.collection('users').doc(user.uid).set({
          'id': user.uid,
          'fullName': displayName,
          'username': username,
          'email': user.email ?? '',
          'zipCode': '', // Will be collected later
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'userType': 'regular',
          'posts': <String>[],
          'followers': <String>[],
          'following': <String>[],
          'captures': <String>[],
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
          'capturesCount': 0,
          'isVerified': false,
        }, SetOptions(merge: true));

        AppLogger.info(
          '✅ Social user document created for ${user.uid} with username: $username',
        );
      }
    } catch (e) {
      AppLogger.error('❌ Failed to create social user document: $e');
      // Don't rethrow - continue with authentication even if Firestore fails
    }
  }

  /// Generate a cryptographically secure nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(
      length,
      (_) => charset[random.nextInt(charset.length)],
    ).join();
  }

  /// Generate a username from display name or email
  String _generateUsername(String displayName, String email) {
    final cleanDisplayName = displayName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    String username = cleanDisplayName.length > 15
        ? cleanDisplayName.substring(0, 15)
        : cleanDisplayName;

    if (username.length < 3) {
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
      username = 'user${DateTime.now().millisecondsSinceEpoch % 10000}';
    }

    return username;
  }
}
