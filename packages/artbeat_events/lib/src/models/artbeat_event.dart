import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
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
    final data = doc.data() as Map<String, dynamic>;

    return ArtbeatEvent(
      id: doc.id,
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      artistId: data['artistId']?.toString() ?? '',
      imageUrls: _parseStringList(data['imageUrls']),
      artistHeadshotUrl: data['artistHeadshotUrl']?.toString() ?? '',
      eventBannerUrl: data['eventBannerUrl']?.toString() ?? '',
      dateTime: _parseDateTime(data['dateTime']),
      location: data['location']?.toString() ?? '',
      ticketTypes: _parseTicketTypes(data['ticketTypes']),
      refundPolicy: RefundPolicy.fromMap(data['refundPolicy'] ?? {}),
      reminderEnabled: data['reminderEnabled'] as bool? ?? true,
      isPublic: data['isPublic'] as bool? ?? true,
      attendeeIds: _parseStringList(data['attendeeIds']),
      maxAttendees: data['maxAttendees'] as int? ?? 100,
      tags: _parseStringList(data['tags']),
      contactEmail: data['contactEmail']?.toString() ?? '',
      contactPhone: data['contactPhone']?.toString(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      category: data['category']?.toString() ?? 'Other', // Default category
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrencePattern: data['recurrencePattern']?.toString(),
      recurrenceInterval: data['recurrenceInterval'] as int?,
      recurrenceEndDate: data['recurrenceEndDate'] != null
          ? _parseDateTime(data['recurrenceEndDate'])
          : null,
      parentEventId: data['parentEventId']?.toString(),
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      saveCount: data['saveCount'] as int? ?? 0,
    );
  }

  /// Create an ArtbeatEvent from a Map (for analytics compatibility)
  factory ArtbeatEvent.fromMap(Map<String, dynamic> data) {
    return ArtbeatEvent(
      id: data['id']?.toString() ?? '',
      title: data['title']?.toString() ?? '',
      description: data['description']?.toString() ?? '',
      artistId: data['artistId']?.toString() ?? '',
      imageUrls: _parseStringList(data['imageUrls']),
      artistHeadshotUrl: data['artistHeadshotUrl']?.toString() ?? '',
      eventBannerUrl: data['eventBannerUrl']?.toString() ?? '',
      dateTime: _parseDateTime(data['dateTime']),
      location: data['location']?.toString() ?? '',
      ticketTypes: _parseTicketTypes(data['ticketTypes']),
      refundPolicy: RefundPolicy.fromMap(data['refundPolicy'] ?? {}),
      reminderEnabled: data['reminderEnabled'] as bool? ?? true,
      isPublic: data['isPublic'] as bool? ?? true,
      attendeeIds: _parseStringList(data['attendeeIds']),
      maxAttendees: data['maxAttendees'] as int? ?? 100,
      tags: _parseStringList(data['tags']),
      contactEmail: data['contactEmail']?.toString() ?? '',
      contactPhone: data['contactPhone']?.toString(),
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      category: data['category']?.toString() ?? 'Other',
      isRecurring: data['isRecurring'] as bool? ?? false,
      recurrencePattern: data['recurrencePattern']?.toString(),
      recurrenceInterval: data['recurrenceInterval'] as int?,
      recurrenceEndDate: data['recurrenceEndDate'] != null
          ? _parseDateTime(data['recurrenceEndDate'])
          : null,
      parentEventId: data['parentEventId']?.toString(),
      viewCount: data['viewCount'] as int? ?? 0,
      likeCount: data['likeCount'] as int? ?? 0,
      shareCount: data['shareCount'] as int? ?? 0,
      saveCount: data['saveCount'] as int? ?? 0,
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
      'dateTime': Timestamp.fromDate(dateTime),
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
  static List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  static DateTime _parseDateTime(dynamic data) {
    if (data is Timestamp) {
      return data.toDate();
    }
    return DateTime.now();
  }

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
}
