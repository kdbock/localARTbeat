import 'package:artbeat_events/artbeat_events.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:artbeat_core/src/routing/app_routes.dart';

class EventsRouteHandler {
  static Widget handleEventsRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case AppRoutes.allEvents:
        return const EventsListScreen();
      case AppRoutes.artistEvents:
        return const EventsDashboardScreen();
      case AppRoutes.myTickets:
        // Get current user ID from Firebase Auth
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return MyTicketsScreen(userId: userId);
      case AppRoutes.createEvent:
        return const CreateEventScreen();
      case AppRoutes.myEvents:
        return const UserEventsDashboardScreen();
      case AppRoutes.eventsSearch:
        return const EventSearchScreen();
      case AppRoutes.eventsNearby:
        // Show events filtered by location - coming soon
        return const EventsListScreen(
          title: 'Events Near Me',
          showCreateButton: true,
        );
      case '/events/trending':
        // Show trending events - coming soon
        return const EventsListScreen(
          title: 'Trending Events',
          showCreateButton: true,
        );
      case '/events/weekend':
        // Show weekend events - coming soon
        return const EventsListScreen(
          title: 'This Weekend\'s Events',
          showCreateButton: true,
        );
      default:
        return const Center(child: Text('Coming Soon'));
    }
  }
}
