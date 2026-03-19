# artbeat_auth

Authentication package for ARTbeat. It provides auth services, auth routes, and the app's auth-facing screens.

## Current package scope

### Exports (`lib/artbeat_auth.dart`)

- Services:
  - `AuthService`
  - `AuthProfileService`
- Screens:
  - `LoginScreen`
  - `RegisterScreen`
  - `ForgotPasswordScreen`
  - `EmailVerificationScreen`
- Constants:
  - `AuthRoutes`

### Folder layout

- `lib/src/services/`
  - `auth_service.dart`
  - `auth_profile_service.dart`
  - `fresh_apple_signin.dart`
- `lib/src/screens/`
  - `login_screen.dart`
  - `register_screen.dart`
  - `forgot_password_screen.dart`
  - `email_verification_screen.dart`
- `lib/src/constants/routes.dart`
- `lib/src/widgets/auth_header.dart`

## Core behavior in use

### `AuthService`

- Email/password sign-in and registration via Firebase Auth.
- Registration writes a base user document to Firestore (`users/{uid}`).
- Password reset and sign-out.
- Email verification send/check/reload helpers.
- Google sign-in via `google_sign_in` v7 API.
- Apple sign-in via standard OAuth provider flow.
- Additional fallback path via `FreshAppleSignIn.signInFresh()`.

Constructor supports dependency injection for tests:

```dart
AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
```

### `AuthProfileService`

- Returns next route from auth/profile state with `checkAuthStatus(...)`.
- Route outcomes:
  - unauthenticated -> `AuthRoutes.login`
  - requires verification and not verified -> `AuthRoutes.emailVerification`
  - authenticated but no Firestore profile -> `AuthRoutes.profileCreate`
  - authenticated with profile -> `AuthRoutes.dashboard`

### Screens

- `LoginScreen`
  - Email/password login
  - Google login
  - Apple login on iOS
  - Routes to dashboard/register/forgot-password
- `RegisterScreen`
  - Full name + email/password form
  - Terms/privacy consent UX
  - Calls `LegalConsentService.recordRegistrationConsent(...)`
  - Ensures user document exists (via `UserService`) and routes to dashboard
- `ForgotPasswordScreen`
  - Sends reset email and displays result state
- `EmailVerificationScreen`
  - Polls verification state every 3s
  - Supports resend with cooldown
  - Can proceed to dashboard

## Route contract

Defined in `AuthRoutes`:

- `/login`
- `/register`
- `/forgot-password`
- `/email-verification`
- `/dashboard`
- `/profile/create`

Profile creation ownership:

- `AuthProfileService` may return `/profile/create`
- the host app is responsible for handling that route and rendering the actual
  profile creation experience

Route helper methods are available for auth/default route decisions.

## Important implementation note

`AuthHeader` currently routes to `/auth/login`, `/auth/register`, and `/auth/forgot-password`, while `AuthRoutes` constants are `/login`, `/register`, `/forgot-password`.

If your app route table does not provide both aliases, this can cause navigation mismatches.

## Testing status

A baseline test suite now exists under `test/` covering:

- `AuthRoutes` helper behavior
- `AuthService` core contract behavior (mocked Firebase auth + fake Firestore)
- `AuthHeader` menu navigation behavior

Run:

```bash
flutter test
flutter analyze
```

from `packages/artbeat_auth`.
