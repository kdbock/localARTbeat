# Artist Overhaul: From SaaS to Studio Tool

## 🎯 Objective
Pivot the `artbeat_artist` experience from a "tech platform" to a **professional tool for working artists**. We win by providing **Visibility** (Reach), not just "features."

---

## 🎨 Artist Realities & Strategic Shifts

### 1. The "First-Week Win" (Free Tier)
*   **The Problem**: Increasing limits to 10 artworks helps, but if "nothing happens" after upload, they leave.
*   **The Shift**: Every new artist gets a guaranteed **"Discovery Boost"** in their first 7 days.
*   **Success Markers**: Instead of "Engagement Metrics," we show:
    *   "37 people nearby saw your work today."
    *   "Your gallery was added to the Local Discovery Map."
    *   "First Save: Someone just bookmarked your piece!"

### 2. Visibility as Currency (Gifts -> Reach)
*   **Simple Copy**: Never explain Apple policy. Use: **"Support helps your work reach more people."**
*   **Reach Translation**: Credits must always be shown in terms of impact.
    *   *UI Display*: **"23 Credits (≈ 2,300 potential views)"**
*   **Conversion**: 1 USD = 1 Credit = ~100 Views (Local Boost).

### 3. Language: The "Gallery Test"
If a term sounds like a SaaS landing page, it doesn't belong.
*   **Dashboard** → **My Gallery Hub**
*   **Analytics/Engagement** → **Views & Interest**
*   **Metrics** → **People who saved your work**
*   **Setup/Onboarding** → **Opening your gallery**

### 4. Auctions: "Naming the Moment"
Auctions will be framed as time-bound events, not just a bidding tool.
*   **Templates**: "Studio Clear-Out," "Moving Sale," "One-Night-Only Event."
*   **Cost**: Fixed **5 Credits** to "Launch a Sale Event."

### 5. "Featured Placement" (Concrete Value)
To convert to the $12.99 Creator tier, we must remove the abstraction:
*   **The Preview**: Show a mock-up of the "Featured Section" during the upgrade flow.
*   **The Promise**: "Your work will rotate daily in the 'Local Discovery' header (Average 3-5x more views)."

---

## 🚀 Technical Roadmap

### Phase 1: Gallery-Centric UI & Limits
*   [ ] Update `SubscriptionTier` enum in `artbeat_core`.
*   [ ] Systematic find-and-replace of SaaS jargon (Dashboard -> Hub, etc.).
*   [ ] Update `SubscriptionTier` labels in `artbeat_core` to focus on **Reach** and **Visibility**.
*   [ ] Revise `ArtistOnboardScreen` copy and logic.

### Phase 2: The Reach System
*   [ ] Implement the **Reach Translation** UI (Credits -> Views).
*   [ ] Add the "First-Week Win" notification system for new uploads.
*   [ ] Update `EarningsService` and `GiftActivities` to reflect "Promotion Credits."

### Phase 3: "The Moment" Auctions
*   [ ] Create Auction templates with artist-centric names (Studio Clear-Out, etc.).
*   [ ] Implement the **5 Credit** launch cost.
*   [ ] Integrate Auction UI into `MyArtworkScreen`.

---

## 📋 The Artist Guarantee
*   **"Setup in Under 5 Minutes"**: Every step of the flow must be optimized for speed. No long forms.
*   **"Peer Proof"**: Integrate "Success Stories" (e.g., "I sold one piece here — that paid for the year") into the upgrade screens.
*   **Value Lock**: Every artist screen reinforces: **"This helps people nearby find your work."**

---
*Created: Jan 11, 2026*
*Status: Approved / Implementation Started*
