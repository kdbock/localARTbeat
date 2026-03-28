import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/gallery_invitation_model.dart';
import '../services/artist_gallery_discovery_read_service.dart';
import '../services/artist_profile_service.dart';

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

  List<core.ArtistProfileModel> _galleryArtists = [];
  List<GalleryInvitationModel> _pendingInvitations = [];
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
      final artists = await context
          .read<ArtistGalleryDiscoveryReadService>()
          .loadCurrentGalleryArtists();
      final artistProfiles = <String, core.ArtistProfileModel>{
        for (final artist in artists) artist.id: artist,
      };

      setState(() {
        _artistProfiles = artistProfiles;
        _galleryArtists = artists;
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
      final invitations = await context
          .read<ArtistGalleryDiscoveryReadService>()
          .loadPendingInvitations();

      setState(() {
        _pendingInvitations = invitations;
      });
    } catch (e) {
      // Handle error silently for now
    }
  }

  Future<void> _sendInvitation(core.ArtistProfileModel artist) async {
    try {
      await context.read<ArtistGalleryDiscoveryReadService>().sendInvitation(
        artist: artist,
      );

      // Refresh invitations
      await _loadPendingInvitations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'artist_gallery_artists_management_success_invitation_sent_successfully',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_gallery_artists_management_error_failed_to_send'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _cancelInvitation(String invitationId) async {
    try {
      await context.read<ArtistGalleryDiscoveryReadService>().cancelInvitation(
        invitationId,
      );

      // Refresh invitations
      await _loadPendingInvitations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_gallery_artists_management_text_invitation_cancelled'),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_gallery_artists_management_error_failed_to_cancel'),
            ),
          ),
        );
      }
    }
  }

  Future<void> _removeArtistFromGallery(String artistId) async {
    try {
      await context
          .read<ArtistGalleryDiscoveryReadService>()
          .removeArtistFromGallery(artistId);

      setState(() {
        _galleryArtists.removeWhere((artist) => artist.id == artistId);
        _artistProfiles.remove(artistId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'artist_gallery_artists_management_success_artist_removed_from',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_gallery_artists_management_error_failed_to_remove'),
            ),
          ),
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
            tr('artist_gallery_artists_management_text_gallery_artists'),
          ),
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
          children: [_buildArtistsList(), _buildPendingInvitations()],
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
            backgroundImage: core.ImageUrlValidator.safeNetworkImage(
              artist.profileImageUrl,
            ),
            child:
                !core.ImageUrlValidator.isValidImageUrl(artist.profileImageUrl)
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
            const Icon(Icons.mail_outline, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              tr('art_walk_no_pending_invitations'),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              tr('art_walk_use_the___button_to_invite_artists_to_your_gallery'),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
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
              backgroundImage: core.ImageUrlValidator.safeNetworkImage(
                invitation.artistProfileImage,
              ),
              child:
                  !core.ImageUrlValidator.isValidImageUrl(
                    invitation.artistProfileImage,
                  )
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
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
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

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'Just now';
    }
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

  void _showCancelInvitationDialog(GalleryInvitationModel invitation) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          tr('artist_gallery_artists_management_text_cancel_invitation'),
        ),
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

  Future<void> _resendInvitation(GalleryInvitationModel invitation) async {
    try {
      await context.read<ArtistGalleryDiscoveryReadService>().resendInvitation(
        invitation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(
                'artist_gallery_artists_management_text_invitation_reminder_sent',
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr('artist_gallery_artists_management_error_failed_to_resend'),
            ),
          ),
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
      final artistProfileService = context.read<ArtistProfileService>();
      final results = await artistProfileService.searchArtists(
        query,
        limit: 20,
      );

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
            content: Text(
              tr(
                'artist_gallery_artists_management_error_error_searching_artists',
              ),
            ),
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
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            backgroundImage:
                                core.ImageUrlValidator.safeNetworkImage(
                                  artist.profileImageUrl,
                                ),
                            child:
                                !core.ImageUrlValidator.isValidImageUrl(
                                  artist.profileImageUrl,
                                )
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(artist.displayName),
                          subtitle: Text(artist.location ?? 'No location'),
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
