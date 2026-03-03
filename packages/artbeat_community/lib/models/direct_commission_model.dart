import 'package:cloud_firestore/cloud_firestore.dart';

/// Enhanced commission model for direct artist-client commissions
class DirectCommissionModel {
  final String id;
  final String clientId;
  final String clientName;
  final String artistId;
  final String artistName;
  final CommissionType type;
  final String title;
  final String description;
  final CommissionStatus status;
  final double totalPrice;
  final double depositAmount;
  final double remainingAmount;
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? deadline;
  final List<CommissionMilestone> milestones;
  final List<CommissionFile> files;
  final List<CommissionMessage> messages;
  final CommissionSpecs specs;
  final Map<String, dynamic> metadata;

  DirectCommissionModel({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.artistId,
    required this.artistName,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.totalPrice,
    required this.depositAmount,
    required this.remainingAmount,
    required this.requestedAt,
    this.acceptedAt,
    this.completedAt,
    this.deadline,
    required this.milestones,
    required this.files,
    required this.messages,
    required this.specs,
    required this.metadata,
  });

  factory DirectCommissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return DirectCommissionModel(
      id: doc.id,
      clientId: data['clientId'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      artistId: data['artistId'] as String? ?? '',
      artistName: data['artistName'] as String? ?? '',
      type: CommissionType.values.firstWhere(
        (t) => t.name == (data['type'] as String? ?? 'digital'),
        orElse: () => CommissionType.digital,
      ),
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      status: CommissionStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'pending'),
        orElse: () => CommissionStatus.pending,
      ),
      totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (data['depositAmount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (data['remainingAmount'] as num?)?.toDouble() ?? 0.0,
      requestedAt:
          (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      milestones:
          (data['milestones'] as List<dynamic>?)
              ?.map(
                (m) => CommissionMilestone.fromMap(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
      files:
          (data['files'] as List<dynamic>?)
              ?.map((f) => CommissionFile.fromMap(f as Map<String, dynamic>))
              .toList() ??
          [],
      messages:
          (data['messages'] as List<dynamic>?)
              ?.map((m) => CommissionMessage.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      specs: CommissionSpecs.fromMap(
        Map<String, dynamic>.from(data['specs'] as Map? ?? const <String, dynamic>{}),
      ),
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientId': clientId,
      'clientName': clientName,
      'artistId': artistId,
      'artistName': artistName,
      'type': type.name,
      'title': title,
      'description': description,
      'status': status.name,
      'totalPrice': totalPrice,
      'depositAmount': depositAmount,
      'remainingAmount': remainingAmount,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'milestones': milestones.map((m) => m.toMap()).toList(),
      'files': files.map((f) => f.toMap()).toList(),
      'messages': messages.map((m) => m.toMap()).toList(),
      'specs': specs.toMap(),
      'metadata': metadata,
    };
  }

  DirectCommissionModel copyWith({
    String? id,
    String? clientId,
    String? clientName,
    String? artistId,
    String? artistName,
    CommissionType? type,
    String? title,
    String? description,
    CommissionStatus? status,
    double? totalPrice,
    double? depositAmount,
    double? remainingAmount,
    DateTime? requestedAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? deadline,
    List<CommissionMilestone>? milestones,
    List<CommissionFile>? files,
    List<CommissionMessage>? messages,
    CommissionSpecs? specs,
    Map<String, dynamic>? metadata,
  }) {
    return DirectCommissionModel(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      totalPrice: totalPrice ?? this.totalPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      requestedAt: requestedAt ?? this.requestedAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      deadline: deadline ?? this.deadline,
      milestones: milestones ?? this.milestones,
      files: files ?? this.files,
      messages: messages ?? this.messages,
      specs: specs ?? this.specs,
      metadata: metadata ?? this.metadata,
    );
  }
}

/// Commission types available
enum CommissionType {
  digital('Digital Artwork'),
  physical('Physical Artwork'),
  portrait('Custom Portrait'),
  commercial('Commercial License');

  const CommissionType(this.displayName);
  final String displayName;
}

/// Commission status throughout the lifecycle
enum CommissionStatus {
  pending('Pending Review'),
  quoted('Quote Provided'),
  accepted('Accepted'),
  inProgress('In Progress'),
  revision('Needs Revision'),
  completed('Completed'),
  delivered('Delivered'),
  cancelled('Cancelled'),
  disputed('Disputed');

  const CommissionStatus(this.displayName);
  final String displayName;
}

/// Commission milestone for payment tracking
class CommissionMilestone {
  final String id;
  final String title;
  final String description;
  final double amount;
  final DateTime dueDate;
  final MilestoneStatus status;
  final DateTime? completedAt;
  final String? paymentIntentId;

  CommissionMilestone({
    required this.id,
    required this.title,
    required this.description,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.completedAt,
    this.paymentIntentId,
  });

  factory CommissionMilestone.fromMap(Map<String, dynamic> data) {
    return CommissionMilestone(
      id: data['id'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: MilestoneStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'pending'),
        orElse: () => MilestoneStatus.pending,
      ),
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      paymentIntentId: data['paymentIntentId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status.name,
      'completedAt': completedAt != null
          ? Timestamp.fromDate(completedAt!)
          : null,
      'paymentIntentId': paymentIntentId,
    };
  }
}

enum MilestoneStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed'),
  paid('Paid');

  const MilestoneStatus(this.displayName);
  final String displayName;
}

/// File attached to commission (reference images, progress updates, final deliverables)
class CommissionFile {
  final String id;
  final String name;
  final String url;
  final String type; // reference, progress, final, revision
  final int sizeBytes;
  final DateTime uploadedAt;
  final String uploadedBy;
  final String? description;

  CommissionFile({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.uploadedBy,
    this.description,
  });

  factory CommissionFile.fromMap(Map<String, dynamic> data) {
    return CommissionFile(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      url: data['url'] as String? ?? '',
      type: data['type'] as String? ?? 'reference',
      sizeBytes: data['sizeBytes'] as int? ?? 0,
      uploadedAt:
          (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      uploadedBy: data['uploadedBy'] as String? ?? '',
      description: data['description'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'sizeBytes': sizeBytes,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'uploadedBy': uploadedBy,
      'description': description,
    };
  }
}

/// Message in commission conversation
class CommissionMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final List<String> attachments;

  CommissionMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.attachments,
  });

  factory CommissionMessage.fromMap(Map<String, dynamic> data) {
    return CommissionMessage(
      id: data['id'] as String? ?? '',
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      attachments: List<String>.from(
        data['attachments'] as List<dynamic>? ?? [],
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'attachments': attachments,
    };
  }
}

/// Commission specifications and requirements
class CommissionSpecs {
  final String size; // e.g., "16x20 inches", "1920x1080 pixels"
  final String medium; // e.g., "Digital", "Oil on Canvas", "Watercolor"
  final String style; // e.g., "Realistic", "Abstract", "Cartoon"
  final String colorScheme; // e.g., "Full Color", "Black & White", "Sepia"
  final int revisions; // Number of revisions included
  final bool commercialUse; // Whether commercial use is allowed
  final String deliveryFormat; // e.g., "High-res PNG", "Physical Shipping"
  final Map<String, dynamic> customRequirements;

  CommissionSpecs({
    required this.size,
    required this.medium,
    required this.style,
    required this.colorScheme,
    required this.revisions,
    required this.commercialUse,
    required this.deliveryFormat,
    required this.customRequirements,
  });

  factory CommissionSpecs.fromMap(Map<String, dynamic> data) {
    return CommissionSpecs(
      size: data['size'] as String? ?? '',
      medium: data['medium'] as String? ?? '',
      style: data['style'] as String? ?? '',
      colorScheme: data['colorScheme'] as String? ?? '',
      revisions: data['revisions'] as int? ?? 1,
      commercialUse: data['commercialUse'] as bool? ?? false,
      deliveryFormat: data['deliveryFormat'] as String? ?? '',
      customRequirements: Map<String, dynamic>.from(
        data['customRequirements'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'size': size,
      'medium': medium,
      'style': style,
      'colorScheme': colorScheme,
      'revisions': revisions,
      'commercialUse': commercialUse,
      'deliveryFormat': deliveryFormat,
      'customRequirements': customRequirements,
    };
  }
}

/// Artist commission settings and availability
class ArtistCommissionSettings {
  final String artistId;
  final bool acceptingCommissions;
  final List<CommissionType> availableTypes;
  final double basePrice;
  final Map<CommissionType, double> typePricing;
  final Map<String, double> sizePricing;
  final int maxActiveCommissions;
  final int averageTurnaroundDays;
  final double depositPercentage;
  final String terms;
  final List<String> portfolioImages;
  final DateTime lastUpdated;

  ArtistCommissionSettings({
    required this.artistId,
    required this.acceptingCommissions,
    required this.availableTypes,
    required this.basePrice,
    required this.typePricing,
    required this.sizePricing,
    required this.maxActiveCommissions,
    required this.averageTurnaroundDays,
    required this.depositPercentage,
    required this.terms,
    required this.portfolioImages,
    required this.lastUpdated,
  });

  factory ArtistCommissionSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ArtistCommissionSettings(
      artistId: doc.id,
      acceptingCommissions: data['acceptingCommissions'] as bool? ?? false,
      availableTypes:
          (data['availableTypes'] as List<dynamic>?)
              ?.map(
                (t) => CommissionType.values.firstWhere(
                  (type) => type.name == t,
                  orElse: () => CommissionType.digital,
                ),
              )
              .toList() ??
          [],
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0.0,
      typePricing: Map<CommissionType, double>.fromEntries(
        (data['typePricing'] as Map<String, dynamic>? ?? {}).entries.map(
          (e) => MapEntry(
            CommissionType.values.firstWhere(
              (t) => t.name == e.key,
              orElse: () => CommissionType.digital,
            ),
            (e.value as num).toDouble(),
          ),
        ),
      ),
      sizePricing: Map<String, double>.from(
        data['sizePricing'] as Map<String, dynamic>? ?? {},
      ),
      maxActiveCommissions: data['maxActiveCommissions'] as int? ?? 5,
      averageTurnaroundDays: data['averageTurnaroundDays'] as int? ?? 14,
      depositPercentage:
          (data['depositPercentage'] as num?)?.toDouble() ?? 50.0,
      terms: data['terms'] as String? ?? '',
      portfolioImages: List<String>.from(
        data['portfolioImages'] as List<dynamic>? ?? [],
      ),
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'acceptingCommissions': acceptingCommissions,
      'availableTypes': availableTypes.map((t) => t.name).toList(),
      'basePrice': basePrice,
      'typePricing': Map<String, dynamic>.fromEntries(
        typePricing.entries.map((e) => MapEntry(e.key.name, e.value)),
      ),
      'sizePricing': sizePricing,
      'maxActiveCommissions': maxActiveCommissions,
      'averageTurnaroundDays': averageTurnaroundDays,
      'depositPercentage': depositPercentage,
      'terms': terms,
      'portfolioImages': portfolioImages,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Commission history event types
enum CommissionHistoryEventType { statusChange, message, milestone, payment }

/// Individual commission history event
class CommissionHistoryEvent {
  final String id;
  final CommissionHistoryEventType type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  CommissionHistoryEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    required this.metadata,
  });

  factory CommissionHistoryEvent.fromMap(Map<String, dynamic> map) {
    return CommissionHistoryEvent(
      id: map['id'] as String? ?? '',
      type: CommissionHistoryEventType.values.firstWhere(
        (t) => t.name == (map['type'] as String? ?? 'statusChange'),
        orElse: () => CommissionHistoryEventType.statusChange,
      ),
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: Map<String, dynamic>.from(
        map['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'timestamp': Timestamp.fromDate(timestamp),
      'metadata': metadata,
    };
  }
}

/// Complete commission history with all events
class CommissionHistory {
  final String commissionId;
  final List<CommissionHistoryEvent> events;
  final int totalEvents;
  final DateTime? lastUpdated;

  CommissionHistory({
    required this.commissionId,
    required this.events,
    required this.totalEvents,
    this.lastUpdated,
  });

  factory CommissionHistory.fromMap(Map<String, dynamic> map) {
    return CommissionHistory(
      commissionId: map['commissionId'] as String? ?? '',
      events:
          (map['events'] as List<dynamic>?)
              ?.map(
                (e) =>
                    CommissionHistoryEvent.fromMap(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      totalEvents: map['totalEvents'] as int? ?? 0,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'commissionId': commissionId,
      'events': events.map((e) => e.toMap()).toList(),
      'totalEvents': totalEvents,
      'lastUpdated': lastUpdated != null
          ? Timestamp.fromDate(lastUpdated!)
          : null,
    };
  }
}

/// Commission analytics data
class CommissionAnalytics {
  final String userId;
  final int totalCommissions;
  final int completedCommissions;
  final int activeCommissions;
  final int cancelledCommissions;
  final double totalRevenue;
  final double totalSpent;
  final double averageCommissionValue;
  final double revisionRate;
  final List<MonthlyCommissionData> monthlyTrends;
  final DateTime generatedAt;

  CommissionAnalytics({
    required this.userId,
    required this.totalCommissions,
    required this.completedCommissions,
    required this.activeCommissions,
    required this.cancelledCommissions,
    required this.totalRevenue,
    required this.totalSpent,
    required this.averageCommissionValue,
    required this.revisionRate,
    required this.monthlyTrends,
    required this.generatedAt,
  });

  factory CommissionAnalytics.fromMap(Map<String, dynamic> map) {
    return CommissionAnalytics(
      userId: map['userId'] as String? ?? '',
      totalCommissions: map['totalCommissions'] as int? ?? 0,
      completedCommissions: map['completedCommissions'] as int? ?? 0,
      activeCommissions: map['activeCommissions'] as int? ?? 0,
      cancelledCommissions: map['cancelledCommissions'] as int? ?? 0,
      totalRevenue: (map['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      averageCommissionValue:
          (map['averageCommissionValue'] as num?)?.toDouble() ?? 0.0,
      revisionRate: (map['revisionRate'] as num?)?.toDouble() ?? 0.0,
      monthlyTrends:
          (map['monthlyTrends'] as List<dynamic>?)
              ?.map(
                (m) => MonthlyCommissionData.fromMap(m as Map<String, dynamic>),
              )
              .toList() ??
          [],
      generatedAt:
          (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'totalCommissions': totalCommissions,
      'completedCommissions': completedCommissions,
      'activeCommissions': activeCommissions,
      'cancelledCommissions': cancelledCommissions,
      'totalRevenue': totalRevenue,
      'totalSpent': totalSpent,
      'averageCommissionValue': averageCommissionValue,
      'revisionRate': revisionRate,
      'monthlyTrends': monthlyTrends.map((m) => m.toMap()).toList(),
      'generatedAt': Timestamp.fromDate(generatedAt),
    };
  }
}

/// Monthly commission data for analytics
class MonthlyCommissionData {
  final DateTime month;
  final int commissionCount;
  final double revenue;

  MonthlyCommissionData({
    required this.month,
    required this.commissionCount,
    required this.revenue,
  });

  factory MonthlyCommissionData.fromMap(Map<String, dynamic> map) {
    return MonthlyCommissionData(
      month: (map['month'] as Timestamp?)?.toDate() ?? DateTime.now(),
      commissionCount: map['commissionCount'] as int? ?? 0,
      revenue: (map['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'month': Timestamp.fromDate(month),
      'commissionCount': commissionCount,
      'revenue': revenue,
    };
  }
}
