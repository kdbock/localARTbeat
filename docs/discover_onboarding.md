# Discover Dashboard Onboarding Sequence

This document outlines the proposed onboarding sequence for the `DiscoverDashboardScreen`. The design follows the same "gaming/quest hub" style used in the main and capture dashboard onboarding sequences.

## Sequence Overview

The onboarding consist of 13 key steps, providing a granular guide through the Discover (Art Walk) interface.

---

### Step 1: Main Menu
- **Target**: Menu Icon (in Header)
- **Title**: OPERATIONS HUB
- **Description**: Access your settings, toolkit, and resource library.
- **Accent Color**: `ArtbeatColors.secondaryTeal`

### Step 2: Global Search
- **Target**: Search Icon (in Header)
- **Title**: ART SCANNER
- **Description**: Search for specific art walks, artists, or locations across the global network.
- **Accent Color**: `ArtbeatColors.primaryGreen`

### Step 3: Communications
- **Target**: Chat Icon (in Header)
- **Title**: COMMS CHANNEL
- **Description**: Message other explorers to coordinate art walks or share intel.
- **Accent Color**: `ArtbeatColors.primaryBlue`

### Step 4: Notifications
- **Target**: Notifications Icon (in Header)
- **Title**: INTEL FEED
- **Description**: Stay updated on new engagement, nearby art walks, and achievement updates.
- **Accent Color**: `ArtbeatColors.primaryPurple`

### Step 5: Explorer Hero
- **Target**: Hero Section (Greeting & Subtitle)
- **Title**: EXPLORER COMMAND
- **Description**: Your central status hub showing your current level, XP progress, and daily mission.
- **Details**:
    - Track Level and XP progress
    - Monitor your daily missions
    - View active explorer stats
- **Accent Color**: `Color(0xFF7C4DFF)` (Purple)

### Step 6: Discovery Radar
- **Target**: Discovery Radar Title
- **Title**: DISCOVERY RADAR
- **Description**: Real-time map scanning for nearby art. Tap the radar to begin an instant discovery mission.
- **Details**:
    - See nearby art count
    - Access instant discovery
    - View local scene highlights
- **Accent Color**: `Color(0xFF22D3EE)` (Cyan)

### Step 7: Kiosk Lane
- **Target**: Kiosk Lane Section
- **Title**: ARTIST SPOTLIGHT
- **Description**: Discover featured artists currently showcasing their work in the Kiosk Lane.
- **Accent Color**: `Color(0xFFFF3D8D)` (Pink/Neon)

### Step 8: Stats Grid
- **Target**: Stats Section (Streak, Discoveries, Level)
- **Title**: EXPLORER STATS
- **Description**: Your performance metrics at a glance. Keep your streak alive and level up!
- **Accent Color**: `Color(0xFFFFC857)` (Yellow/Gold)

### Step 9: Weekly Goals
- **Target**: Weekly Goals Title
- **Title**: SEASONAL OBJECTIVES
- **Description**: Complete long-term goals to earn massive rewards and exclusive badges.
- **Accent Color**: `Color(0xFF34D399)` (Emerald/Green)

### Step 10: Social Feed
- **Target**: Live Social Feed
- **Title**: ACTIVITY STREAM
- **Description**: See what other explorers are discovering in real-time. Join the global conversation.
- **Accent Color**: `Color(0xFF2947FF)` (Blue)

### Step 11: Quick Actions
- **Target**: Quick Actions Section
- **Title**: RAPID DEPLOYMENT
- **Description**: Quick access to essential tools and actions for efficient art exploration.
- **Accent Color**: `Color(0xFFFF6B35)` (Orange)

### Step 12: Achievements
- **Target**: Achievements Section
- **Title**: GLORY VAULT
- **Description**: Showcase your exploration achievements and unlock exclusive rewards.
- **Accent Color**: `Color(0xFF9D4EDD)` (Violet)

### Step 13: Nearby Art Hotspots
- **Target**: Nearby Art Hotspots Section
- **Title**: HOT ZONE NAVIGATOR
- **Description**: Discover high-activity art locations and trending discovery spots in your area.
- **Accent Color**: `Color(0xFF06FFA5)` (Mint)

---

## Implementation Plan

1. **Update `OnboardingService`**: Add `isDiscoverOnboardingCompleted` flag.
2. **Create `DiscoverTourOverlay`**: A new widget based on the common tour overlay design.
3. **Add GlobalKeys**: Update `DiscoverDashboardScreen` to include GlobalKeys for each target element.
4. **Trigger Onboarding**: Implement `_checkOnboarding` logic in `DiscoverDashboardScreen`.
