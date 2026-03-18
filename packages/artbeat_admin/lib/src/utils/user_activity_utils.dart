import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? parseFirestoreDate(dynamic value) {
  if (value == null) return null;
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return null;
}

DateTime? getEffectiveLastActive(Map<String, dynamic> data) {
  final lastActive = parseFirestoreDate(data['lastActive']);
  final lastActiveAt = parseFirestoreDate(data['lastActiveAt']);

  if (lastActive == null) return lastActiveAt;
  if (lastActiveAt == null) return lastActive;
  return lastActive.isAfter(lastActiveAt) ? lastActive : lastActiveAt;
}

bool isWithinRange(
  DateTime? value, {
  required DateTime start,
  required DateTime end,
}) {
  if (value == null) return false;
  return !value.isBefore(start) && value.isBefore(end);
}
