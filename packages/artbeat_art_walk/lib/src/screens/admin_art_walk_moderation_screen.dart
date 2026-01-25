import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/models/art_walk_model.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';
import 'package:artbeat_art_walk/src/theme/art_walk_design_system.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_drawer.dart';
import 'package:artbeat_art_walk/src/widgets/art_walk_world_scaffold.dart';
import 'package:artbeat_art_walk/src/widgets/glass_secondary_button.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';

/// Admin screen for moderating art walks
class AdminArtWalkModerationScreen extends StatefulWidget {
  const AdminArtWalkModerationScreen({Key? key}) : super(key: key);

  @override
  State<AdminArtWalkModerationScreen> createState() =>
      _AdminArtWalkModerationScreenState();
}

class _AdminArtWalkModerationScreenState
    extends State<AdminArtWalkModerationScreen> {
  late final ArtWalkService _artWalkService;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<ArtWalkModel> _artWalks = [];
  bool _loading = true;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    AppLogger.info('🔍 AdminArtWalkModerationScreen: initState called');
    try {
      _artWalkService = context.read<ArtWalkService>();
      AppLogger.info(
        '✅ AdminArtWalkModerationScreen: ArtWalkService initialized',
      );
      _loadArtWalks();
    } catch (e, stackTrace) {
      AppLogger.error('❌ AdminArtWalkModerationScreen: Error in initState: $e');
      AppLogger.error('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _loadArtWalks() async {
    AppLogger.info('🔍 AdminArtWalkModerationScreen: _loadArtWalks called');
    setState(() => _loading = true);

    try {
      List<ArtWalkModel> walks;
      if (_selectedTab == 'all') {
        AppLogger.info(
          '🔍 AdminArtWalkModerationScreen: Fetching all art walks',
        );
        walks = await _artWalkService.getAllArtWalks(limit: 100);
      } else {
        AppLogger.info(
          '🔍 AdminArtWalkModerationScreen: Fetching reported art walks',
        );
        walks = await _artWalkService.getReportedArtWalks(limit: 100);
      }

      AppLogger.info(
        '✅ AdminArtWalkModerationScreen: Loaded ${walks.length} art walks',
      );
      if (mounted) {
        setState(() {
          _artWalks = walks;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        '❌ AdminArtWalkModerationScreen: Error loading art walks: $e',
      );
      AppLogger.error('Stack trace: $stackTrace');
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_admin_art_walk_moderation_error_error_loading_art'.tr(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _deleteArtWalk(ArtWalkModel walk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'art_walk_admin_art_walk_moderation_text_delete_art_walk'.tr(),
          ),
          content: Text(
            'Are you sure you want to permanently delete "${walk.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('admin_admin_payment_text_cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: Text(
                'admin_modern_unified_admin_dashboard_text_delete'.tr(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _artWalkService.adminDeleteArtWalk(walk.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_admin_art_walk_moderation_success_art_walk_deleted'
                    .tr(),
              ),
            ),
          );
          _loadArtWalks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_admin_art_walk_moderation_error_error_deleting_art'
                    .tr(),
              ),
            ),
          );
        }
      }
    }
  }

  Future<void> _clearReports(ArtWalkModel walk) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'art_walk_admin_art_walk_moderation_text_clear_reports'.tr(),
          ),
          content: Text(
            'Clear ${walk.reportCount} report(s) from "${walk.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('admin_admin_payment_text_cancel'.tr()),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'art_walk_admin_art_walk_moderation_text_clear_reports'.tr(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await _artWalkService.clearArtWalkReports(walk.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_admin_art_walk_moderation_success_reports_cleared_successfully'
                    .tr(),
              ),
            ),
          );
          _loadArtWalks();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_admin_art_walk_moderation_error_error_clearing_reports'
                    .tr(),
              ),
            ),
          );
        }
      }
    }
  }

  void _showArtWalkDetails(ArtWalkModel walk) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(walk.title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (walk.coverImageUrl != null &&
                    walk.coverImageUrl!.isNotEmpty) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      walk.coverImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                _buildDetailRow('Description', walk.description),
                _buildDetailRow('Creator ID', walk.userId),
                _buildDetailRow('Created', _formatDate(walk.createdAt)),
                _buildDetailRow('Public', walk.isPublic ? 'Yes' : 'No'),
                _buildDetailRow('Views', walk.viewCount.toString()),
                _buildDetailRow('Artworks', walk.artworkIds.length.toString()),
                if (walk.estimatedDuration != null)
                  _buildDetailRow(
                    'Duration',
                    '${walk.estimatedDuration!.toStringAsFixed(0)} min',
                  ),
                if (walk.estimatedDistance != null)
                  _buildDetailRow(
                    'Distance',
                    '${walk.estimatedDistance!.toStringAsFixed(1)} mi',
                  ),
                if (walk.difficulty != null)
                  _buildDetailRow('Difficulty', walk.difficulty!),
                if (walk.zipCode != null)
                  _buildDetailRow('ZIP Code', walk.zipCode!),
                if (walk.reportCount > 0)
                  _buildDetailRow(
                    'Reports',
                    walk.reportCount.toString(),
                    isWarning: true,
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('admin_admin_payment_text_close'.tr()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isWarning = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isWarning)
            const Padding(
              padding: EdgeInsets.only(right: 4),
              child: Icon(Icons.flag, size: 16, color: Colors.red),
            ),
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isWarning ? Colors.red : null,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: isWarning ? Colors.red : null),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ArtWalkWorldScaffold(
      scaffoldKey: _scaffoldKey,
      drawer: const ArtWalkDrawer(),
      title: 'art_walk_admin_art_walk_moderation_text_art_walk_moderation',
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          children: [
            _buildTabSelector(),
            const SizedBox(height: 24),
            if (_loading)
              Expanded(
                child: ArtWalkScreenTemplate.buildLoadingState(
                  message:
                      'art_walk_admin_art_walk_moderation_text_loading_art_walks'
                          .tr(),
                ),
              )
            else if (_artWalks.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(child: _buildArtWalksList()),
          ],
        ),
      ),
      floatingActionButton: _loading
          ? null
          : ArtWalkDesignSystem.buildFloatingActionButton(
              onPressed: _loadArtWalks,
              icon: Icons.refresh,
              tooltip: 'art_walk_admin_art_walk_moderation_text_refresh'.tr(),
            ),
    );
  }

  Widget _buildTabSelector() {
    return ArtWalkDesignSystem.buildGlassCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              value: 'all',
              label: 'art_walk_admin_art_walk_moderation_text_all'.tr(),
              icon: Icons.route,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildTabButton(
              value: 'reported',
              label: 'art_walk_admin_art_walk_moderation_text_reported'.tr(),
              icon: Icons.flag,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedTab == value;
    return Semantics(
      selected: isSelected,
      button: true,
      child: GestureDetector(
        onTap: () {
          if (_selectedTab == value) return;
          setState(() => _selectedTab = value);
          _loadArtWalks();
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: isSelected
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.04),
            border: Border.all(
              color: Colors.white.withValues(alpha: isSelected ? 0.35 : 0.12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.body(
                  isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtWalksList() {
    return RefreshIndicator(
      color: ArtWalkDesignSystem.primaryTeal,
      backgroundColor: Colors.black87,
      onRefresh: _loadArtWalks,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: _artWalks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 18),
        itemBuilder: (context, index) => _buildArtWalkTile(_artWalks[index]),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isReported = _selectedTab == 'reported';
    final title = isReported
        ? 'art_walk_admin_art_walk_moderation_text_no_reported_walks'.tr()
        : 'art_walk_admin_art_walk_moderation_text_no_art_walks'.tr();
    final subtitle = isReported
        ? 'art_walk_admin_art_walk_moderation_text_no_reported_walks_subtitle'
              .tr()
        : 'art_walk_admin_art_walk_moderation_text_no_art_walks_subtitle'.tr();

    return ArtWalkScreenTemplate.buildEmptyState(
      title: title,
      subtitle: subtitle,
      icon: isReported ? Icons.flag_outlined : Icons.route_outlined,
      actionText: 'art_walk_admin_art_walk_moderation_text_refresh'.tr(),
      onAction: _loadArtWalks,
    );
  }

  Widget _buildArtWalkTile(ArtWalkModel walk) {
    final imageProvider = ImageUrlValidator.safeCorrectedNetworkImage(
      walk.coverImageUrl,
    );

    return GestureDetector(
      onTap: () => _showArtWalkDetails(walk),
      child: ArtWalkDesignSystem.buildGlassCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildThumbnail(imageProvider),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(walk.title, style: AppTypography.body()),
                      const SizedBox(height: 6),
                      Text(
                        _formatDate(walk.createdAt),
                        style: AppTypography.helper(),
                      ),
                    ],
                  ),
                ),
                if (walk.reportCount > 0) _buildReportBadge(walk.reportCount),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              walk.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body(Colors.white.withValues(alpha: 0.75)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _buildMetadataChips(walk),
            ),
            const SizedBox(height: 20),
            _buildActionButtons(walk),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail(ImageProvider? image) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: ArtWalkDesignSystem.buttonGradient,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: image != null
            ? Image(image: image, fit: BoxFit.cover)
            : Container(
                color: Colors.white.withValues(alpha: 0.08),
                child: const Icon(Icons.route, color: Colors.white70),
              ),
      ),
    );
  }

  List<Widget> _buildMetadataChips(ArtWalkModel walk) {
    final chips = <Widget>[];

    chips.add(
      _buildMetadataChip(
        Icons.visibility,
        'art_walk_admin_art_walk_moderation_text_views'.tr(
          namedArgs: {'count': walk.viewCount.toString()},
        ),
      ),
    );

    chips.add(
      _buildMetadataChip(
        Icons.palette,
        'art_walk_art_walk_card_text_artworks'.tr(
          namedArgs: {'count': walk.artworkIds.length.toString()},
        ),
      ),
    );

    if (walk.estimatedDuration != null) {
      chips.add(
        _buildMetadataChip(
          Icons.access_time,
          'art_walk_art_walk_card_text_duration'.tr(
            namedArgs: {'minutes': walk.estimatedDuration!.toStringAsFixed(0)},
          ),
        ),
      );
    }

    if (walk.estimatedDistance != null) {
      chips.add(
        _buildMetadataChip(
          Icons.straighten,
          'art_walk_art_walk_card_text_distance'.tr(
            namedArgs: {'miles': walk.estimatedDistance!.toStringAsFixed(1)},
          ),
        ),
      );
    }

    if (walk.difficulty?.isNotEmpty == true) {
      chips.add(_buildMetadataChip(Icons.trending_up, walk.difficulty!));
    }

    if (walk.isAccessible == true) {
      chips.add(
        _buildMetadataChip(
          Icons.accessible,
          'art_walk_accessibility_text_accessible'.tr(),
        ),
      );
    }

    return chips;
  }

  Widget _buildMetadataChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.05),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(label, style: AppTypography.badge()),
        ],
      ),
    );
  }

  Widget _buildActionButtons(ArtWalkModel walk) {
    return Row(
      children: [
        Expanded(
          child: GlassSecondaryButton(
            label: 'art_walk_admin_art_walk_moderation_text_view_details'.tr(),
            icon: Icons.visibility,
            onTap: () => _showArtWalkDetails(walk),
          ),
        ),
        const SizedBox(width: 12),
        if (walk.reportCount > 0) ...[
          _buildActionChip(
            icon: Icons.flag_outlined,
            label: 'art_walk_admin_art_walk_moderation_text_clear_reports'.tr(),
            color: ArtWalkDesignSystem.accentOrange,
            onTap: () => _clearReports(walk),
          ),
          const SizedBox(width: 12),
        ],
        _buildActionChip(
          icon: Icons.delete_outline,
          label: 'art_walk_admin_art_walk_moderation_text_delete'.tr(),
          color: Colors.redAccent,
          onTap: () => _deleteArtWalk(walk),
        ),
      ],
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final chipColor = color ?? ArtWalkDesignSystem.primaryTeal;
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: chipColor.withValues(alpha: 0.18),
            border: Border.all(color: chipColor.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: chipColor),
              const SizedBox(width: 6),
              Text(label, style: AppTypography.body(chipColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportBadge(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.pinkAccent.withValues(alpha: 0.15),
        border: Border.all(color: Colors.pinkAccent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flag, size: 14, color: Colors.pinkAccent),
          const SizedBox(width: 4),
          Text(count.toString(), style: AppTypography.body(Colors.pinkAccent)),
        ],
      ),
    );
  }
}
