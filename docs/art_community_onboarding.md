# Art Community Hub Onboarding Sequence

This document outlines the proposed onboarding sequence for the `ArtCommunityHub` screen. The design follows the same "gaming/quest hub" style used in the main, capture, and discover dashboard onboarding sequences.

## Sequence Overview

The onboarding consist of 12 key steps, providing a comprehensive guide through the Art Community Hub interface with its four main tabs: Feed, Artists, Artwork, and Commissions.

---

### Step 1: Main Menu
- **Target**: Menu Icon (in HUD AppBar)
- **Title**: COMMUNITY MENU
- **Description**: Access your community toolkit and navigation options.
- **Details**:
    - View trending content
    - Browse artwork collections
    - Access artist onboarding
    - Check leaderboards
- **Accent Color**: `ArtbeatColors.secondaryTeal`

### Step 2: Community Title
- **Target**: "Art Community" Title (in HUD AppBar)
- **Title**: ART COMMUNITY HUB
- **Description**: Your central hub for connecting with artists and art enthusiasts.
- **Details**:
    - Share your art journey
    - Discover new artists
    - Connect with the community
    - Commission custom artwork
- **Accent Color**: `ArtbeatColors.primaryGreen`

### Step 3: Search
- **Target**: Search Icon (in HUD AppBar)
- **Title**: COMMUNITY SEARCH
- **Description**: Find specific posts, artists, or artwork within the community.
- **Details**:
    - Search community posts
    - Find artists by name
    - Discover artwork by title
    - Filter by categories
- **Accent Color**: `ArtbeatColors.primaryBlue`

### Step 4: Feed Tab
- **Target**: Feed Tab
- **Title**: COMMUNITY FEED
- **Description**: Stay updated with the latest posts and community activity.
- **Details**:
    - View recent posts
    - See community discussions
    - Follow artist updates
    - Engage with content
- **Accent Color**: `Color(0xFF7C4DFF)` (Purple)

### Step 5: Artists Tab
- **Target**: Artists Tab
- **Title**: ARTISTS GALLERY
- **Description**: Explore and connect with talented artists in your area.
- **Details**:
    - Browse artist profiles
    - View portfolios
    - Follow favorite artists
    - Discover new talent
- **Accent Color**: `Color(0xFF22D3EE)` (Cyan)

### Step 6: Artwork Tab
- **Target**: Artwork Tab
- **Title**: ARTWORK DISCOVERY
- **Description**: Browse and discover amazing artwork from the community.
- **Details**:
    - Explore artwork collections
    - Filter by style and medium
    - Save favorite pieces
    - Get inspired
- **Accent Color**: `Color(0xFFFF3D8D)` (Pink/Neon)

### Step 7: Commissions Tab
- **Target**: Commissions Tab
- **Title**: COMMISSION MARKET
- **Description**: Find artists to create custom artwork for you.
- **Details**:
    - Browse available artists
    - View commission details
    - Request custom work
    - Connect with creators
- **Accent Color**: `Color(0xFFFFC857)` (Yellow/Gold)

### Step 8: Create Post FAB
- **Target**: Floating Action Button
- **Title**: SHARE YOUR ART
- **Description**: Create and share your own posts with the community.
- **Details**:
    - Share your artwork
    - Post updates and thoughts
    - Start discussions
    - Connect with others
- **Accent Color**: `Color(0xFF34D399)` (Emerald/Green)

### Step 9: Feed Content
- **Target**: Community Feed Section (Feed Tab)
- **Title**: LIVE COMMUNITY FEED
- **Description**: See real-time posts and activity from community members.
- **Details**:
    - Recent community posts
    - Artist announcements
    - Community discussions
    - Trending content
- **Accent Color**: `Color(0xFF2947FF)` (Blue)

### Step 10: Artist Spotlight
- **Target**: Artist Cards (Artists Tab)
- **Title**: FEATURED ARTISTS
- **Description**: Discover amazing local artists and their creative work.
- **Details**:
    - Artist profiles and bios
    - Portfolio previews
    - Commission availability
    - Contact information
- **Accent Color**: `Color(0xFFFF6B35)` (Orange)

### Step 11: Artwork Gallery
- **Target**: Artwork Grid (Artwork Tab)
- **Title**: ARTWORK SHOWCASE
- **Description**: Browse beautiful artworks shared by community members.
- **Details**:
    - High-quality art previews
    - Artist attributions
    - Style and medium filters
    - Save and share options
- **Accent Color**: `Color(0xFF9D4EDD)` (Violet)

### Step 12: Commission Artists
- **Target**: Commission Artists List (Commissions Tab)
- **Title**: COMMISSION ARTISTS
- **Description**: Connect with artists who offer custom commission services.
- **Details**:
    - Artist specialties
    - Pricing information
    - Portfolio samples
    - Commission process
- **Accent Color**: `Color(0xFF06FFA5)` (Mint)

---

## Implementation Plan

1. **Update `OnboardingService`**: Add `isArtCommunityOnboardingCompleted` flag.
2. **Create `ArtCommunityTourOverlay`**: A new widget based on the common tour overlay design.
3. **Add GlobalKeys**: Update `ArtCommunityHub` to include GlobalKeys for each target element.
4. **Trigger Onboarding**: Implement `_checkOnboarding` logic in `ArtCommunityHub`.</content>
<parameter name="filePath">/Volumes/ExternalDrive/DevProjects/artbeat/art_community_onboarding.md