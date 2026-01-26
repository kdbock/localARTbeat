import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/direct_commission_model.dart';
import 'package:artbeat_core/artbeat_core.dart';

class DirectCommissionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();

  /// Get commissions for a specific user (as client or artist)
  Future<List<DirectCommissionModel>> getCommissionsByUser(
    String userId,
  ) async {
    try {
      // Get commissions where user is the client
      final clientCommissionsQuery = await _firestore
          .collection('direct_commissions')
          .where('clientId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .get();

      // Get commissions where user is the artist
      final artistCommissionsQuery = await _firestore
          .collection('direct_commissions')
          .where('artistId', isEqualTo: userId)
          .orderBy('requestedAt', descending: true)
          .get();

      final allCommissions = [
        ...clientCommissionsQuery.docs,
        ...artistCommissionsQuery.docs,
      ];

      // Remove duplicates
      final uniqueCommissions = <String, DocumentSnapshot>{};
      for (final doc in allCommissions) {
        uniqueCommissions[doc.id] = doc;
      }

      return uniqueCommissions.values
          .map((doc) {
            try {
              return DirectCommissionModel.fromFirestore(doc);
            } catch (e) {
              AppLogger.error('Error parsing commission ${doc.id}: $e');
              return null;
            }
          })
          .where((commission) => commission != null)
          .cast<DirectCommissionModel>()
          .toList();
    } catch (e) {
      throw Exception('Failed to get commissions: $e');
    }
  }

  /// Get commissions by status
  Future<List<DirectCommissionModel>> getCommissionsByStatus(
    String userId,
    CommissionStatus status,
  ) async {
    try {
      final commissions = await getCommissionsByUser(userId);
      return commissions.where((c) => c.status == status).toList();
    } catch (e) {
      throw Exception('Failed to get commissions by status: $e');
    }
  }

  /// Create a new commission request
  Future<String> createCommissionRequest({
    required String artistId,
    required String artistName,
    required CommissionType type,
    required String title,
    required String description,
    required CommissionSpecs specs,
    required DateTime? deadline,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to create commission');
      }

      // Get user profile for client name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final clientName =
          userData?['displayName'] as String? ??
          userData?['name'] as String? ??
          user.displayName ??
          'Unknown Client';

      final commissionId = _firestore.collection('direct_commissions').doc().id;

      final commission = DirectCommissionModel(
        id: commissionId,
        clientId: user.uid,
        clientName: clientName,
        artistId: artistId,
        artistName: artistName,
        type: type,
        title: title,
        description: description,
        status: CommissionStatus.pending,
        totalPrice: 0.0, // Will be set when artist provides quote
        depositAmount: 0.0,
        remainingAmount: 0.0,
        requestedAt: DateTime.now(),
        deadline: deadline,
        milestones: [],
        files: [],
        messages: [],
        specs: specs,
        metadata: metadata ?? {},
      );

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .set(commission.toFirestore());

      // Create initial message
      await addMessage(
        commissionId,
        'Commission request created. Waiting for artist to review and provide quote.',
      );

      return commissionId;
    } catch (e) {
      throw Exception('Failed to create commission request: $e');
    }
  }

  /// Update commission with quote from artist
  Future<void> provideQuote({
    required String commissionId,
    required double totalPrice,
    required double depositPercentage,
    required List<CommissionMilestone> milestones,
    required DateTime estimatedCompletion,
    String? quoteMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final depositAmount = totalPrice * (depositPercentage / 100);
      final remainingAmount = totalPrice - depositAmount;

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.quoted.name,
            'totalPrice': totalPrice,
            'depositAmount': depositAmount,
            'remainingAmount': remainingAmount,
            'milestones': milestones.map((m) => m.toMap()).toList(),
            'deadline': Timestamp.fromDate(estimatedCompletion),
            'metadata.quoteProvidedAt': Timestamp.now(),
            'metadata.quoteProvidedBy': user.uid,
          });

      // Add quote message
      if (quoteMessage != null) {
        await addMessage(commissionId, quoteMessage);
      }

      await addMessage(
        commissionId,
        'Quote provided: \$${totalPrice.toStringAsFixed(2)} total, \$${depositAmount.toStringAsFixed(2)} deposit required.',
      );
    } catch (e) {
      throw Exception('Failed to provide quote: $e');
    }
  }

  /// Accept commission quote (by client)
  Future<void> acceptCommission(String commissionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.accepted.name,
            'acceptedAt': Timestamp.now(),
            'metadata.acceptedBy': user.uid,
          });

      await addMessage(
        commissionId,
        'Commission accepted! Deposit payment required to begin work.',
      );
    } catch (e) {
      throw Exception('Failed to accept commission: $e');
    }
  }

  /// Start commission work (after deposit payment)
  Future<void> startCommission(String commissionId) async {
    try {
      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.inProgress.name,
            'metadata.startedAt': Timestamp.now(),
          });

      await addMessage(commissionId, 'Work has begun on your commission!');
    } catch (e) {
      throw Exception('Failed to start commission: $e');
    }
  }

  /// Complete commission
  Future<void> completeCommission(String commissionId) async {
    try {
      // 1. Update the direct_commissions document status
      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.completed.name,
            'completedAt': Timestamp.now(),
          });

      // 2. Call the Cloud Function to release funds in the earnings system
      // This transitions funds from pending to available balance
      final result = await _paymentService.completeCommission(
        commissionId: commissionId,
      );

      if (!result.success) {
        AppLogger.warning(
          '⚠️ Financial fulfillment failed for commission $commissionId: ${result.error}',
        );
      }

      await addMessage(
        commissionId,
        'Commission completed! Please review the final artwork.',
      );
    } catch (e) {
      throw Exception('Failed to complete commission: $e');
    }
  }

  /// Deliver commission (final step)
  Future<void> deliverCommission(String commissionId) async {
    try {
      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.delivered.name,
            'metadata.deliveredAt': Timestamp.now(),
          });

      await addMessage(commissionId, 'Commission delivered successfully!');
    } catch (e) {
      throw Exception('Failed to deliver commission: $e');
    }
  }

  /// Cancel commission
  Future<void> cancelCommission(String commissionId, String reason) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.cancelled.name,
            'metadata.cancelledAt': Timestamp.now(),
            'metadata.cancelledBy': user.uid,
            'metadata.cancellationReason': reason,
          });

      await addMessage(commissionId, 'Commission cancelled: $reason');
    } catch (e) {
      throw Exception('Failed to cancel commission: $e');
    }
  }

  /// Add message to commission
  Future<void> addMessage(String commissionId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get user profile for sender name
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final senderName =
          userData?['displayName'] as String? ??
          userData?['name'] as String? ??
          user.displayName ??
          'Unknown User';

      final messageObj = CommissionMessage(
        id: _firestore.collection('temp').doc().id,
        senderId: user.uid,
        senderName: senderName,
        message: message,
        timestamp: DateTime.now(),
        attachments: [],
      );

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'messages': FieldValue.arrayUnion([messageObj.toMap()]),
          });
    } catch (e) {
      throw Exception('Failed to add message: $e');
    }
  }

  /// Upload file to commission
  Future<void> uploadFile({
    required String commissionId,
    required String fileName,
    required String fileUrl,
    required String fileType,
    required int sizeBytes,
    String? description,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final file = CommissionFile(
        id: _firestore.collection('temp').doc().id,
        name: fileName,
        url: fileUrl,
        type: fileType,
        sizeBytes: sizeBytes,
        uploadedAt: DateTime.now(),
        uploadedBy: user.uid,
        description: description,
      );

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'files': FieldValue.arrayUnion([file.toMap()]),
          });

      await addMessage(commissionId, 'File uploaded: $fileName');
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Update milestone status
  Future<void> updateMilestone({
    required String commissionId,
    required String milestoneId,
    required MilestoneStatus status,
    String? paymentIntentId,
  }) async {
    try {
      final commission = await getCommission(commissionId);
      final updatedMilestones = commission.milestones.map((milestone) {
        if (milestone.id == milestoneId) {
          return CommissionMilestone(
            id: milestone.id,
            title: milestone.title,
            description: milestone.description,
            amount: milestone.amount,
            dueDate: milestone.dueDate,
            status: status,
            completedAt:
                status == MilestoneStatus.completed ||
                    status == MilestoneStatus.paid
                ? DateTime.now()
                : milestone.completedAt,
            paymentIntentId: paymentIntentId ?? milestone.paymentIntentId,
          );
        }
        return milestone;
      }).toList();

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'milestones': updatedMilestones.map((m) => m.toMap()).toList(),
          });

      await addMessage(
        commissionId,
        'Milestone "${commission.milestones.firstWhere((m) => m.id == milestoneId).title}" updated to ${status.displayName}',
      );
    } catch (e) {
      throw Exception('Failed to update milestone: $e');
    }
  }

  /// Get single commission by ID
  Future<DirectCommissionModel> getCommission(String commissionId) async {
    try {
      final doc = await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .get();

      if (!doc.exists) {
        throw Exception('Commission not found');
      }

      return DirectCommissionModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get commission: $e');
    }
  }

  /// Get artist commission settings
  Future<ArtistCommissionSettings?> getArtistCommissionSettings(
    String artistId,
  ) async {
    try {
      final doc = await _firestore
          .collection('artist_commission_settings')
          .doc(artistId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return ArtistCommissionSettings.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get artist commission settings: $e');
    }
  }

  /// Update artist commission settings
  Future<void> updateArtistCommissionSettings(
    ArtistCommissionSettings settings,
  ) async {
    try {
      await _firestore
          .collection('artist_commission_settings')
          .doc(settings.artistId)
          .set(settings.toFirestore(), SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update artist commission settings: $e');
    }
  }

  /// Alias for getArtistCommissionSettings for backward compatibility
  Future<ArtistCommissionSettings?> getArtistSettings(String artistId) async {
    return getArtistCommissionSettings(artistId);
  }

  /// Alias for updateArtistCommissionSettings for backward compatibility
  Future<void> updateArtistSettings(ArtistCommissionSettings settings) async {
    return updateArtistCommissionSettings(settings);
  }

  /// Calculate commission price based on specs and artist settings
  Future<double> calculateCommissionPrice({
    required String artistId,
    required CommissionType type,
    required CommissionSpecs specs,
  }) async {
    try {
      final settings = await getArtistCommissionSettings(artistId);
      if (settings == null) {
        throw Exception('Artist commission settings not found');
      }

      double basePrice = settings.basePrice;

      // Add type-specific pricing
      if (settings.typePricing.containsKey(type)) {
        basePrice += settings.typePricing[type]!;
      }

      // Add size-specific pricing
      if (settings.sizePricing.containsKey(specs.size)) {
        basePrice += settings.sizePricing[specs.size]!;
      }

      // Add commercial use fee (typically 50% more)
      if (specs.commercialUse) {
        basePrice *= 1.5;
      }

      // Add revision fee for extra revisions
      if (specs.revisions > 1) {
        basePrice +=
            (specs.revisions - 1) * (basePrice * 0.1); // 10% per extra revision
      }

      return basePrice;
    } catch (e) {
      throw Exception('Failed to calculate commission price: $e');
    }
  }

  /// Get available artists for commissions
  Future<List<ArtistCommissionSettings>> getAvailableArtists({
    CommissionType? type,
    double? maxPrice,
  }) async {
    try {
      Query query = _firestore
          .collection('artist_commission_settings')
          .where('acceptingCommissions', isEqualTo: true);

      if (type != null) {
        query = query.where('availableTypes', arrayContains: type.name);
      }

      final snapshot = await query.get();

      List<ArtistCommissionSettings> artists = snapshot.docs
          .map((doc) => ArtistCommissionSettings.fromFirestore(doc))
          .toList();

      // Filter by max price if specified
      if (maxPrice != null) {
        artists = artists
            .where((artist) => artist.basePrice <= maxPrice)
            .toList();
      }

      return artists;
    } catch (e) {
      throw Exception('Failed to get available artists: $e');
    }
  }

  /// Stream commission updates
  Stream<DirectCommissionModel> streamCommission(String commissionId) {
    return _firestore
        .collection('direct_commissions')
        .doc(commissionId)
        .snapshots()
        .map((doc) => DirectCommissionModel.fromFirestore(doc));
  }

  /// Stream user's commissions
  Stream<List<DirectCommissionModel>> streamUserCommissions(String userId) {
    return _firestore
        .collection('direct_commissions')
        .where('clientId', isEqualTo: userId)
        .snapshots()
        .asyncMap((clientSnapshot) async {
          final artistSnapshot = await _firestore
              .collection('direct_commissions')
              .where('artistId', isEqualTo: userId)
              .get();

          final allDocs = [...clientSnapshot.docs, ...artistSnapshot.docs];
          final uniqueDocs = <String, DocumentSnapshot>{};

          for (final doc in allDocs) {
            uniqueDocs[doc.id] = doc;
          }

          return uniqueDocs.values
              .map((doc) => DirectCommissionModel.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
        });
  }

  /// Request revisions for a commission
  Future<void> requestRevision({
    required String commissionId,
    required String revisionDetails,
    required List<String> revisionItems,
    DateTime? deadline,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.revision.name,
            'metadata.revisionRequestedAt': Timestamp.now(),
            'metadata.revisionRequestedBy': user.uid,
            'metadata.revisionDetails': revisionDetails,
            'metadata.revisionItems': revisionItems,
            'metadata.revisionDeadline': deadline != null
                ? Timestamp.fromDate(deadline)
                : null,
          });

      await addMessage(commissionId, 'Revision requested: $revisionDetails');
    } catch (e) {
      throw Exception('Failed to request revision: $e');
    }
  }

  /// Submit revision work (artist response to revision request)
  Future<void> submitRevision({
    required String commissionId,
    required String revisionNotes,
    List<String>? fileUrls,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.completed.name,
            'metadata.revisionSubmittedAt': Timestamp.now(),
            'metadata.revisionSubmittedBy': user.uid,
            'metadata.revisionNotes': revisionNotes,
            'metadata.revisionFiles': fileUrls ?? [],
          });

      await addMessage(commissionId, 'Revision submitted: $revisionNotes');
    } catch (e) {
      throw Exception('Failed to submit revision: $e');
    }
  }

  /// Approve revision work
  Future<void> approveRevision(String commissionId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      await _firestore
          .collection('direct_commissions')
          .doc(commissionId)
          .update({
            'status': CommissionStatus.delivered.name,
            'metadata.revisionApprovedAt': Timestamp.now(),
            'metadata.revisionApprovedBy': user.uid,
          });

      await addMessage(
        commissionId,
        'Revision approved. Commission delivered successfully!',
      );
    } catch (e) {
      throw Exception('Failed to approve revision: $e');
    }
  }

  /// Get commission analytics for a user
  Future<CommissionAnalytics> getCommissionAnalytics(String userId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      // Get all commissions for the user
      final commissions = await getCommissionsByUser(userId);

      // Calculate analytics
      final totalCommissions = commissions.length;
      final completedCommissions = commissions
          .where((c) => c.status == CommissionStatus.delivered)
          .length;
      final activeCommissions = commissions
          .where(
            (c) =>
                c.status == CommissionStatus.inProgress ||
                c.status == CommissionStatus.accepted ||
                c.status == CommissionStatus.revision,
          )
          .length;
      final cancelledCommissions = commissions
          .where((c) => c.status == CommissionStatus.cancelled)
          .length;

      final totalRevenue = commissions
          .where(
            (c) =>
                c.artistId == userId && c.status == CommissionStatus.delivered,
          )
          .fold<double>(0.0, (sum, c) => sum + c.totalPrice);

      final totalSpent = commissions
          .where(
            (c) =>
                c.clientId == userId && c.status == CommissionStatus.delivered,
          )
          .fold<double>(0.0, (sum, c) => sum + c.totalPrice);

      final averageCommissionValue = totalCommissions > 0
          ? commissions.fold<double>(0.0, (sum, c) => sum + c.totalPrice) /
                totalCommissions
          : 0.0;

      final revisionRate = totalCommissions > 0
          ? commissions
                    .where((c) => c.status == CommissionStatus.revision)
                    .length /
                totalCommissions
          : 0.0;

      // Calculate monthly trends (last 6 months)
      final monthlyTrends = await _calculateMonthlyTrends(userId);

      return CommissionAnalytics(
        userId: userId,
        totalCommissions: totalCommissions,
        completedCommissions: completedCommissions,
        activeCommissions: activeCommissions,
        cancelledCommissions: cancelledCommissions,
        totalRevenue: totalRevenue,
        totalSpent: totalSpent,
        averageCommissionValue: averageCommissionValue,
        revisionRate: revisionRate,
        monthlyTrends: monthlyTrends,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Failed to get commission analytics: $e');
    }
  }

  /// Calculate monthly commission trends
  Future<List<MonthlyCommissionData>> _calculateMonthlyTrends(
    String userId,
  ) async {
    try {
      final now = DateTime.now();
      final trends = <MonthlyCommissionData>[];

      for (int i = 5; i >= 0; i--) {
        final monthStart = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(now.year, now.month - i + 1, 1);

        final monthCommissions = await _firestore
            .collection('direct_commissions')
            .where('clientId', isEqualTo: userId)
            .where(
              'requestedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
            )
            .where('requestedAt', isLessThan: Timestamp.fromDate(monthEnd))
            .get();

        final monthRevenue = monthCommissions.docs.fold<double>(0.0, (
          sum,
          doc,
        ) {
          final data = doc.data();
          final price = (data['totalPrice'] as num?)?.toDouble() ?? 0.0;
          return sum + price;
        });

        trends.add(
          MonthlyCommissionData(
            month: monthStart,
            commissionCount: monthCommissions.docs.length,
            revenue: monthRevenue,
          ),
        );
      }

      return trends;
    } catch (e) {
      AppLogger.error('Error calculating monthly trends: $e');
      return [];
    }
  }
}
