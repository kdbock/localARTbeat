# Explore Dashboard Onboarding Sequence

This document outlines the proposed onboarding sequence for the `ArtbeatDashboardScreen` (Explore Dashboard). The design follows the same "gaming/quest hub" style used in the main and capture dashboard onboarding sequences.

## Sequence Overview

The onboarding consist of 10 key steps, providing a comprehensive guide through the Explore dashboard interface with its three main tabs: For You, Explore, and Community.

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

### Step 2: Dashboard Title
- **Target**: "Local ART" Title (in Header)
- **Title**: LOCAL ART DASHBOARD
- **Description**: Your personalized gateway to local art discovery.
- **Details**:
    - Curated content just for you
    - Explore trending local artists
    - Discover nearby art scenes
- **Accent Color**: `ArtbeatColors.primaryGreen`

### Step 3: Search Bar
- **Target**: Search Input Field (in Header)
- **Title**: ART SEARCH
- **Description**: Find specific artists, artworks, or locations instantly.
- **Details**:
    - Search by artist name
    - Find artworks by title
    - Locate art in specific areas
- **Accent Color**: `ArtbeatColors.primaryBlue`

### Step 4: Location Indicator
- **Target**: Location Pill (in Header)
- **Title**: YOUR LOCATION
- **Description**: See art based on your current location.
- **Details**:
    - Location-based recommendations
    - Nearby art discovery
    - Local artist spotlights
- **Accent Color**: `ArtbeatColors.primaryPurple`

### Step 5: For You Tab
- **Target**: "For You" Tab
- **Title**: PERSONALIZED FOR YOU
- **Description**: Curated content tailored to your interests.
- **Details**:
    - Artist spotlights near you
    - Recommended artworks
    - Upcoming local events
- **Accent Color**: `Color(0xFF7C4DFF)` (Purple)

### Step 6: Explore Tab
- **Target**: "Explore" Tab
- **Title**: DISCOVER MORE
- **Description**: Browse all available artists and artworks.
- **Details**:
    - Complete artist galleries
    - Full artwork collections
    - Browse by category
- **Accent Color**: `Color(0xFF22D3EE)` (Cyan)

### Step 7: Community Tab
- **Target**: "Community" Tab
- **Title**: JOIN THE COMMUNITY
- **Description**: Connect with fellow art enthusiasts and artists.
- **Details**:
    - See community posts
    - Follow your favorite artists
    - Join art discussions
- **Accent Color**: `Color(0xFFFF3D8D)` (Pink/Neon)

### Step 8: Artist Spotlight
- **Target**: Artist Spotlight Hero Section (For You Tab)
- **Title**: FEATURED ARTIST
- **Description**: Discover amazing local artists and their work.
- **Details**:
    - View artist portfolios
    - Learn about their background
    - See upcoming exhibitions
- **Accent Color**: `Color(0xFFFFC857)` (Yellow/Gold)

### Step 9: Artwork Gallery
- **Target**: Artwork Spotlight Rail (For You Tab)
- **Title**: ARTWORK GALLERY
- **Description**: Browse beautiful artworks from local creators.
- **Details**:
    - High-quality art previews
    - Artist attribution
    - Quick access to details
- **Accent Color**: `Color(0xFF34D399)` (Emerald/Green)

### Step 10: Browse Gateway
- **Target**: Browse Section (Explore Tab)
- **Title**: BROWSE ALL CONTENT
- **Description**: Access the complete art database and filters.
- **Details**:
    - Advanced search options
    - Filter by style, medium, price
    - Save favorite artworks
- **Accent Color**: `Color(0xFF2947FF)` (Blue)

---

## Implementation Plan

1. **Update `OnboardingService`**: Add `isExploreOnboardingCompleted` flag.
2. **Create `ExploreTourOverlay`**: A new widget based on the common tour overlay design.
3. **Add GlobalKeys**: Update `ArtbeatDashboardScreen` to include GlobalKeys for each target element.
4. **Trigger Onboarding**: Implement `_checkOnboarding` logic in `ArtbeatDashboardScreen`.</content>
<parameter name="filePath">/Volumes/ExternalDrive/DevProjects/artbeat/explore_onboarding.md