import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Extended user model with admin-specific functionality
class UserAdminModel extends UserModel {
  final DateTime? lastLoginAt;
  final DateTime? lastActiveAt;
  final bool isSuspended;
  final bool isShadowBanned;
  final bool isDeleted;
  final String? suspensionReason;
  final DateTime? suspendedAt;
  final String? suspendedBy;
  final Map<String, dynamic> adminNotes;
  final List<String> adminFlags;
  final int reportCount;
  final DateTime? emailVerifiedAt;
  final bool requiresPasswordReset;
  final String? coverImageUrl;
  final DateTime? birthDate;
  final String? gender;
  final DateTime? updatedAt;
  final bool isVerified;
  final List<String> achievements;
  final bool isFeatured;

  UserAdminModel({
    required super.id,
    required super.email,
    required super.username,
    required super.fullName,
    super.bio,
    super.profileImageUrl,
    super.location,
    super.engagementStats,
    super.captures,
    super.posts,
    required super.createdAt,
    super.lastActive,
    super.userType,
    super.preferences,
    super.experiencePoints,
    super.level,
    super.zipCode,
    this.lastLoginAt,
    this.lastActiveAt,
    this.isSuspended = false,
    this.isShadowBanned = false,
    this.isDeleted = false,
    this.suspensionReason,
    this.suspendedAt,
    this.suspendedBy,
    this.adminNotes = const {},
    this.adminFlags = const [],
    this.reportCount = 0,
    this.emailVerifiedAt,
    this.requiresPasswordReset = false,
    this.coverImageUrl,
    this.birthDate,
    this.gender,
    this.updatedAt,
    this.isVerified = false,
    this.achievements = const [],
    this.isFeatured = false,
  });

  factory UserAdminModel.fromUserModel(UserModel user) {
    return UserAdminModel(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      username: user.username,
      bio: user.bio,
      profileImageUrl: user.profileImageUrl,
      location: user.location,
      posts: user.posts,
      captures: user.captures,
      createdAt: user.createdAt,
      lastActive: user.lastActive,
      userType: user.userType,
      preferences: user.preferences,
      experiencePoints: user.experiencePoints,
      level: user.level,
      zipCode: user.zipCode,
    );
  }

  factory UserAdminModel.fromDocumentSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return UserAdminModel(
      id: doc.id,
      email: data['email'] as String? ?? '',
      fullName: data['fullName'] as String? ?? '',
      username: data['username'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      profileImageUrl: data['profileImageUrl'] as String? ?? '',
      location: data['location'] as String? ?? '',
      posts: List<String>.from(data['posts'] as List<dynamic>? ?? []),
      captures: (data['captures'] as List<dynamic>? ?? [])
          .map((capture) =>
              CaptureModel.fromJson(capture as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
      userType: data['userType'] as String?,
      preferences: data['preferences'] as Map<String, dynamic>?,
      experiencePoints: data['experiencePoints'] as int? ?? 0,
      level: data['level'] as int? ?? 1,
      zipCode: data['zipCode'] as String?,
      // Admin-specific fields
      coverImageUrl: data['coverImageUrl'] as String?,
      birthDate: (data['birthDate'] as Timestamp?)?.toDate(),
      gender: data['gender'] as String?,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isVerified: data['isVerified'] as bool? ?? false,
      achievements: List<String>.from(
        data['achievements'] as List<dynamic>? ?? [],
      ),
      isFeatured: data['isFeatured'] as bool? ?? false,
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
      lastActiveAt: (data['lastActiveAt'] as Timestamp?)?.toDate(),
      isSuspended: data['isSuspended'] as bool? ?? false,
      isShadowBanned: data['isShadowBanned'] as bool? ?? false,
      isDeleted: data['isDeleted'] as bool? ?? false,
      suspensionReason: data['suspensionReason'] as String?,
      suspendedAt: (data['suspendedAt'] as Timestamp?)?.toDate(),
      suspendedBy: data['suspendedBy'] as String?,
      adminNotes: Map<String, dynamic>.from(
        data['adminNotes'] as Map<String, dynamic>? ?? {},
      ),
      adminFlags: List<String>.from(
        data['adminFlags'] as List<dynamic>? ?? [],
      ),
      reportCount: data['reportCount'] as int? ?? 0,
      emailVerifiedAt: (data['emailVerifiedAt'] as Timestamp?)?.toDate(),
      requiresPasswordReset: data['requiresPasswordReset'] as bool? ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      // Admin-specific fields
      'coverImageUrl': coverImageUrl,
      'zipCode': zipCode,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'gender': gender,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isVerified': isVerified,
      'experiencePoints': experiencePoints,
      'level': level,
      'achievements': achievements,
      'isFeatured': isFeatured,
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'lastActiveAt':
          lastActiveAt != null ? Timestamp.fromDate(lastActiveAt!) : null,
      'isSuspended': isSuspended,
      'isShadowBanned': isShadowBanned,
      'isDeleted': isDeleted,
      'suspensionReason': suspensionReason,
      'suspendedAt':
          suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
      'suspendedBy': suspendedBy,
      'adminNotes': adminNotes,
      'adminFlags': adminFlags,
      'reportCount': reportCount,
      'emailVerifiedAt':
          emailVerifiedAt != null ? Timestamp.fromDate(emailVerifiedAt!) : null,
      'requiresPasswordReset': requiresPasswordReset,
    });
    return map;
  }

  Map<String, dynamic> toMap() => toJson();

  /// Admin-specific copyWith method with all admin fields
  UserAdminModel copyWithAdmin({
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
    // Admin-specific fields
    String? coverImageUrl,
    DateTime? birthDate,
    String? gender,
    DateTime? updatedAt,
    bool? isVerified,
    List<String>? achievements,
    bool? isFeatured,
    DateTime? lastLoginAt,
    DateTime? lastActiveAt,
    bool? isSuspended,
    bool? isShadowBanned,
    bool? isDeleted,
    String? suspensionReason,
    DateTime? suspendedAt,
    String? suspendedBy,
    Map<String, dynamic>? adminNotes,
    List<String>? adminFlags,
    int? reportCount,
    DateTime? emailVerifiedAt,
    bool? requiresPasswordReset,
  }) {
    return UserAdminModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      engagementStats: engagementStats,
      captures: captures ?? this.captures,
      posts: posts ?? this.posts,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
      userType: userType ?? this.userType,
      preferences: preferences ?? this.preferences,
      experiencePoints: experiencePoints ?? this.experiencePoints,
      level: level ?? this.level,
      zipCode: zipCode ?? this.zipCode,
      // Admin-specific fields
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      updatedAt: updatedAt ?? this.updatedAt,
      isVerified: isVerified ?? this.isVerified,
      achievements: achievements ?? this.achievements,
      isFeatured: isFeatured ?? this.isFeatured,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      isSuspended: isSuspended ?? this.isSuspended,
      isShadowBanned: isShadowBanned ?? this.isShadowBanned,
      isDeleted: isDeleted ?? this.isDeleted,
      suspensionReason: suspensionReason ?? this.suspensionReason,
      suspendedAt: suspendedAt ?? this.suspendedAt,
      suspendedBy: suspendedBy ?? this.suspendedBy,
      adminNotes: adminNotes ?? this.adminNotes,
      adminFlags: adminFlags ?? this.adminFlags,
      reportCount: reportCount ?? this.reportCount,
      emailVerifiedAt: emailVerifiedAt ?? this.emailVerifiedAt,
      requiresPasswordReset:
          requiresPasswordReset ?? this.requiresPasswordReset,
    );
  }

  /// Get user status text
  String get statusText {
    if (isDeleted) return 'Deleted';
    if (isSuspended) return 'Suspended';
    if (!isVerified) return 'Unverified';
    return 'Active';
  }

  /// Get user status color
  String get statusColor {
    if (isDeleted) return 'red';
    if (isSuspended) return 'orange';
    if (!isVerified) return 'yellow';
    return 'green';
  }

  /// Check if user is active (logged in within last 30 days)
  bool get isActiveUser {
    if (lastActiveAt == null) return false;
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return lastActiveAt!.isAfter(thirtyDaysAgo);
  }
}
