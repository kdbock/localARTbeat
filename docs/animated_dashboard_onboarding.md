# Animated Dashboard Onboarding Sequence

This document outlines the proposed onboarding sequence for the `AnimatedDashboardScreen`. The design follows the same "gaming/quest hub" style used in the main dashboard onboarding.

## Sequence Overview

The onboarding consist of 13 key steps, providing a comprehensive guide through the main ArtBeat dashboard interface.

---

### Step 1: Main Menu
- **Target**: Menu Icon (in Header)
- **Title**: MAIN MENU
- **Description**: Access your full toolkit and resources.
- **Details**:
    - View your collections
    - Explore art by local artists
    - Get help and support
- **Accent Color**: `ArtbeatColors.secondaryTeal`

### Step 2: Progress Tracker
- **Target**: XP Progress Section (in Header)
- **Title**: PROGRESS TRACKER
- **Description**: Monitor your growth and daily consistency.
- **Details**:
    - Track Level and XP progress
    - Keep your daily Streak alive
    - See your current XP bar
- **Accent Color**: `ArtbeatColors.primaryGreen`

### Step 3: Your Identity
- **Target**: Profile Icon (in Header)
- **Title**: YOUR IDENTITY
- **Description**: Customize how the art world sees you.
- **Details**:
    - Edit your public bio
    - View your shared captures
    - Check your achievements
- **Accent Color**: `ArtbeatColors.accentYellow`

### Step 4: Preferences
- **Target**: Settings Icon (in Header)
- **Title**: PREFERENCES
- **Description**: Tailor the app experience to your needs.
- **Details**:
    - Manage notifications
    - Change language settings
    - Adjust privacy options
- **Accent Color**: `ArtbeatColors.primaryPurple`

### Step 5: Capture Art
- **Target**: Capture Section
- **Title**: CAPTURE ART
- **Description**: The core tool for documenting your finds.
- **Details**:
    - Take high-quality art photos
    - Add locations to your finds
    - Share with the community
- **Accent Color**: `ArtbeatColors.primaryPurple`

### Step 6: Discover Quests
- **Target**: Discover Section
- **Title**: DISCOVER QUESTS
- **Description**: Find new art through guided challenges.
- **Details**:
    - Join local art missions
    - Earn unique rewards
    - Follow curated paths
- **Accent Color**: `ArtbeatColors.primaryBlue`

### Step 7: Explore Map
- **Target**: Explore Section
- **Title**: EXPLORE MAP
- **Description**: A birds-eye view of art around you.
- **Details**:
    - See all nearby artwork
    - Find upcoming events
    - Plan your art routes
- **Accent Color**: `ArtbeatColors.primaryGreen`

### Step 8: Community Hub
- **Target**: Community Section
- **Title**: COMMUNITY HUB
- **Description**: Connect with fellow art enthusiasts.
- **Details**:
    - See trending art posts
    - Follow your favorite artists
    - Comment and give feedback
- **Accent Color**: `ArtbeatColors.accentOrange`

### Step 9: Home Base
- **Target**: Home Navigation Tab
- **Title**: HOME BASE
- **Description**: Your central starting point for everything.
- **Details**:
    - Quick return to dashboard
    - View latest highlights
- **Accent Color**: `ArtbeatColors.secondaryTeal`

### Step 10: Art Walks
- **Target**: Art Walk Navigation Tab
- **Title**: ART WALKS
- **Description**: Embark on curated walking tours.
- **Details**:
    - Discover themed routes
    - Learn about local history
- **Accent Color**: `ArtbeatColors.primaryBlue`

### Step 11: Quick Capture
- **Target**: Capture Navigation Tab
- **Title**: QUICK CAPTURE
- **Description**: Launch the camera instantly.
- **Details**:
    - Never miss a piece of art
    - One-tap camera access
- **Accent Color**: `ArtbeatColors.accentYellow`

### Step 12: Social Feed
- **Target**: Community Navigation Tab
- **Title**: SOCIAL FEED
- **Description**: The heartbeat of the art community.
- **Details**:
    - See what others are finding
    - Stay connected on the go
- **Accent Color**: `ArtbeatColors.accentOrange`

### Step 13: Art Events
- **Target**: Events Navigation Tab
- **Title**: ART EVENTS
- **Description**: Local happenings you won't want to miss.
- **Details**:
    - Exhibitions and gallery openings
    - Community art workshops
- **Accent Color**: `ArtbeatColors.primaryPurple`

---

## Implementation Plan

1. **Update `OnboardingService`**: Ensure `isOnboardingCompleted()` tracks main dashboard completion.
2. **Create/Update `DashboardTourOverlay`**: The overlay is already implemented with the steps above.
3. **Add GlobalKeys**: The `AnimatedDashboardScreen` already includes all necessary GlobalKeys for each target element.
4. **Trigger Onboarding**: The `_checkOnboarding()` logic is already implemented in `AnimatedDashboardScreen`.</content>
<parameter name="filePath">/Volumes/ExternalDrive/DevProjects/artbeat/animated_dashboard_onboarding.md