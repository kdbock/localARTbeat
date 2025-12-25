// packages/artbeat_core/lib/src/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'user_type.dart';
import 'capture_model.dart';
import 'engagement_model.dart';
import '../utils/logger.dart';

class UserModel {
  final String id;
  final String email;
  final String username;
  final String fullName;
  final String bio;
  final String location;
  final String profileImageUrl;
  final EngagementStats engagementStats;
  final List<CaptureModel> captures;
  final List<String> posts;
  final DateTime createdAt;
  final DateTime? lastActive;
  final String? userType;
  final Map<String, dynamic>? preferences;
  final int experiencePoints;
  final int level;
  final String? zipCode;
  final bool isVerified;
  final bool onboardingCompleted;

  UserModel({
    required this.id,
    required this.email,
    required this.username,
    required this.fullName,
    this.bio = '',
    this.location = '',
    this.profileImageUrl = '',
    EngagementStats? engagementStats,
    this.captures = const [],
    this.posts = const [],
    required this.createdAt,
    this.lastActive,
    this.userType,
    this.preferences,
    this.experiencePoints = 0,
    this.level = 1,
    this.zipCode,
    this.onboardingCompleted = false,
    this.isVerified = false,
  }) : engagementStats =
           engagementStats ?? EngagementStats(lastUpdated: DateTime.now());

  // Getters for compatibility
  int get xp => experiencePoints;
  int get nextLevelXp => level * 100; // Dummy calculation
  String get avatarUrl => profileImageUrl;
  String get displayName => fullName;
  String get handle => username;
  List<String> get badges => []; // Dummy
  List<String> get favorites => []; // Dummy
  bool get isFollowing => false; // Dummy
  set isFollowing(bool value) {} // Dummy

  // Factory constructor from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      username: data['username'] as String? ?? '',
      fullName:
          data['fullName'] as String? ?? data['displayName'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      location: data['location'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      engagementStats: EngagementStats.fromFirestore(
        data['engagementStats'] as Map<String, dynamic>? ?? {},
      ),
      captures:
          (data['captures'] as List<dynamic>?)
              ?.map((e) => CaptureModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      posts:
          (data['posts'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      userType: data['userType'] as String?,
      preferences: data['preferences'] as Map<String, dynamic>?,
      experiencePoints: data['experiencePoints'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      zipCode: data['zipCode'] as String?,
      onboardingCompleted: data['onboardingCompleted'] as bool? ?? false,
    );
  }

  // Computed getters for counts
  int get connectionsCount => engagementStats.followCount;
  int get postsCount => posts.length;

  // Backward compatibility getters for migration period
  int get followersCount => engagementStats.followCount;
  int get followingCount => 0; // Will be calculated from engagement service
  List<String> get followers => []; // Legacy - use engagement service instead
  List<String> get following => []; // Legacy - use engagement service instead
  int get capturesCount => captures.length;

  factory UserModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data).copyWith(id: doc.id); // Use the document ID
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Debug logging for profile image URL resolution
    final profileImageUrl = json['profileImageUrl'] as String?;
    final photoUrl = json['photoUrl'] as String?;
    final finalImageUrl = profileImageUrl ?? photoUrl ?? '';

    // Only log in debug mode and when there are issues
    if (kDebugMode && (profileImageUrl == null && photoUrl == null)) {
      AppLogger.warning('⚠️ UserModel.fromJson: No profile image URL found');
    }

    return UserModel(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      location: json['location'] as String? ?? '',
      profileImageUrl: finalImageUrl,
      engagementStats: EngagementStats.fromFirestore(json),
      captures: (json['captures'] as List<dynamic>? ?? [])
          .map(
            (capture) => CaptureModel.fromJson(capture as Map<String, dynamic>),
          )
          .toList(),
      posts: List<String>.from(json['posts'] as List<dynamic>? ?? []),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (json['lastActive'] as Timestamp?)?.toDate(),
      userType: json['userType'] as String?,
      preferences: json['preferences'] as Map<String, dynamic>?,
      experiencePoints: json['experiencePoints'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      zipCode: json['zipCode'] as String?,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  /// Placeholder constructor for use in UI development and testing
  factory UserModel.placeholder([String? id]) {
    return UserModel(
      id: id ?? 'placeholder_id',
      email: 'placeholder@example.com',
      username: 'placeholder_user',
      fullName: 'Placeholder User',
      bio: 'This is a placeholder bio for UI development',
      location: 'San Francisco, CA',
      profileImageUrl: '',
      captures: [],
      posts: [],
      createdAt: DateTime.now(),
      userType: UserType.regular.value,
      preferences: {},
      experiencePoints: 0,
      level: 1,
      zipCode: '94102',
      onboardingCompleted: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'username': username,
      'fullName': fullName,
      'bio': bio,
      'location': location,
      'profileImageUrl': profileImageUrl,
      'engagementStats': engagementStats.toFirestore(),
      'captures': captures.map((capture) => capture.toJson()).toList(),
      'posts': posts,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'userType': userType,
      'preferences': preferences,
      'experiencePoints': experiencePoints,
      'level': level,
      'zipCode': zipCode,
      'onboardingCompleted': onboardingCompleted,
      'isVerified': isVerified,
    };
  }

  Map<String, dynamic> toFirestore() => toJson();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'fullName': fullName,
      'bio': bio,
      'location': location,
      'profileImageUrl': profileImageUrl,
      'engagementStats': engagementStats.toFirestore(),
      'captures': captures.map((capture) => capture.toJson()).toList(),
      'posts': posts,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
      'userType': userType,
      'preferences': preferences,
      'experiencePoints': experiencePoints,
      'level': level,
      'zipCode': zipCode,
      'onboardingCompleted': onboardingCompleted,
      'isVerified': isVerified,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? bio,
    String? location,
    String? profileImageUrl,
    EngagementStats? engagementStats,
    List<CaptureModel>? captures,
    List<String>? posts,
    DateTime? createdAt,
    DateTime? lastActive,
    String? userType,
    Map<String, dynamic>? preferences,
    int? experiencePoints,
    int? level,
    String? zipCode,
    bool? onboardingCompleted,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      engagementStats: engagementStats ?? this.engagementStats,
      captures: captures ?? this.captures,
      posts: posts ?? this.posts,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      userType: userType ?? this.userType,
      preferences: preferences ?? this.preferences,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      zipCode: zipCode ?? this.zipCode,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
    );
  }

  /// Check if user is an artist
  bool get isArtist => userType == UserType.artist.value;

  /// Check if user is a gallery
  bool get isGallery => userType == UserType.gallery.value;

  /// Check if user is a moderator
  bool get isModerator => userType == UserType.moderator.value;

  /// Check if user is an admin
  bool get isAdmin => userType == UserType.admin.value;

  /// Check if user is a basic user
  bool get isRegularUser => userType == UserType.regular.value;
}
