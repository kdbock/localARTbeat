# Legal Staging UI QA Session Report - YYYY-MM-DD

Project: `wordnerd-artbeat`  
Tester: <name>  
Build: <app version/build number>  
Scope: manual in-app legal/data-rights QA checklist

## Result Summary

- Overall result: PASS / FAIL
- Manual checklist reference: `docs/LEGAL_STAGING_MANUAL_QA_CHECKLIST.md`
- Start time (UTC):
- End time (UTC):

## Test Accounts

- User A (request submitter):
- Admin (queue processor):

## Evidence Index

- Screenshot folder:
- Video recording (optional):
- Firebase Console links (optional):

## Checklist Outcomes

- Settings > Privacy actions visible: PASS / FAIL
- User export request creation/status: PASS / FAIL
- User deletion request creation/status: PASS / FAIL
- Duplicate pending request blocked: PASS / FAIL
- Admin queue transitions (`pending -> in_review -> fulfilled`): PASS / FAIL
- Deletion callable completes without UI error: PASS / FAIL
- Post-deletion login blocked for User A: PASS / FAIL
- `/users/{userId}` removed: PASS / FAIL
- `dataRequestAudit` row exists with summary: PASS / FAIL
- Non-admin blocked from admin queue: PASS / FAIL

## Screenshot Evidence

1. User request list with pending export/deletion
- File:
- Notes:

2. Admin queue before processing
- File:
- Notes:

3. Admin queue after fulfillment
- File:
- Notes:

4. Deletion evidence (`dataRequestAudit` summary)
- File:
- Notes:

5. Non-admin access denied to admin queue
- File:
- Notes:

## Failures and Follow-Ups

- Failed step:
- Timestamp:
- Error/details:
- Follow-up ticket:
- Blocker for canary sign-off: YES / NO

## Sign-Off Inputs

- Product/legal owner review: APPROVED / PENDING
- Support readiness review: APPROVED / PENDING
- Notes:
