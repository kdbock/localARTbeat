import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_artist/artbeat_artist.dart';

/// Service for managing gallery invitations to artists
class GalleryInvitationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final NotificationService _notificationService = NotificationService();
  final ArtistProfileService _artistProfileService = ArtistProfileService();
  final Logger _logger = Logger();

  // Collection references
  final CollectionReference _invitationsCollection = FirebaseFirestore.instance
      .collection('galleryInvitations');

  /// Get current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Send invitation from gallery to artist
  Future<String> sendInvitation({
    required String artistProfileId,
    required String message,
    Map<String, dynamic>? terms,
    int validityDays = 14, // Default: invitation valid for 14 days
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get gallery profile (sender)
      final galleryProfile = await _artistProfileService
          .getArtistProfileByUserId(userId);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Verify this is a gallery account
      if (galleryProfile.userType.name != UserType.gallery.name) {
        throw Exception('Only gallery accounts can send invitations');
      }

      // Get artist profile (recipient)
      final artistProfile = await _artistProfileService.getArtistProfileById(
        artistProfileId,
      );
      if (artistProfile == null) {
        throw Exception('Artist profile not found');
      }

      // Create expiration date
      final expiresAt = DateTime.now().add(Duration(days: validityDays));

      // Create invitation
      final invitationData = {
        'galleryId': galleryProfile.id,
        'artistId': artistProfileId,
        'galleryName': galleryProfile.displayName,
        'artistName': artistProfile.displayName,
        'message': message,
        'status': InvitationStatus.pending.name,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(expiresAt),
        'galleryImageUrl': galleryProfile.profileImageUrl,
        'artistImageUrl': artistProfile.profileImageUrl,
        'terms': terms,
      };

      // Add to Firestore
      final invitationRef = await _invitationsCollection.add(invitationData);

      // Send notification to artist
      await _notificationService.sendNotification(
        userId: artistProfile.userId,
        title: 'Gallery Invitation',
        message:
            '${galleryProfile.displayName} has invited you to join their gallery',
        type: NotificationType.galleryInvitation,
        data: {
          'galleryId': galleryProfile.id,
          'invitationId': invitationRef.id,
        },
      );

      return invitationRef.id;
    } catch (e) {
      throw Exception('Error sending invitation: $e');
    }
  }

  /// Send multiple invitations at once (bulk invite)
  Future<List<String>> sendBulkInvitations({
    required List<String> artistProfileIds,
    required String message,
    Map<String, dynamic>? terms,
    int validityDays = 14,
  }) async {
    final List<String> sentInvitationIds = [];

    for (final artistId in artistProfileIds) {
      try {
        final invitationId = await sendInvitation(
          artistProfileId: artistId,
          message: message,
          terms: terms,
          validityDays: validityDays,
        );
        sentInvitationIds.add(invitationId);
      } catch (e) {
        _logger.e('Error sending invitation to artist $artistId: $e');
        // Continue with other invitations even if this one failed
      }
    }

    return sentInvitationIds;
  }

  /// Respond to an invitation (accept or decline)
  Future<void> respondToInvitation({
    required String invitationId,
    required bool accept,
  }) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get invitation
      final invitationDoc = await _invitationsCollection
          .doc(invitationId)
          .get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitationData = invitationDoc.data() as Map<String, dynamic>;

      // Verify this artist is the recipient
      final artistProfile = await _artistProfileService
          .getArtistProfileByUserId(userId);
      if (artistProfile == null ||
          artistProfile.id != invitationData['artistId']) {
        throw Exception('You are not authorized to respond to this invitation');
      }

      // Update invitation status
      final newStatus = accept
          ? InvitationStatus.accepted
          : InvitationStatus.declined;
      await _invitationsCollection.doc(invitationId).update({
        'status': newStatus.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // If accepted, update gallery's artist list
      if (accept) {
        final galleryId = invitationData['galleryId'] as String;
        final galleryProfileDoc = await _firestore
            .collection('artistProfiles')
            .doc(galleryId)
            .get();

        if (galleryProfileDoc.exists) {
          final galleryArtists = List<String>.from(
            (galleryProfileDoc.get('galleryArtists') as List<dynamic>?) ?? [],
          );

          if (!galleryArtists.contains(artistProfile.id)) {
            await _firestore.collection('artistProfiles').doc(galleryId).update(
              {
                'galleryArtists': FieldValue.arrayUnion([artistProfile.id]),
                'updatedAt': FieldValue.serverTimestamp(),
              },
            );
          }
        }
      }

      // Send notification to gallery
      final notificationTitle = accept
          ? 'Invitation Accepted'
          : 'Invitation Declined';
      final notificationBody = accept
          ? '${artistProfile.displayName} has accepted your gallery invitation'
          : '${artistProfile.displayName} has declined your gallery invitation';

      await _notificationService.sendNotification(
        userId: invitationData['galleryUserId'] as String,
        title: notificationTitle,
        message: notificationBody,
        type: NotificationType.invitationResponse,
        data: {
          'artistId': artistProfile.id,
          'invitationId': invitationId,
          'accepted': accept,
        },
      );
    } catch (e) {
      throw Exception('Error responding to invitation: $e');
    }
  }

  /// Get all invitations sent by the current gallery
  Future<List<GalleryInvitationModel>> getSentInvitations() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get gallery profile
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final galleryProfile = await _artistProfileService
          .getArtistProfileByUserId(userId);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Query invitations
      final snapshot = await _invitationsCollection
          .where('galleryId', isEqualTo: galleryProfile.id)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GalleryInvitationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting sent invitations: $e');
    }
  }

  /// Get all invitations received by the current artist
  Future<List<GalleryInvitationModel>> getReceivedInvitations() async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get artist profile
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final artistProfile = await _artistProfileService
          .getArtistProfileByUserId(userId);
      if (artistProfile == null) {
        throw Exception('Artist profile not found');
      }

      // Query invitations
      final snapshot = await _invitationsCollection
          .where('artistId', isEqualTo: artistProfile.id)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => GalleryInvitationModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Error getting received invitations: $e');
    }
  }

  /// Cancel an invitation (only gallery can do this)
  Future<void> cancelInvitation(String invitationId) async {
    final userId = getCurrentUserId();
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Get invitation
      final invitationDoc = await _invitationsCollection
          .doc(invitationId)
          .get();
      if (!invitationDoc.exists) {
        throw Exception('Invitation not found');
      }

      final invitationData = invitationDoc.data() as Map<String, dynamic>;

      // Get gallery profile
      final userId = getCurrentUserId();
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final galleryProfile = await _artistProfileService
          .getArtistProfileByUserId(userId);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Verify this gallery is the sender
      if (galleryProfile.id != invitationData['galleryId']) {
        throw Exception('You are not authorized to cancel this invitation');
      }

      // Update invitation status
      await _invitationsCollection.doc(invitationId).update({
        'status': InvitationStatus.expired.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Optionally notify the artist
      await _notificationService.sendNotification(
        userId: invitationData['artistUserId'] as String,
        title: 'Invitation Cancelled',
        message: '${galleryProfile.displayName} has cancelled their invitation',
        type: NotificationType.invitationCancelled,
        data: {'galleryId': galleryProfile.id, 'invitationId': invitationId},
      );
    } catch (e) {
      throw Exception('Error cancelling invitation: $e');
    }
  }
}

enum InvitationStatus { pending, accepted, declined, expired }
