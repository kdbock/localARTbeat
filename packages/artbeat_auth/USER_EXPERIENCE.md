# artbeat_auth User Experience (Current Implementation)

This guide reflects the UX currently implemented in `packages/artbeat_auth`.

## UX boundary

`artbeat_auth` owns authentication-facing screens and decisions. It does not own the full app shell.

- It authenticates users and resolves next-route decisions.
- It hands off to other packages for post-auth experiences (dashboard/profile package flows).

## Primary user journeys

### 1. Login

Entry: `LoginScreen`

User actions:

1. Email + password sign-in.
2. Google sign-in.
3. Apple sign-in (iOS only).
4. Navigate to register or forgot-password.

Outcome:

- Successful auth routes to dashboard (`AuthRoutes.dashboard`) or pops with success when opened modally.

### 2. Registration

Entry: `RegisterScreen`

User actions:

1. Enter first name, last name, email, password, confirm password.
2. Accept terms/privacy checkbox.
3. Submit registration.

System behavior:

- Creates auth account.
- Ensures Firestore user document exists.
- Records legal consent via `LegalConsentService`.
- Routes to dashboard.

### 3. Password reset

Entry: `ForgotPasswordScreen`

User actions:

1. Enter email.
2. Submit password reset request.

System behavior:

- Calls Firebase reset email.
- Shows success or mapped error state.

### 4. Email verification

Entry: `EmailVerificationScreen`

System behavior:

- Polls verification every 3 seconds.
- Offers resend verification with 60s cooldown.
- On verified state, routes to dashboard.

User option:

- Can continue to dashboard via skip confirmation flow.

### 5. Profile creation handoff

Entry: host app route `/profile/create`

System behavior:

- Auth logic can route a user to `/profile/create` when no Firestore profile
  exists.
- The host application owns the actual profile creation screen and flow.

## Auth decision flow (`AuthProfileService`)

`checkAuthStatus(requireEmailVerification: bool)` resolves route in this order:

1. Not authenticated -> `/login`
2. Email verification required + not verified -> `/email-verification`
3. No Firestore profile -> `/profile/create`
4. Otherwise -> `/dashboard`

## Current UX risks / drift

1. `AuthHeader` uses `/auth/*` route strings while `AuthRoutes` uses root auth paths (`/login`, `/register`, `/forgot-password`).
2. Login screen mixes `AuthRoutes.dashboard` and literal `'/dashboard'`.

These are valid only if host routing table supports both patterns.

## Test coverage in package

Current tests validate:

- Auth route constants and helper methods
- `AuthService` contract behaviors (email login/register/reset/verification helpers)
- `AuthHeader` menu-driven navigation

Recommended next additions:

1. Widget tests for `LoginScreen`, `RegisterScreen`, and `ForgotPasswordScreen` form validation/error states.
2. Injectable/mocked tests for `AuthProfileService` route resolution with profile existence scenarios.
