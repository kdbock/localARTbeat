import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing an event in the ARTbeat app
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final String? artistProfileImageUrl;
  final String artistId; // Creator of the event
  final bool isPublic; // Whether event shows on community calendar
  final List<String> attendeeIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? contactEmail;
  final double? price; // Event ticket price

  // Computed property for attendees count
  int get attendeesCount => attendeeIds.length;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.imageUrl,
    this.artistProfileImageUrl,
    required this.artistId,
    required this.isPublic,
    required this.attendeeIds,
    required this.createdAt,
    required this.updatedAt,
    this.contactEmail,
    this.price,
  });

  /// Create an EventModel from a Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    String? _firstNonEmpty(List<String?> values) {
      for (final value in values) {
        final trimmed = value?.trim();
        if (trimmed != null && trimmed.isNotEmpty) {
          return trimmed;
        }
      }
      return null;
    }

    final galleryImages =
        (data['imageUrls'] as List?)
            ?.whereType<String>()
            .map((url) => url.trim())
            .where((url) => url.isNotEmpty)
            .toList() ??
        [];

    final resolvedImageUrl = _firstNonEmpty([
      data['imageUrl'] as String?,
      data['eventBannerUrl'] as String?,
      data['eventCoverUrl'] as String?,
      galleryImages.isNotEmpty ? galleryImages.first : null,
    ]);

    final resolvedArtistImageUrl = _firstNonEmpty([
      data['artistProfileImageUrl'] as String?,
      data['artistHeadshotUrl'] as String?,
      data['artistAvatarUrl'] as String?,
    ]);

    return EventModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      startDate:
          (data['startDate'] as Timestamp?)?.toDate() ??
          (data['dateTime'] as Timestamp?)?.toDate() ??
          DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
      location: data['location'] as String? ?? '',
      imageUrl: resolvedImageUrl,
      artistProfileImageUrl: resolvedArtistImageUrl,
      artistId: data['artistId'] as String? ?? '',
      isPublic: data['isPublic'] as bool? ?? true,
      attendeeIds: List<String>.from(data['attendeeIds'] as List? ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      contactEmail: data['contactEmail'] as String?,
      price: (data['price'] as num?)?.toDouble(),
    );
  }

  /// Convert model to a Firestore document
  Map<String, dynamic> toFirestore() {
    final map = {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'location': location,
      'imageUrl': imageUrl,
      'artistProfileImageUrl': artistProfileImageUrl,
      'artistId': artistId,
      'isPublic': isPublic,
      'attendeeIds': attendeeIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'contactEmail': contactEmail,
      'price': price,
    };
    // Remove null values to prevent iOS crash in cloud_firestore plugin
    map.removeWhere((key, value) => value == null);
    return map;
  }

  /// Create a copy of this EventModel with given fields replaced
  EventModel copyWith({
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    String? artistProfileImageUrl,
    String? artistId,
    bool? isPublic,
    List<String>? attendeeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? contactEmail,
    double? price,
  }) {
    return EventModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      artistProfileImageUrl:
          artistProfileImageUrl ?? this.artistProfileImageUrl,
      artistId: artistId ?? this.artistId,
      isPublic: isPublic ?? this.isPublic,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      contactEmail: contactEmail ?? this.contactEmail,
      price: price ?? this.price,
    );
  }
}
