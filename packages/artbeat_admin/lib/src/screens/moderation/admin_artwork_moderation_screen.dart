import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide ArtworkModel, GlassInputDecoration;
import 'package:artbeat_core/artbeat_core.dart'
    show
        GlassCard,
        HudTopBar,
        MainLayout,
        SecureNetworkImage,
        WorldBackground;
import 'package:artbeat_artwork/artbeat_artwork.dart';

/// Admin screen for moderating artwork content
class AdminArtworkModerationScreen extends StatefulWidget {
  const AdminArtworkModerationScreen({super.key});

  @override
  State<AdminArtworkModerationScreen> createState() =>
      _AdminArtworkModerationScreenState();
}

class _AdminArtworkModerationScreenState extends State<AdminArtworkModerationScreen> {
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
      final artworks = snapshot.docs
          .map((doc) => ArtworkModel.fromFirestore(doc))
          .toList();

      setState(() {
        _artworks = artworks;
        _selectedArtworks.clear();
      });
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'moderation_error_loading'.tr(namedArgs: {'error': e.toString()}),
          ),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _moderateArtwork(
    ArtworkModel artwork,
    ArtworkModerationStatus status, {
    String? notes,
  }) async {
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
          content: Text(
            'moderation_success_status'.tr(
              namedArgs: {'status': status.displayName.toLowerCase()},
            ),
          ),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'moderation_error_moderating'.tr(
              namedArgs: {'error': e.toString()},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _bulkModerate(
    ArtworkModerationStatus status, {
    String? notes,
  }) async {
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
          content: Text(
            'moderation_success_bulk'.tr(
              namedArgs: {
                'count': selectedIds.length.toString(),
                'status': status.displayName.toLowerCase(),
              },
            ),
          ),
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'moderation_error_bulk'.tr(namedArgs: {'error': e.toString()}),
          ),
        ),
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
          'moderation_dialog_title'.tr(namedArgs: {'title': artwork.title}),
        ),
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
              _moderateArtwork(
                artwork,
                ArtworkModerationStatus.approved,
                notes: notesController.text,
              );
            },
            child: Text('moderation_dialog_approve'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _moderateArtwork(
                artwork,
                ArtworkModerationStatus.rejected,
                notes: notesController.text,
              );
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
    final selectedCount = _selectedArtworks.values
        .where((selected) => selected)
        .length;

    if (selectedCount == 0) return;

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'moderation_bulk_dialog_title'.tr(
            namedArgs: {'count': selectedCount.toString()},
          ),
        ),
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
              _bulkModerate(
                ArtworkModerationStatus.approved,
                notes: notesController.text,
              );
            },
            child: Text('moderation_bulk_dialog_approve_all'.tr()),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _bulkModerate(
                ArtworkModerationStatus.rejected,
                notes: notesController.text,
              );
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
    final selectedCount = _selectedArtworks.values
        .where((selected) => selected)
        .length;

    return MainLayout(
      currentIndex: 0,
      appBar: HudTopBar(
        title: 'moderation_artwork_title'.tr(),
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).pop(),
        actions: [
          if (selectedCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                radius: 18,
                glassOpacity: 0.08,
                borderOpacity: 0.16,
                child: Text(
                  'moderation_selected_count'.tr(
                    namedArgs: {'count': selectedCount.toString()},
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
        subtitle: '',
      ),
      floatingActionButton: selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _showBulkModerationDialog,
              tooltip: 'moderation_bulk_actions_tooltip'.tr(),
              backgroundColor: const Color(0xFF22D3EE),
              icon: const Icon(Icons.batch_prediction, color: Colors.white),
              label: Text(
                'moderation_bulk_actions'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          : null,
      child: WorldBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF22D3EE),
                            ),
                          ),
                        )
                      : _artworks.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          itemCount: _artworks.length,
                          itemBuilder: (context, index) {
                            final artwork = _artworks[index];
                            final isSelected =
                                _selectedArtworks[artwork.id] ?? false;
                            return _buildArtworkCard(
                              artwork,
                              isSelected,
                              selectedCount,
                            );
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          _buildFilterChip('pending', 'moderation_filter_pending'.tr()),
          _buildFilterChip('flagged', 'moderation_filter_flagged'.tr()),
          _buildFilterChip('approved', 'moderation_filter_approved'.tr()),
          _buildFilterChip('rejected', 'moderation_filter_rejected'.tr()),
          _buildFilterChip('all', 'moderation_filter_all'.tr()),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedFilter = value;
              _loadArtworks();
            });
          }
        },
        selectedColor: const Color(0xFF22D3EE).withValues(alpha: 0.3),
        checkmarkColor: const Color(0xFF22D3EE),
        labelStyle: GoogleFonts.spaceGrotesk(
          color: isSelected ? const Color(0xFF22D3EE) : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        backgroundColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.done_all_rounded,
            size: 64,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'moderation_no_artworks'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork, bool isSelected, int totalSelected) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected 
              ? const Color(0xFF22D3EE) 
              : Colors.white.withValues(alpha: 0.1),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (totalSelected > 0) {
            setState(() {
              _selectedArtworks[artwork.id] = !isSelected;
            });
          } else {
            _showModerationDialog(artwork);
          }
        },
        onLongPress: () {
          setState(() {
            _selectedArtworks[artwork.id] = !isSelected;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (totalSelected > 0)
                Checkbox(
                  value: isSelected,
                  onChanged: (value) {
                    setState(() {
                      _selectedArtworks[artwork.id] = value ?? false;
                    });
                  },
                  activeColor: const Color(0xFF22D3EE),
                ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SecureNetworkImage(
                  imageUrl: artwork.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      artwork.title,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      artwork.artistName,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusBadge(artwork.moderationStatus),
                        const Spacer(),
                        if (artwork.flagged)
                          const Icon(
                            Icons.flag,
                            color: Colors.red,
                            size: 16,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () => _showModerationDialog(artwork),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ArtworkModerationStatus status) {
    Color color;
    switch (status) {
      case ArtworkModerationStatus.approved:
        color = Colors.green;
        break;
      case ArtworkModerationStatus.rejected:
        color = Colors.red;
        break;
      case ArtworkModerationStatus.pending:
        color = Colors.orange;
        break;
      case ArtworkModerationStatus.flagged:
        color = Colors.redAccent;
        break;
      case ArtworkModerationStatus.underReview:
        color = Colors.blue;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
