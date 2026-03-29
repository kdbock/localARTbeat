import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/gallery_invitation_model.dart';
import 'artist_profile_service.dart';

class ArtistGalleryDiscoveryReadService {
  ArtistGalleryDiscoveryReadService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    ArtistProfileService? artistProfileService,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _artistProfileService = artistProfileService ?? ArtistProfileService();

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final ArtistProfileService _artistProfileService;

  Future<List<core.ArtistProfileModel>> getNearbyPublicArtists({
    required String zipCode,
    int limit = 50,
  }) async {
    final snapshot = await _firestore
        .collection('artistProfiles')
        .where('isPortfolioPublic', isEqualTo: true)
        .limit(limit)
        .get();

    final artists = snapshot.docs
        .map(core.ArtistProfileModel.fromFirestore)
        .toList();

    final zipCoords = await core.LocationUtils.getCoordinatesFromZipCode(
      zipCode,
    );
    final viewerLocation =
        zipCoords ?? await core.GeoWeightingUtils.resolveViewerLocation(null);

    return core.GeoWeightingUtils.sortByDistance<core.ArtistProfileModel>(
      items: artists,
      idOf: (artist) => artist.userId,
      locationOf: (artist) => artist.location,
      coordsOf: (artist) {
        final lat = artist.locationLat;
        final lng = artist.locationLng;
        if (lat == null || lng == null) return null;
        return core.SimpleLatLng(lat, lng);
      },
      viewerLocation: viewerLocation,
      tieBreaker: (a, b) {
        final scoreCompare = b.boostScore.compareTo(a.boostScore);
        if (scoreCompare != 0) return scoreCompare;
        final aBoost = a.lastBoostAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bBoost = b.lastBoostAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final boostTimeCompare = bBoost.compareTo(aBoost);
        if (boostTimeCompare != 0) return boostTimeCompare;
        return a.displayName.compareTo(b.displayName);
      },
    );
  }

  Stream<List<core.ArtistProfileModel>> watchLocalGalleries({
    required String zipCode,
    int limit = 6,
  }) {
    return _firestore
        .collection('artistProfiles')
        .where('userType', isEqualTo: 'business')
        .where('location', isEqualTo: zipCode)
        .limit(limit)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map(core.ArtistProfileModel.fromFirestore).toList(),
        );
  }

  Future<List<core.ArtistProfileModel>> loadCurrentGalleryArtists() async {
    final galleryProfile = await _requireCurrentGalleryProfile();
    final relationshipQuery = await _firestore
        .collection('galleryArtists')
        .where('galleryId', isEqualTo: galleryProfile.id)
        .where('status', isEqualTo: 'active')
        .get();

    final artists = <core.ArtistProfileModel>[];
    for (final doc in relationshipQuery.docs) {
      final artistId = doc.data()['artistId'] as String?;
      if (artistId == null || artistId.isEmpty) {
        continue;
      }

      final artistDoc = await _firestore
          .collection('artistProfiles')
          .doc(artistId)
          .get();
      if (!artistDoc.exists) {
        continue;
      }
      artists.add(core.ArtistProfileModel.fromFirestore(artistDoc));
    }

    return artists;
  }

  Future<List<GalleryInvitationModel>> loadPendingInvitations() async {
    final galleryProfile = await _requireCurrentGalleryProfile();
    final invitationQuery = await _firestore
        .collection('galleryInvitations')
        .where('galleryId', isEqualTo: galleryProfile.id)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .get();

    return invitationQuery.docs
        .map(GalleryInvitationModel.fromFirestore)
        .toList();
  }

  Future<void> sendInvitation({required core.ArtistProfileModel artist}) async {
    final galleryProfile = await _requireCurrentGalleryProfile();
    final artistUserDoc = await _firestore
        .collection('users')
        .doc(artist.userId)
        .get();
    final artistEmail = artistUserDoc.data()?['email'] as String? ?? '';

    final existingInvitation = await _firestore
        .collection('galleryInvitations')
        .where('galleryId', isEqualTo: galleryProfile.id)
        .where('artistId', isEqualTo: artist.id)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();

    if (existingInvitation.docs.isNotEmpty) {
      throw Exception('Invitation already sent to this artist');
    }

    await _firestore.collection('galleryInvitations').add({
      'galleryId': galleryProfile.id,
      'artistId': artist.id,
      'artistName': artist.displayName,
      'artistEmail': artistEmail,
      'artistProfileImage': artist.profileImageUrl,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _firestore.collection('notifications').add({
      'userId': artist.userId,
      'title': 'Gallery Invitation',
      'message':
          '${galleryProfile.displayName} has invited you to join their gallery',
      'type': 'galleryInvitation',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'galleryId': galleryProfile.id,
        'galleryName': galleryProfile.displayName,
        'artistId': artist.id,
      },
    });
  }

  Future<void> cancelInvitation(String invitationId) async {
    await _requireCurrentGalleryProfile();
    await _firestore.collection('galleryInvitations').doc(invitationId).update({
      'status': 'cancelled',
      'respondedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeArtistFromGallery(String artistId) async {
    final galleryProfile = await _requireCurrentGalleryProfile();
    final relationshipQuery = await _firestore
        .collection('galleryArtists')
        .where('galleryId', isEqualTo: galleryProfile.id)
        .where('artistId', isEqualTo: artistId)
        .limit(1)
        .get();

    if (relationshipQuery.docs.isEmpty) {
      return;
    }

    await _firestore
        .collection('galleryArtists')
        .doc(relationshipQuery.docs.first.id)
        .update({
          'status': 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> resendInvitation(GalleryInvitationModel invitation) async {
    final galleryProfile = await _requireCurrentGalleryProfile();
    final artistProfile = await _artistProfileService.getArtistProfileById(
      invitation.artistId,
    );
    final recipientUserId = artistProfile?.userId ?? invitation.artistId;

    await _firestore.collection('notifications').add({
      'userId': recipientUserId,
      'title': 'Gallery Invitation Reminder',
      'message':
          '${galleryProfile.displayName} has sent you a reminder about their gallery invitation',
      'type': 'galleryInvitation',
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'galleryId': galleryProfile.id,
        'galleryName': galleryProfile.displayName,
        'artistId': invitation.artistId,
      },
    });
  }

  Future<core.ArtistProfileModel> _requireCurrentGalleryProfile() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('User not authenticated');
    }

    final galleryProfile = await _artistProfileService.getArtistProfileByUserId(
      currentUser.uid,
    );
    if (galleryProfile == null) {
      throw Exception('Gallery profile not found');
    }
    return galleryProfile;
  }
}
