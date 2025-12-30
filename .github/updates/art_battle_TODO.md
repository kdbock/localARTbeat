# 🎨 Art Battle — TODO

Head-to-Head “Which Do You Like?” discovery system for Local ARTbeat  
Core goal: **drive discovery of newer artists**  
Monetization-ready via **rotating sponsors (every 5th match)**  
No rankings. No downvotes. Visibility only.

---

## PHASE 0 — PRODUCT RULES (LOCKED)

- [x] Art Battle is a **core app feature**
- [x] Any artwork may enter
- [x] System controls eligibility automatically
- [x] Artists may opt out **after current cycle**
- [x] No automatic aging out (manual / algorithmic only)
- [x] No comments, no downvotes, no rankings
- [x] Polling-based updates (no real-time infra)
- [x] Launch as **polished feature**
- [x] Same content rules as rest of app
- [x] Visibility-only rewards (no prizes)

---

## PHASE 1 — DATA MODELS

### Artwork Model (Extend Existing)

- [x] Add `artBattleEnabled: bool`
- [x] Add `artBattleStatus: enum`
  - `eligible`
  - `active`
  - `cooling_down`
  - `opted_out`
- [x] Add `artBattleScore: int`
- [x] Add `artBattleAppearances: int`
- [x] Add `artBattleWins: int`
- [x] Add `artBattleLastShownAt: timestamp`
- [x] Add `artBattleLastWinAt: timestamp`

> System-managed fields only (artists cannot edit directly)

---

### Art Battle Match Record

**Collection:** `art_battles`

- [x] Create collection
- [x] Fields:
  - `artworkAId`
  - `artworkBId`
  - `winnerArtworkId`
  - `timestamp`
  - `region`
  - `medium`
  - `isSponsored: bool`
  - `sponsorId (nullable)`

> Append-only. No edits after creation.

---

### Vote Record (Internal)

**Collection:** `art_battle_votes`

- [x] Create collection
- [x] Fields:
  - `battleId`
  - `artworkIdChosen`
  - `userId`
  - `timestamp`
  - `voteWeight`

> Admin / server access only.

---

## PHASE 2 — MATCHMAKING ENGINE

### ArtBattleMatchService

- [x] Create matchmaking service
- [x] Random selection with guardrails:
  - Same city/region preferred
  - Same medium/category preferred
  - Similar follower count preferred
- [x] Prevent same-artist matchups
- [x] Prevent recent repeat pairings
- [x] Allow big-name vs new artist (weighted)

---

### Exposure Control (Soft Limits)

- [ ] Reduce selection probability for:
  - High recent appearances
  - Long win streaks
- [ ] Boost selection probability for:
  - Lower exposure count
  - Newer artists
- [ ] No hard caps (algorithmic decay only)

---

## PHASE 3 — USER EXPERIENCE

### Entry Point

- [x] Add **Art Battle** to main navigation
- [ ] Optional secondary entry in home feed
- [ ] Copy: “Which one catches your eye?”

---

### Battle Screen (Swipe UI)

- [x] Swipe left / right interaction
- [x] Full artwork image only (no metadata)
- [x] Preload next matchup
- [x] Lightweight animation on vote

---

### Post-Vote Reveal

- [x] Reveal artist name only
- [ ] No profile link
- [x] Optional “View Artwork” CTA
- [x] Immediately advance to next matchup

---

## PHASE 4 — SCORING & VISIBILITY

### Vote Submission (Cloud Function)

**Function:** `submitArtBattleVote`

- [x] Validate authenticated user
- [x] Validate active battle
- [x] Anti-bot / abuse checks
- [x] Apply vote weighting
- [x] Increment:
  - Winning artwork score
  - Appearance counts
- [x] Record vote
- [x] Close battle

> Losing artwork receives **no penalty**.

---

### Visibility Boost Logic

- [ ] Increase future battle selection weight for winners
- [ ] Enable:
  - Feed feature eligibility
  - Badge/ribbon
  - Artist profile boost
  - Eligibility for special features

---

### Reward Expiration

- [ ] Rewards expire after **7 days**
- [ ] Auto-remove badge/ribbon
- [ ] Visibility boost decays naturally

---

## PHASE 5 — ARTIST DASHBOARD

### Read-Only Metrics

- [x] Display:
  - Total votes received
  - Number of battles appeared in
  - Featured appearances
  - Traffic driven
- [x] Do NOT display:
  - Opponents
  - Win/loss ratios
  - Rankings

---

## PHASE 6 — MODERATION & ADMIN

### Admin Controls

- [x] Remove artwork from battles
- [x] Temporarily exclude artist
- [x] Adjust scores manually
- [x] Freeze battles (global or scoped)
- [x] Log all admin actions

---

## PHASE 7 — SPONSOR ROTATION (MONETIZATION)

### Sponsor Injection

- [x] Inject sponsor every **5th battle**
- [x] Display: "Art Battle sponsored by X"
- [x] Store sponsor ID on battle record
- [x] Ensure sponsor has zero influence on outcome

---

### Sponsor Management (Later)

- [ ] Manual sponsor rotation list
- [ ] Admin-controlled only
- [ ] No bidding / targeting (initial)

---

## PHASE 8 — SAFETY, PERFORMANCE, POLISH

### Anti-Abuse

- [x] Throttle rapid voting
- [x] Detect repetitive patterns
- [x] Weight votes to reduce gaming
- [x] No visible enforcement messaging

---

### Performance

- [x] Image caching required
- [x] Pre-fetch matchups
- [x] Polling only (no websockets)

---

### Language Rules (Hard)

❌ Never use:

- win / lose
- beat / defeated
- rankings

✅ Approved language:

- Community Favorite
- Featured
- Getting noticed
- Discovered by the community

---

## OUT OF SCOPE (INTENTIONAL)

- Comments
- Live leaderboards
- Real-time updates
- Push notifications
- Monetary rewards
- Artist messaging
- Public comparisons

---

## FUTURE INTEGRATION (OPEN)

- [ ] Feed Art Battle signals into:
  - Auctions
  - Tours
  - Sponsored features
- [ ] Expand sponsor tools if demand exists
