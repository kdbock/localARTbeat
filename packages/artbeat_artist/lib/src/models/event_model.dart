import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

/// Model representing an event in the ARTbeat app
class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String? imageUrl;
  final String artistId; // Creator of the event
  final bool isPublic; // Whether event shows on community calendar
  final List<String> attendeeIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.location,
    this.imageUrl,
    required this.artistId,
    required this.isPublic,
    required this.attendeeIds,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create an EventModel from a Firestore document
  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return EventModel(
      id: doc.id,
      title: FirestoreUtils.safeStringDefault(data['title']),
      description: FirestoreUtils.safeStringDefault(data['description']),
      startDate: data['startDate'] != null
          ? FirestoreUtils.safeDateTime(data['startDate'])
          : FirestoreUtils.safeDateTime(data['dateTime']),
      endDate: data['endDate'] != null
          ? FirestoreUtils.safeDateTime(data['endDate'])
          : null,
      location: FirestoreUtils.safeStringDefault(data['location']),
      imageUrl: FirestoreUtils.safeString(data['imageUrl']),
      artistId: FirestoreUtils.safeStringDefault(data['artistId']),
      isPublic: FirestoreUtils.safeBool(data['isPublic'], false),
      attendeeIds: (data['attendeeIds'] as List<dynamic>?)
              ?.map((e) => FirestoreUtils.safeStringDefault(e))
              .toList() ??
          <String>[],
      createdAt: FirestoreUtils.safeDateTime(data['createdAt']),
      updatedAt: FirestoreUtils.safeDateTime(data['updatedAt']),
    );
  }

  /// Convert model to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'location': location,
      'imageUrl': imageUrl,
      'artistId': artistId,
      'isPublic': isPublic,
      'attendeeIds': attendeeIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// Create a copy of this EventModel with the given fields replaced
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? location,
    String? imageUrl,
    String? artistId,
    bool? isPublic,
    List<String>? attendeeIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      artistId: artistId ?? this.artistId,
      isPublic: isPublic ?? this.isPublic,
      attendeeIds: attendeeIds ?? this.attendeeIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
