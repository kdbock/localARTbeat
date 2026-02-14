# Capture Dashboard Onboarding Sequence

This document outlines the proposed onboarding sequence for the `EnhancedCaptureDashboardScreen`. The design will follow the same "gaming/quest hub" style used in the main dashboard onboarding.

## Sequence Overview

The onboarding will consist of 10 key steps, providing a granular guide through the Capture interface.

---

### Step 1: Main Menu
- **Target**: Menu Icon
- **Title**: OPERATIONS MENU
- **Description**: Access your settings, toolkit, and resource library.
- **Accent Color**: `ArtbeatColors.secondaryTeal`

### Step 2: Search
- **Target**: Search Icon
- **Title**: ART SCANNER
- **Description**: Search for specific captures, artists, or locations across the global network.
- **Accent Color**: `ArtbeatColors.primaryGreen`

### Step 3: Communications
- **Target**: Chat Icon
- **Title**: COMMS CHANNEL
- **Description**: Message other hunters to coordinate drops or share Intel.
- **Accent Color**: `ArtbeatColors.primaryBlue`

### Step 4: Notifications
- **Target**: Notifications Icon
- **Title**: INTEL FEED
- **Description**: Stay updated on new engagement, nearby drops, and mission updates.
- **Accent Color**: `ArtbeatColors.primaryPurple`

### Step 5: Hunter Profile
- **Target**: Profile Icon
- **Title**: YOUR IDENTITY
- **Description**: View your rank, achievements, and your public art collection.
- **Accent Color**: `ArtbeatColors.accentYellow`

### Step 6: Quest Tracker
- **Target**: Quest Tracker Section
- **Title**: ACTIVE MISSIONS
- **Description**: Complete daily challenges to earn XP and level up your Hunter rank.
- **Details**:
    - **Daily Drop**: Capture 3 pieces of art
    - **Community Scout**: Engage with other hunters
    - **Map Block**: Explore new neighborhoods
- **Accent Color**: `Color(0xFF34D399)`

### Step 7: Community Pulse
- **Target**: Community Pulse Widget
- **Title**: NEIGHBORHOOD BEAT
- **Description**: Real-time stats showing the activity of fellow art hunters in your area.
- **Details**:
    - See active hunters nearby
    - Track new drops in the last 24h
- **Accent Color**: `Color(0xFF22D3EE)`

### Step 8: Recent Loot
- **Target**: Recent Loot Grid
- **Title**: YOUR COLLECTION
- **Description**: Quick access to your most recent art captures and their current status.
- **Accent Color**: `Color(0xFF7C4DFF)`

### Step 9: Community Inspiration
- **Target**: Community Inspiration List
- **Title**: HUNTER INSPIRATION
- **Description**: See what other hunters are discovering to find new spots for your next mission.
- **Accent Color**: `Color(0xFFFFC857)`

### Step 10: Quick Capture
- **Target**: Enhanced Bottom Nav (Capture Tab)
- **Title**: DEPLOY CAMERA
- **Description**: The primary tool for every mission. Tap here to start capturing art instantly.
- **Accent Color**: `ArtbeatColors.accentYellow`

---

## Implementation Plan

1. **Update `OnboardingService`**: Add `isCaptureOnboardingCompleted` flag to track status separately.
2. **Create `CaptureTourOverlay`**: A new widget based on `DashboardTourOverlay` but tailored for these steps.
3. **Add GlobalKeys**: Update `EnhancedCaptureDashboardScreen` to include GlobalKeys for each target element.
4. **Trigger Onboarding**: Implement `_checkOnboarding` logic in `EnhancedCaptureDashboardScreen` similar to `AnimatedDashboardScreen`.
