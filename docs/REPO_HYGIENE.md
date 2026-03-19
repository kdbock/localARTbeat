# Repo Hygiene

## Purpose

Track what belongs in the repo root, what does not, and how cleanup should be
done without disrupting active development or production support.

## Current Situation

The repo root currently contains a mix of:

- primary source/config files
- durable operational files
- one-off utility scripts
- exported text/data artifacts
- debug/log output
- local secret/config files

That mix makes the project harder to navigate and easier to change incorrectly.

## Root Classification

### Keep In Root

These are normal root-level files:

- `README.md`
- `pubspec.yaml`
- `pubspec.lock`
- `analysis_options.yaml`
- `firebase.json`
- `firestore.rules`
- `storage.rules`
- `package.json`
- `package-lock.json`
- top-level environment templates such as `.env.example`

### Move Out Of Root Over Time

These should live in a clearer home once verified safe to move:

- one-off utility scripts:
  - `check_users.js`
  - `cleanup_json.py`
  - `create_test_artist_profile.js`
  - `debug_users.js`
  - `extract_english_text.py`
  - `extract_strings.py`
  - `add_crashlytics_build_phase.sh`
  - `sync_comment_counts.dart`
  - `test_app_check.dart`
  - `translate_de.py`
  - `translate_de_simple.py`
  - `verify_fix.dart`
- exported or analysis artifacts:
  - `artbeat_*_texts_data.json`
  - `english_texts_data.json`
  - `existing_profile_keys.txt`
  - `used_profile_keys.txt`
  - `deps.txt`
  - `fields`
- one-off notes:
  - `WHATS_NEW.md`
  - `legal_system_full_checklist.md`
  - `finding-forgiveness-STANDARD-PRINT-READY.txt`
  - `delete_data.html`

Target homes:

- `tools/`
- `docs/archive/`
- feature-specific subfolders if still actively used

Initial archival moves completed:

- `docs/manual_qa_result.md` ->
  `docs/archive/manual_qa_result_2026-02-27.md`
- `docs/IMPLEMENTATION_PROGRESS.md` ->
  `docs/archive/IMPLEMENTATION_PROGRESS.md`
- `docs/2026-02-26_legal_security_recap.md` ->
  `docs/archive/2026-02-26_legal_security_recap.md`
- extracted text-analysis artifacts moved under:
  `tools/text-extraction/data/`
- root text-extraction scripts moved under:
  `tools/text-extraction/scripts/`
- legacy standalone root scripts moved under:
  `tools/legacy-root-scripts/`
- `add_crashlytics_build_phase.sh` ->
  `tools/legacy-root-scripts/add_crashlytics_build_phase.sh`
- `sync_comment_counts.dart` ->
  `tools/legacy-root-scripts/sync_comment_counts.dart`
- `test_app_check.dart` ->
  `tools/legacy-root-scripts/test_app_check.dart`
- `legal_system_full_checklist.md` ->
  `docs/archive/legal_system_full_checklist.md`
- `finding-forgiveness-STANDARD-PRINT-READY.txt` ->
  `docs/archive/finding-forgiveness-STANDARD-PRINT-READY.txt`
- `WHATS_NEW.md` ->
  `docs/archive/WHATS_NEW_2026-01-28.md`
- `delete_data.html` ->
  `docs/archive/delete_data_google_play_account_deletion_page.html`
- `fields` ->
  `docs/archive/flutter_widget_dump_fields.txt`

### Should Not Be Committed Or Relied On

These are local/debug artifacts and should remain ignored:

- `firebase-debug.log`
- `firestore-debug.log`
- `flutter_*.log`
- `flutter_output.log`
- `appcheck_test.log`
- `test_results.log`
- `pglite-debug.log`
- `build_log.txt`
- `catlog`
- `.backup`

### Sensitive Or Local-Only Files

Treat these as local-only and avoid editing casually in source-control work:

- `.env`
- `.env.local`
- `key.properties`
- `service-account-key.json`

## Package-Level Cleanup Targets

Observed package-local residue includes:

- `packages/*/.dart_tool`
- `packages/*/build`
- `packages/*/coverage`
- `packages/artbeat_admin/.git`
- `packages/artbeat_profile/ios`

Not all of these should be removed blindly. Some may reflect intentional local
workflows or historical package scaffolding. Cleanup must happen only after
verifying they are not still referenced.

Audit details:

- see `docs/PACKAGE_RESIDUE_AUDIT.md`

Current decision:

- `packages/artbeat_admin/.git` was accidental residue and is removed
- `packages/artbeat_profile/ios` appears to be an unused standalone scaffold,
  but because it is tracked source it should only be removed in a dedicated
  cleanup change, not during opportunistic repo-hygiene work

## Safe Cleanup Order

1. tighten ignore rules
2. create destination folders and guidance
3. inventory tracked files and classify them
4. move clearly inactive tracked artifacts in small batches
5. verify builds/tests still work
6. remove unusual package-local project residue after targeted review

## Rules

- do not mix cleanup with production bug fixes
- move files in small batches with clear commit messages
- prefer archiving to deleting when provenance is unclear
- every cleanup batch should be reversible
