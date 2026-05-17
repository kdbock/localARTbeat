import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

class AdminEventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final List<String> imageUrls;
  final bool isPublic;
  final bool isActive;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime createdAt;
  final String moderationStatus;
  final bool isRecurring;

  const AdminEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.imageUrls,
    required this.isPublic,
    required this.isActive,
    required this.startDate,
    this.endDate,
    required this.createdAt,
    required this.moderationStatus,
    required this.isRecurring,
  });

  factory AdminEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final startDateRaw = data.containsKey('startDate')
        ? data['startDate']
        : data.containsKey('dateTime')
            ? data['dateTime']
            : data['createdAt'];
    return AdminEventModel(
      id: doc.id,
      title: FirestoreUtils.getString(data, 'title'),
      description: FirestoreUtils.getString(data, 'description'),
      location: FirestoreUtils.getString(data, 'location'),
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? [])
          .whereType<String>()
          .toList(),
      isPublic: FirestoreUtils.getBool(data, 'isPublic', true),
      isActive: FirestoreUtils.getBool(data, 'isActive', true),
      startDate: FirestoreUtils.safeDateTime(startDateRaw),
      endDate: data['endDate'] != null
          ? FirestoreUtils.getDateTime(data, 'endDate')
          : null,
      createdAt: FirestoreUtils.getDateTime(data, 'createdAt'),
      moderationStatus: FirestoreUtils.getString(
        data,
        'moderationStatus',
        'pending',
      ),
      isRecurring: FirestoreUtils.getBool(data, 'isRecurring'),
    );
  }
}
