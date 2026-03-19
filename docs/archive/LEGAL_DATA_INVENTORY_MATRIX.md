# Legal Data Inventory Matrix (Expanded Coverage)

Owner: Kristy Kelly  
Entity: Local ARTbeat, LLC  
Environment baseline: `wordnerd-artbeat`  
Status: expanded rules-derived coverage baseline (Firestore + Storage); keep current with every schema/rules release.

## Scope

This matrix maps key legal/privacy data stores to:

- purpose
- access model
- retention expectation
- deletion behavior

## Firestore Collections (Core Legal/Privacy Focus)

| Collection | Purpose | Access Model (High-Level) | Retention | Deletion Behavior |
|---|---|---|---|---|
| `users` | Core account profile and account state | owner/admin by rules logic | while account active | deleted in deletion pipeline |
| `userSettings` | user preferences/settings | owner/admin | while account active | deleted in deletion pipeline |
| `notificationSettings` | notification controls | owner/admin | while account active | deleted in deletion pipeline |
| `privacySettings` | privacy settings (legacy/optional paths) | owner/admin | while account active | deleted in deletion pipeline |
| `securitySettings` | security preferences (legacy/optional paths) | owner/admin | while account active | deleted in deletion pipeline |
| `accountSettings` | account-level preferences (legacy/optional paths) | owner/admin | while account active | deleted in deletion pipeline |
| `captures` | user-generated capture content | owner/admin and feature-specific readers | until deleted/moderated | deleted by `userId` in pipeline |
| `posts` | user-generated social content | feature-scoped auth/public | until deleted/moderated | deleted by `userId` in pipeline |
| `comments` | user-generated comment content | feature-scoped auth/public | until deleted/moderated | deleted by `userId` in pipeline |
| `likes` | engagement state | feature-scoped | while related content exists | deleted by `userId` in pipeline |
| `notifications` | in-app notifications | owner/admin | operational | deleted by `userId` in pipeline |
| `socialActivities` | activity feed records | auth users/admin | operational | deleted by `userId` in pipeline |
| `artWalkProgress` | art walk participation progress | owner/admin | operational | deleted by `userId` in pipeline |
| `followers` / `following` | social graph roots | owner/admin | while account active | root docs deleted in pipeline |
| `localAds` | user-submitted ad records | owner/admin (plus public read paths) | policy-driven | deleted by `userId` in pipeline |
| `dataRequests` | data-rights queue (`pending/in_review/fulfilled/denied`) | owner/admin | legal ops evidence window | request docs deleted in pipeline for target user |
| `dataRequestAudit` | immutable-ish admin audit evidence | admin-only | retained per legal ops policy | retained (not removed by user pipeline) |
| `payments` | payment records | restricted/admin + service flows | up to 7 years (legal/tax) | retained carveout |
| `subscriptions` | subscription records | restricted/admin + service flows | up to 7 years (financial/legal context) | retained carveout |
| `payouts` | payout records | restricted/admin + service flows | up to 7 years | retained carveout |
| `earnings_transactions` | earnings ledger | restricted/admin + service flows | up to 7 years | retained carveout |
| `refundRequests` | refund request records | restricted/admin + service flows | up to 7 years | retained carveout |
| `gift_purchases` | gift purchase records | restricted/admin + participants | up to 7 years where financially relevant | retained carveout |
| `artwork_sales` | sale transaction records | restricted/admin + participants | up to 7 years | retained carveout |
| `commission_requests` | commission transaction records | restricted/admin + participants | up to 7 years where financially relevant | retained carveout |
| `directCommissions` / `direct_commissions` | direct commission transaction data | restricted/admin + participants | up to 7 years where financially relevant | retained carveout |

## Storage Paths (Core Legal/Privacy Focus)

| Path Prefix | Purpose | Access Model (High-Level) | Retention | Deletion Behavior |
|---|---|---|---|---|
| `users/{userId}/` | user root storage assets | owner/admin | while account active | deleted in pipeline |
| `profile_images/{userId}/` | profile image assets | owner/admin/public-read where configured | while account active | deleted in pipeline |
| `capture_images/{userId}/` | capture media | owner/admin | until deleted/moderated | deleted in pipeline |
| `artwork_images/{userId}/` | artwork images | owner/admin | until deleted/moderated | deleted in pipeline |
| `artwork_videos/{userId}/` | artwork videos | owner/admin | until deleted/moderated | deleted in pipeline |
| `artwork_audio/{userId}/` | artwork audio | owner/admin | until deleted/moderated | deleted in pipeline |
| `written_content/{userId}/` | written manuscripts/files | owner/admin | until deleted/moderated | deleted in pipeline |
| `artist_images/{userId}/` | artist profile/banner assets | owner/admin | while account active | deleted in pipeline |
| `post_images/{userId}/` | post image assets | owner/admin | until deleted/moderated | deleted in pipeline |
| `posts/{userId}/` | post media folders | owner/admin | until deleted/moderated | deleted in pipeline |
| `events/{userId}/` | event media assets | owner/admin | policy-driven | deleted in pipeline |
| `public_art_images/{userId}/` | public art media | owner/admin | policy-driven | deleted in pipeline |
| `art_walk_images/{userId}/` | art walk media | owner/admin | policy-driven | deleted in pipeline |
| `ads/{userId}/` | ad media | owner/admin | financial/legal policy-driven | deleted in pipeline for user-owned assets |
| `artist_ads/{userId}/` | artist ad media | owner/admin | financial/legal policy-driven | deleted in pipeline |
| `gallery_ads/{userId}/` | gallery ad media | owner/admin | financial/legal policy-driven | deleted in pipeline |
| `user_ads/{userId}/` | user ad media | owner/admin | financial/legal policy-driven | deleted in pipeline |
| `feedback_images/{userId}/` | support/feedback attachments | owner/admin | operational + legal needs | deleted in pipeline |
| `chat_media/{chatId}/` | shared chat media | authenticated participants model (currently auth-wide write in rules) | message lifecycle policy | not user-prefix deletable today; requires chat ownership mapping |
| `chat_images/{chatId}/` | shared chat images | authenticated participants model | message lifecycle policy | not user-prefix deletable today; requires chat ownership mapping |

## Full Dataset Coverage (Rules-Derived Classification)

Coverage objective: every rules-defined dataset has a legal handling class and deletion expectation.

### Firestore Coverage Classes

| Class | Collections | Retention/Deletion Expectation |
|---|---|---|
| Account identity + settings | `users`, `userSettings`, `notificationSettings`, `privacySettings`, `securitySettings`, `accountSettings`, `messageStats`, `unreadCounts`, `calendarSettings`, `blockedUsers`, `discoveries` | active account lifecycle; delete on account deletion except legal carveouts |
| Social graph + feed | `posts`, `comments`, `likes`, `applause`, `followers`, `following`, `artistFollows`, `socialActivities`, `user_posts`, `notifications`, `user_activity` | operational lifecycle; delete/de-identify by user on account deletion |
| Messaging + chat | `chats`, `messages`, `typing`, `archivedChats` | shared conversation lifecycle; participant-aware retention/deletion policy required |
| Creative + portfolio | `captures`, `artists`, `artistProfiles`, `artworks`, `artwork`, `files`, `visits`, `favorites`, `completedWalks`, `achievements`, `dailyChallenges`, `weeklyGoals` | content lifecycle; delete user-owned artifacts on account deletion |
| Events + location | `events`, `pendingEvents`, `flaggedEvents`, `artWalks`, `artWalkProgress`, `publicArt`, `artLocationClusters`, `chapter_analytics`, `monthly_stats`, `chapters`, `quests`, `galleries` | policy-driven operational retention; user-owned records removed on account deletion |
| Commerce + finance (retained carveout) | `payments`, `subscriptions`, `payouts`, `earnings_transactions`, `refundRequests`, `gift_purchases`, `artwork_sales`, `commission_requests`, `directCommissions`, `direct_commissions`, `commissions`, `giftSubscriptions`, `giftCampaigns`, `contributions`, `coupons`, `ticket_purchases`, `gifts` | retain up to 7 years where required for legal/accounting/tax/dispute defense |
| Ads + sponsorship | `ads`, `localAds`, `artist_approved_ads`, `title_sponsorships`, `sponsorships`, `engagements`, `ad_analytics`, `analytics` | operational + contractual retention; user-owned assets removed, financial proofs retained as required |
| Moderation + trust/safety | `content_reviews`, `content_review_logs`, `commission_disputes`, `commission_ratings`, `commission_templates`, `commission_analytics`, `moderationAnalytics`, `developer_feedback`, `evidence`, `content`, `artist_reputation`, `artist_momentum`, `artist_features`, `artistProfileViews`, `artist_earnings`, `boosts`, `artist_boosters`, `boosters`, `bids`, `auction_results` | retain per abuse/dispute/legal necessity; define explicit retention windows in policy table |
| Legal operations | `dataRequests`, `dataExportRequests`, `dataDeletionRequests`, `dataRequestAudit`, `admin`, `broadcasts` | legal ops evidence retention; `dataRequestAudit` retained/admin-controlled |

### Storage Coverage Classes

| Class | Paths | Retention/Deletion Expectation |
|---|---|---|
| User-owned profile/content media | `users/`, `profile_images/`, `capture_images/`, `artwork_images/`, `artwork_videos/`, `artwork_audio/`, `written_content/`, `artist_images/`, `post_images/`, `posts/`, `events/`, `public_art_images/`, `art_walk_images/`, `feedback_images/` | delete by user prefix in deletion pipeline |
| Ads/media | `ads/`, `admin_ads/`, `artist_ads/`, `gallery_ads/`, `user_ads/`, `artist_approved_ads/` | delete user-owned prefixes; retain legal/financial evidence where required |
| Shared chat media | `chat_media/`, `chat_images/` | shared lifecycle; requires participant-aware ownership metadata and deletion logic |
| Legacy/debug/admin-only paths | `profile/`, `artwork/`, `captures/`, `art_walks/`, `art_walks_debug/`, `debug_uploads/`, `temp_uploads/`, `uploads/` | admin-only or debug-restricted; verify no accidental production dependency |

## Known Gaps To Close

- Map and implement deletion behavior for shared chat media (`chat_media`, `chat_images`) by participant ownership.
- Confirm analytics/event telemetry datasets and whether deletion requests require pseudonymization/deletion there.
- Add documented retention windows per collection/path in an enforceable policy table.
- Add evidence retention policy for `dataRequestAudit`.

## Shared Chat Media Lifecycle (Expanded)

### Current State

- Storage paths:
- `chat_media/{chatId}/{fileName}`
- `chat_images/{chatId}/{fileName}`
- Access:
- storage uploads are authenticated; participant enforcement is now enforced on Firestore message creation for media messages
- Deletion pipeline:
- deletion pipeline now scans sender-owned chat messages and removes referenced `chat_media/` / `chat_images/` objects, then redacts message media fields

### Required Controls

- Enforce participant-aware authorization where chat media is committed to conversation state:
- `chats/{chatId}/messages` media create now requires:
- `senderId == auth.uid`
- `storagePath`, `uploaderId`, `chatId` present and consistent
- `storagePath` constrained to `chat_images/{chatId}/...` or `chat_media/{chatId}/...`
- Maintain metadata requirements on upload:
- uploader user ID
- chat ID
- createdAt
- message ID linkage (for traceability and delete-by-owner queries)
- Server-side cleanup implemented in deletion callable:
- remove chat media owned by deleted user (by message references)
- redact media fields in historical message docs to preserve thread integrity
- preserve evidence only where legally required
- Add retention policy for chat attachments and deleted-account references.

### Concrete Implementation Target (Next Patch)

1. Require Firestore message docs to store `senderId`, `storagePath`, and `mediaType` for all media messages.
2. Tighten Storage rules for `chat_media`/`chat_images`:
   - write only if requester is chat participant and metadata `uploaderId == request.auth.uid`
   - delete only by uploader or admin
3. Extend deletion pipeline:
   - query chat message docs by `senderId == userId`
   - delete referenced storage objects
   - soft-mark messages as removed or replace with tombstone text where thread integrity is needed
4. Add retention carveout:
   - preserve abuse/dispute evidence artifacts if tied to active legal/safety case
5. Add automated regression:
   - owner upload allow, non-participant deny, cross-user delete deny, account deletion cleanup for user-owned chat media.

### Interim Legal Posture

- Chat media is currently treated as shared conversation data and may persist until chat/content policy actions remove it.
- This is a documented exception candidate and should be reflected in final policy-to-product mapping.

## Full Rules-Derived Dataset Index (Coverage Baseline)

The following is the current rules-derived index for legal coverage expansion.

### Firestore (collection/subcollection identifiers found in `firestore.rules`)

- `flaggedEvents`
- `pendingEvents`
- `moderationAnalytics`
- `users`
- `messageStats`
- `unreadCounts`
- `completedWalks`
- `achievements`
- `favorites`
- `dailyChallenges`
- `weeklyGoals`
- `notifications`
- `archivedChats`
- `calendarSettings`
- `blockedUsers`
- `discoveries`
- `artists`
- `artistProfiles`
- `artist_boosters`
- `boosters`
- `artist_earnings`
- `artworkViews`
- `artworks`
- `bids`
- `auction_results`
- `earnings_transactions`
- `payouts`
- `artistProfileViews`
- `artist_momentum`
- `artist_features`
- `boosts`
- `artist_commission_settings`
- `direct_commissions`
- `artwork_sales`
- `commission_requests`
- `gift_purchases`
- `localAds`
- `chats`
- `messages`
- `typing`
- `notificationSettings`
- `events`
- `ticket_purchases`
- `artwork`
- `chapters`
- `subscriptions`
- `artWalks`
- `comments`
- `ratings`
- `visits`
- `publicArt`
- `galleries`
- `commissions`
- `directCommissions`
- `files`
- `milestones`
- `artistCommissionSettings`
- `commission_ratings`
- `artist_reputation`
- `commission_disputes`
- `evidence`
- `commission_templates`
- `commission_analytics`
- `coupons`
- `giftCampaigns`
- `contributions`
- `giftSubscriptions`
- `captures`
- `posts`
- `applause`
- `likes`
- `followers`
- `following`
- `artistFollows`
- `user_activity`
- `developer_feedback`
- `ads`
- `artist_approved_ads`
- `analytics`
- `ad_analytics`
- `title_sponsorships`
- `engagements`
- `content_reviews`
- `content_review_logs`
- `content`
- `artWalkProgress`
- `artLocationClusters`
- `socialActivities`
- `user_posts`
- `sponsorships`
- `quests`
- `chapter_analytics`
- `monthly_stats`
- `gifts`
- `broadcasts`
- `dataRequests`
- `dataExportRequests`
- `dataDeletionRequests`
- `dataRequestAudit`
- `admin`

### Storage (path prefixes found in `storage.rules`)

- `profile`
- `artwork`
- `post_images`
- `debug_uploads`
- `artwork_images`
- `artwork_videos`
- `artwork_audio`
- `written_content`
- `artist_images`
- `capture_images`
- `captures`
- `posts`
- `profile_images`
- `feedback_images`
- `public_art_images`
- `events`
- `art_walk_images`
- `art_walks`
- `art_walks_debug`
- `temp_uploads`
- `uploads`
- `ads`
- `admin_ads`
- `artist_ads`
- `gallery_ads`
- `user_ads`
- `artist_approved_ads`
- `chat_images`
- `chat_media`

## Change Control

- Update this matrix before deploying new collections/paths.
- Review monthly during legal/compliance routine.
- Keep this file synchronized with:
- `functions/src/index.js` deletion pipeline summary
- `firestore.rules`
- `storage.rules`
