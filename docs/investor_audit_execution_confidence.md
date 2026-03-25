# Investor Audit: Execution Confidence

## Investor View

**Current rating:** 6.5/10  
**Assessment:** The app is real, analyzable, and tested, but execution confidence is capped by runtime complexity and concentrated technical debt.

## Code Reviewed

- `lib/main.dart`
- `lib/app.dart`
- `lib/src/routing/app_router.dart`
- `packages/artbeat_core/lib/src/services/user_service.dart`
- `analysis_options.yaml`
- local `flutter analyze`
- local `flutter test --reporter compact`

## Findings

### 1. Baseline engineering discipline is real

The repo passed `flutter analyze` locally and the root test suite passed locally. `analysis_options.yaml` is also stricter than average. That is a strong positive signal.

### 2. App startup and global error handling are too layered

`lib/main.dart` defines global Flutter and platform error handlers, then `lib/app.dart` reassigns Flutter error handling again. This creates ambiguity about which layer owns production crash handling and what gets filtered versus surfaced.

### 3. Dependency setup is centralized and fragile

`lib/app.dart` contains a large `MultiProvider` composition root. It is workable, but difficult to reason about and easy to regress. It also creates `capture.CaptureService` twice through different providers, which is a concrete sign of dependency graph drift.

### 4. Core runtime files are too large

Current file sizes:

- `lib/src/routing/app_router.dart`: 2812 lines
- `lib/main.dart`: 482 lines
- `lib/app.dart`: 279 lines
- `packages/artbeat_core/lib/src/services/user_service.dart`: 1283 lines

That concentration raises review cost, onboarding cost, and regression risk.

### 5. Singleton services still own side effects directly

`packages/artbeat_core/lib/src/services/user_service.dart` initializes Firebase inside a singleton constructor. This is exactly the kind of hidden side effect that makes tests, boot order, and environment setup less predictable.

## Recommended Action Checklist

- [ ] Establish one source of truth for global error handling and remove duplicate framework handler setup.
- [ ] Split `app_router.dart` into domain route handlers with a thin root router only.
- [ ] Replace service-constructor side effects with explicit `initialize()` calls owned by app bootstrap.
- [ ] Audit the provider graph and eliminate duplicate service construction, starting with `CaptureService`.
- [ ] Introduce dependency injection boundaries for FirebaseAuth, Firestore, Storage, and payment clients.
- [ ] Add smoke tests for startup, login, dashboard, and monetization entry points.
- [ ] Add architecture tests or lint checks for forbidden direct singleton access in UI layers.
- [ ] Set file-size or module-size thresholds for core app orchestration files so future growth is forced into better boundaries.
