import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Account settings model for user account information
/// Implementation Date: September 5, 2025
class AccountSettingsModel {
  final String userId;
  final String email;
  final String username;
  final String displayName;
  final String phoneNumber;
  final String profileImageUrl;
  final String bio;
  final bool emailVerified;
  final bool phoneVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const AccountSettingsModel({
    required this.userId,
    required this.email,
    required this.username,
    required this.displayName,
    this.phoneNumber = '',
    this.profileImageUrl = '',
    this.bio = '',
    this.emailVerified = false,
    this.phoneVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AccountSettingsModel.fromMap(Map<String, dynamic> map) {
    return AccountSettingsModel(
      userId: map['userId'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName:
          map['displayName'] as String? ?? map['fullName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      profileImageUrl:
          map['profileImageUrl'] as String? ?? map['photoUrl'] as String? ?? '',
      bio: map['bio'] as String? ?? '',
      emailVerified: map['emailVerified'] as bool? ?? false,
      phoneVerified: map['phoneVerified'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  factory AccountSettingsModel.fromUserDocument(
    Map<String, dynamic> map, {
    User? authUser,
  }) {
    return AccountSettingsModel(
      userId:
          map['userId'] as String? ??
          authUser?.uid ??
          (map['id'] as String? ?? ''),
      email: authUser?.email ?? map['email'] as String? ?? '',
      username: map['username'] as String? ?? '',
      displayName:
          map['fullName'] as String? ??
          map['displayName'] as String? ??
          authUser?.displayName ??
          '',
      phoneNumber: authUser?.phoneNumber ?? map['phoneNumber'] as String? ?? '',
      profileImageUrl:
          map['profileImageUrl'] as String? ??
          map['photoUrl'] as String? ??
          authUser?.photoURL ??
          '',
      bio: map['bio'] as String? ?? '',
      emailVerified: authUser?.emailVerified ?? map['emailVerified'] as bool? ?? false,
      phoneVerified:
          (authUser?.phoneNumber?.isNotEmpty ?? false) ||
          (map['phoneVerified'] as bool? ?? false),
      createdAt: _parseDateTime(map['createdAt'], fallback: authUser?.metadata.creationTime),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email,
      'username': username,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'emailVerified': emailVerified,
      'phoneVerified': phoneVerified,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  AccountSettingsModel copyWith({
    String? userId,
    String? email,
    String? username,
    String? displayName,
    String? phoneNumber,
    String? profileImageUrl,
    String? bio,
    bool? emailVerified,
    bool? phoneVerified,
    DateTime? createdAt,
  }) {
    return AccountSettingsModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      emailVerified: emailVerified ?? this.emailVerified,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: DateTime.now(),
    );
  }

  bool isValid() =>
      userId.isNotEmpty &&
      email.isNotEmpty &&
      username.isNotEmpty &&
      displayName.isNotEmpty;

  static DateTime _parseDateTime(dynamic value, {DateTime? fallback}) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? fallback ?? DateTime.now();
    }
    return fallback ?? DateTime.now();
  }
}
