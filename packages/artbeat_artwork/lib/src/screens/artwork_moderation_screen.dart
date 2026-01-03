import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide ArtworkModel, GlassInputDecoration;
import 'package:artbeat_core/artbeat_core.dart'
    show
        GlassCard,
        GradientCTAButton,
        HudTopBar,
        MainLayout,
        SecureNetworkImage,
        WorldBackground;
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                radius: 18,
                glassOpacity: 0.08,
                borderOpacity: 0.16,
                child: Text(
                  'moderation_selected_count'
                      .tr(namedArgs: {'count': selectedCount.toString()}),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
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
                                Color(0xFF22D3EE)),
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
                                    artwork, isSelected, selectedCount);
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
    final filters = [
      ('pending', 'moderation_filter_pending'.tr()),
      ('flagged', 'moderation_filter_flagged'.tr()),
      ('approved', 'moderation_filter_approved'.tr()),
      ('rejected', 'moderation_filter_rejected'.tr()),
      ('all', 'moderation_filter_all'.tr()),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    filter.$2,
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                  selected: _selectedFilter == filter.$1,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedFilter = filter.$1);
                      _loadArtworks();
                    }
                  },
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  selectedColor: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: GlassCard(
        radius: 26,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                  child: const Icon(Icons.inbox_outlined,
                      color: Colors.white70),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'moderation_empty_state'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'moderation_empty_subtitle'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GradientCTAButton(
              height: 44,
              text: 'moderation_refresh'.tr(),
              icon: Icons.refresh,
              onPressed: _loadArtworks,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtworkCard(
      ArtworkModel artwork, bool isSelected, int selectedCount) {
    return GlassCard(
      radius: 24,
      padding: EdgeInsets.zero,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: isSelected,
            onChanged: (value) {
              setState(() {
                _selectedArtworks[artwork.id] = value ?? false;
              });
            },
            title: Text(
              artwork.title,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            subtitle: Text(
              'moderation_by_artist'
                  .tr(namedArgs: {'artist': artwork.artistProfileId}),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.72),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            activeColor: const Color(0xFF22D3EE),
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: SecureNetworkImage(
                imageUrl: artwork.imageUrl,
                fit: BoxFit.cover,
                enableThumbnailFallback: true,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildChip(
                      label: artwork.medium,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                    _buildChip(
                      label: artwork.moderationStatus.displayName,
                      color: _getStatusColor(artwork.moderationStatus),
                    ),
                    if (artwork.flagged)
                      _buildChip(
                        label: 'moderation_flagged_badge'.tr(),
                        color: Colors.orange.withValues(alpha: 0.12),
                        icon: Icons.flag,
                      ),
                  ],
                ),
                if (artwork.moderationNotes != null &&
                    artwork.moderationNotes!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${'moderation_notes_label'.tr()}: ${artwork.moderationNotes}',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => _showModerationDialog(artwork),
                      child: Text('moderation_button_review'.tr()),
                    ),
                    const SizedBox(width: 8),
                    GradientCTAButton(
                      height: 42,
                      width: 120,
                      text: 'moderation_button_approve'.tr(),
                      icon: Icons.check,
                      onPressed: () => _moderateArtwork(
                        artwork,
                        ArtworkModerationStatus.approved,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GlassCard(
                      padding: EdgeInsets.zero,
                      radius: 18,
                      glassOpacity: 0.06,
                      borderOpacity: 0.18,
                      onTap: () => _moderateArtwork(
                        artwork,
                        ArtworkModerationStatus.rejected,
                      ),
                      child: Container(
                        height: 42,
                        width: 110,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.6),
                          ),
                        ),
                        child: Text(
                          'moderation_button_reject'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({required String label, required Color color, IconData? icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white70),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
