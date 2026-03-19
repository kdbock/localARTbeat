import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAdReportModel {
  final String id;
  final String adId;
  final String reportedBy;
  final String reason;
  final String? additionalDetails;
  final DateTime createdAt;
  final AdminAdReportStatus status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? adminNotes;

  const AdminAdReportModel({
    required this.id,
    required this.adId,
    required this.reportedBy,
    required this.reason,
    this.additionalDetails,
    required this.createdAt,
    required this.status,
    this.reviewedBy,
    this.reviewedAt,
    this.adminNotes,
  });

  factory AdminAdReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminAdReportModel(
      id: doc.id,
      adId: (data['adId'] ?? '') as String,
      reportedBy: (data['reportedBy'] ?? '') as String,
      reason: (data['reason'] ?? '') as String,
      additionalDetails: data['additionalDetails'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AdminAdReportStatus.fromString((data['status'] ?? 'pending') as String),
      reviewedBy: data['reviewedBy'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      adminNotes: data['adminNotes'] as String?,
    );
  }
}

enum AdminAdReportStatus {
  pending,
  reviewed,
  dismissed,
  actionTaken;

  String get value => name;

  String get displayName {
    switch (this) {
      case AdminAdReportStatus.pending:
        return 'Pending Review';
      case AdminAdReportStatus.reviewed:
        return 'Reviewed';
      case AdminAdReportStatus.dismissed:
        return 'Dismissed';
      case AdminAdReportStatus.actionTaken:
        return 'Action Taken';
    }
  }

  static AdminAdReportStatus fromString(String value) {
    return AdminAdReportStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => AdminAdReportStatus.pending,
    );
  }
}

class AdminAdReportReasons {
  static const List<Map<String, String>> reasons = [
    {
      'value': 'inappropriate_content',
      'label': 'Inappropriate Content',
    },
    {
      'value': 'misleading',
      'label': 'Misleading or False',
    },
    {
      'value': 'spam',
      'label': 'Spam',
    },
    {
      'value': 'copyright',
      'label': 'Copyright Violation',
    },
    {
      'value': 'harassment',
      'label': 'Harassment',
    },
    {
      'value': 'hate_speech',
      'label': 'Hate Speech',
    },
    {
      'value': 'scam',
      'label': 'Scam or Fraud',
    },
    {
      'value': 'other',
      'label': 'Other',
    },
  ];

  static Map<String, String>? getReasonByValue(String value) {
    for (final reason in reasons) {
      if (reason['value'] == value) {
        return reason;
      }
    }
    return null;
  }
}
