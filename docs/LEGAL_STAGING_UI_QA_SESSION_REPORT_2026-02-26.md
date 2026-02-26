# Legal Staging UI QA Session Report - 2026-02-26

Project: `wordnerd-artbeat`  
Tester: Codex (terminal execution)  
Scope requested: full manual in-app QA checklist + deployment/CI evidence

## Result Summary

- Automated legal regression: PASS
- Production canary deploy: PASS
- Manual in-app tap-through UI checklist: NOT EXECUTED in this terminal session (requires device/emulator interaction)
- CI secret configuration and workflow run: PASS
- Shared chat media lifecycle hardening regression: PASS (rules + message authorization + deletion pipeline deploy)

## Executed Evidence

1. Canary deploy
   - Command: `PROJECT_ID=wordnerd-artbeat ./scripts/legal_canary_deploy.sh`
   - Result: deploy complete, rules + `processDataDeletionRequest` updated.
2. End-to-end legal regression (post-deploy)
   - Command: `PROJECT_ID=wordnerd-artbeat ADMIN_EMAIL=<set> ADMIN_PASSWORD=<set> ./scripts/legal_staging_regression.sh`
   - Result: local tests passed (`+62`), rule checks passed (`403/200/200/200/403/403`), admin callable returned `ok: true` with deletion summary (`authDeleted: true`).
3. GitHub Actions workflow validation
   - Workflow run: `legal_staging_regression.yml` run `22424833231`
   - Result: `success`
4. Shared chat media hardening regression
   - Command: `PROJECT_ID=wordnerd-artbeat ./scripts/legal_staging_regression.sh`
   - Result highlights:
     - `chat_media_upload_http=200`
     - `chat_message_participant_create_http=200`
     - `chat_message_non_participant_create_http=403`

## Manual UI Checklist Status

Reference: `docs/LEGAL_STAGING_MANUAL_QA_CHECKLIST.md`

- Status: pending interactive execution.
- Reason: no emulator/device UI control from this terminal-only run.

## CI Workflow Status

- Workflow file exists: `.github/workflows/legal_staging_regression.yml`
- Helper script exists: `scripts/legal_ci_setup_and_run.sh`
- Required secrets:
  - `STAGING_ADMIN_EMAIL`
  - `STAGING_ADMIN_PASSWORD`
  - `STAGING_FIREBASE_API_KEY`
  - `STAGING_FIREBASE_STORAGE_BUCKET`
- Status:
  - Configured and validated.
  - Evidence: GitHub Actions run `22424833231` completed `success`.
