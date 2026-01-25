import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:artbeat_events/artbeat_events.dart';
import '../models/event_model_internal.dart' as internal;
import 'package:artbeat_core/artbeat_core.dart';

/// Adapter service to bridge between artbeat_artist EventModel and artbeat_events ArtbeatEvent
/// This provides backward compatibility while migrating to the unified event system
class EventServiceAdapter {
  final EventService _eventService = EventService();
  final EventAnalyticsService _analyticsService = EventAnalyticsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get currently logged-in user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Convert ArtbeatEvent to EventModel for backward compatibility
  internal.EventModel _convertFromArtbeatEvent(ArtbeatEvent artbeatEvent) {
    return internal.EventModel(
      id: artbeatEvent.id,
      title: artbeatEvent.title,
      description: artbeatEvent.description,
      startDate: artbeatEvent.dateTime,
      endDate: null, // ArtbeatEvent doesn't have endDate concept
      location: artbeatEvent.location,
      imageUrl: artbeatEvent.imageUrls.isNotEmpty
          ? artbeatEvent.imageUrls.first
          : null,
      artistId: artbeatEvent.artistId,
      isPublic: artbeatEvent.isPublic,
      attendeeIds: artbeatEvent.attendeeIds,
      createdAt: artbeatEvent.createdAt,
      updatedAt: artbeatEvent.updatedAt,
    );
  }

  /// Get event by ID (converted to EventModel for compatibility)
  Future<internal.EventModel> getEventById(String eventId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final artbeatEvent = await _eventService.getEventById(eventId);

      if (artbeatEvent == null) {
        throw Exception('Event not found');
      }

      // Check if user has permission to view this event
      if (!artbeatEvent.isPublic &&
          artbeatEvent.artistId != userId &&
          !artbeatEvent.attendeeIds.contains(userId)) {
        throw Exception('Permission denied');
      }

      // Track event view for analytics
      _analyticsService.trackEventView(eventId);

      return _convertFromArtbeatEvent(artbeatEvent);
    } catch (e) {
      throw Exception('Failed to fetch event: $e');
    }
  }

  /// Get local events for the current user
  Future<List<internal.EventModel>> getLocalEvents() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final artbeatEvents = await _eventService.getEventsByArtist(userId);
      return artbeatEvents.map(_convertFromArtbeatEvent).toList();
    } catch (e) {
      AppLogger.error('Error fetching local events: $e');
      return [];
    }
  }

  /// Get upcoming events
  Future<List<internal.EventModel>> getUpcomingEvents() async {
    try {
      final artbeatEvents = await _eventService.getUpcomingPublicEvents(
        limit: 50,
      );
      return artbeatEvents.map(_convertFromArtbeatEvent).toList();
    } catch (e) {
      AppLogger.error('Error fetching upcoming events: $e');
      return [];
    }
  }

  /// Create event - adapted to use ArtbeatEvent.create
  Future<void> createEvent({
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required String location,
    required bool isPublic,
    File? imageFile,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Upload image if provided
      String? imageUrl;
      if (imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask;
        imageUrl = await snapshot.ref.getDownloadURL();
      }

      // Create ArtbeatEvent with minimal required fields
      final artbeatEvent = ArtbeatEvent.create(
        title: title,
        description: description,
        artistId: userId,
        imageUrls: imageUrl != null ? [imageUrl] : [],
        artistHeadshotUrl: '', // Could be fetched from user profile
        eventBannerUrl: imageUrl ?? '',
        dateTime: startDate,
        location: location,
        ticketTypes: [], // Default to no tickets for artist-created events
        contactEmail: FirebaseAuth.instance.currentUser?.email ?? '',
        isPublic: isPublic,
        category: 'Artist Event',
        tags: [],
      );

      await _eventService.createEvent(artbeatEvent);
      AppLogger.info('Event created successfully');
    } catch (e) {
      AppLogger.error('Error creating event: $e');
      rethrow;
    }
  }

  /// Update event - adapted to work with ArtbeatEvent
  Future<void> updateEvent({
    required String eventId,
    required String title,
    required String description,
    required DateTime startDate,
    DateTime? endDate,
    required String location,
    required bool isPublic,
    File? imageFile,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the existing event first
      final existingEvent = await _eventService.getEventById(eventId);
      if (existingEvent == null) {
        throw Exception('Event not found');
      }

      // Check permissions
      if (existingEvent.artistId != userId) {
        throw Exception('Permission denied');
      }

      // Upload new image if provided
      String? newImageUrl;
      if (imageFile != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('event_images')
            .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

        final uploadTask = storageRef.putFile(imageFile);
        final snapshot = await uploadTask;
        newImageUrl = await snapshot.ref.getDownloadURL();
      }

      // Create updated event
      final updatedEvent = existingEvent.copyWith(
        title: title,
        description: description,
        dateTime: startDate,
        location: location,
        isPublic: isPublic,
        imageUrls: newImageUrl != null
            ? [newImageUrl]
            : existingEvent.imageUrls,
        eventBannerUrl: newImageUrl ?? existingEvent.eventBannerUrl,
        updatedAt: DateTime.now(),
      );

      await _eventService.updateEvent(updatedEvent);
      AppLogger.info('Event updated successfully');
    } catch (e) {
      AppLogger.error('Error updating event: $e');
      rethrow;
    }
  }

  /// Delete event
  Future<void> deleteEvent(String eventId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get the existing event first to check permissions
      final existingEvent = await _eventService.getEventById(eventId);
      if (existingEvent == null) {
        throw Exception('Event not found');
      }

      // Check permissions
      if (existingEvent.artistId != userId) {
        throw Exception('Permission denied');
      }

      await _eventService.deleteEvent(eventId);
      AppLogger.info('Event deleted successfully');
    } catch (e) {
      AppLogger.error('Error deleting event: $e');
      rethrow;
    }
  }

  // Analytics Methods

  /// Track when a user saves/bookmarks an event
  Future<void> trackEventSave(String eventId) async {
    await _analyticsService.trackEventSave(eventId);
  }

  /// Track when a user shares an event
  Future<void> trackEventShare(String eventId, String shareMethod) async {
    await _analyticsService.trackEventShare(eventId, shareMethod);
  }

  /// Get basic analytics for an event
  Future<Map<String, dynamic>> getEventAnalytics(String eventId) async {
    final analyticsData = await _analyticsService.getEventAnalytics(eventId);
    return {
      'viewCount': analyticsData?.viewCount ?? 0,
      'engagementCount': analyticsData?.engagementCount ?? 0,
      'shareCount': analyticsData?.shareCount ?? 0,
      'saveCount': analyticsData?.saveCount ?? 0,
    };
  }

  /// Get popular events based on engagement (placeholder implementation)
  Future<List<internal.EventModel>> getPopularEvents({int limit = 10}) async {
    // Since getPopularEvents doesn't exist in basic EventAnalyticsService,
    // we'll return an empty list for now
    return [];
  }
}
