# Artist Boosts Concept - Redesign Proposal

**Status:** Draft Proposal  
**Target:** Replace current "Gift/Token" system with a more engaging "Artist Boost" experience.

---

## 🚀 The Vision
Transition from a transactional "gift" system to a community-driven "boost" mechanism. Instead of "sending tokens," users "fuel the artist's journey."

## 🎮 Boost 2.0: "Fuel the Artist" (Recommended)
Boosts are not "time bought." Boosts are momentum earned. Each boost adds **Visibility Energy** that powers dynamic features across ARTbeat.

### ✅ Guardrails
- **Artists must benefit**: boosts directly improve discovery and local visibility.
- **Users feel like patrons**: boosts grant recognition + game rewards.
- **Game feel**: momentum meters, tiers, and unlocks.

### 🔥 Core Rules
- **Momentum Meter**: each boost adds Momentum points to the artist.
- **Momentum Decay**: Momentum decays 10% per week unless sustained by engagement.
- **Diminishing Returns**: after a weekly threshold, extra boosts add 50% value.
- **Caps**: per-artist weekly cap to prevent monopolies in local feeds.
- **Local-first**: boosts weigh strongest in the artist’s city/region.

---

## 🧭 Boost Impact Ladder (Guaranteed + Weighted)
Defines what boosts actually do and removes ambiguity.

| Tier | Impact Type | What It Does |
| :--- | :--- | :--- |
| **Small Boost** | **Weighted** | Increases local discovery ranking + “Who To Follow” weighting. |
| **Medium Boost** | **Weighted + Visible** | Adds map pin glow + boosts artist card priority. |
| **Large Boost** | **Guaranteed Slot** | Scheduled placement in a rotating “Kiosk Lane.” |

Notes:
- “Guaranteed” means a **rotation slot**, not permanent placement.
- “Weighted” means boosted probability, not a lock.

---

## 🎁 Supporter Rewards (User Loop)
Supporters should feel the boost as part of gameplay.

- **Patron Badges**: tiered badges (Spark / Surge / Overdrive).
- **Collector XP**: boosts grant XP toward profile cosmetics and titles.
- **Early Drop Access**: supporters get early access to the artist’s next drop.
- **Supporter Trail**: optional public list of recent patrons on artist profile.

---

## 💎 Moving Beyond "Tokens"
Instead of "Credits," use **Momentum** or **Artist XP**.

- **Momentum**: powers local discovery + kiosk rotation.
- **Artist XP**: a long-term progression layer (themes, badges, profile effects).
- **Why**: It feels like a video game achievement rather than a bank balance.

---

## ✨ Making it "Fun & Exciting"

### 1. Visual Celebration
- **The "Splash" Effect**: When a user sends a boost, a burst of digital paint splatters across the artist's profile for 3 seconds.
- **The "Pulse" Badge**: Boosted artists get a glowing animated ring around their profile picture in search results.

### 2. Community Engagement
- **The Wall of Patrons**: A small "Boosted By" section on the artist's profile showing recent supporters.
- **Boost Streaks**: "This artist has been boosted for 5 months in a row!" notifications.

### 3. Transparency for Artists
- **Momentum Meter**: visible to the artist with a simple breakdown.
- **Impact Preview**: “This boost increases your local discovery weight by X.”
- **Next Unlock**: shows the next milestone (e.g., “12 points to Kiosk Lane.”)

---

## 🛠️ Implementation Strategy

1.  **Codebase Refactor**:
    - Rename `InAppGiftService` → `ArtistBoostService`
    - Rename `GiftModel` → `ArtistBoostModel`
    - Update Firestore collections: `gifts` → `boosts`
2.  **UI Updates**:
    - `GiftSelectionWidget` → `ArtistBoostWidget`
    - Use vibrant, gradient-based cards for boost selection.
3.  **Data Migration**:
    - Map existing `giftCredits` to `artistXP`.
    - Ensure current active gifts are treated as "Active Boosts."

---

## 🎨 Proposed UI Mockup (Text-Based)
```
[ FUEL THIS ARTIST ]
----------------------
(🔥) SPARK - $4.99
     "Boosts local discovery + supporter badge"

(⚡) SURGE - $9.99
     "Adds map glow + follow weight"

(💎) OVERDRIVE - $24.99
     "Kiosk Lane rotation slot"
---------------------
[ SEND FUEL ]
```
TODO:
Momentum rules: weekly cap + diminishing returns enforcement and “local‑first” weighting by region (current sorting is global boostScore, not city/region‑aware).
Artist‑facing transparency: momentum meter, impact preview, and “next unlock” UI for artists.
Supporter rewards UX: patron badges/collector XP are stored, but there’s no surfaced badge UI or cosmetics unlock flow.
Early drop access: data is written (earlyAccess fields), but there’s no gating or UI to actually grant early access.
Boost streaks: no streak tracking + notification yet.
Map/kiosk parity: kiosk lane is on dashboard + storefront, but if you want it on map/art‑walk/kiosk screens, those aren’t wired.
Localization completeness: kiosk lane strings now exist, but other hardcoded boost/kiosk strings in store/boost screens are still English.