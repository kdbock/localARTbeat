import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import '../models/artbeat_event.dart';
import '../models/ticket_purchase.dart';
import 'recurring_event_service.dart';

/// Service for managing events in Firestore
class EventService {
  static const String _eventsCollection = 'events';
  static const String _ticketPurchasesCollection = 'ticket_purchases';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Logger _logger = Logger();
  final RecurringEventService _recurringEventService = RecurringEventService();

  /// Create a new event
  /// If the event is recurring, this will also generate all recurring instances
  Future<String> createEvent(ArtbeatEvent event) async {
    try {
      final docRef = await _firestore
          .collection(_eventsCollection)
          .add(event.toFirestore());

      _logger.i('Event created with ID: ${docRef.id}');

      // If this is a recurring event, generate all instances
      if (event.isRecurring) {
        await _recurringEventService.generateRecurringInstances(
          docRef.id,
          event.copyWith(id: docRef.id),
        );
      }

      return docRef.id;
    } catch (e) {
      _logger.e('Error creating event: $e');
      rethrow;
    }
  }

  /// Update an existing event
  /// If the event is a recurring parent event, this will also update all instances
  Future<void> updateEvent(ArtbeatEvent event) async {
    try {
      await _firestore
          .collection(_eventsCollection)
          .doc(event.id)
          .update(event.copyWith(updatedAt: DateTime.now()).toFirestore());

      _logger.i('Event updated: ${event.id}');

      // If this is a recurring parent event, update all instances
      if (event.isRecurring) {
        await _recurringEventService.updateRecurringInstances(event.id, event);
      }
    } catch (e) {
      _logger.e('Error updating event: $e');
      rethrow;
    }
  }

  /// Delete an event
  /// If the event is a recurring parent event, this will also delete all instances
  Future<void> deleteEvent(String eventId) async {
    try {
      // Check if this is a recurring parent event
      final event = await getEvent(eventId);

      await _firestore.collection(_eventsCollection).doc(eventId).delete();

      _logger.i('Event deleted: $eventId');

      // If this was a recurring parent event, delete all instances
      if (event?.isRecurring == true) {
        await _recurringEventService.deleteRecurringInstances(eventId);
      }
    } catch (e) {
      _logger.e('Error deleting event: $e');
      rethrow;
    }
  }

  /// Get a single event by ID
  Future<ArtbeatEvent?> getEvent(String eventId) async {
    try {
      final doc = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (doc.exists) {
        return ArtbeatEvent.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Error getting event: $e');
      rethrow;
    }
  }

  /// Get an event by its ID
  Future<ArtbeatEvent?> getEventById(String eventId) async {
    try {
      final docSnapshot = await _firestore
          .collection(_eventsCollection)
          .doc(eventId)
          .get();

      if (!docSnapshot.exists) {
        _logger.w('Event not found: $eventId');
        return null;
      }

      final eventData = docSnapshot.data() as Map<String, dynamic>;
      eventData['id'] = docSnapshot.id; // Add the document ID to the data

      _logger.i('Event retrieved: $eventId');
      return ArtbeatEvent.fromFirestore(docSnapshot);
    } catch (e) {
      _logger.e('Error getting event: $e');
      rethrow;
    }
  }

  /// Get upcoming public events for community feed
  Future<List<ArtbeatEvent>> getUpcomingPublicEvents({int? limit, String? chapterId}) async {
    try {
      Query query = _firestore
          .collection(_eventsCollection)
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.now());
      
      if (chapterId != null) {
        query = query.where('chapterId', isEqualTo: chapterId);
      }
      // If chapterId is null, we show all public events (Local ARTbeat)

      query = query.orderBy('dateTime', descending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) {
            try {
              return ArtbeatEvent.fromFirestore(doc);
            } on Exception catch (e) {
              AppLogger.error('Error parsing event ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ArtbeatEvent>()
          .toList();
    } catch (e) {
      _logger.e('Error getting upcoming public events: $e');
      rethrow;
    }
  }

  /// Get events created by a specific artist
  Future<List<ArtbeatEvent>> getEventsByArtist(String artistId) async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('artistId', isEqualTo: artistId)
          .orderBy('dateTime', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return ArtbeatEvent.fromFirestore(doc);
            } on Exception catch (e) {
              AppLogger.error('Error parsing event ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ArtbeatEvent>()
          .toList();
    } catch (e) {
      _logger.e('Error getting events by artist: $e');
      rethrow;
    }
  }

  /// Get events by tags
  Future<List<ArtbeatEvent>> getEventsByTags(List<String> tags) async {
    try {
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('tags', arrayContainsAny: tags)
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.now())
          .orderBy('dateTime', descending: false)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return ArtbeatEvent.fromFirestore(doc);
            } on Exception catch (e) {
              AppLogger.error('Error parsing event ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ArtbeatEvent>()
          .toList();
    } catch (e) {
      _logger.e('Error getting events by tags: $e');
      rethrow;
    }
  }

  /// Search events by title or description
  Future<List<ArtbeatEvent>> searchEvents(String query) async {
    try {
      // Note: This is a simple implementation. For production, consider using
      // a dedicated search service like Algolia or Elasticsearch
      final snapshot = await _firestore
          .collection(_eventsCollection)
          .where('isPublic', isEqualTo: true)
          .where('dateTime', isGreaterThan: Timestamp.now())
          .get();

      final events = snapshot.docs
          .map((doc) {
            try {
              return ArtbeatEvent.fromFirestore(doc);
            } on Exception catch (e) {
              AppLogger.error('Error parsing event ${doc.id}: $e');
              return null;
            }
          })
          .whereType<ArtbeatEvent>()
          .where(
            (event) =>
                event.title.toLowerCase().contains(query.toLowerCase()) ||
                event.description.toLowerCase().contains(query.toLowerCase()) ||
                event.location.toLowerCase().contains(query.toLowerCase()),
          )
          .toList();

      // Sort by relevance (events with query in title first)
      events.sort((a, b) {
        final aInTitle = a.title.toLowerCase().contains(query.toLowerCase());
        final bInTitle = b.title.toLowerCase().contains(query.toLowerCase());
        if (aInTitle && !bInTitle) return -1;
        if (!aInTitle && bInTitle) return 1;
        return a.dateTime.compareTo(b.dateTime);
      });

      return events;
    } catch (e) {
      _logger.e('Error searching events: $e');
      rethrow;
    }
  }

  /// Purchase tickets for an event
  Future<String> purchaseTickets({
    required String eventId,
    required String ticketTypeId,
    required int quantity,
    required String userEmail,
    required String userName,
    String? paymentIntentId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get the event to calculate total amount
      final event = await getEvent(eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      final ticketType = event.ticketTypes
          .where((t) => t.id == ticketTypeId)
          .firstOrNull;
      if (ticketType == null) {
        throw Exception('Ticket type not found');
      }

      if (!ticketType.isAvailable) {
        throw Exception('Tickets are not available');
      }

      if (ticketType.remainingQuantity < quantity) {
        throw Exception('Not enough tickets available');
      }

      final totalAmount = ticketType.price * quantity;

      // Create ticket purchase record
      final purchase = TicketPurchase.create(
        eventId: eventId,
        ticketTypeId: ticketTypeId,
        userId: user.uid,
        userEmail: userEmail,
        userName: userName,
        quantity: quantity,
        totalAmount: totalAmount,
        paymentIntentId: paymentIntentId,
      );

      // Save to Firestore
      final docRef = await _firestore
          .collection(_ticketPurchasesCollection)
          .add(purchase.toFirestore());

      // Update ticket quantity sold
      await _updateTicketQuantitySold(eventId, ticketTypeId, quantity);

      // Add user to event attendees if not already added
      await _addAttendeeToEvent(eventId, user.uid);

      _logger.i('Tickets purchased: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      _logger.e('Error purchasing tickets: $e');
      rethrow;
    }
  }

  /// Get ticket purchases for a user
  Future<List<TicketPurchase>> getUserTicketPurchases(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_ticketPurchasesCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return TicketPurchase.fromFirestore(doc);
            } on Exception catch (e) {
              AppLogger.error('Error parsing ticket purchase ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TicketPurchase>()
          .toList();
    } catch (e) {
      _logger.e('Error getting user ticket purchases: $e');
      rethrow;
    }
  }

  /// Get ticket purchases for an event
  Future<List<TicketPurchase>> getEventTicketPurchases(String eventId) async {
    try {
      final snapshot = await _firestore
          .collection(_ticketPurchasesCollection)
          .where('eventId', isEqualTo: eventId)
          .orderBy('purchaseDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) {
            try {
              return TicketPurchase.fromFirestore(doc);
            } on Exception catch (e) {
              AppLogger.error('Error parsing ticket purchase ${doc.id}: $e');
              return null;
            }
          })
          .whereType<TicketPurchase>()
          .toList();
    } catch (e) {
      _logger.e('Error getting event ticket purchases: $e');
      rethrow;
    }
  }

  /// Refund a ticket purchase
  Future<void> refundTicketPurchase(String purchaseId, String refundId) async {
    try {
      final purchase = await _getTicketPurchase(purchaseId);
      if (purchase == null) {
        throw Exception('Purchase not found');
      }

      final event = await getEvent(purchase.eventId);
      if (event == null) {
        throw Exception('Event not found');
      }

      if (!event.canRefund) {
        throw Exception('Refund deadline has passed');
      }

      // Update purchase status
      await _firestore
          .collection(_ticketPurchasesCollection)
          .doc(purchaseId)
          .update({
            'status': TicketPurchaseStatus.refunded.name,
            'refundId': refundId,
            'refundDate': Timestamp.now(),
          });

      // Update ticket quantity sold (reduce by refunded quantity)
      await _updateTicketQuantitySold(
        purchase.eventId,
        purchase.ticketTypeId,
        -purchase.quantity,
      );

      _logger.i('Ticket purchase refunded: $purchaseId');
    } catch (e) {
      _logger.e('Error refunding ticket purchase: $e');
      rethrow;
    }
  }

  /// Update ticket quantity sold
  Future<void> _updateTicketQuantitySold(
    String eventId,
    String ticketTypeId,
    int quantityChange,
  ) async {
    await _firestore.runTransaction((transaction) async {
      final eventDoc = await transaction.get(
        _firestore.collection(_eventsCollection).doc(eventId),
      );

      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final event = ArtbeatEvent.fromFirestore(eventDoc);
      final updatedTicketTypes = event.ticketTypes.map((ticket) {
        if (ticket.id == ticketTypeId) {
          final currentSold = ticket.quantitySold ?? 0;
          final newSold = (currentSold + quantityChange).clamp(
            0,
            ticket.quantity,
          );
          return ticket.copyWith(quantitySold: newSold);
        }
        return ticket;
      }).toList();

      final updatedEvent = event.copyWith(ticketTypes: updatedTicketTypes);
      transaction.update(eventDoc.reference, updatedEvent.toFirestore());
    });
  }

  /// Add attendee to event
  Future<void> _addAttendeeToEvent(String eventId, String userId) async {
    await _firestore.collection(_eventsCollection).doc(eventId).update({
      'attendeeIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Get a single ticket purchase
  Future<TicketPurchase?> _getTicketPurchase(String purchaseId) async {
    final doc = await _firestore
        .collection(_ticketPurchasesCollection)
        .doc(purchaseId)
        .get();

    if (doc.exists) {
      return TicketPurchase.fromFirestore(doc);
    }
    return null;
  }

  /// Stream of upcoming events for real-time updates
  Stream<List<ArtbeatEvent>> watchUpcomingEvents({int? limit}) {
    Query query = _firestore
        .collection(_eventsCollection)
        .where('isPublic', isEqualTo: true)
        .where('dateTime', isGreaterThan: Timestamp.now())
        .orderBy('dateTime', descending: false);

    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
      (snapshot) => snapshot.docs.map(ArtbeatEvent.fromFirestore).toList(),
    );
  }

  /// Stream of events by artist for real-time updates
  Stream<List<ArtbeatEvent>> watchEventsByArtist(String artistId) {
    return _firestore
        .collection(_eventsCollection)
        .where('artistId', isEqualTo: artistId)
        .orderBy('dateTime', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map(ArtbeatEvent.fromFirestore).toList(),
        );
  }

  /// Get events by filters
  Future<List<ArtbeatEvent>> getFilteredEvents({
    String? artistId,
    String? category,
    List<String>? tags,
    bool? isUpcoming,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _firestore.collection(_eventsCollection);

      if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      if (category != null && category != 'All') {
        query = query.where('category', isEqualTo: category);
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      if (isUpcoming == true) {
        query = query.where(
          'dateTime',
          isGreaterThanOrEqualTo: DateTime.now().toIso8601String(),
        );
      }

      if (startDate != null) {
        query = query.where(
          'dateTime',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        query = query.where(
          'dateTime',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      // Always order by date
      query = query.orderBy('dateTime');

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // Add the document ID to the data
        return ArtbeatEvent.fromFirestore(doc);
      }).toList();
    } catch (e) {
      _logger.e('Error getting filtered events: $e');
      rethrow;
    }
  }

  /// Get events based on various criteria
  Future<List<ArtbeatEvent>> getEvents({
    String? artistId,
    List<String>? tags,
    bool? onlyMine = false,
    bool? onlyMyTickets = false,
  }) async {
    try {
      Query query = _firestore.collection(_eventsCollection);
      final currentUserId = _auth.currentUser?.uid;

      if (onlyMine == true && currentUserId != null) {
        query = query.where('artistId', isEqualTo: currentUserId);
      } else if (artistId != null) {
        query = query.where('artistId', isEqualTo: artistId);
      }

      if (onlyMyTickets == true && currentUserId != null) {
        // First get the ticket purchases for the current user
        final ticketPurchases = await _firestore
            .collection(_ticketPurchasesCollection)
            .where('userId', isEqualTo: currentUserId)
            .get();

        // Get the event IDs from the purchases
        final eventIds = ticketPurchases.docs
            .map((doc) => doc.data()['eventId'] as String)
            .toSet();

        if (eventIds.isEmpty) {
          return [];
        }

        // Add a where clause to only get these events
        query = query.where(FieldPath.documentId, whereIn: eventIds.toList());
      }

      if (tags != null && tags.isNotEmpty) {
        query = query.where('tags', arrayContainsAny: tags);
      }

      // Order by dateTime to get upcoming events first
      query = query.orderBy('dateTime');

      final querySnapshot = await query.get();
      return querySnapshot.docs.map(ArtbeatEvent.fromFirestore).toList();
    } catch (e) {
      _logger.e('Error fetching events: $e');
      rethrow;
    }
  }
}
