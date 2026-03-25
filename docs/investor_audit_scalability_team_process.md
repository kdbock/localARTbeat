# Investor Audit: Scalability Of Team And Process

## Investor View

**Current rating:** 6/10  
**Assessment:** The modular package layout is a good foundation, but the code ownership model and CI coverage are not yet at the level expected for a multi-team product organization.

## Code Reviewed

- `pubspec.yaml`
- package directory structure under `packages/`
- `.github/workflows/tests.yml`
- `.github/workflows/comprehensive_tests.yml`
- `lib/src/routing/app_router.dart`
- `lib/app.dart`

## Findings

### 1. Package modularization is a real strength

The repo is split into 14 packages, which is materially better than a single-app monolith:

- `artbeat_core`
- `artbeat_auth`
- `artbeat_profile`
- `artbeat_artist`
- `artbeat_artwork`
- `artbeat_capture`
- `artbeat_community`
- `artbeat_art_walk`
- `artbeat_events`
- `artbeat_messaging`
- `artbeat_ads`
- `artbeat_settings`
- `artbeat_sponsorships`
- `artbeat_admin`

That makes future team ownership possible.

### 2. Central orchestration still bottlenecks parallel work

Despite package modularity, `lib/src/routing/app_router.dart` remains a 2812-line control center. `lib/app.dart` also centralizes service wiring. This means feature teams still converge on the same high-conflict files.

### 3. CI coverage is improved, but still incomplete

`tests.yml` only runs a subset of packages. `comprehensive_tests.yml` expands coverage, but its package matrix still omits some important surfaces such as:

- `artbeat_ads`
- `artbeat_admin`
- `artbeat_sponsorships`
- Firebase functions

Those are exactly the kinds of packages that tend to create business-critical regressions.

### 4. Process evidence is good, but not yet systematic

The repo has documentation, workflows, and tests, which is above average. What is not obvious yet is a strong long-term process framework such as:

- package ownership rules
- API boundary rules between packages
- architectural decision records tied to current implementation
- release gates per monetized subsystem

## Recommended Action Checklist

- [ ] Assign ownership for each package and document who is allowed to modify cross-cutting root files.
- [ ] Split root routing into per-domain route registries so teams can ship without editing one giant router.
- [ ] Expand CI matrices to cover `artbeat_ads`, `artbeat_admin`, `artbeat_sponsorships`, and Firebase functions on every relevant change.
- [ ] Add required analyze and test gates for the root app plus every package that contains monetization, moderation, or admin behavior.
- [ ] Add package boundary rules that prevent UI layers from reaching directly into unrelated package internals.
- [ ] Add CODEOWNERS or an equivalent review rule for monetization, auth, admin, and security-sensitive areas.
- [ ] Convert architecture decisions into maintained ADRs for routing, payments, environment loading, and Firebase usage.
- [ ] Create release checklists for app store submission, payment changes, and moderation/admin changes.
