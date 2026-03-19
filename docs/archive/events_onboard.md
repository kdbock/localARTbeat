# Events Dashboard Onboarding Sequence

This document outlines the proposed onboarding sequence for the `EventsDashboardScreen`. The design follows the same "gaming/quest hub" style used in the main, capture, explore, and discover dashboard onboarding sequences.

## Sequence Overview

The onboarding consist of 12 key steps, providing a comprehensive guide through the Events dashboard interface with its main sections: hero header, stats, categories, featured events, quick actions, and event listings.

---

### Step 1: Main Menu
- **Target**: Menu Icon (in Hero Header)
- **Title**: EVENTS MENU
- **Description**: Access your events toolkit and navigation options.
- **Details**:
    - View event categories
    - Access your tickets
    - Create new events
    - Manage event settings
- **Accent Color**: `ArtbeatColors.secondaryTeal`

### Step 2: Hero Greeting
- **Target**: Hero Header Section
- **Title**: EVENTS DASHBOARD
- **Description**: Your central hub for discovering and managing art events.
- **Details**:
    - Personalized greeting
    - Dynamic time-based welcome
    - Quick access to search
    - Event discovery tools
- **Accent Color**: `ArtbeatColors.primaryGreen`

### Step 3: Event Search
- **Target**: Search Pill (in Hero Header)
- **Title**: EVENT SEARCH
- **Description**: Find specific events, artists, or venues instantly.
- **Details**:
    - Search by event name
    - Filter by location
    - Advanced search options
    - Real-time results
- **Accent Color**: `ArtbeatColors.primaryBlue`

### Step 4: Event Stats
- **Target**: Stats Section
- **Title**: EVENT STATISTICS
- **Description**: Quick overview of upcoming events and activity.
- **Details**:
    - Events happening today
    - This week's schedule
    - Total upcoming events
    - Real-time attendance counts
- **Accent Color**: `ArtbeatColors.primaryPurple`

### Step 5: Category Filter
- **Target**: Browse Categories
- **Title**: EVENT CATEGORIES
- **Description**: Filter events by type to find what interests you.
- **Details**:
    - Exhibition events
    - Workshops and classes
    - Art tours and walks
    - Concerts and performances
- **Accent Color**: `Color(0xFF7C4DFF)` (Purple)

### Step 6: Featured Events
- **Target**: Featured Section
- **Title**: FEATURED EVENTS
- **Description**: Highlighted events you shouldn't miss.
- **Details**:
    - Curated event selection
    - High-quality event banners
    - Attendance tracking
    - Quick event details
- **Accent Color**: `Color(0xFF22D3EE)` (Cyan)

### Step 7: Quick Actions
- **Target**: Discover Section
- **Title**: QUICK DISCOVERY
- **Description**: Fast access to popular event categories and filters.
- **Details**:
    - Events near you
    - Trending events
    - This weekend's events
    - Your ticketed events
- **Accent Color**: `Color(0xFFFF3D8D)` (Pink/Neon)

### Step 8: Events Near Me
- **Target**: "Events Near You" Quick Action
- **Title**: LOCAL EVENTS
- **Description**: Discover art events happening in your area.
- **Details**:
    - Location-based filtering
    - Nearby venue highlights
    - Distance indicators
    - Local artist focus
- **Accent Color**: `Color(0xFFFFC857)` (Yellow/Gold)

### Step 9: Trending Events
- **Target**: "Trending Events" Quick Action
- **Title**: POPULAR EVENTS
- **Description**: See what's hot in the art event scene.
- **Details**:
    - High-attendance events
    - Community favorites
    - Trending categories
    - Popular time slots
- **Accent Color**: `Color(0xFF34D399)` (Emerald/Green)

### Step 10: Weekend Events
- **Target**: "This Weekend" Quick Action
- **Title**: WEEKEND HIGHLIGHTS
- **Description**: Plan your weekend around art events.
- **Details**:
    - Friday through Sunday events
    - Weekend-only exhibitions
    - Special weekend programming
    - Extended hours venues
- **Accent Color**: `Color(0xFF2947FF)` (Blue)

### Step 11: My Tickets
- **Target**: "My Tickets" Quick Action
- **Title**: YOUR EVENTS
- **Description**: Manage events you're attending or have tickets for.
- **Details**:
    - Upcoming tickets
    - Event reminders
    - Ticket validation
    - Past event history
- **Accent Color**: `Color(0xFFFF6B35)` (Orange)

### Step 12: Create Event
- **Target**: Floating Action Button
- **Title**: CREATE EVENT
- **Description**: Share your own art events with the community.
- **Details**:
    - Host exhibitions
    - Organize workshops
    - Plan art tours
    - Schedule performances
- **Accent Color**: `Color(0xFF9D4EDD)` (Violet)

---

## Implementation Plan

1. **Update `OnboardingService`**: Add `isEventsOnboardingCompleted` flag.
2. **Create `EventsTourOverlay`**: A new widget based on the common tour overlay design.
3. **Add GlobalKeys**: Update `EventsDashboardScreen` to include GlobalKeys for each target element.
4. **Trigger Onboarding**: Implement `_checkOnboarding` logic in `EventsDashboardScreen`.</content>
<parameter name="filePath">/Volumes/ExternalDrive/DevProjects/artbeat/events_onboard.md