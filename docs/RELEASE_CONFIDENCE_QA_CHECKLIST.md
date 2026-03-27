# Release Confidence QA Checklist

Use this checklist for the next targeted manual QA pass after the recent reliability and foundation cleanup.

Execution labels:

- `Simulator`: reasonable to complete on simulator/emulator
- `Partial`: useful on simulator, but still needs a real-device follow-up
- `Device Required`: should be treated as real-device validation

## Purpose

This checklist focuses on the highest-value flows that were recently hardened in code and now need real-device verification.

## Current Status

Manual QA pass completed on 2026-03-26.

Outcome:

- account and profile persistence passed
- paid local ads and sponsorship review flows passed for the targeted release-confidence checks performed in this session
- capture upload reliability passed
- chat media upload reliability passed for location, gallery, and camera sends after storage/upload hardening and Storage rule alignment
- admin data-rights deletion handling passed

Notes:

- chat media upload reliability required a foundation fix, not a UI-only fix:
  - shared Firebase Storage upload retry/token-refresh behavior was standardized
  - chat Storage authorization in `storage.rules` was aligned with the actual chat participant contract and redeployed
- no blocking failures remained at closeout for the checklist items exercised in this pass

## Priority Order

1. account and profile persistence
2. paid local ads and sponsorship review flows
3. capture upload reliability
4. chat media upload reliability
5. admin data-rights deletion handling

## 1. Account And Profile Persistence

Environment: `Simulator`

- `Simulator`: Sign in as a normal user.
- `Simulator`: Open [account_settings_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_settings/lib/src/screens/account_settings_screen.dart).
- `Simulator`: Change display name, username, and bio.
- `Simulator`: Save changes and confirm the success message appears.
- `Simulator`: Force-close and relaunch the app.
- `Simulator`: Confirm display name, username, and bio persist after reload.
- `Simulator`: Confirm the profile/avatar header surfaces the updated display name.
- `Partial`: Change the profile photo.
- `Partial`: Confirm the new profile photo persists after relaunch.
- `Device Required`: Verify phone verification persists the updated phone number and verified state.

Pass criteria:
- no silent reversion to prior values
- no mismatch between `displayName` and `fullName` surfaces
- profile photo remains visible after relaunch

## 2. Paid Local Ads And Sponsorships

Environment: `Partial`

- `Device Required`: Create a paid local ad through [create_local_ad_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_ads/lib/src/screens/create_local_ad_screen.dart).
- `Partial`: Confirm the success dialog explains review/billing expectations clearly.
- `Partial`: Confirm the ad appears in `My Ads` with pending review status.
- `Simulator`: Reject one paid ad in admin and verify payment follow-up state appears clearly in [admin_ad_management_widget.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_admin/lib/src/widgets/admin_ad_management_widget.dart).
- `Device Required`: Create one sponsorship through [sponsorship_review_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/lib/src/screens/sponsorships/sponsorship_review_screen.dart).
- `Simulator`: Confirm the saved sponsorship record surfaces payment follow-up state in:
  - [sponsorship_detail_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_sponsorships/lib/src/screens/sponsorships/sponsorship_detail_screen.dart)
  - [admin_sponsorship_moderation_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_admin/lib/src/screens/moderation/admin_sponsorship_moderation_screen.dart)

Pass criteria:
- paid submissions are visible to admins with actionable payment state
- no ambiguity about pending review versus refund/payment follow-up

## 3. Capture Upload Reliability

Environment: `Partial`

- `Partial`: Create a new capture while online.
- `Partial`: Confirm normal upload succeeds.
- `Partial`: Create a capture while offline or after forcing network interruption.
- `Partial`: Confirm the capture is queued instead of failing hard.
- `Partial`: Restore connectivity and verify the queued capture syncs later.
- `Partial`: Confirm no duplicate capture records are created after sync.

Real-device follow-up still needed for actual camera behavior, permissions, and storage quirks.

Relevant code:
- [capture_view_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_capture/lib/src/screens/capture_view_screen.dart)
- [capture_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_capture/lib/src/services/capture_service.dart)
- [offline_queue_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_capture/lib/src/services/offline_queue_service.dart)

Pass criteria:
- offline/unstable network path degrades into queueing
- queued capture eventually syncs without manual database repair

## 4. Chat Media Upload Reliability

Environment: `Partial`

- `Simulator`: Open a 1:1 chat.
- `Partial`: Send an image from gallery.
- `Device Required`: Send an image from camera.
- `Partial`: Confirm only one upload starts at a time.
- `Partial`: Simulate a transient failure if possible.
- `Partial`: Confirm the error snackbar offers retry.
- `Partial`: Retry the same media send and confirm it succeeds.
- `Partial`: Confirm no duplicate messages appear after retry.
- `Partial`: Confirm there are no stuck broken-image messages for the failed attempt.

Relevant code:
- [chat_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_messaging/lib/src/screens/chat_screen.dart)
- [chat_service.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_messaging/lib/src/services/chat_service.dart)

Pass criteria:
- transient upload failures can be retried cleanly
- no duplicate sends from repeated taps
- no obvious orphaned or broken media path after retry

## 5. Admin Data Rights Deletion

Environment: `Simulator`

- `Simulator`: Submit a deletion request from [privacy_settings_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_settings/lib/src/screens/privacy_settings_screen.dart).
- `Simulator`: Open [admin_data_requests_screen.dart](/Volumes/ExternalDrive/DevProjects/artbeat/packages/artbeat_admin/lib/src/screens/admin_data_requests_screen.dart).
- `Simulator`: Confirm the request shows SLA info, processing state, and any prior failure details.
- `Simulator`: Run the deletion pipeline from the explicit confirmation flow.
- `Simulator`: If it fails, confirm the screen now surfaces:
  - processing timestamps
  - current step / failed step
  - latest pipeline steps
  - processing error details

If this is pointed at production-like or destructive data, use staging/test accounts only.

## Simulator-First Order

If you want to knock out the most simulator-safe work first, do it in this order:

1. `Simulator`: Account and profile persistence
2. `Simulator`: Admin data-rights deletion flow
3. `Simulator`: Admin moderation visibility for paid ads and sponsorships
4. `Partial`: Chat gallery upload and retry behavior
5. `Partial`: Capture offline queue behavior

Leave these for real devices:

1. `Device Required`: payments and billing flows
2. `Device Required`: camera-based chat/capture flows
3. `Device Required`: phone verification

Pass criteria:
- admins have enough on-screen data to decide whether to retry or escalate
- destructive fulfillment requires explicit confirmation

## Closeout

After the session:

- update [KNOWN_ISSUES.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/KNOWN_ISSUES.md) with any still-reproducible failures
- update [WORK_QUEUE.md](/Volumes/ExternalDrive/DevProjects/artbeat/docs/WORK_QUEUE.md) if release risk changed
- capture screenshots or short notes for any blocking issue

Closeout completed for the 2026-03-26 pass:

- no checklist blocker remained reproducible
- messaging media authorization issue was resolved through shared upload hardening plus `storage.rules` changes and Firebase Storage rules redeploy
