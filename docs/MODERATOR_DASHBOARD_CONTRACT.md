# Moderator Dashboard Contract

Last updated: 2026-06-28

This contract defines how the external moderator dashboard approves or rejects paid submissions without putting admin controls back in the mobile app.

## Collections

### `sponsorships`

Pending mobile submissions use:

- `status = pending`
- `paymentStatus = completed` or another store completion status
- `paymentFollowUpStatus = paid_pending_review`
- `iapProductId`
- `iapPurchaseId`
- `iapTransactionId`
- `businessName`
- `contactEmail`
- `phone`
- `businessAddress`
- `brandingNotes`
- `additionalNotes`
- `placementKeys`
- `tier`
- `startDate`
- `endDate`

Dashboard approval should set:

- `status = active`
- `paymentFollowUpStatus = paid_approved_active`
- `reviewedAt`
- `reviewedBy`
- `moderationNotes`
- `startDate = approval time`
- `endDate = approval time + purchased duration`

Dashboard rejection should set:

- `status = rejected`
- `paymentFollowUpStatus = rejected_review_refund_required`
- `reviewedAt`
- `reviewedBy`
- `moderationNotes`

Dashboard expiration should set:

- `status = expired`
- `endDate = now`
- `reviewedAt`
- `reviewedBy`
- `moderationNotes`

### `events`

Paid mobile submissions use:

- `moderationStatus = paid_pending_review`
- `isPublic = false`
- `metadata.submissionProductId`
- `metadata.submissionPurchaseId`
- `metadata.submissionTransactionId`
- `metadata.submissionPaymentStatus`
- `metadata.submissionAmount`
- `metadata.submissionCurrency`
- `metadata.submittedForReviewAt`

Dashboard approval should set:

- `moderationStatus = approved`
- `isPublic = true`
- `lastModerated`
- `reviewedBy`
- `reviewNotes`

Dashboard rejection should set:

- `moderationStatus = rejected`
- `isPublic = false`
- `lastModerated`
- `reviewedBy`
- `reviewNotes`

## Mobile Visibility Rules

The mobile app should only display public events that satisfy:

- `isPublic = true`
- `moderationStatus = approved`

The mobile app should only display sponsorships that satisfy:

- `status in [approved, active]`
- current time within `startDate` and `endDate`
- placement key matches the surface
- radius targeting matches when configured

## First Dashboard Scope

Required:

- pending sponsorship list
- pending event submission list
- approve
- reject
- expire sponsorship
- review notes
- reviewed by/date fields

Deferred:

- refunds
- upload review workflow
- granular moderator roles
- performance analytics
- full audit-log collection
