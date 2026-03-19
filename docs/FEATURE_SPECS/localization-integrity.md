# Localization Integrity

## Goal

Make translation work predictable by ensuring locale keys are created once,
validated automatically, and tracked in a way that prevents runtime warning
drift.

## Scope

- in scope:
  - English key parity enforcement
  - missing key cleanup
  - translation workflow consolidation
- out of scope:
  - rewriting the localization library
  - redesigning localized UI copy everywhere

## Affected Areas

- `assets/translations/*.json`
- `assets/translations/missing_keys.md`
- `test/sponsorship_localization_keys_test.dart`
- translation scripts under `scripts/`
- startup/runtime validation in `lib/main.dart`

## User Flow

1. developer adds a new key to `en.json`
2. validation reports missing keys in other locales
3. translations are added or intentionally deferred and tracked
4. app runs without avoidable runtime localization warnings

## Acceptance Criteria

- English is treated as the canonical locale file
- all locale files share the same key set for active keys
- missing keys are surfaced by a repeatable validation step
- runtime missing-key warnings are reduced to real regressions, not background
  noise

## Risks

- existing locale files may have drifted significantly
- translation scripts are fragmented and may overlap
- some warnings may be caused by dead or typoed keys in code rather than missing
  translations

## Validation

- locale parity test
- manual smoke on at least one non-English locale
- update `KNOWN_ISSUES.md` if unresolved warnings remain

## Current Implementation Status

- canonical report script added:
  `tools/localization/report_missing_keys.py`
- generated debt report lives at:
  `assets/translations/missing_keys.md`
- strict parity enforcement in tests/CI should happen only after current locale
  gaps are reduced to a manageable level
