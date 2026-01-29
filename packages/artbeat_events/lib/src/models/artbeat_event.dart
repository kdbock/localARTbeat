import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;
import 'ticket_type.dart';
import 'refund_policy.dart';

/// Main event model for the ARTbeat events system
/// Supports multiple images, ticketing, and comprehensive event management
class ArtbeatEvent {
  final String id;
  final String title;
  final String description;
  final String artistId;
  final List<String> imageUrls; // multiple event images
  final String artistHeadshotUrl;
  final String eventBannerUrl;
  final String artistHeadshotFit;
  final String eventBannerFit;
  final String imageFit;
  final DateTime dateTime;
  final String location;
  final List<TicketType> ticketTypes;
  final RefundPolicy refundPolicy;
  final bool reminderEnabled;
  final bool isPublic; // Whether event shows on community calendar
  final List<String> attendeeIds;
  final int maxAttendees;
  final List<String> tags; // art-related tags for categorization
  final String contactEmail;
  final String? contactPhone;
  final Map<String, dynamic>? metadata; // for additional event-specific data
  final DateTime createdAt;
  final DateTime updatedAt;
  final String category; // Added category field
  final String
  moderationStatus; // pending, approved, rejected, flagged, under_review
  final DateTime? lastModerated;

  // Recurring event fields
  final bool isRecurring;
  final String? recurrencePattern; // 'daily', 'weekly', 'monthly', 'custom'
  final int? recurrenceInterval; // e.g., every 2 weeks
  final DateTime? recurrenceEndDate;
  final String? parentEventId; // For recurring event instances

  // Social interaction counts
  final int viewCount;
  final int likeCount;
  final int shareCount;
  final int saveCount;

  const ArtbeatEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.artistId,
    required this.imageUrls,
    required this.artistHeadshotUrl,
    required this.eventBannerUrl,
    this.artistHeadshotFit = 'cover',
    this.eventBannerFit = 'cover',
    this.imageFit = 'cover',
    required this.dateTime,
    required this.location,
    required this.ticketTypes,
    required this.refundPolicy,
    required this.reminderEnabled,
    this.isPublic = true,
    this.attendeeIds = const [],
    this.maxAttendees = 100,
    this.tags = const [],
    required this.contactEmail,
    this.contactPhone,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
    required this.category,
    this.moderationStatus = 'pending',
    this.lastModerated,
    this.isRecurring = false,
    this.recurrencePattern,
    this.recurrenceInterval,
    this.recurrenceEndDate,
    this.parentEventId,
    this.viewCount = 0,
    this.likeCount = 0,
    this.shareCount = 0,
    this.saveCount = 0,
  });

  /// Factory constructor to create a new event with generated ID
  factory ArtbeatEvent.create({
    required String title,
    required String description,
    required String artistId,
    required List<String> imageUrls,
    required String artistHeadshotUrl,
    required String eventBannerUrl,
    String artistHeadshotFit = 'cover',
    String eventBannerFit = 'cover',
    String imageFit = 'cover',
    required DateTime dateTime,
    required String location,
    required List<TicketType> ticketTypes,
    RefundPolicy? refundPolicy,
    bool reminderEnabled = true,
    bool isPublic = true,
    int maxAttendees = 100,
    List<String> tags = const [],
    required String contactEmail,
    String? contactPhone,
    Map<String, dynamic>? metadata,
    String category = 'Other', // Default category
    bool isRecurring = false,
    String? recurrencePattern,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    String? parentEventId,
  }) {
    final now = DateTime.now();
    return ArtbeatEvent(
      id: const Uuid().v4(),
      title: title,
      description: description,
      artistId: artistId,
      imageUrls: imageUrls,
      artistHeadshotUrl: artistHeadshotUrl,
      eventBannerUrl: eventBannerUrl,
      artistHeadshotFit: artistHeadshotFit,
      eventBannerFit: eventBannerFit,
      imageFit: imageFit,
      dateTime: dateTime,
      location: location,
      ticketTypes: ticketTypes,
      refundPolicy: refundPolicy ?? const RefundPolicy(),
      reminderEnabled: reminderEnabled,
      isPublic: isPublic,
      attendeeIds: [],
      maxAttendees: maxAttendees,
      tags: tags,
      contactEmail: contactEmail,
      contactPhone: contactPhone,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
      category: category, // Default category
      isRecurring: isRecurring,
      recurrencePattern: recurrencePattern,
      recurrenceInterval: recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate,
      parentEventId: parentEventId,
    );
  }

  /// Create an ArtbeatEvent from a Firestore document
  factory ArtbeatEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return ArtbeatEvent(
      id: doc.id,
      title: FirestoreUtils.getString(data, 'title'),
      description: FirestoreUtils.getString(data, 'description'),
      artistId: FirestoreUtils.getString(data, 'artistId'),
      imageUrls: FirestoreUtils.getStringList(data, 'imageUrls'),
      artistHeadshotUrl: FirestoreUtils.getString(data, 'artistHeadshotUrl'),
      eventBannerUrl: FirestoreUtils.getString(data, 'eventBannerUrl'),
      artistHeadshotFit: FirestoreUtils.getString(
        data,
        'artistHeadshotFit',
        'cover',
      ),
      eventBannerFit: FirestoreUtils.getString(data, 'eventBannerFit', 'cover'),
      imageFit: FirestoreUtils.getString(data, 'imageFit', 'cover'),
      dateTime: FirestoreUtils.getDateTime(data, 'dateTime'),
      location: FirestoreUtils.getString(data, 'location'),
      ticketTypes: _parseTicketTypes(data['ticketTypes']),
      refundPolicy: RefundPolicy.fromMap(data['refundPolicy'] ?? {}),
      reminderEnabled: FirestoreUtils.getBool(data, 'reminderEnabled', true),
      isPublic: FirestoreUtils.getBool(data, 'isPublic', true),
      attendeeIds: FirestoreUtils.getStringList(data, 'attendeeIds'),
      maxAttendees: FirestoreUtils.getInt(data, 'maxAttendees', 100),
      tags: FirestoreUtils.getStringList(data, 'tags'),
      contactEmail: FirestoreUtils.getString(data, 'contactEmail'),
      contactPhone: FirestoreUtils.getOptionalString(data, 'contactPhone'),
      metadata: FirestoreUtils.getOptionalMap(data, 'metadata'),
      createdAt: FirestoreUtils.getDateTime(data, 'createdAt'),
      updatedAt: FirestoreUtils.getDateTime(data, 'updatedAt'),
      category: FirestoreUtils.getString(data, 'category', 'Other'),
      moderationStatus: FirestoreUtils.getString(
        data,
        'moderationStatus',
        'pending',
      ),
      lastModerated: FirestoreUtils.getOptionalDateTime(data, 'lastModerated'),
      isRecurring: FirestoreUtils.getBool(data, 'isRecurring'),
      recurrencePattern: FirestoreUtils.getOptionalString(
        data,
        'recurrencePattern',
      ),
      recurrenceInterval: FirestoreUtils.getInt(data, 'recurrenceInterval'),
      recurrenceEndDate: FirestoreUtils.getOptionalDateTime(
        data,
        'recurrenceEndDate',
      ),
      parentEventId: FirestoreUtils.getOptionalString(data, 'parentEventId'),
      viewCount: FirestoreUtils.getInt(data, 'viewCount'),
      likeCount: FirestoreUtils.getInt(data, 'likeCount'),
      shareCount: FirestoreUtils.getInt(data, 'shareCount'),
      saveCount: FirestoreUtils.getInt(data, 'saveCount'),
    );
  }

  /// Create an ArtbeatEvent from a Map (for analytics compatibility)
  factory ArtbeatEvent.fromMap(Map<String, dynamic> data) {
    return ArtbeatEvent(
      id: FirestoreUtils.getString(data, 'id'),
      title: FirestoreUtils.getString(data, 'title'),
      description: FirestoreUtils.getString(data, 'description'),
      artistId: FirestoreUtils.getString(data, 'artistId'),
      imageUrls: FirestoreUtils.getStringList(data, 'imageUrls'),
      artistHeadshotUrl: FirestoreUtils.getString(data, 'artistHeadshotUrl'),
      eventBannerUrl: FirestoreUtils.getString(data, 'eventBannerUrl'),
      artistHeadshotFit: FirestoreUtils.getString(
        data,
        'artistHeadshotFit',
        'cover',
      ),
      eventBannerFit: FirestoreUtils.getString(data, 'eventBannerFit', 'cover'),
      imageFit: FirestoreUtils.getString(data, 'imageFit', 'cover'),
      dateTime: FirestoreUtils.getDateTime(data, 'dateTime'),
      location: FirestoreUtils.getString(data, 'location'),
      ticketTypes: _parseTicketTypes(data['ticketTypes']),
      refundPolicy: RefundPolicy.fromMap(data['refundPolicy'] ?? {}),
      reminderEnabled: FirestoreUtils.getBool(data, 'reminderEnabled', true),
      isPublic: FirestoreUtils.getBool(data, 'isPublic', true),
      attendeeIds: FirestoreUtils.getStringList(data, 'attendeeIds'),
      maxAttendees: FirestoreUtils.getInt(data, 'maxAttendees', 100),
      tags: FirestoreUtils.getStringList(data, 'tags'),
      contactEmail: FirestoreUtils.getString(data, 'contactEmail'),
      contactPhone: FirestoreUtils.getOptionalString(data, 'contactPhone'),
      metadata: FirestoreUtils.getOptionalMap(data, 'metadata'),
      createdAt: FirestoreUtils.getDateTime(data, 'createdAt'),
      updatedAt: FirestoreUtils.getDateTime(data, 'updatedAt'),
      category: FirestoreUtils.getString(data, 'category', 'Other'),
      moderationStatus: FirestoreUtils.getString(
        data,
        'moderationStatus',
        'pending',
      ),
      lastModerated: FirestoreUtils.getOptionalDateTime(data, 'lastModerated'),
      isRecurring: FirestoreUtils.getBool(data, 'isRecurring'),
      recurrencePattern: FirestoreUtils.getOptionalString(
        data,
        'recurrencePattern',
      ),
      recurrenceInterval: FirestoreUtils.getInt(data, 'recurrenceInterval'),
      recurrenceEndDate: FirestoreUtils.getOptionalDateTime(
        data,
        'recurrenceEndDate',
      ),
      parentEventId: FirestoreUtils.getOptionalString(data, 'parentEventId'),
      viewCount: FirestoreUtils.getInt(data, 'viewCount'),
      likeCount: FirestoreUtils.getInt(data, 'likeCount'),
      shareCount: FirestoreUtils.getInt(data, 'shareCount'),
      saveCount: FirestoreUtils.getInt(data, 'saveCount'),
    );
  }

  /// Convert ArtbeatEvent to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    final map = {
      'title': title,
      'description': description,
      'artistId': artistId,
      'imageUrls': imageUrls,
      'artistHeadshotUrl': artistHeadshotUrl,
      'eventBannerUrl': eventBannerUrl,
      'artistHeadshotFit': artistHeadshotFit,
      'eventBannerFit': eventBannerFit,
      'imageFit': imageFit,
      'dateTime': Timestamp.fromDate(dateTime),
      'startDate': Timestamp.fromDate(dateTime),
      'location': location,
      'ticketTypes': ticketTypes.map((t) => t.toMap()).toList(),
      'refundPolicy': refundPolicy.toMap(),
      'reminderEnabled': reminderEnabled,
      'isPublic': isPublic,
      'attendeeIds': attendeeIds,
      'maxAttendees': maxAttendees,
      'tags': tags,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'category': category, // Added category field
      'moderationStatus': moderationStatus,
      'lastModerated': lastModerated != null
          ? Timestamp.fromDate(lastModerated!)
          : null,
      'isRecurring': isRecurring,
      'recurrencePattern': recurrencePattern,
      'recurrenceInterval': recurrenceInterval,
      'recurrenceEndDate': recurrenceEndDate != null
          ? Timestamp.fromDate(recurrenceEndDate!)
          : null,
      'parentEventId': parentEventId,
      'viewCount': viewCount,
      'likeCount': likeCount,
      'shareCount': shareCount,
      'saveCount': saveCount,
    };
    // Remove null values to prevent iOS crash in cloud_firestore plugin
    map.removeWhere((key, value) => value == null);
    return map;
  }

  /// Create a copy of this ArtbeatEvent with the given fields replaced
  ArtbeatEvent copyWith({
    String? id,
    String? title,
    String? description,
    String? artistId,
    List<String>? imageUrls,
    String? artistHeadshotUrl,
    String? eventBannerUrl,
    String? artistHeadshotFit,
    String? eventBannerFit,
    String? imageFit,
    DateTime? dateTime,
    String? location,
    List<TicketType>? ticketTypes,
    RefundPolicy? refundPolicy,
    bool? reminderEnabled,
    bool? isPublic,
    List<String>? attendeeIds,
    int? maxAttendees,
    List<String>? tags,
    String? contactEmail,
    String? contactPhone,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    String? moderationStatus,
    DateTime? lastModerated,
    bool? isRecurring,
    String? recurrencePattern,
    int? recurrenceInterval,
    DateTime? recurrenceEndDate,
    String? parentEventId,
    int? viewCount,
    int? likeCount,
    int? shareCount,
    int? saveCount,
  }) {
    return ArtbeatEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      artistId: artistId ?? this.artistId,
      imageUrls: imageUrls ?? this.imageUrls,
      artistHeadshotUrl: artistHeadshotUrl ?? this.artistHeadshotUrl,
      eventBannerUrl: eventBannerUrl ?? this.eventBannerUrl,
      artistHeadshotFit: artistHeadshotFit ?? this.artistHeadshotFit,
      eventBannerFit: eventBannerFit ?? this.eventBannerFit,
      imageFit: imageFit ?? this.imageFit,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      ticketTypes: ticketTypes ?? this.ticketTypes,
      refundPolicy: refundPolicy ?? this.refundPolicy,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      isPublic: isPublic ?? this.isPublic,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      maxAttendees: maxAttendees ?? this.maxAttendees,
      tags: tags ?? this.tags,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      category: category ?? this.category, // Added category field
      moderationStatus: moderationStatus ?? this.moderationStatus,
      lastModerated: lastModerated ?? this.lastModerated,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      recurrenceInterval: recurrenceInterval ?? this.recurrenceInterval,
      recurrenceEndDate: recurrenceEndDate ?? this.recurrenceEndDate,
      parentEventId: parentEventId ?? this.parentEventId,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      shareCount: shareCount ?? this.shareCount,
      saveCount: saveCount ?? this.saveCount,
    );
  }

  /// Check if the event is sold out
  bool get isSoldOut {
    final totalSold = ticketTypes.fold<int>(
      0,
      (total, ticket) => total + (ticket.quantitySold ?? 0),
    );
    return totalSold >= maxAttendees;
  }

  /// Check if the event has passed
  bool get hasEnded => DateTime.now().isAfter(dateTime);

  /// Check if refunds are still available
  bool get canRefund {
    final deadline = dateTime.subtract(refundPolicy.fullRefundDeadline);
    return DateTime.now().isBefore(deadline);
  }

  /// Get total available tickets
  int get totalAvailableTickets {
    return ticketTypes.fold<int>(0, (total, ticket) => total + ticket.quantity);
  }

  /// Get total tickets sold
  int get totalTicketsSold {
    return ticketTypes.fold<int>(
      0,
      (total, ticket) => total + (ticket.quantitySold ?? 0),
    );
  }

  /// Check if event has free tickets
  bool get hasFreeTickets {
    return ticketTypes.any((ticket) => ticket.category == TicketCategory.free);
  }

  /// Check if event has paid tickets
  bool get hasPaidTickets {
    return ticketTypes.any((ticket) => ticket.category != TicketCategory.free);
  }

  // Helper methods for parsing Firestore data
  static List<TicketType> _parseTicketTypes(dynamic data) {
    if (data is List) {
      return data
          .map((e) => TicketType.fromMap(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  @override
  String toString() {
    return 'ArtbeatEvent{id: $id, title: $title, dateTime: $dateTime, location: $location}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ArtbeatEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  DateTime get startDate => dateTime;
}
