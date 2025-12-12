import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artwork_model.dart';
import '../services/artwork_service.dart';

/// Admin screen for moderating artwork content
class ArtworkModerationScreen extends StatefulWidget {
  const ArtworkModerationScreen({super.key});

  @override
  State<ArtworkModerationScreen> createState() =>
      _ArtworkModerationScreenState();
}

class _ArtworkModerationScreenState extends State<ArtworkModerationScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _selectedFilter = 'pending';
  bool _isLoading = false;
  List<ArtworkModel> _artworks = [];
  final Map<String, bool> _selectedArtworks = {};

  @override
  void initState() {
    super.initState();
    _loadArtworks();
  }

  Future<void> _loadArtworks() async {
    setState(() => _isLoading = true);

    try {
      Query query = _firestore.collection('artworks');

      // Apply filter
      switch (_selectedFilter) {
        case 'pending':
          query = query.where('moderationStatus', isEqualTo: 'pending');
          break;
        case 'flagged':
          query = query.where('flagged', isEqualTo: true);
          break;
        case 'approved':
          query = query.where('moderationStatus', isEqualTo: 'approved');
          break;
        case 'rejected':
          query = query.where('moderationStatus', isEqualTo: 'rejected');
          break;
        case 'all':
          // No filter
          break;
      }

      query = query.orderBy('createdAt', descending: true).limit(50);

      final snapshot = await query.get();
      final artworks =
          snapshot.docs.map((doc) => ArtworkModel.fromFirestore(doc)).toList();

      setState(() {
        _artworks = artworks;
        _selectedArtworks.clear();
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('moderation_error_loading'
                .tr(namedArgs: {'error': e.toString()}))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moderateArtwork(
      ArtworkModel artwork, ArtworkModerationStatus status,
      {String? notes}) async {
    try {
      await _artworkService.updateArtworkModeration(
        artworkId: artwork.id,
        status: status,
        notes: notes,
      );

      setState(() {
        _artworks.removeWhere((a) => a.id == artwork.id);
        _selectedArtworks.remove(artwork.id);
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('moderation_success_status'
                .tr(namedArgs: {'status': status.displayName.toLowerCase()}))),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('moderation_error_moderating'
                .tr(namedArgs: {'error': e.toString()}))),
      );
    }
  }

  Future<void> _bulkModerate(ArtworkModerationStatus status,
      {String? notes}) async {
    final selectedIds = _selectedArtworks.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedIds.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      for (final artworkId in selectedIds) {
        await _artworkService.updateArtworkModeration(
          artworkId: artworkId,
          status: status,
          notes: notes,
        );
      }

      setState(() {
        _artworks.removeWhere((artwork) => selectedIds.contains(artwork.id));
        _selectedArtworks.clear();
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('moderation_success_bulk'.tr(namedArgs: {
          'count': selectedIds.length.toString(),
          'status': status.displayName.toLowerCase()
        }))),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('moderation_error_bulk'
                .tr(namedArgs: {'error': e.toString()}))),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showModerationDialog(ArtworkModel artwork) {
    final notesController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            'moderation_dialog_title'.tr(namedArgs: {'title': artwork.title})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('moderation_dialog_choose_action'.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'moderation_dialog_notes_label'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('moderation_dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moderateArtwork(artwork, ArtworkModerationStatus.approved,
                  notes: notesController.text);
            },
            child: Text('moderation_dialog_approve'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moderateArtwork(artwork, ArtworkModerationStatus.rejected,
                  notes: notesController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('moderation_dialog_reject'.tr()),
          ),
        ],
      ),
    );
  }

  void _showBulkModerationDialog() {
    final notesController = TextEditingController();
    final selectedCount =
        _selectedArtworks.values.where((selected) => selected).length;

    if (selectedCount == 0) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('moderation_bulk_dialog_title'
            .tr(namedArgs: {'count': selectedCount.toString()})),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('moderation_bulk_dialog_message'.tr()),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: InputDecoration(
                labelText: 'moderation_dialog_notes_label'.tr(),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('moderation_dialog_cancel'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bulkModerate(ArtworkModerationStatus.approved,
                  notes: notesController.text);
            },
            child: Text('moderation_bulk_dialog_approve_all'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bulkModerate(ArtworkModerationStatus.rejected,
                  notes: notesController.text);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('moderation_bulk_dialog_reject_all'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        _selectedArtworks.values.where((selected) => selected).length;

    return Scaffold(
      appBar: AppBar(
        title: Text('moderation_artwork_title'.tr()),
        actions: [
          if (selectedCount > 0) ...[
            IconButton(
              icon: const Icon(Icons.check_circle),
              onPressed: _showBulkModerationDialog,
              tooltip: 'moderation_bulk_approve_tooltip'.tr(),
            ),
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () => _bulkModerate(ArtworkModerationStatus.rejected),
              tooltip: 'moderation_bulk_reject_tooltip'.tr(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Chip(
                label: Text('moderation_selected_count'
                    .tr(namedArgs: {'count': selectedCount.toString()})),
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Filter tabs
          Container(
            color: Theme.of(context).cardColor,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  FilterChip(
                    label: Text('moderation_filter_pending'.tr()),
                    selected: _selectedFilter == 'pending',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'pending');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('moderation_filter_flagged'.tr()),
                    selected: _selectedFilter == 'flagged',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'flagged');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('moderation_filter_approved'.tr()),
                    selected: _selectedFilter == 'approved',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'approved');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('moderation_filter_rejected'.tr()),
                    selected: _selectedFilter == 'rejected',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'rejected');
                        _loadArtworks();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text('moderation_filter_all'.tr()),
                    selected: _selectedFilter == 'all',
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedFilter = 'all');
                        _loadArtworks();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _artworks.isEmpty
                    ? Center(
                        child: Text('moderation_empty_state'.tr()),
                      )
                    : ListView.builder(
                        itemCount: _artworks.length,
                        itemBuilder: (context, index) {
                          final artwork = _artworks[index];
                          final isSelected =
                              _selectedArtworks[artwork.id] ?? false;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Column(
                              children: [
                                // Selection checkbox
                                CheckboxListTile(
                                  value: isSelected,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedArtworks[artwork.id] =
                                          value ?? false;
                                    });
                                  },
                                  title: Text(
                                    artwork.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('moderation_by_artist'.tr(
                                      namedArgs: {
                                        'artist': artwork.artistProfileId
                                      })),
                                ),

                                // Artwork image
                                Container(
                                  height: 200,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    image: DecorationImage(
                                      image: NetworkImage(artwork.imageUrl),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                // Artwork details
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        artwork.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Chip(
                                            label: Text(artwork.medium),
                                            backgroundColor: Colors.blue
                                                .withValues(alpha: 0.1),
                                          ),
                                          const SizedBox(width: 8),
                                          Chip(
                                            label: Text(artwork
                                                .moderationStatus.displayName),
                                            backgroundColor: _getStatusColor(
                                                artwork.moderationStatus),
                                          ),
                                        ],
                                      ),
                                      if (artwork.flagged) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            const Icon(Icons.flag,
                                                color: Colors.orange, size: 16),
                                            const SizedBox(width: 4),
                                            Text('moderation_flagged_badge'
                                                .tr()),
                                          ],
                                        ),
                                      ],
                                      if (artwork.moderationNotes != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          '${'moderation_notes_label'.tr()}: ${artwork.moderationNotes}',
                                          style: const TextStyle(
                                              fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),

                                OverflowBar(
                                  alignment: MainAxisAlignment.end,
                                  spacing: 8,
                                  children: [
                                    TextButton(
                                      onPressed: () =>
                                          _showModerationDialog(artwork),
                                      child:
                                          Text('moderation_button_review'.tr()),
                                    ),
                                    TextButton(
                                      onPressed: () => _moderateArtwork(artwork,
                                          ArtworkModerationStatus.approved),
                                      child: Text(
                                          'moderation_button_approve'.tr()),
                                    ),
                                    TextButton(
                                      onPressed: () => _moderateArtwork(artwork,
                                          ArtworkModerationStatus.rejected),
                                      style: TextButton.styleFrom(
                                          foregroundColor: Colors.red),
                                      child:
                                          Text('moderation_button_reject'.tr()),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: selectedCount > 0
          ? FloatingActionButton(
              onPressed: _showBulkModerationDialog,
              tooltip: 'moderation_bulk_actions_tooltip'.tr(),
              child: const Icon(Icons.batch_prediction),
            )
          : null,
    );
  }

  Color _getStatusColor(ArtworkModerationStatus status) {
    switch (status) {
      case ArtworkModerationStatus.pending:
        return Colors.orange.withValues(alpha: 0.1);
      case ArtworkModerationStatus.approved:
        return Colors.green.withValues(alpha: 0.1);
      case ArtworkModerationStatus.rejected:
        return Colors.red.withValues(alpha: 0.1);
      case ArtworkModerationStatus.flagged:
        return Colors.orange.withValues(alpha: 0.1);
      case ArtworkModerationStatus.underReview:
        return Colors.blue.withValues(alpha: 0.1);
    }
  }
}
