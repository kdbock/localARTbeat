# Legal Staging Manual QA Checklist (Single Session)

Owner: Kristy Kelly  
Environment: `wordnerd-artbeat` (staging)  
Goal: manually verify legal/data-rights UX and admin workflow in one session.

## Session Setup (5-10 min)

- [x ] Confirm app build points to staging Firebase project.
- [ x] Confirm admin account can access admin data-requests screen.
- [ x] Prepare two test users:
- [ x] `User A` (normal user) for request submission.
- [x ] `Admin` (userType=`admin`) for queue processing.
- [ x] Open a notes doc and record:
- [ x] date/time
- [x ] app build/version
- [x ] tester name
- [x ] test user IDs/emails

## Preflight Checks (5 min)

- [x ] Open Privacy Policy screen and verify security wording is current and non-overpromising.
Expected:
- Security section mentions safeguards and encrypted channels.
- No claim that cannot be directly proven (for example forced 2FA guarantee).

- [ ] Open Settings > Privacy and confirm Data Rights actions are visible.
Expected:
- `Request Data Export`
- `Request Data Deletion`
- Recent requests/status list visible.

## User Flow: Create Requests (10-15 min)

Using `User A`:

- [ ] Submit Data Export request.
Expected:
- Success feedback shown.
- Request appears in recent requests with `pending` state.
- Requested timestamp shown.

- [ ] Submit Data Deletion request.
Expected:
- Success feedback shown.
- Request appears in recent requests with `pending` state.

- [ ] Attempt duplicate same-type request while pending.
Expected:
- Duplicate blocked with clear error message.

Evidence:
- [ ] Screenshot of user request list with pending entries.
- [ ] Copy request IDs from Firestore (if available).

## Admin Flow: Queue Processing (15-20 min)

Using `Admin`:

- [ ] Open admin data-rights queue screen.
Expected:
- Requests visible with user ID, request type, status, and SLA due fields.

- [ ] Filter by `pending`.
Expected:
- Newly created requests are shown.

- [ ] Move Export request `pending -> in_review`.
Expected:
- Status updates to `in_review`.
- `acknowledgedAt` is set.

- [ ] Move Export request `in_review -> fulfilled`.
Expected:
- Status updates to `fulfilled`.
- `fulfilledAt` is set.

- [ ] For Deletion request, set `pending -> in_review`.
Expected:
- Acknowledged timestamp appears.

- [ ] Set Deletion request `in_review -> fulfilled` (triggers callable pipeline).
Expected:
- No UI error.
- Request ends as `fulfilled`.
- `reviewedBy` and notes (if entered) are stored.

Evidence:
- [ ] Screenshot of admin queue before and after status transitions.
- [ ] Screenshot or log of fulfilled deletion item.

## Deletion Verification (10-15 min)

After deletion fulfillment for `User A`:

- [ ] Attempt login as `User A`.
Expected:
- Login fails because auth account is deleted.

- [ ] Check Firestore for deleted user document.
Expected:
- `/users/{userId}` does not exist.

- [ ] Check `dataRequestAudit` for the processed deletion request.
Expected:
- Audit row exists with requestId, performedBy, summary.

- [ ] Confirm retained collections behavior is documented in summary (financial/legal carveout).
Expected:
- Retained collection list present in callable summary/audit.

Evidence:
- [ ] Screenshot or copied JSON summary from callable/audit record.

## Security Regression Spot-Check (5-10 min)

- [ ] Confirm non-admin cannot access admin queue screen.
Expected:
- Access denied/blocked route.

- [ ] Confirm non-owner cannot write to owner-scoped storage paths (spot-check via existing script output or dev test panel).
Expected:
- Denied.

## Exit Criteria (Pass/Fail)

Mark session PASS only if all are true:

- [ ] User can submit requests and see status.
- [ ] Admin can process queue through all statuses.
- [ ] Deletion fulfillment removes auth + user profile doc.
- [ ] Audit evidence exists for deletion.
- [ ] No legal/policy UX mismatch discovered.

If any item fails:

- [ ] Record exact failure step + timestamp.
- [ ] Capture screenshot/log.
- [ ] Create follow-up ticket and block production canary until resolved.

## Session Report Template

- Date:
- Tester:
- Build:
- Project:
- User A:
- Admin:
- Result: PASS / FAIL
- Failed steps (if any):
- Evidence links/notes:
