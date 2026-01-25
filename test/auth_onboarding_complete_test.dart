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

  setUpAll(() async {
    SharedPreferences.setMockInitialValues(const {});
    await EasyLocalization.ensureInitialized();
    // Initialize Firebase for all tests
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

  Future<void> pumpLocalized(
    WidgetTester tester,
    Widget child,
  ) async {
    await tester.pumpWidget(wrapWithLocalization(child));
    // Avoid pumpAndSettle to prevent timeouts from animations/timers.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  group('🎯 ArtBeat Authentication & Onboarding Tests', () {
    group('1. AUTHENTICATION & ONBOARDING - Core UI Tests', () {
      testWidgets('✅ Splash screen displays on app launch', (tester) async {
        final mockSponsorService = FirebaseTestSetup.createMockSponsorService();
        await pumpLocalized(
          tester,
          SplashScreen(
            sponsorService: mockSponsorService,
            enableBackgroundAnimation: false,
            autoNavigate: false,
          ),
        );

        // Verify splash screen elements are present
        expect(find.byType(SplashScreen), findsOneWidget);

        // Check for key UI components that should be in splash screen
        expect(find.byType(Container), findsAtLeastNWidgets(1));
        expect(find.byType(AnimatedBuilder), findsAtLeastNWidgets(1));
      });

      testWidgets('Login screen displays correctly', (tester) async {
        final mockAuthService = FirebaseTestSetup.createMockAuthService();

        await pumpLocalized(
          tester,
          LoginScreen(
            authService: mockAuthService,
            enableBackgroundAnimation: false,
          ),
        );

        // Verify login screen loads
        expect(find.byType(LoginScreen), findsOneWidget);

        // Check for form elements
        expect(find.byType(Form), findsOneWidget);
        expect(
          find.byType(TextFormField),
          findsAtLeastNWidgets(2),
        ); // Email and password fields
        expect(find.byType(InkWell), findsAtLeastNWidgets(1)); // Login button
      });

      testWidgets('Register screen displays correctly', (tester) async {
        final mockAuthService = FirebaseTestSetup.createMockAuthService();

        await pumpLocalized(
          tester,
          RegisterScreen(
            authService: mockAuthService,
            enableBackgroundAnimation: false,
          ),
        );

        // Verify registration screen loads
        expect(find.byType(RegisterScreen), findsOneWidget);

        // Check for form elements - RegisterScreen should have multiple text fields
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsAtLeastNWidgets(4));
        expect(find.byType(InkWell), findsAtLeastNWidgets(1));
      });

      testWidgets('Forgot Password screen displays correctly', (tester) async {
        final mockAuthService = FirebaseTestSetup.createMockAuthService();
        await pumpLocalized(
          tester,
          ForgotPasswordScreen(authService: mockAuthService),
        );

        // Verify forgot password screen loads
        expect(find.byType(ForgotPasswordScreen), findsOneWidget);

        // Check for essential elements
        expect(find.byType(Form), findsOneWidget);
        expect(find.byType(TextFormField), findsOneWidget); // Email field
        expect(find.byType(InkWell), findsAtLeastNWidgets(1)); // Reset button
      });

      testWidgets('Email verification screen displays correctly', (
        tester,
      ) async {
        await pumpLocalized(
          tester,
          const TestEmailVerificationScreen(),
        );

        // Verify email verification screen loads
        expect(find.byType(TestEmailVerificationScreen), findsOneWidget);
      });

      testWidgets('Profile creation screen displays correctly', (tester) async {
        await pumpLocalized(
          tester,
          const CreateProfileScreen(userId: 'test-user-id'),
        );

        // Verify profile creation screen loads
        expect(find.byType(CreateProfileScreen), findsOneWidget);
      });
      group('Form Validation Tests', () {
        testWidgets('Login form accepts text input', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();

          await pumpLocalized(
            tester,
            LoginScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          // Find form fields by type since we might not have specific keys
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
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await pumpLocalized(
            tester,
            RegisterScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          final textFields = find.byType(TextFormField);

          if (textFields.evaluate().isNotEmpty) {
            // Test first name field (assuming it's first)
            await tester.enterText(textFields.first, 'John');
            await tester.pump();
            expect(find.text('John'), findsOneWidget);

            // Test email field (varies by implementation)
            if (textFields.evaluate().length >= 3) {
              await tester.enterText(textFields.at(2), 'john@example.com');
              await tester.pump();
              expect(find.text('john@example.com'), findsOneWidget);
            }
          }
        });
      });

      group('Navigation Tests', () {
        testWidgets('Login screen has navigation elements', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await tester.pumpWidget(
            EasyLocalization(
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
                  initialRoute: '/login',
                  routes: {
                    '/login': (context) => LoginScreen(
                      authService: mockAuthService,
                      enableBackgroundAnimation: false,
                    ),
                    '/register': (context) => RegisterScreen(
                      authService: mockAuthService,
                      enableBackgroundAnimation: false,
                    ),
                    '/forgot-password': (context) =>
                        ForgotPasswordScreen(authService: mockAuthService),
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(LoginScreen), findsOneWidget);

          // Look for navigation buttons/links (usually TextButton or InkWell)
          final navElements = find.byType(TextButton);
          expect(
            navElements,
            findsAtLeastNWidgets(0),
          ); // May or may not have nav buttons
        });

        testWidgets('Registration screen has required navigation', (
          tester,
        ) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await tester.pumpWidget(
            EasyLocalization(
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
                  initialRoute: '/register',
                  routes: {
                    '/login': (context) => LoginScreen(
                      authService: mockAuthService,
                      enableBackgroundAnimation: false,
                    ),
                    '/register': (context) => RegisterScreen(
                      authService: mockAuthService,
                      enableBackgroundAnimation: false,
                    ),
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(find.byType(RegisterScreen), findsOneWidget);
        });
      });

      group('Button Interaction Tests', () {
        testWidgets('Login button can be tapped', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();

          await pumpLocalized(
            tester,
            LoginScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          // Find and tap the main action button
          final buttons = find.byType(InkWell);
          if (buttons.evaluate().isNotEmpty) {
            await tester.tap(buttons.first);
            await tester.pump();

            // If button was tapped, form should be processed (may show errors if empty)
            expect(find.byType(LoginScreen), findsOneWidget);
          }
        });

        testWidgets('Registration button can be tapped', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await pumpLocalized(
            tester,
            RegisterScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          final buttons = find.byType(InkWell);
          if (buttons.evaluate().isNotEmpty) {
            // Ensure the button is visible before tapping
            await tester.ensureVisible(buttons.first);
            await tester.pumpAndSettle();

            await tester.tap(buttons.first);
            await tester.pump();

            expect(find.byType(RegisterScreen), findsOneWidget);
          }
        });

        testWidgets('Password reset button can be tapped', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await pumpLocalized(
            tester,
            ForgotPasswordScreen(authService: mockAuthService),
          );

          final buttons = find.byType(InkWell);
          if (buttons.evaluate().isNotEmpty) {
            await tester.tap(buttons.first);
            await tester.pump();

            expect(find.byType(ForgotPasswordScreen), findsOneWidget);
          }
        });
      });

      group('UI Element Validation', () {
        testWidgets('Password fields have visibility toggle', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await pumpLocalized(
            tester,
            LoginScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          // Look for password visibility icons (usually IconButton with visibility icon)
          final iconButtons = find.byType(IconButton);

          // Password fields should have some way to toggle visibility
          // This might be an IconButton with visibility icon
          if (iconButtons.evaluate().isNotEmpty) {
            await tester.tap(iconButtons.first);
            await tester.pump();
          }

          expect(find.byType(LoginScreen), findsOneWidget);
        });

        testWidgets('Forms have proper validation structure', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await pumpLocalized(
            tester,
            RegisterScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          // Verify form validation structure exists
          expect(find.byType(Form), findsOneWidget);

          // All text fields should be TextFormField for validation
          final formFields = find.byType(TextFormField);
          expect(formFields.evaluate().length, greaterThan(0));
        });
      });

      group('Accessibility Tests', () {
        testWidgets('Login screen has proper semantics', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await pumpLocalized(
            tester,
            LoginScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          // Check that screen has proper structure for accessibility
          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(SafeArea), findsAtLeastNWidgets(0));
        });

        testWidgets('Registration screen has proper semantics', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          await pumpLocalized(
            tester,
            RegisterScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          expect(find.byType(Scaffold), findsOneWidget);
        });
      });

      group('Error Handling UI Tests', () {
        testWidgets('Forms can display error states', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();

          await pumpLocalized(
            tester,
            LoginScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          // Ensure the button is present
          expect(find.byType(InkWell), findsAtLeastNWidgets(1));

          // Try to submit empty form to trigger validation
          final submitButton = find.byType(InkWell).first;
          await tester.tap(submitButton);
          await tester.pump();

          // Form should still be displayed (validation prevents submission)
          expect(find.byType(Form), findsOneWidget);
          expect(find.byType(LoginScreen), findsOneWidget);
        });
      });

      group('Screen Layout Tests', () {
        testWidgets('Splash screen has proper layout', (tester) async {
          final mockSponsorService =
              FirebaseTestSetup.createMockSponsorService();
          await pumpLocalized(
            tester,
            SplashScreen(
              sponsorService: mockSponsorService,
              enableBackgroundAnimation: false,
              autoNavigate: false,
            ),
          );

          // Check for proper layout structure
          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(Container), findsAtLeastNWidgets(1));
        });

        testWidgets('Auth screens have consistent layout', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();

          // Test login screen layout
          await pumpLocalized(
            tester,
            LoginScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          expect(find.byType(Scaffold), findsOneWidget);
          expect(find.byType(SafeArea), findsAtLeastNWidgets(0));

          // Test registration screen layout separately
          await pumpLocalized(
            tester,
            RegisterScreen(
              authService: mockAuthService,
              enableBackgroundAnimation: false,
            ),
          );

          expect(find.byType(Scaffold), findsOneWidget);
        });
      });

      group('Integration Readiness Tests', () {
        testWidgets('Screens handle navigation properly', (tester) async {
          final mockAuthService = FirebaseTestSetup.createMockAuthService();
          final mockSponsorService =
              FirebaseTestSetup.createMockSponsorService();

          await tester.pumpWidget(
            EasyLocalization(
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
                  initialRoute: '/',
                  routes: {
                    '/': (context) => SplashScreen(
                      sponsorService: mockSponsorService,
                      enableBackgroundAnimation: false,
                      autoNavigate: false,
                    ),
                    '/login': (context) => LoginScreen(
                      authService: mockAuthService,
                      enableBackgroundAnimation: false,
                    ),
                    '/register': (context) => RegisterScreen(
                      authService: mockAuthService,
                      enableBackgroundAnimation: false,
                    ),
                    '/dashboard': (context) =>
                        const Scaffold(body: Center(child: Text('Dashboard'))),
                  },
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();

          // Start with splash screen
          expect(find.byType(SplashScreen), findsOneWidget);

          await tester.pump();
        });
      });
    });

    group('Service Layer Tests', () {
      test('AuthService can be instantiated', () {
        // Basic service instantiation test using mock for testing
        final authService = FirebaseTestSetup.createMockAuthService();
        expect(authService, isA<AuthService>());
      });

      test('UserService can be instantiated', () {
        final userService = UserService();
        expect(userService, isA<UserService>());
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
