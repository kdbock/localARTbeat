# artbeat_events

Event management package for ARTbeat. This package owns event CRUD, ticketing, attendee purchases, event discovery UI, reminders, recurring events, and analytics/moderation integration points.

## What Is In This Package

Public API export entrypoint: `lib/artbeat_events.dart`

- Models
  - `ArtbeatEvent`
  - `TicketType`
  - `TicketPurchase`
  - `RefundPolicy`
- Services
  - `EventService`
  - `RecurringEventService`
  - `EventNotificationService`
  - `CalendarIntegrationService`
  - `EventAnalyticsService`
  - `EventAnalyticsServicePhase3`
  - `EventModerationService`
  - `EventBulkManagementService`
  - `RevenueTrackingService`
  - `SocialIntegrationService`
- Screens
  - `CreateEventScreen`
  - `EventDetailsScreen`
  - `EventDetailsWrapper`
  - `EventsDashboardScreen`
  - `EventsListScreen`
  - `EventSearchScreen`
  - `MyTicketsScreen`
  - `UserEventsDashboardScreen`
  - `EventBulkManagementScreen`
  - `CalendarScreen`
- Widgets
  - `EventCard`
  - `CommunityFeedEventsWidget`
  - `TicketPurchaseSheet`
  - `QRCodeTicketWidget`
  - `TicketTypeBuilder`
  - `EventsDrawer`
  - `EventsHeader`
  - `SocialFeedWidget`
  - shared UI kit under `src/widgets/widgets.dart`

## Core Behavior

`EventService` is the main integration point for app code. It provides:

- Event CRUD (`createEvent`, `updateEvent`, `deleteEvent`, `getEvent`)
- Listing and discovery (`getUpcomingPublicEvents`, `searchEvents`, filtered/event owner queries)
- Ticket purchase/refund workflows
- Real-time streams (`watchUpcomingEvents`, `watchEventsByArtist`)

`EventNotificationService` handles:

- Notification channel initialization
- Permission request workflow
- Event reminder scheduling/cancelation
- Ticket/refund/update notification delivery

## Data Expectations (Firestore)

Primary collections used directly by `EventService`:

- `events`
- `ticket_purchases`

Common event document fields include:

- core metadata (`title`, `description`, `artistId`, `dateTime`, `location`)
- media (`imageUrls`, `artistHeadshotUrl`, `eventBannerUrl`)
- ticketing (`ticketTypes`, `maxAttendees`, `attendeeIds`)
- status/visibility (`isPublic`, `moderationStatus`)
- optional recurrence (`isRecurring`, `recurrencePattern`, `recurrenceEndDate`)

## Dependency Notes

This package currently depends on:

- Firebase (`firebase_auth`, `cloud_firestore`, `firebase_storage`)
- Notifications (`awesome_notifications`, `flutter_local_notifications`)
- Payments (`flutter_stripe`)
- Shared ARTbeat packages (`artbeat_core`, `artbeat_auth`, `artbeat_ads`, `artbeat_sponsorships`)

## Testing

From repository root:

```bash
flutter test packages/artbeat_events
flutter analyze packages/artbeat_events
```

Current package tests focus on:

- event model computed behavior
- ticket model contracts and serialization
- event service CRUD/purchase/refund contract behavior with fake Firestore + mocked auth
