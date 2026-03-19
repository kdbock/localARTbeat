import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' show FirestoreUtils;

class AdminEventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime createdAt;
  final String moderationStatus;
  final bool isRecurring;

  const AdminEventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.moderationStatus,
    required this.isRecurring,
  });

  factory AdminEventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AdminEventModel(
      id: doc.id,
      title: FirestoreUtils.getString(data, 'title'),
      description: FirestoreUtils.getString(data, 'description'),
      location: FirestoreUtils.getString(data, 'location'),
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
