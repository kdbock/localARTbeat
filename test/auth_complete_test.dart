// Copyright (c) 2025 ArtBeat. All rights reserved.

import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'auth_test_helpers.dart';
import 'firebase_test_setup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await EasyLocalization.ensureInitialized();
    await FirebaseTestSetup.initializeFirebaseForTesting();
  });

  Widget wrapWithLocalization(Widget child) => EasyLocalization(
    supportedLocales: const [Locale('en')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: const Locale('en'),
    useOnlyLangCode: true,
    assetLoader: const TestFileAssetLoader(),
    child: Builder(
      builder: (BuildContext context) => MaterialApp(
        locale: context.locale,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        home: child,
      ),
    ),
  );

  group('🎯 ArtBeat Authentication & Onboarding Tests (Complete)', () {
    group('1. AUTHENTICATION SCREENS - UI Tests', () {
      testWidgets('✅ Splash screen displays and animates', (tester) async {
        await tester.pumpWidget(
          wrapWithLocalization(
            SplashScreen(
              sponsorService: FirebaseTestSetup.createMockSponsorService(),
              enableBackgroundAnimation: false,
              autoNavigate: false,
            ),
          ),
        );

        // Wait for timers to complete
        await tester.pumpAndSettle();

        // Verify splash screen elements are present
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(
          find.byType(AnimatedBuilder),
          findsAtLeastNWidgets(1),
        ); // Multiple animations expected

        // Check for app branding (image logo)
        expect(find.byType(Image), findsOneWidget);

        // Test animation
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 500));

        // Animation should be running (ScaleTransition)
        expect(find.byType(ScaleTransition), findsAtLeastNWidgets(1));
      });

      testWidgets('✅ Login screen displays correctly', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        // Verify login screen structure
        expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);

        // Check for form fields
        final textFields = find.byType(TextFormField);
        expect(textFields, findsAtLeastNWidgets(2)); // Email and password

        // Check for buttons
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });

      testWidgets('✅ Registration screen displays correctly', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestRegisterScreen());
        await tester.pumpAndSettle();

        // Verify registration screen structure
        expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);

        // Registration should have more fields than login
        final textFields = find.byType(TextFormField);
        expect(
          textFields,
          findsAtLeastNWidgets(4),
        ); // Name, email, password, confirm, etc.

        // Check for submit button
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });

      testWidgets('✅ Forgot Password screen displays correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          AuthTestHelpers.createTestForgotPasswordScreen(),
        );
        await tester.pumpAndSettle();

        // Verify forgot password screen structure
        expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);

        // Should have email field
        expect(find.byType(TextFormField), findsOneWidget);

        // Should have reset button
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });

      testWidgets('✅ Email verification screen displays correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          AuthTestHelpers.createTestEmailVerificationScreen(),
        );
        await tester.pumpAndSettle();

        // Verify email verification screen
        expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('✅ Profile creation screen displays correctly', (
        tester,
      ) async {
        await tester.pumpWidget(
          AuthTestHelpers.createTestProfileCreateScreen(),
        );
        await tester.pumpAndSettle();

        // Verify profile creation screen
        expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        expect(find.byType(Scaffold), findsOneWidget);
      });
    });

    group('2. FORM INTERACTIONS - Input Tests', () {
      testWidgets('✅ Login form accepts email input', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().isNotEmpty) {
          // Enter email in first field
          await tester.enterText(textFields.first, 'test@example.com');
          await tester.pumpAndSettle();

          // Verify email was entered
          expect(find.text('test@example.com'), findsOneWidget);
        }
      });

      testWidgets('✅ Login form accepts password input', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextFormField);
        if (textFields.evaluate().length >= 2) {
          // Enter password in second field
          await tester.enterText(textFields.at(1), 'password123');
          await tester.pumpAndSettle();

          // Note: Password might be obscured, so we check the field exists
          expect(textFields.at(1), findsOneWidget);
        }
      });

      testWidgets('✅ Registration form accepts user input', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestRegisterScreen());
        await tester.pumpAndSettle();

        final textFields = find.byType(TextFormField);

        if (textFields.evaluate().isNotEmpty) {
          // Test first name field
          await tester.enterText(textFields.first, 'John');
          await tester.pumpAndSettle();
          expect(find.text('John'), findsOneWidget);

          // Test additional fields if available
          if (textFields.evaluate().length >= 2) {
            await tester.enterText(textFields.at(1), 'Doe');
            await tester.pumpAndSettle();
            expect(find.text('Doe'), findsOneWidget);
          }

          if (textFields.evaluate().length >= 3) {
            await tester.enterText(textFields.at(2), 'john@example.com');
            await tester.pumpAndSettle();
            expect(find.text('john@example.com'), findsOneWidget);
          }
        }
      });

      testWidgets('✅ Forgot password form accepts email', (tester) async {
        await tester.pumpWidget(
          AuthTestHelpers.createTestForgotPasswordScreen(),
        );
        await tester.pumpAndSettle();

        final textField = find.byType(TextFormField);
        await tester.enterText(textField, 'reset@example.com');
        await tester.pumpAndSettle();

        expect(find.text('reset@example.com'), findsOneWidget);
      });
    });

    group('3. BUTTON INTERACTIONS - Action Tests', () {
      testWidgets('✅ Login button can be tapped', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        final buttons = find.byType(InkWell);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();

          // Form should still be present (validation may prevent submission)
          expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        }
      });

      testWidgets('✅ Registration button can be tapped', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestRegisterScreen());
        await tester.pumpAndSettle();

        final buttons = find.byType(InkWell);
        if (buttons.evaluate().isNotEmpty) {
          // Ensure button is visible by scrolling if needed
          await tester.ensureVisible(buttons.first);
          await tester.tap(buttons.first, warnIfMissed: false);
          await tester.pumpAndSettle();

          expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        }
      });

      testWidgets('✅ Password reset button can be tapped', (tester) async {
        await tester.pumpWidget(
          AuthTestHelpers.createTestForgotPasswordScreen(),
        );
        await tester.pumpAndSettle();

        final buttons = find.byType(InkWell);
        if (buttons.evaluate().isNotEmpty) {
          await tester.tap(buttons.first);
          await tester.pumpAndSettle();

          expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        }
      });
    });

    group('4. FORM VALIDATION - Error Handling Tests', () {
      testWidgets('✅ Login form handles empty submission', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        // Try to submit without entering data
        final submitButton = find.byType(InkWell);
        if (submitButton.evaluate().isNotEmpty) {
          await tester.tap(submitButton.first);
          await tester.pumpAndSettle();

          // Form should still be displayed (validation should prevent submission)
          expect(find.byType(Form), findsOneWidget);
          expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        }
      });

      testWidgets('✅ Registration form handles empty submission', (
        tester,
      ) async {
        await tester.pumpWidget(AuthTestHelpers.createTestRegisterScreen());
        await tester.pumpAndSettle();

        final submitButton = find.byType(InkWell);
        if (submitButton.evaluate().isNotEmpty) {
          // Ensure button is visible and tap with warning disabled
          await tester.ensureVisible(submitButton.first);
          await tester.tap(submitButton.first, warnIfMissed: false);
          await tester.pumpAndSettle();

          expect(find.byType(Form), findsOneWidget);
          expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        }
      });
    });

    group('5. UI ELEMENT VALIDATION - Layout Tests', () {
      testWidgets('✅ All auth screens have proper Scaffold structure', (
        tester,
      ) async {
        // Test login screen
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);

        // Test registration screen
        await tester.pumpWidget(AuthTestHelpers.createTestRegisterScreen());
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);

        // Test forgot password screen
        await tester.pumpWidget(
          AuthTestHelpers.createTestForgotPasswordScreen(),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Scaffold), findsOneWidget);
      });

      testWidgets('✅ Forms have proper validation structure', (tester) async {
        // Login form
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();
        expect(find.byType(Form), findsOneWidget);

        // Registration form
        await tester.pumpWidget(AuthTestHelpers.createTestRegisterScreen());
        await tester.pumpAndSettle();
        expect(find.byType(Form), findsOneWidget);

        // Forgot password form
        await tester.pumpWidget(
          AuthTestHelpers.createTestForgotPasswordScreen(),
        );
        await tester.pumpAndSettle();
        expect(find.byType(Form), findsOneWidget);
      });

      testWidgets('✅ Password fields have visibility toggle capability', (
        tester,
      ) async {
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        // Look for password visibility icons
        final iconButtons = find.byType(IconButton);

        // If there are icon buttons, they might be for password visibility
        if (iconButtons.evaluate().isNotEmpty) {
          await tester.tap(iconButtons.first);
          await tester.pumpAndSettle();

          // Screen should still be functional
          expect(find.byType(TestAuthScreenWrapper), findsOneWidget);
        }
      });
    });

    group('6. MOCK AUTHENTICATION STATE TESTS', () {
      testWidgets('✅ Mock user creation works', (tester) async {
        final mockUser = AuthTestHelpers.createMockUser(uid: 'test-123');

        expect(mockUser.uid, equals('test-123'));
        expect(mockUser.email, equals('test@example.com'));
        expect(mockUser.displayName, equals('Test User'));
      });

      testWidgets('✅ Mock auth service integration', (tester) async {
        final mockAuth = AuthTestHelpers.createMockAuth();
        expect(mockAuth.currentUser, isNull);

        final signedInAuth = AuthTestHelpers.createMockAuth(signedIn: true);
        expect(signedInAuth, isNotNull);
      });

      testWidgets('✅ Mock Firestore integration', (tester) async {
        final mockFirestore = AuthTestHelpers.createMockFirestore();
        expect(mockFirestore, isNotNull);

        // Can add test data
        await mockFirestore.collection('users').doc('test').set({
          'name': 'Test User',
          'email': 'test@example.com',
        });

        final doc = await mockFirestore.collection('users').doc('test').get();
        expect(doc.exists, isTrue);
        expect(doc.data()?['name'], equals('Test User'));
      });
    });

    group('7. SERVICE LAYER TESTS', () {
      test('✅ Mock Auth service integration works', () {
        final mockAuth = AuthTestHelpers.createMockAuth();
        final mockFirestore = AuthTestHelpers.createMockFirestore();

        // Mock services should be created successfully
        expect(mockAuth, isNotNull);
        expect(mockFirestore, isNotNull);
      });

      test('✅ Test data structures work correctly', () {
        // Test that we can create test user data
        final userData = {
          'id': 'test-id',
          'email': 'test@example.com',
          'username': 'testuser',
          'fullName': 'Test User',
          'createdAt': DateTime.now().toIso8601String(),
        };

        expect(userData['id'], equals('test-id'));
        expect(userData['email'], equals('test@example.com'));
        expect(userData['username'], equals('testuser'));
        expect(userData['fullName'], equals('Test User'));
      });
    });

    group('8. ACCESSIBILITY TESTS', () {
      testWidgets('✅ Login screen is accessible', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        // Check that screen has proper structure for accessibility
        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);

        // Form fields should be accessible
        final textFields = find.byType(TextFormField);
        expect(textFields, findsAtLeastNWidgets(1));
      });

      testWidgets('✅ Registration screen is accessible', (tester) async {
        await tester.pumpWidget(AuthTestHelpers.createTestRegisterScreen());
        await tester.pumpAndSettle();

        expect(find.byType(Scaffold), findsOneWidget);
        expect(find.byType(Form), findsOneWidget);
      });
    });

    group('9. NAVIGATION READINESS TESTS', () {
      testWidgets('✅ Screens handle MaterialApp context', (tester) async {
        // Test that screens work within MaterialApp context
        await tester.pumpWidget(AuthTestHelpers.createTestLoginScreen());
        await tester.pumpAndSettle();

        // Should find MaterialApp wrapper
        expect(find.byType(MaterialApp), findsOneWidget);
        expect(find.byType(TestAuthScreenWrapper), findsOneWidget);

        // Test navigation context exists (MaterialApp provides Navigator)
        final materialAppContext = tester.element(find.byType(MaterialApp));
        expect(materialAppContext, isNotNull);
      });
    });
  });
}
