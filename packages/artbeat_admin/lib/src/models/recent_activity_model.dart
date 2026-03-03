import 'package:cloud_firestore/cloud_firestore.dart';

/// Activity type enumeration
enum ActivityType {
  userRegistered,
  userLogin,
  artworkUploaded,
  artworkApproved,
  artworkRejected,
  postCreated,
  commentAdded,
  eventCreated,
  userSuspended,
  userVerified,
  contentReported,
  systemError,
  adminAction;

  String get displayName {
    switch (this) {
      case ActivityType.userRegistered:
        return 'User Registered';
      case ActivityType.userLogin:
        return 'User Login';
      case ActivityType.artworkUploaded:
        return 'Artwork Uploaded';
      case ActivityType.artworkApproved:
        return 'Artwork Approved';
      case ActivityType.artworkRejected:
        return 'Artwork Rejected';
      case ActivityType.postCreated:
        return 'Post Created';
      case ActivityType.commentAdded:
        return 'Comment Added';
      case ActivityType.eventCreated:
        return 'Event Created';
      case ActivityType.userSuspended:
        return 'User Suspended';
      case ActivityType.userVerified:
        return 'User Verified';
      case ActivityType.contentReported:
        return 'Content Reported';
      case ActivityType.systemError:
        return 'System Error';
      case ActivityType.adminAction:
        return 'Admin Action';
    }
  }

  String get icon {
    switch (this) {
      case ActivityType.userRegistered:
        return 'person_add';
      case ActivityType.userLogin:
        return 'login';
      case ActivityType.artworkUploaded:
        return 'image';
      case ActivityType.artworkApproved:
        return 'check_circle';
      case ActivityType.artworkRejected:
        return 'cancel';
      case ActivityType.postCreated:
        return 'post_add';
      case ActivityType.commentAdded:
        return 'comment';
      case ActivityType.eventCreated:
        return 'event';
      case ActivityType.userSuspended:
        return 'block';
      case ActivityType.userVerified:
        return 'verified';
      case ActivityType.contentReported:
        return 'report';
      case ActivityType.systemError:
        return 'error';
      case ActivityType.adminAction:
        return 'admin_panel_settings';
    }
  }

  String get color {
    switch (this) {
      case ActivityType.userRegistered:
        return 'green';
      case ActivityType.userLogin:
        return 'blue';
      case ActivityType.artworkUploaded:
        return 'purple';
      case ActivityType.artworkApproved:
        return 'green';
      case ActivityType.artworkRejected:
        return 'red';
      case ActivityType.postCreated:
        return 'blue';
      case ActivityType.commentAdded:
        return 'orange';
      case ActivityType.eventCreated:
        return 'indigo';
      case ActivityType.userSuspended:
        return 'red';
      case ActivityType.userVerified:
        return 'green';
      case ActivityType.contentReported:
        return 'orange';
      case ActivityType.systemError:
        return 'red';
      case ActivityType.adminAction:
        return 'purple';
    }
  }

  static ActivityType fromString(String value) {
    switch (value) {
      case 'userRegistered':
      case 'user_registered':
        return ActivityType.userRegistered;
      case 'userLogin':
      case 'user_login':
        return ActivityType.userLogin;
      case 'artworkUploaded':
      case 'artwork_uploaded':
        return ActivityType.artworkUploaded;
      case 'artworkApproved':
      case 'artwork_approved':
        return ActivityType.artworkApproved;
      case 'artworkRejected':
      case 'artwork_rejected':
        return ActivityType.artworkRejected;
      case 'postCreated':
      case 'post_created':
        return ActivityType.postCreated;
      case 'commentAdded':
      case 'comment_added':
        return ActivityType.commentAdded;
      case 'eventCreated':
      case 'event_created':
        return ActivityType.eventCreated;
      case 'userSuspended':
      case 'user_suspended':
        return ActivityType.userSuspended;
      case 'userVerified':
      case 'user_verified':
        return ActivityType.userVerified;
      case 'contentReported':
      case 'content_reported':
        return ActivityType.contentReported;
      case 'systemError':
      case 'system_error':
        return ActivityType.systemError;
      case 'adminAction':
      case 'admin_action':
        return ActivityType.adminAction;
      default:
        return ActivityType.adminAction;
    }
  }
}

/// Recent activity model
class RecentActivityModel {
  final String id;
  final ActivityType type;
  final String title;
  final String description;
  final String? userId;
  final String? userName;
  final String? targetId;
  final String? targetType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  RecentActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.userId,
    this.userName,
    this.targetId,
    this.targetType,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Create from Firestore document
  factory RecentActivityModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RecentActivityModel(
      id: doc.id,
      type: ActivityType.fromString((data['type'] as String?) ?? ''),
      title: (data['title'] as String?) ?? '',
      description: (data['description'] as String?) ?? '',
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      targetId: data['targetId'] as String?,
      targetType: data['targetType'] as String?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from((data['metadata'] as Map?) ?? {}),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toDocument() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'userId': userId,
      'userName': userName,
      'targetId': targetId,
      'targetType': targetType,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }

  /// Create a copy with updated fields
  RecentActivityModel copyWith({
    String? id,
    ActivityType? type,
    String? title,
    String? description,
    String? userId,
    String? userName,
    String? targetId,
    String? targetType,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return RecentActivityModel(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      targetId: targetId ?? this.targetId,
      targetType: targetType ?? this.targetType,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Get formatted time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
