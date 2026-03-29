import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Service for authentication-related operations
class AuthService {
  static AuthService? _instance;
  FirebaseAuth? _authInstance;

  factory AuthService({FirebaseAuth? auth}) {
    _instance ??= AuthService._internal();
    if (auth != null) {
      _instance!._authInstance = auth;
    }
    return _instance!;
  }

  AuthService._internal();

  void initialize() {
    _authInstance ??= FirebaseAuth.instance;
  }

  FirebaseAuth get _auth {
    initialize();
    return _authInstance!;
  }

  FirebaseAuth get auth => _auth;

  /// Get current authenticated user
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials;
    } catch (e) {
      AppLogger.error('Sign in error: $e');
      rethrow;
    }
  }

  /// Register new user with email and password
  Future<UserCredential> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credentials = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credentials;
    } catch (e) {
      AppLogger.error('Registration error: $e');
      rethrow;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      AppLogger.error('Password reset error: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      AppLogger.error('Sign out error: $e');
      rethrow;
    }
  }
}
