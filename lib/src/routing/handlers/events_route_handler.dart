import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_events/artbeat_events.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EventsRouteHandler {
  static Widget handleEventsRoute(String routeName, Object? arguments) {
    switch (routeName) {
      case core.AppRoutes.allEvents:
        return const EventsListScreen();
      case core.AppRoutes.artistEvents:
        return const EventsDashboardScreen();
      case core.AppRoutes.myTickets:
        // Get current user ID from Firebase Auth
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        return MyTicketsScreen(userId: userId);
      case core.AppRoutes.createEvent:
        return const CreateEventScreen();
      case core.AppRoutes.myEvents:
        return const UserEventsDashboardScreen();
      case core.AppRoutes.eventsSearch:
        return const EventSearchScreen();
      case core.AppRoutes.eventsNearby:
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
