// Copyright (c) 2025 ArtBeat. All rights reserved.

import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';

/// Test-specific wrapper widgets that provide mocked dependencies
class TestAuthScreenWrapper extends StatelessWidget {
  const TestAuthScreenWrapper({
    super.key,
    required this.child,
    this.mockAuth,
    this.mockFirestore,
  });
  final Widget child;
  final MockFirebaseAuth? mockAuth;
  final FakeFirebaseFirestore? mockFirestore;

  @override
  Widget build(BuildContext context) => MaterialApp(home: child);
}

/// Test helper for creating auth screens with mocked dependencies
class AuthTestHelpers {
  static MockFirebaseAuth createMockAuth({bool signedIn = false}) =>
      MockFirebaseAuth(signedIn: signedIn);

  static FakeFirebaseFirestore createMockFirestore() => FakeFirebaseFirestore();

  static MockUser createMockUser({
    String uid = 'test-uid',
    String email = 'test@example.com',
    String displayName = 'Test User',
    bool isEmailVerified = true,
  }) => MockUser(
    uid: uid,
    email: email,
    displayName: displayName,
    isEmailVerified: isEmailVerified,
  );

  /// Create a LoginScreen with mocked dependencies
  static Widget createTestLoginScreen({
    MockFirebaseAuth? mockAuth,
    FakeFirebaseFirestore? mockFirestore,
  }) {
    final auth = mockAuth ?? createMockAuth();
    final firestore = mockFirestore ?? createMockFirestore();

    return TestAuthScreenWrapper(
      mockAuth: auth,
      mockFirestore: firestore,
      child: LoginScreen(
        authService: AuthService(auth: auth, firestore: firestore),
      ),
    );
  }

  /// Create a RegisterScreen with mocked dependencies
  static Widget createTestRegisterScreen({
    MockFirebaseAuth? mockAuth,
    FakeFirebaseFirestore? mockFirestore,
  }) {
    final auth = mockAuth ?? createMockAuth();
    final firestore = mockFirestore ?? createMockFirestore();

    return TestAuthScreenWrapper(
      mockAuth: auth,
      mockFirestore: firestore,
      child: RegisterScreen(
        authService: AuthService(auth: auth, firestore: firestore),
      ),
    );
  }

  /// Create a ForgotPasswordScreen with mocked dependencies
  static Widget createTestForgotPasswordScreen({
    MockFirebaseAuth? mockAuth,
    FakeFirebaseFirestore? mockFirestore,
  }) {
    final auth = mockAuth ?? createMockAuth();
    final firestore = mockFirestore ?? createMockFirestore();

    return TestAuthScreenWrapper(
      mockAuth: auth,
      mockFirestore: firestore,
      child: ForgotPasswordScreen(
        authService: AuthService(auth: auth, firestore: firestore),
      ),
    );
  }

  /// Create EmailVerificationScreen for testing
  static Widget createTestEmailVerificationScreen() =>
      const TestAuthScreenWrapper(child: TestEmailVerificationScreen());

  /// Create ProfileCreateScreen for testing
  static Widget createTestProfileCreateScreen() =>
      const TestAuthScreenWrapper(child: TestProfileCreateScreen());

  /// Create a simplified SplashScreen for testing (without Firebase dependencies)
  static Widget createTestSplashScreen() =>
      const TestAuthScreenWrapper(child: TestSplashScreen());
}

/// A simplified EmailVerificationScreen for testing that doesn't require Firebase
class TestEmailVerificationScreen extends StatelessWidget {
  const TestEmailVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Email Verification'),
      backgroundColor: Theme.of(context).primaryColor,
    ),
    body: const Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.email_outlined, size: 80, color: Colors.blue),
          SizedBox(height: 24),
          Text(
            'Verify Your Email',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Text(
            'We sent a verification link to your email address.',
            style: TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: null, // Disabled in test
            child: Text('Resend Email'),
          ),
        ],
      ),
    ),
  );
}

/// A simplified ProfileCreateScreen for testing that doesn't require Firebase
class TestProfileCreateScreen extends StatelessWidget {
  const TestProfileCreateScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Create Profile'),
      backgroundColor: Theme.of(context).primaryColor,
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Complete Your Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Display Name',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Bio',
                prefixIcon: Icon(Icons.edit),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            const ElevatedButton(
              onPressed: null, // Disabled in test
              child: Text('Complete Profile'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A simplified SplashScreen for testing that doesn't require Firebase
class TestSplashScreen extends StatefulWidget {
  const TestSplashScreen({super.key});

  @override
  State<TestSplashScreen> createState() => _TestSplashScreenState();
}

class _TestSplashScreenState extends State<TestSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Colors.purple, Colors.blue]),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Opacity(
            opacity: _animation.value,
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.palette, size: 100, color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'ArtBeat',
                  style: TextStyle(
                    fontSize: 32,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
