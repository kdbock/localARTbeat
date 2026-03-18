# ARTbeat Test Strategy

## Purpose

Define what is tested where and what confidence is required before shipping.

## Test Layers

### 1. Package Unit Tests

Use for:

- models
- pure services
- validators
- low-level feature logic

Expected location:

- `packages/*/test/`

### 2. Root App Tests

Use for:

- app shell behavior
- routing and startup behavior
- integration between packages
- localization/runtime configuration checks

Expected location:

- `test/`
- `integration_test/` when present

### 3. Backend And Rules Verification

Use for:

- Cloud Functions behavior
- Firestore/Storage access assumptions
- sensitive legal/security/data deletion workflows

Sources:

- `functions/`
- `firestore.rules`
- `storage.rules`
- legal regression scripts and runbooks

### 4. Manual QA

Required for:

- payments
- auth flows across providers
- production-only config or platform behavior
- security/legal flows
- UI-heavy changes not well-covered by automation

## Current Repo Reality

- package tests exist in multiple packages and should remain the default place
  for isolated logic tests
- root tests cover app-level behavior and some localization checks
- backend verification is partially documented and partially script-based
- manual QA is still necessary for several release-critical flows

## Release-Critical Coverage

These areas must have either automated coverage or explicit manual QA evidence
before release:

- startup/bootstrap
- authentication
- dashboard load
- payments/subscriptions
- legal/data request flows
- messaging basics when touched
- localization key integrity
- Firebase rules changes

## Required Evidence By Change Type

### App UI Or Feature Logic

- touched package tests
- root app smoke if app shell was touched
- manual QA for changed flow

### Routing / Startup / Provider Wiring

- root tests where feasible
- manual startup test on at least one platform

### Localization

- locale parity validation
- changed screen smoke test in English
- sample non-English runtime validation where risk is higher

### Payments

- touched service/package tests
- release build validation
- manual end-to-end payment QA in safe environment

### Rules / Legal / Security

- targeted validation script or staging verification
- manual QA evidence when user/admin flows changed

## CI Expectations

CI should eventually enforce:

- `flutter analyze`
- touched package tests
- root app tests
- translation parity checks
- backend lint/build/test where applicable

## What We Are Trying To Avoid

- relying on compilation as proof of correctness
- shipping architecture refactors without regression coverage
- mixing high-risk backend/rules changes with unrelated UI work
- trusting manual memory instead of explicit release checks
