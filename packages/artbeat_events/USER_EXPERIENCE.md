# artbeat_events User Experience

This document reflects the current UX surface implemented inside `packages/artbeat_events`.

## Primary User Journeys

1. Discover events
- Entry points: `EventsDashboardScreen`, `EventsListScreen`, `EventSearchScreen`
- Users browse public events, filter/search, and open event details.

2. View event details and purchase tickets
- Entry points: `EventDetailsScreen`, `EventDetailsWrapper`
- Ticket selection and purchase UI: `TicketPurchaseSheet`
- Post-purchase ownership view: `MyTicketsScreen` with `QRCodeTicketWidget`.

3. Create and manage events (artist flow)
- Entry point: `CreateEventScreen`
- Ticket type configuration: `TicketTypeBuilder`
- Creator-facing management dashboards: `UserEventsDashboardScreen`, `EventBulkManagementScreen`

4. Calendar and reminders
- Entry point: `CalendarScreen`
- Reminder + push behavior via `EventNotificationService`

## UX Building Blocks

- Event discovery cards and lists: `EventCard`, `CommunityFeedEventsWidget`
- Event-specific navigation surface: `EventsDrawer`, `EventsHeader`
- Community/social event interactions: `SocialFeedWidget`
- Shared event styling helpers: glass components (`glass_kit.dart`, related widgets)

## Current Behavior Notes

- Public event discovery is driven by `isPublic == true` and upcoming `dateTime`.
- Ticket availability is computed from ticket quantity vs. sold quantity and sale windows.
- Ticket refund eligibility is based on event `RefundPolicy` and event date.
- Recurring event support exists in models/services and is triggered from `EventService` when `isRecurring` is enabled.

## Operational Expectations

- Firebase Auth must be available for purchase flows.
- Firestore security rules must allow reads/writes for `events` and `ticket_purchases`.
- Notification UX requires runtime permission approval and local notification setup.
