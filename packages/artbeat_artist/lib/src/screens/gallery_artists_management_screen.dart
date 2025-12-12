import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/artist_profile_service.dart';

/// Model for gallery invitations
class GalleryInvitation {
  final String id;
  final String galleryId;
  final String artistId;
  final String artistName;
  final String artistEmail;
  final String? artistProfileImage;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final DateTime? respondedAt;

  GalleryInvitation({
    required this.id,
    required this.galleryId,
    required this.artistId,
    required this.artistName,
    required this.artistEmail,
    this.artistProfileImage,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory GalleryInvitation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryInvitation(
      id: doc.id,
      galleryId: data['galleryId'] as String,
      artistId: data['artistId'] as String,
      artistName: data['artistName'] as String,
      artistEmail: data['artistEmail'] as String,
      artistProfileImage: data['artistProfileImage'] as String?,
      status: data['status'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      respondedAt: data['respondedAt'] != null
          ? (data['respondedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'galleryId': galleryId,
      'artistId': artistId,
      'artistName': artistName,
      'artistEmail': artistEmail,
      'artistProfileImage': artistProfileImage,
      'status': status,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }
}

class GalleryArtistsManagementScreen extends StatefulWidget {
  const GalleryArtistsManagementScreen({super.key});

  @override
  State<GalleryArtistsManagementScreen> createState() =>
      _GalleryArtistsManagementScreenState();
}

class _GalleryArtistsManagementScreenState
    extends State<GalleryArtistsManagementScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ArtistProfileService _artistProfileService = ArtistProfileService();

  List<core.ArtistProfileModel> _galleryArtists = [];
  List<GalleryInvitation> _pendingInvitations = [];
  Map<String, core.ArtistProfileModel> _artistProfiles = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadGalleryArtists();
    _loadPendingInvitations();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGalleryArtists() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load gallery artists from Firestore
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current gallery profile
      final galleryProfile =
          await _artistProfileService.getArtistProfileByUserId(currentUser.uid);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Get gallery-artist relationships
      final relationshipQuery = await _firestore
          .collection('galleryArtists')
          .where('galleryId', isEqualTo: galleryProfile.id)
          .where('status', isEqualTo: 'active')
          .get();

      final artistIds = relationshipQuery.docs
          .map((doc) => doc.data()['artistId'] as String)
          .toList();

      // Load artist profiles
      final Map<String, core.ArtistProfileModel> artistProfiles = {};
      for (final artistId in artistIds) {
        final artistDoc =
            await _firestore.collection('artistProfiles').doc(artistId).get();
        if (artistDoc.exists) {
          final artist = core.ArtistProfileModel.fromFirestore(artistDoc);
          artistProfiles[artistId] = artist;
        }
      }

      setState(() {
        _artistProfiles = artistProfiles;
        _galleryArtists = artistProfiles.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load gallery artists. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPendingInvitations() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return;

      // Get current gallery profile
      final galleryProfile =
          await _artistProfileService.getArtistProfileByUserId(currentUser.uid);
      if (galleryProfile == null) return;

      // Load pending invitations from Firestore
      final invitationQuery = await _firestore
          .collection('galleryInvitations')
          .where('galleryId', isEqualTo: galleryProfile.id)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      final invitations = invitationQuery.docs
          .map((doc) => GalleryInvitation.fromFirestore(doc))
          .toList();

      setState(() {
        _pendingInvitations = invitations;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _sendInvitation(core.ArtistProfileModel artist) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current gallery profile
      final galleryProfile =
          await _artistProfileService.getArtistProfileByUserId(currentUser.uid);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Get artist user information for email
      final artistUserDoc =
          await _firestore.collection('users').doc(artist.userId).get();

      final artistEmail = artistUserDoc.data()?['email'] as String? ?? '';

      // Check if invitation already exists
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

      // Create new invitation
      final invitation = GalleryInvitation(
        id: '',
        galleryId: galleryProfile.id,
        artistId: artist.id,
        artistName: artist.displayName,
        artistEmail: artistEmail,
        artistProfileImage: artist.profileImageUrl,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore.collection('galleryInvitations').add(invitation.toMap());

      // Send notification to artist
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

      // Refresh invitations
      await _loadPendingInvitations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(
                'artist_gallery_artists_management_success_invitation_sent_successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'artist_gallery_artists_management_error_failed_to_send'))),
        );
      }
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    try {
      await _firestore
          .collection('galleryInvitations')
          .doc(invitationId)
          .update({
        'status': 'cancelled',
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Refresh invitations
      await _loadPendingInvitations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(
                'artist_gallery_artists_management_text_invitation_cancelled')),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'artist_gallery_artists_management_error_failed_to_cancel'))),
        );
      }
    }
  }

  Future<void> _removeArtistFromGallery(String artistId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current gallery profile
      final galleryProfile =
          await _artistProfileService.getArtistProfileByUserId(currentUser.uid);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Update gallery-artist relationship to inactive
      final relationshipQuery = await _firestore
          .collection('galleryArtists')
          .where('galleryId', isEqualTo: galleryProfile.id)
          .where('artistId', isEqualTo: artistId)
          .limit(1)
          .get();

      if (relationshipQuery.docs.isNotEmpty) {
        await _firestore
            .collection('galleryArtists')
            .doc(relationshipQuery.docs.first.id)
            .update({
          'status': 'inactive',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      setState(() {
        _galleryArtists.removeWhere((artist) => artist.id == artistId);
        _artistProfiles.remove(artistId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(
                'artist_gallery_artists_management_success_artist_removed_from')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'artist_gallery_artists_management_error_failed_to_remove'))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
              tr('artist_gallery_artists_management_text_gallery_artists')),
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Current Artists'),
              Tab(text: 'Pending Invitations'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildArtistsList(),
            _buildPendingInvitations(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await showDialog<core.ArtistProfileModel>(
              context: context,
              builder: (context) => _ArtistSearchDialog(
                currentArtists: _galleryArtists.map((a) => a.id).toList(),
                onArtistSelected: (artist) => Navigator.pop(context, artist),
              ),
            );

            if (result != null) {
              await _sendInvitation(result);
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildArtistsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    return ListView.builder(
      itemCount: _galleryArtists.length,
      itemBuilder: (context, index) {
        final artist = _galleryArtists[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: artist.profileImageUrl != null &&
                    artist.profileImageUrl!.isNotEmpty &&
                    Uri.tryParse(artist.profileImageUrl!)?.hasScheme == true
                ? NetworkImage(artist.profileImageUrl!)
                : null,
            child: artist.profileImageUrl == null ||
                    artist.profileImageUrl!.isEmpty ||
                    Uri.tryParse(artist.profileImageUrl!)?.hasScheme != true
                ? const Icon(Icons.person)
                : null,
          ),
          title: Text(artist.displayName),
          subtitle: Text(artist.bio ?? ''),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => _removeArtistFromGallery(artist.id),
          ),
        );
      },
    );
  }

  Widget _buildPendingInvitations() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pendingInvitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.mail_outline,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              tr('art_walk_no_pending_invitations'),
              style: const TextStyle(
                fontSize: 18,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              tr('art_walk_use_the___button_to_invite_artists_to_your_gallery'),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingInvitations.length,
      itemBuilder: (context, index) {
        final invitation = _pendingInvitations[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: invitation.artistProfileImage != null &&
                      invitation.artistProfileImage!.isNotEmpty &&
                      Uri.tryParse(invitation.artistProfileImage!)?.hasScheme ==
                          true
                  ? NetworkImage(invitation.artistProfileImage!)
                  : null,
              child: invitation.artistProfileImage == null ||
                      invitation.artistProfileImage!.isEmpty ||
                      Uri.tryParse(invitation.artistProfileImage!)?.hasScheme !=
                          true
                  ? const Icon(Icons.person)
                  : null,
            ),
            title: Text(
              invitation.artistName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(invitation.artistEmail),
                const SizedBox(height: 4),
                Text(
                  'Invited ${_formatDate(invitation.createdAt)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  onPressed: () => _showCancelInvitationDialog(invitation),
                  tooltip: 'Cancel invitation',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.blue),
                  onPressed: () => _resendInvitation(invitation),
                  tooltip: 'Resend invitation',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  void _showCancelInvitationDialog(GalleryInvitation invitation) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            tr('artist_gallery_artists_management_text_cancel_invitation')),
        content: Text(
          'Are you sure you want to cancel the invitation to ${invitation.artistName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(tr('admin_admin_payment_text_cancel')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelInvitation(invitation.id);
            },
            child: Text(tr('admin_migration_text_confirm')),
          ),
        ],
      ),
    );
  }

  Future<void> _resendInvitation(GalleryInvitation invitation) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get current gallery profile
      final galleryProfile =
          await _artistProfileService.getArtistProfileByUserId(currentUser.uid);
      if (galleryProfile == null) {
        throw Exception('Gallery profile not found');
      }

      // Send notification to artist again
      await _firestore.collection('notifications').add({
        'userId': invitation.artistId,
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(
                'artist_gallery_artists_management_text_invitation_reminder_sent')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(tr(
                  'artist_gallery_artists_management_error_failed_to_resend'))),
        );
      }
    }
  }
}

/// Dialog for searching and selecting artists to add to gallery
class _ArtistSearchDialog extends StatefulWidget {
  final List<String> currentArtists;
  final void Function(core.ArtistProfileModel) onArtistSelected;

  const _ArtistSearchDialog({
    required this.currentArtists,
    required this.onArtistSelected,
  });

  @override
  State<_ArtistSearchDialog> createState() => _ArtistSearchDialogState();
}

class _ArtistSearchDialogState extends State<_ArtistSearchDialog> {
  final TextEditingController _searchController = TextEditingController();

  List<core.ArtistProfileModel> _searchResults = [];
  bool _isLoading = false;

  @override
  dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Search for artists
  Future<void> _searchArtists(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Use ArtistProfileService to search for artists
      final artistProfileService = ArtistProfileService();
      final results =
          await artistProfileService.searchArtists(query, limit: 20);

      setState(() {
        // Filter out artists already in the gallery
        _searchResults = results
            .where((artist) => !widget.currentArtists.contains(artist.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });

      // Show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(tr(
                'artist_gallery_artists_management_error_error_searching_artists')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        constraints: const BoxConstraints(maxHeight: 500),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tr('art_walk_find_artists'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name or location',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: _searchArtists,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _searchResults.isEmpty
                      ? Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Type to search for artists'
                                : 'No artists found',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final artist = _searchResults[index];
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              leading: CircleAvatar(
                                backgroundImage: artist.profileImageUrl !=
                                            null &&
                                        artist.profileImageUrl!.isNotEmpty &&
                                        Uri.tryParse(artist.profileImageUrl!)
                                                ?.hasScheme ==
                                            true
                                    ? NetworkImage(artist.profileImageUrl!)
                                    : null,
                                child: artist.profileImageUrl == null ||
                                        artist.profileImageUrl!.isEmpty ||
                                        Uri.tryParse(artist.profileImageUrl!)
                                                ?.hasScheme !=
                                            true
                                    ? const Icon(Icons.person)
                                    : null,
                              ),
                              title: Text(artist.displayName),
                              subtitle: Text(
                                artist.location ?? 'No location',
                              ),
                              onTap: () {
                                widget.onArtistSelected(artist);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(tr('admin_admin_payment_text_cancel')),
            ),
          ],
        ),
      ),
    );
  }
}
