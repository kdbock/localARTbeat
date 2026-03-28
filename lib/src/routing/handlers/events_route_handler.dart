import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/auth_service.dart' as core_auth;
import 'package:artbeat_events/artbeat_events.dart' as events;
import 'package:flutter/material.dart';

import '../route_utils.dart';

class EventsRouteHandler {
  const EventsRouteHandler({required core_auth.AuthService authService})
    : _authService = authService;

  final core_auth.AuthService _authService;

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.events:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          drawer: const events.EventsDrawer(),
          child: const events.EventsDashboardScreen(),
        );

      case core.AppRoutes.eventsDiscover:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          drawer: const events.EventsDrawer(),
          child: const events.EventsListScreen(),
        );

      case core.AppRoutes.eventsDashboard:
      case core.AppRoutes.eventsArtistDashboard:
        return RouteUtils.createMainLayoutRoute(
          currentIndex: 4,
          drawer: const events.EventsDrawer(),
          child: const events.EventsDashboardScreen(),
        );

      case core.AppRoutes.eventsCreate:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.CreateEventScreen(),
        );

      case core.AppRoutes.eventsSearch:
        return RouteUtils.createSimpleRoute(
          child: const events.EventSearchScreen(),
        );

      case core.AppRoutes.myEvents:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.UserEventsDashboardScreen(),
        );

      case core.AppRoutes.myTickets:
        final currentUserId = _authService.currentUser?.uid ?? '';
        return RouteUtils.createSimpleRoute(
          child: events.MyTicketsScreen(userId: currentUserId),
        );

      case core.AppRoutes.eventsDetail:
        final args = settings.arguments as Map<String, dynamic>?;
        final eventId = args?['eventId'] as String?;
        if (eventId != null) {
          return RouteUtils.createMainLayoutRoute(
            drawer: const events.EventsDrawer(),
            child: events.EventDetailsScreen(eventId: eventId),
          );
        }
        return RouteUtils.createNotFoundRoute();

      case core.AppRoutes.eventsCalendar:
        return RouteUtils.createMainLayoutRoute(
          drawer: const events.EventsDrawer(),
          child: const events.CalendarScreen(),
        );

      default:
        return RouteUtils.createComingSoonRoute('Events');
    }
  }
}
