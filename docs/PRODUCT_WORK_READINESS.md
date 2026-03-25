# Product Work Readiness

This document marks the stopping point for the current startup-integrity pass and defines what product work can safely resume next.

## Foundation Status

The app is in a materially better state for feature work than it was before this cleanup.

- startup ownership is clearer
- major app-scoped services no longer hide Firebase/Auth setup in constructors
- route ownership is less centralized
- global error handling is centralized
- initialization contracts now have multi-package regression coverage

This is the point to stop broad foundation churn unless a new concrete issue appears.

## What Is Safe To Resume

The next product work should favor high-value user flows over more architectural drift.

Recommended order:

1. monetization and purchase-flow polish
2. critical user-flow QA and release confidence work
3. backend/rules follow-through tied to current product blockers
4. feature delivery inside existing package boundaries

## Highest-Value Product Areas

### 1. Monetization reliability

Focus on paid flows that directly affect trust and revenue:

- local ads purchase and verification UX
- sponsorship checkout and approval flow
- subscription entitlement clarity
- payment/admin visibility for support and moderation

### 2. Release-critical user flows

Use the current stabilization phase to harden the flows users will notice immediately:

- sign-in and account settings persistence
- capture upload flow
- chat/media upload flow
- profile edits and image updates
- admin/legal deletion processing

### 3. Backend follow-through

Do targeted backend work only where it protects live flows:

- function-side modularization for actively changing domains
- rules alignment with current uploads and admin operations
- production/staging verification discipline for deletion and payment paths

## Guardrails For New Work

Do not give back the cleanup gains during feature work.

- Do not add constructor side effects to services.
- Do not reintroduce duplicate startup ownership across `main.dart`, app shell, and widgets.
- Keep provider-owned services explicit about initialization.
- Add or extend constructor-safety tests when introducing app-scoped services.
- Prefer existing package boundaries over convenience imports across features.

## When To Reopen Foundation Work

Return to foundation work only if one of these happens:

- a new feature needs cross-package architectural movement
- a service reintroduces hidden Firebase/Auth/plugin initialization
- a release issue exposes unclear ownership at startup
- tests show repeated regressions in startup or lifecycle behavior

## Current Deferred Items

These are intentionally deferred, not forgotten:

- a few lower-priority leaf services still using direct Firebase access patterns
- deeper provider-construction tests beyond the current initialization contracts
- broader backend modularization not tied to an immediate release blocker

## Practical Next Move

Resume product work with a release-confidence bias, not a rewrite bias.

If no urgent blocker overrides it, the best next execution track is:

1. payment and sponsorship polish
2. critical manual QA pass
3. release blocker cleanup
4. new feature work on the cleaned foundation
