import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_art_walk/src/models/art_walk_model.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';

/// Admin screen for moderating art walks
/// Relocated to artbeat_admin for unified administration
class AdminArtWalkModerationScreen extends StatefulWidget {
  const AdminArtWalkModerationScreen({Key? key}) : super(key: key);

  @override
  State<AdminArtWalkModerationScreen> createState() =>
      _AdminArtWalkModerationScreenState();
}

class _AdminArtWalkModerationScreenState
    extends State<AdminArtWalkModerationScreen> {
  ArtWalkService? _artWalkService;
  List<ArtWalkModel> _artWalks = [];
  bool _loading = true;
  String _selectedTab = 'all';

  @override
  void initState() {
    super.initState();
    // Use addPostFrameCallback or obtain service in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_artWalkService == null) {
      try {
        _artWalkService = context.read<ArtWalkService>();
        _loadArtWalks();
      } catch (e) {
        AppLogger.error('Error initializing ArtWalkService: $e');
      }
    }
  }

  Future<void> _loadArtWalks() async {
    if (_artWalkService == null) return;
    setState(() => _loading = true);

    try {
      List<ArtWalkModel> walks;
      if (_selectedTab == 'all') {
        walks = await _artWalkService!.getAllArtWalks(limit: 100);
      } else {
        walks = await _artWalkService!.getReportedArtWalks(limit: 100);
      }

      if (mounted) {
        setState(() {
          _artWalks = walks;
          _loading = false;
        });
      }
    } catch (e) {
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

    if (confirmed == true && _artWalkService != null) {
      try {
        await _artWalkService!.adminDeleteArtWalk(walk.id);
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

    if (confirmed == true && _artWalkService != null) {
      try {
        await _artWalkService!.clearArtWalkReports(walk.id);
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('art_walk_admin_art_walk_moderation_text_art_walk_moderation'.tr()),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTabSelector(),
            const SizedBox(height: 16),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_artWalks.isEmpty)
              Expanded(child: _buildEmptyState())
            else
              Expanded(child: _buildArtWalksList()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              value: 'all',
              label: 'art_walk_admin_art_walk_moderation_text_all'.tr(),
              icon: Icons.route,
            ),
          ),
          const SizedBox(width: 4),
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
    return GestureDetector(
      onTap: () {
        if (_selectedTab == value) return;
        setState(() => _selectedTab = value);
        _loadArtWalks();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _buildArtWalksList() {
    return ListView.separated(
      itemCount: _artWalks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildArtWalkTile(_artWalks[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedTab == 'reported' ? Icons.flag_outlined : Icons.route_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No art walks found',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildArtWalkTile(ArtWalkModel walk) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walk.title,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(walk.createdAt),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (walk.reportCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag, size: 14, color: Colors.red),
                      const SizedBox(width: 4),
                      Text(walk.reportCount.toString(), style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            walk.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _showArtWalkDetails(walk),
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Details'),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
              ),
              const Spacer(),
              if (walk.reportCount > 0)
                IconButton(
                  onPressed: () => _clearReports(walk),
                  icon: const Icon(Icons.check_circle_outline, color: Colors.green),
                  tooltip: 'Clear Reports',
                ),
              IconButton(
                onPressed: () => _deleteArtWalk(walk),
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
