# Artist Boosts Concept - Redesign Proposal

**Status:** Draft Proposal  
**Target:** Replace current "Gift/Token" system with a more engaging "Artist Boost" experience.

---

## 🚀 The Vision
Transition from a transactional "gift" system to a community-driven "boost" mechanism. Instead of "sending tokens," users "fuel the artist's journey."

## 🎭 Option 1: The Gallery Aesthetic
Focused on art-centric terminology and "spotlighting" the work.

| Price | Proposed Name | The "Vibe" | Benefits |
| :--- | :--- | :--- | :--- |
| **$4.99** | **The Spotlight** | ✨ *Instant Visibility* | 30 Days Featured Artist status. |
| **$9.99** | **The Gallery Glow** | 🖼️ *Portfolio Shine* | 90 Days Artist + 1 Featured Artwork. |
| **$24.99** | **The Canvas Conquest** | 🚀 *Major Exposure* | 180 Days Artist + 5 Artworks + Ad Rotation. |
| **$49.99** | **The ArtBeat Legend** | 👑 *Ultimate Legacy* | 1 Year Artist + 5 Artworks + Ad Rotation. |

---

## 🎮 Option 2: The Power-Up / Game Pack Vibe (Recommended)
This approach treats boosts like "Game Packs" or "DLC Expansion" for an artist's career. It uses terminology familiar to gamers (Buffs, Gear, Expansions).

| Price | Proposed Name | The "Vibe" | Benefits |
| :--- | :--- | :--- | :--- |
| **$4.99** | **The Quick Spark** | ⚡ *Instant Buff* | 30 Days "Glow" effect on profile + Featured status. |
| **$9.99** | **The Neon Surge** | 🌈 *Chroma Pack* | 90 Days Featured Artist + 1 "Shiny" Artwork slot. |
| **$24.99** | **The Titan Overdrive** | 🛡️ *Elite Gear* | 180 Days Max Visibility + 5 Slots + Global Ad Rotation. |
| **$49.99** | **The Mythic Expansion** | 💎 *Ultimate DLC* | 1 Year "Legendary" status + Zero Commission on next 3 sales. |

---

## 💎 Moving Beyond "Tokens"
Instead of "Credits" (which feel like a digital currency), we'll rebrand them as **Artist XP** or **Power Level**.

- **Artist XP**: Every boost grants the artist XP.
- **Progression**: High XP artists can unlock "Legendary" profile themes or exclusive community badges.
- **Why**: It feels like a video game achievement rather than a bank balance.

---

## ✨ Making it "Fun & Exciting"

### 1. Visual Celebration
- **The "Splash" Effect**: When a user sends a boost, a burst of digital paint splatters across the artist's profile for 3 seconds.
- **The "Pulse" Badge**: Boosted artists get a glowing animated ring around their profile picture in search results.

### 2. Community Engagement
- **The Wall of Patrons**: A small "Boosted By" section on the artist's profile showing recent supporters.
- **Boost Streaks**: "This artist has been boosted for 5 months in a row!" notifications.

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
[ BOOST THIS ARTIST ]
---------------------
(✨) THE SPOTLIGHT - $4.99
     "Put them on the map for 30 days"

(🖼️) GALLERY GLOW - $9.99
     "Make their profile and top art shine"

(🚀) CANVAS CONQUEST - $24.99
     "Full rotation in discovery & ads"

(👑) ARTBEAT LEGEND - $49.99
     "Ultimate support for one full year"
---------------------
[ SEND BOOST ]
```
