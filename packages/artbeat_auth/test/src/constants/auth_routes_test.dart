import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_auth/src/constants/routes.dart';

void main() {
  group('AuthRoutes', () {
    test('isAuthRoute returns true for auth routes', () {
      expect(AuthRoutes.isAuthRoute(AuthRoutes.login), isTrue);
      expect(AuthRoutes.isAuthRoute(AuthRoutes.register), isTrue);
      expect(AuthRoutes.isAuthRoute(AuthRoutes.forgotPassword), isTrue);
      expect(AuthRoutes.isAuthRoute(AuthRoutes.emailVerification), isTrue);
      expect(AuthRoutes.isAuthRoute(AuthRoutes.profileCreate), isTrue);
    });

    test('isAuthRoute returns false for non-auth routes', () {
      expect(AuthRoutes.isAuthRoute(AuthRoutes.dashboard), isFalse);
      expect(AuthRoutes.isAuthRoute('/unknown-route'), isFalse);
    });

    test('returns expected default routes', () {
      expect(AuthRoutes.getDefaultPostAuthRoute(), AuthRoutes.dashboard);
      expect(AuthRoutes.getProfileCreationRoute(), AuthRoutes.profileCreate);
      expect(
        AuthRoutes.getEmailVerificationRoute(),
        AuthRoutes.emailVerification,
      );
      expect(AuthRoutes.getDefaultUnauthenticatedRoute(), AuthRoutes.login);
    });
  });
}
