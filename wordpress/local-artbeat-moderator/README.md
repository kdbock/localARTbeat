# Local ARTbeat Admin WordPress Plugin

Private WordPress admin dashboard for Local ARTbeat analytics, capture review, paid sponsorship moderation, and event submission moderation.

## What It Does

- Shows an overview of captures, users, events, sponsorships, and paid review backlog
- Lists recent captures from Firestore collection `captures`
- Provides capture filters for recent, public, flagged, promoted, and social candidates
- Generates social-ready caption text for reviewed captures
- Displays capture locations from `locationName`, `address`, or Firestore `location` coordinates
- Shares capture image URLs to Facebook and copies the generated caption for posting
- Publishes capture images directly as Facebook Page photo posts when a Page ID and Page access token are configured
- Marks captures as promoted, clears promoted status, flags captures, approves captures, or rejects captures
- Lists pending sponsorships from Firestore collection `sponsorships`
- Lists paid pending event submissions from Firestore collection `events`
- Approves, rejects, or expires sponsorships
- Approves or rejects event submissions
- Keeps admin and moderation out of the mobile app

## Install

1. Copy this folder to the WordPress site:

   `wp-content/plugins/local-artbeat-moderator`

2. Activate **Local ARTbeat Moderator** in WordPress Plugins.
3. Open **Local ARTbeat > Settings**.
4. Enter Firebase project ID:

   `wordnerd-artbeat`

5. Paste the entire restricted Firebase service account JSON file contents, or preferably a base64-encoded copy of the JSON.
6. Optional: add Facebook Page ID and Page access token if you want **Post Photo to Facebook Page** to publish actual image posts.
7. Open **Local ARTbeat** in the WordPress admin sidebar.

## Firebase Service Account

Create a dedicated service account for the dashboard. Do not use a personal Google account.

Minimum recommended access:

- read `sponsorships`
- update `sponsorships`
- read `events`
- update `events`
- read `captures`
- update `captures`
- read `users`

The plugin uses the Firestore REST API with a signed service-account JWT.

## Facebook Page Posting

The public Facebook share dialog only shares links. To post the actual capture image with the generated Local ARTbeat caption, configure:

- `Facebook Page ID`
- `Facebook Page access token`

The access token must be for a Page you manage and must allow publishing Page posts. The plugin sends the capture image URL and caption to Meta's Page photo publishing endpoint, then stores the returned `facebookPostId` on the capture.

The JSON must look like the full downloaded file:

```json
{
  "type": "service_account",
  "project_id": "wordnerd-artbeat",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "...@...iam.gserviceaccount.com",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

Do not paste only the `private_key` value.

## Approval Effects

### Capture Mark Promoted

Sets:

- `adminPromotionStatus = promoted`
- `promotedAt = now`
- `promotedBy = WordPress user email/login`
- review metadata

### Capture Clear Promoted

Sets:

- `adminPromotionStatus = not_promoted`
- review metadata

### Capture Approve Public

Sets:

- `status = approved`
- `isPublic = true`
- `isFlagged = false`
- review metadata

### Capture Flag

Sets:

- `isFlagged = true`
- `adminFlaggedAt = now`
- review metadata

### Capture Reject

Sets:

- `status = rejected`
- `isPublic = false`
- `moderationNotes = notes`
- review metadata

### Sponsorship Approve

Sets:

- `status = active`
- `paymentFollowUpStatus = paid_approved_active`
- `reviewedAt = now`
- `reviewedBy = WordPress user email/login`
- `moderationNotes = notes`
- `startDate = now`
- `endDate = now + original purchased duration`

### Sponsorship Reject

Sets:

- `status = rejected`
- `paymentFollowUpStatus = rejected_review_refund_required`
- `reviewedAt = now`
- `reviewedBy = WordPress user email/login`
- `moderationNotes = notes`

### Sponsorship Expire

Sets:

- `status = expired`
- `endDate = now`
- review metadata

### Event Approve

Sets:

- `moderationStatus = approved`
- `isPublic = true`
- `lastModerated = now`
- `reviewedBy = WordPress user email/login`
- `reviewNotes = notes`

### Event Reject

Sets:

- `moderationStatus = rejected`
- `isPublic = false`
- `lastModerated = now`
- `reviewedBy = WordPress user email/login`
- `reviewNotes = notes`

## Security Notes

- Restrict access to WordPress users with `manage_options`.
- Keep the service account JSON secret.
- Prefer a dedicated service account that only has the permissions needed for review.
- Put the WordPress admin behind strong passwords and MFA.
- Do not expose this plugin on a public page.

## Current Limitations

- No refund automation yet.
- No audit log collection yet beyond Firestore review fields.
- No role split between admin and moderator yet; WordPress `manage_options` controls access.
- Analytics are intentionally lightweight and computed from recent Firestore documents, not a warehouse.

Those are intentional for the first version.
