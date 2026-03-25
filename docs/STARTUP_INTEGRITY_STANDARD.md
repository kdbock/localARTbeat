# Startup Integrity Standard

This document records the startup and service-lifecycle standard that now applies across the app.

## Goal

Startup must be predictable, testable, and side-effect-aware.

That means:

- constructing a service must not silently touch Firebase/Auth/Storage
- background listeners must not start in constructors
- global error handling must be installed once, in one bootstrap path
- provider-owned app services must be initialized explicitly by the provider graph
- regression tests must protect these contracts

## Current Ownership

Startup ownership is now split by responsibility instead of being mixed across multiple layers.

- [main.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/main.dart): framework bootstrap, localization, Firebase/core init, deferred startup flow
- [app_error_handling.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/bootstrap/app_error_handling.dart): global Flutter/platform error handler installation
- [app_providers.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/app_providers.dart): app-scoped service creation and explicit initialization
- [error_boundary.dart](/Volumes/ExternalDrive/DevProjects/artbeat/lib/src/widgets/error_boundary.dart): UI fallback, not global handler ownership

## Foundation Rules

All new or updated services should follow these rules:

- Use lazy getters or an explicit `initialize()` method for Firebase/Auth/Storage/plugin access.
- Do not subscribe to auth streams, timers, or background listeners in constructors.
- If a service is app-scoped and provider-owned, initialize it in the provider graph.
- If a service is a leaf utility and not startup-critical, lazy getters are usually enough.
- Constructors should stay safe under `flutter test` without requiring a default Firebase app.
- Singleton services still need to be side-effect-free at construction time.

## What Was Standardized

The biggest integrity issues that were cleaned up in this pass:

- Global error handling was centralized so bootstrap no longer reassigns handlers in multiple places.
- App router ownership was reduced by extracting route-family handlers out of the central router.
- Provider wiring now owns initialization for major app-scoped services instead of relying on hidden constructor side effects.
- Core, messaging, art-walk, and sponsorship service layers were normalized away from eager Firebase binding.
- Initialization contract tests were added so constructor safety is now enforced in CI-friendly test paths.

## Services Already Normalized

Representative services now following the standard include:

- [user_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/user_service.dart)
- [subscription_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/subscription_service.dart)
- [content_engagement_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/content_engagement_service.dart)
- [presence_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_messaging/lib/src/services/presence_service.dart)
- [challenge_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/challenge_service.dart)
- [instant_discovery_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/lib/src/services/instant_discovery_service.dart)
- [sponsor_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/lib/src/services/sponsor_service.dart)

## Regression Coverage

Current startup-integrity regression coverage lives in:

- [service_initialization_contract_test.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/test/src/services/service_initialization_contract_test.dart)
- [presence_service_test.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_messaging/test/src/services/presence_service_test.dart)
- [service_initialization_contract_test.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_messaging/test/src/services/service_initialization_contract_test.dart)
- [service_initialization_contract_test.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_art_walk/test/service_initialization_contract_test.dart)
- [service_initialization_contract_test.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_capture/test/service_initialization_contract_test.dart)
- [service_initialization_contract_test.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/test/service_initialization_contract_test.dart)

These tests are intended to fail when a constructor starts touching Firebase or spins up background behavior too early.

## Remaining Lower-Priority Outliers

The remaining work should stay targeted. Lower-priority leaf services can still be normalized, but the provider/startup critical path is already much cleaner.

Current lower-priority outliers or near-outliers include:

- [chapter_partner_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/chapter_partner_service.dart)
- [firebase_storage_auth_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/firebase_storage_auth_service.dart)
- [enhanced_storage_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_core/lib/src/services/enhanced_storage_service.dart)
- constructor-injected read/write services that already support explicit dependency injection

## Definition Of Done For Future Services

A service should be considered startup-safe only when all of the following are true:

- constructor executes normally in a `flutter test` environment with no default Firebase app
- Firebase/Auth/Storage/plugin access is lazy or gated behind explicit initialization
- app-scoped services have clear provider ownership
- tests exist when the service is in or near the startup path
- no duplicate global ownership exists for logging, error handling, or background listeners
