import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:artbeat_auth/src/widgets/auth_header.dart';

class _TestAssetLoader extends AssetLoader {
  const _TestAssetLoader();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async {
    return <String, dynamic>{
      'auth_header_menu_title': 'Auth Menu',
      'auth_header_menu_login': 'Login',
      'auth_header_menu_register': 'Register',
      'auth_header_menu_forgot_password': 'Forgot Password',
      'auth_header_dev_tools_title': 'Developer Tools',
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  Widget _buildApp() {
    return EasyLocalization(
      supportedLocales: const [Locale('en')],
      path: 'unused',
      assetLoader: const _TestAssetLoader(),
      fallbackLocale: const Locale('en'),
      child: Builder(
        builder: (context) => MaterialApp(
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          routes: {
            '/auth/login': (_) => const Scaffold(body: Text('login-screen')),
            '/auth/register': (_) =>
                const Scaffold(body: Text('register-screen')),
            '/auth/forgot-password': (_) =>
                const Scaffold(body: Text('forgot-screen')),
          },
          home: const Scaffold(appBar: AuthHeader(showBackButton: false)),
        ),
      ),
    );
  }

  testWidgets('opens menu and navigates to login', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.login));
    await tester.pumpAndSettle();

    expect(find.text('login-screen'), findsOneWidget);
  });

  testWidgets('opens menu and navigates to register', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.person_add));
    await tester.pumpAndSettle();

    expect(find.text('register-screen'), findsOneWidget);
  });

  testWidgets('opens menu and navigates to forgot password', (tester) async {
    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.lock_reset));
    await tester.pumpAndSettle();

    expect(find.text('forgot-screen'), findsOneWidget);
  });
}
