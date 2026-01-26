import 'package:cloud_firestore/cloud_firestore.dart';

/// Utilities for safe Firestore data parsing
class FirestoreUtils {
  /// Safely converts a value to a String, handling DocumentReference
  static String? safeString(dynamic val) {
    if (val == null) return null;
    if (val is String) return val;
    if (val is DocumentReference) return val.id;
    return val.toString();
  }

  /// Safely converts a value to a String with a default fallback
  static String safeStringDefault(dynamic val, [String defaultValue = '']) {
    return safeString(val) ?? defaultValue;
  }

  /// Safely converts a value to a DateTime
  static DateTime safeDateTime(dynamic val, [DateTime? defaultValue]) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) {
      final parsed = DateTime.tryParse(val);
      if (parsed != null) return parsed;
    }
    return defaultValue ?? DateTime.now();
  }

  /// Safely converts a value to an int
  static int safeInt(dynamic val, [int defaultValue = 0]) {
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  /// Safely converts a value to a double
  static double safeDouble(dynamic val, [double defaultValue = 0.0]) {
    if (val is double) return val;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? defaultValue;
    return defaultValue;
  }

  /// Safely converts a value to a bool
  static bool safeBool(dynamic val, [bool defaultValue = false]) {
    if (val is bool) return val;
    if (val is String) {
      if (val.toLowerCase() == 'true') return true;
      if (val.toLowerCase() == 'false') return false;
    }
    return defaultValue;
  }

  // --- Map-based getter helpers ---

  /// Gets a String from a map with a default value
  static String getString(Map<String, dynamic> data, String key,
          [String defaultValue = '']) =>
      safeStringDefault(data[key], defaultValue);

  /// Gets an optional String from a map
  static String? getOptionalString(Map<String, dynamic> data, String key) =>
      safeString(data[key]);

  /// Gets an int from a map with a default value
  static int getInt(Map<String, dynamic> data, String key,
          [int defaultValue = 0]) =>
      safeInt(data[key], defaultValue);

  /// Gets a double from a map with a default value
  static double getDouble(Map<String, dynamic> data, String key,
          [double defaultValue = 0.0]) =>
      safeDouble(data[key], defaultValue);

  /// Gets a bool from a map with a default value
  static bool getBool(Map<String, dynamic> data, String key,
          [bool defaultValue = false]) =>
      safeBool(data[key], defaultValue);

  /// Gets a DateTime from a map with a default value
  static DateTime getDateTime(Map<String, dynamic> data, String key,
          [DateTime? defaultValue]) =>
      safeDateTime(data[key], defaultValue);

  /// Gets an optional DateTime from a map
  static DateTime? getOptionalDateTime(Map<String, dynamic> data, String key) {
    if (data[key] == null) return null;
    return safeDateTime(data[key]);
  }

  /// Gets an optional Map from a map
  static Map<String, dynamic>? getOptionalMap(
          Map<String, dynamic> data, String key) =>
      data[key] is Map<String, dynamic> ? data[key] as Map<String, dynamic> : null;

  /// Gets a List of Strings from a map
  static List<String> getStringList(Map<String, dynamic> data, String key) {
    final list = data[key];
    if (list is List) {
      return list.map((e) => safeStringDefault(e)).toList();
    }
    return [];
  }
}
