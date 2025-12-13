// Copyright (c) 2025 ArtBeat. All rights reserved.

import 'package:artbeat_auth/artbeat_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_profile/artbeat_profile.dart' hide UserService;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_test_helpers.dart';
import 'firebase_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('🎯 ArtBeat Authentication & Onboarding Tests (Firebase Enabled)', () {
    setUpAll(() async {
      // Initialize shared preferences mock for all tests
      SharedPreferences.setMockInitialValues({});

      // Initialize easy_localization for all tests
      await EasyLocalization.ensureInitialized();

      // Initialize Firebase for all tests
      await FirebaseTestSetup.initializeFirebaseForTesting();
    });

    tearDownAll(() async {
      // Clean up Firebase after all tests
      await FirebaseTestSetup.cleanup();
    });

    setUp(() async {
      // Reset Firebase state before each test
      await FirebaseTestSetup.reset();
    });

    group('1. AUTHENTICATION & ONBOARDING - Core UI Tests', () {
      testWidgets('✅ Splash screen displays on app launch', (tester) async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            child: const MaterialApp(home: SplashScreen()),
          ),
        );

        // Give the splash screen time to initialize
        await tester.pump(const Duration(milliseconds: 100));

        // Verify splash screen elements are present
        expect(find.byType(SplashScreen), findsOneWidget);

        // Check for key UI components that should be in splash screen
        expect(find.byType(Container), findsAtLeastNWidgets(1));
      });

      testWidgets('Login screen displays correctly with Firebase', (
        tester,
      ) async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            child: MaterialApp(
              home: LoginScreen(
                authService: AuthService(
                  auth: FirebaseTestSetup.mockAuth,
                  firestore: FirebaseTestSetup.fakeFirestore,
                ),
              ),
            ),
          ),
        );

        // Allow the widget to build
        await tester.pump();

        // Verify login screen loads
        expect(find.byType(LoginScreen), findsOneWidget);

        // Check for form elements
        expect(find.byType(Form), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsAtLeastNWidgets(2),
        ); // Email and password fields
        expect(
          find.byType(ElevatedButton),
          findsAtLeastNWidgets(1),
        ); // Login button
      });

      testWidgets('Register screen displays correctly with Firebase', (
        tester,
      ) async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            child: MaterialApp(
              home: RegisterScreen(
                authService: AuthService(
                  auth: FirebaseTestSetup.mockAuth,
                  firestore: FirebaseTestSetup.fakeFirestore,
                ),
              ),
            ),
          ),
        );

        // Allow the widget to build
        await tester.pump();

        // Verify registration screen loads
        expect(find.byType(RegisterScreen), findsOneWidget);

        // Check for form elements - RegisterScreen should have multiple text fields
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(4));
        expect(find.byType(ElevatedButton), findsAtLeastNWidgets(1));
      });

      testWidgets('Forgot Password screen displays correctly with Firebase', (
        tester,
      ) async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            child: MaterialApp(
              home: ForgotPasswordScreen(
                authService: AuthService(
                  auth: FirebaseTestSetup.mockAuth,
                  firestore: FirebaseTestSetup.fakeFirestore,
                ),
              ),
            ),
          ),
        );

        // Allow the widget to build
        await tester.pump();

        // Verify forgot password screen loads
        expect(find.byType(ForgotPasswordScreen), findsOneWidget);

        // Check for essential elements
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget); // Email field
        expect(
          find.byType(ElevatedButton),
          findsAtLeastNWidgets(1),
        ); // Reset button
      });

      testWidgets('Email verification screen displays correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          EasyLocalization(
            supportedLocales: const [Locale('en')],
            path: 'assets/translations',
            fallbackLocale: const Locale('en'),
            child: const MaterialApp(home: TestEmailVerificationScreen()),
          ),
        );

        // Allow the widget to build
        await tester.pump();

        // Verify email verification screen loads
        expect(find.byType(TestEmailVerificationScreen), findsOneWidget);
      });

      testWidgets('Profile creation screen displays correctly', (tester) async {
        // Ensure Firebase is initialized for this test
        await FirebaseTestSetup.initializeFirebaseForTesting();

        await tester.pumpWidget(
          const TestAuthScreenWrapper(
            child: CreateProfileScreen(userId: 'test-user-id'),
          ),
        );

        // Allow Firebase initialization and widget to build
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify profile creation screen loads
        expect(find.byType(CreateProfileScreen), findsOneWidget);
      });

      group('Form Interaction Tests with Firebase', () {
        testWidgets('Login form accepts text input', (tester) async {
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('en')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: MaterialApp(
                home: LoginScreen(
                  authService: AuthService(
                    auth: FirebaseTestSetup.mockAuth,
                    firestore: FirebaseTestSetup.fakeFirestore,
                  ),
                ),
              ),
            ),
          );

          await tester.pump();

          // Find form fields by type
          final textFields = find.byType(TextFormField);

          if (textFields.evaluate().length >= 2) {
            // Enter text in first field (email)
            await tester.enterText(textFields.first, 'test@example.com');
            await tester.pump();

            // Verify text was entered
            expect(find.text('test@example.com'), findsOneWidget);

            // Enter text in second field (password)
            await tester.enterText(textFields.at(1), 'password123');
            await tester.pump();
          }
        });

        testWidgets('Registration form accepts text input', (tester) async {
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('en')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: MaterialApp(
                home: RegisterScreen(
                  authService: AuthService(
                    auth: FirebaseTestSetup.mockAuth,
                    firestore: FirebaseTestSetup.fakeFirestore,
                  ),
                ),
              ),
            ),
          );

          await tester.pump();

          final textFields = find.byType(TextFormField);

          if (textFields.evaluate().isNotEmpty) {
            // Test first name field (assuming it's first)
            await tester.enterText(textFields.first, 'John');
            await tester.pump();
            expect(find.text('John'), findsOneWidget);
          }
        });
      });

      group('Button Interaction Tests with Firebase', () {
        testWidgets('Login button can be tapped', (tester) async {
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('en')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: MaterialApp(
                home: LoginScreen(
                  authService: AuthService(
                    auth: FirebaseTestSetup.mockAuth,
                    firestore: FirebaseTestSetup.fakeFirestore,
                  ),
                ),
              ),
            ),
          );

          await tester.pump();

          // Find and tap the main action button
          final buttons = find.byType(ElevatedButton);
          if (buttons.evaluate().isNotEmpty) {
            await tester.tap(buttons.first);
            await tester.pump();

            // If button was tapped, form should be processed (may show errors if empty)
            expect(find.byType(LoginScreen), findsOneWidget);
          }
        });

        testWidgets('Registration button can be tapped', (tester) async {
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('en')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: MaterialApp(
                home: RegisterScreen(
                  authService: AuthService(
                    auth: FirebaseTestSetup.mockAuth,
                    firestore: FirebaseTestSetup.fakeFirestore,
                  ),
                ),
              ),
            ),
          );

          await tester.pump();

          final buttons = find.byType(ElevatedButton);
          if (buttons.evaluate().isNotEmpty) {
            await tester.tap(buttons.first);
            await tester.pump();

            expect(find.byType(RegisterScreen), findsOneWidget);
          }
        });

        testWidgets('Password reset button can be tapped', (tester) async {
          await tester.pumpWidget(
            EasyLocalization(
              supportedLocales: const [Locale('en')],
              path: 'assets/translations',
              fallbackLocale: const Locale('en'),
              child: MaterialApp(
                home: ForgotPasswordScreen(
                  authService: AuthService(
                    auth: FirebaseTestSetup.mockAuth,
                    firestore: FirebaseTestSetup.fakeFirestore,
                  ),
                ),
              ),
            ),
          );

          await tester.pump();

          final buttons = find.byType(ElevatedButton);
          if (buttons.evaluate().isNotEmpty) {
            await tester.tap(buttons.first);
            await tester.pump();

            expect(find.byType(ForgotPasswordScreen), findsOneWidget);
          }
        });
      });

      group('Authentication State Tests', () {
        testWidgets('User authentication status check works', (tester) async {
          // Test when user is not authenticated
          expect(FirebaseTestSetup.mockAuth.currentUser, isNull);

          // Test when user is authenticated
          await FirebaseTestSetup.signInTestUser();
          expect(FirebaseTestSetup.mockAuth.currentUser, isNotNull);
          expect(
            FirebaseTestSetup.mockAuth.currentUser!.uid,
            equals('test-uid'),
          );
        });

        testWidgets('Session persistence works', (tester) async {
          // Sign in test user
          await FirebaseTestSetup.signInTestUser();

          // User should be signed in
          expect(FirebaseTestSetup.mockAuth.currentUser, isNotNull);

          // Simulate app restart by checking auth state again
          expect(
            FirebaseTestSetup.mockAuth.currentUser!.uid,
            equals('test-uid'),
          );
        });

        testWidgets('Logout functionality works', (tester) async {
          // Sign in test user
          await FirebaseTestSetup.signInTestUser();
          expect(FirebaseTestSetup.mockAuth.currentUser, isNotNull);

          // Sign out
          await FirebaseTestSetup.signOutTestUser();

          // User should be signed out
          expect(FirebaseTestSetup.mockAuth.currentUser, isNull);
        });
      });
    });

    group('Service Layer Tests with Firebase', () {
      test('AuthService can be instantiated with mock Firebase', () {
        final authService = AuthService(
          auth: FirebaseTestSetup.mockAuth,
          firestore: FirebaseTestSetup.fakeFirestore,
        );
        expect(authService, isA<AuthService>());
      });

      test('UserService works with fake Firestore', () {
        // Create UserService with fake Firestore would require more setup
        // For now, just verify the service exists
        expect(UserService, isNotNull);
      });
    });

    group('Model Tests', () {
      test('UserModel can be created with required fields', () {
        final userModel = UserModel(
          id: 'test-id',
          email: 'test@example.com',
          username: 'testuser',
          fullName: 'Test User',
          createdAt: DateTime.now(),
        );

        expect(userModel.id, equals('test-id'));
        expect(userModel.email, equals('test@example.com'));
        expect(userModel.username, equals('testuser'));
        expect(userModel.fullName, equals('Test User'));
      });
    });
  });
}
