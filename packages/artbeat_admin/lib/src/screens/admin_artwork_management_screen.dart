import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork_pkg;
import '../services/admin_artwork_management_service.dart';

class AdminArtworkManagementScreen extends StatefulWidget {
  AdminArtworkManagementScreen({super.key});

  @override
  State<AdminArtworkManagementScreen> createState() =>
      _AdminArtworkManagementScreenState();
}

class _AdminArtworkManagementScreenState
    extends State<AdminArtworkManagementScreen> {
  final AdminArtworkManagementService _service =
      AdminArtworkManagementService();
  
  String _selectedFilter = 'reported';
  artwork_pkg.ArtworkModel? _selectedArtwork;
  List<artwork_pkg.ArtworkModel> _artworks = [];
  bool _isLoading = false;
  Map<String, dynamic>? _selectedArtworkDetails;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadArtwork();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadArtwork() async {
    setState(() => _isLoading = true);
    try {
      final artworkList = await _service.getArtworkList(
        filterType: _selectedFilter,
        limit: 100,
      );
      setState(() => _artworks = artworkList);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_error_error_loading_artwork'.tr())),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadArtworkDetails(artwork_pkg.ArtworkModel artwork) async {
    try {
      final details = await _service.getArtworkReportDetails(artwork.id);
      setState(() {
        _selectedArtwork = artwork;
        _selectedArtworkDetails = details;
        _titleController.text = artwork.title;
        _descriptionController.text = artwork.description;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_error_error_loading_details'.tr())),
        );
      }
    }
  }

  Future<void> _updateArtworkStatus(String newStatus, {String? reason}) async {
    if (_selectedArtwork == null) return;

    try {
      await _service.updateArtworkStatus(
        _selectedArtwork!.id,
        newStatus,
        reason: reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_success_artwork_status_updated'.tr())),
        );
        await _loadArtwork();
        setState(() => _selectedArtworkDetails = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_error_error_e'.tr())),
        );
      }
    }
  }

  Future<void> _deleteArtwork(String reason) async {
    if (_selectedArtwork == null) return;

    try {
      await _service.deleteArtwork(_selectedArtwork!.id, reason: reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_text_artwork_deleted'.tr())),
        );
        await _loadArtwork();
        setState(() => _selectedArtworkDetails = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_error_error_e'.tr())),
        );
      }
    }
  }

  Future<void> _deleteComment(String commentId, String reason) async {
    if (_selectedArtwork == null) return;

    try {
      await _service.deleteComment(_selectedArtwork!.id, commentId, reason: reason);
      await _loadArtworkDetails(_selectedArtwork!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_text_comment_deleted'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_admin_artwork_management_error_error_e'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin_admin_artwork_management_text_artwork_management'.tr()),
        elevation: 0,
      ),
      body: Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildArtworkList(),
          ),
          if (_selectedArtworkDetails != null)
            Expanded(
              flex: 3,
              child: _buildDetailPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildArtworkList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search artwork...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) {
                  if (value.isNotEmpty) {
                    _service.searchArtwork(value).then((results) {
                      setState(() => _artworks = results);
                    });
                  } else {
                    _loadArtwork();
                  }
                },
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Reported', 'reported'),
                    _buildFilterChip('Flagged', 'flagged'),
                    _buildFilterChip('Pending', 'pending'),
                    _buildFilterChip('Approved', 'approved'),
                    _buildFilterChip('Rejected', 'rejected'),
                    _buildFilterChip('All', 'all'),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _artworks.isEmpty
                  ? Center(child: Text('admin_admin_artwork_management_text_no_artwork_found'.tr()))
                  : ListView.builder(
                      itemCount: _artworks.length,
                      itemBuilder: (context, index) {
                        final artwork = _artworks[index];
                        final isSelected = _selectedArtwork?.id == artwork.id;
                        return ListTile(
                          selected: isSelected,
                          selectedTileColor: Colors.blue.withValues(alpha: 0.1),
                          title: Text(artwork.title),
                          subtitle: Text(
                            artwork.description.length > 50
                                ? '${artwork.description.substring(0, 50)}...'
                                : artwork.description,
                          ),
                          leading: artwork.imageUrl.isNotEmpty
                              ? Image.network(
                                  artwork.imageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image),
                                )
                              : const Icon(Icons.image),
                          onTap: () => _loadArtworkDetails(artwork),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _selectedFilter = value);
          _loadArtwork();
        },
      ),
    );
  }

  Widget _buildDetailPanel() {
    if (_selectedArtwork == null || _selectedArtworkDetails == null) {
      return Center(child: Text('admin_admin_artwork_management_text_select_artwork_to'.tr()));
    }

    final artwork = _selectedArtwork!;
    final details = _selectedArtworkDetails!;
    final analytics = (details['analyticsData'] as Map<String, dynamic>?) ?? {};
    final reportsList = (details['reports'] as List<dynamic>?) ?? [];
    final comments = (details['comments'] as List<artwork_pkg.CommentModel>?) ?? [];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailHeader(artwork),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnalyticsSection(analytics),
                const SizedBox(height: 20),
                _buildContentEditor(artwork),
                const SizedBox(height: 20),
                _buildReportedBySection(reportsList),
                const SizedBox(height: 20),
                _buildCommentsSection(comments),
                const SizedBox(height: 20),
                _buildActionButtons(artwork),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeader(artwork_pkg.ArtworkModel artwork) {
    return Container(
      color: Colors.grey[200],
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (artwork.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                artwork.imageUrl,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  artwork.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Created: ${artwork.createdAt.toString().split('.')[0]}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(artwork.moderationStatus),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    artwork.moderationStatus.displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSection(Map<String, dynamic> analytics) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAnalyticItem(
                  'Views',
                  '${analytics['viewCount'] ?? 0}',
                  Icons.visibility,
                ),
                _buildAnalyticItem(
                  'Likes',
                  '${analytics['likeCount'] ?? 0}',
                  Icons.favorite,
                ),
                _buildAnalyticItem(
                  'Comments',
                  '${analytics['commentCount'] ?? 0}',
                  Icons.comment,
                ),
                _buildAnalyticItem(
                  'Reports',
                  '${analytics['reportCount'] ?? 0}',
                  Icons.flag,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildReportedBySection(List<dynamic> reports) {
    if (reports.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No reports',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reports',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${reports.length} total',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...reports.asMap().entries.map((entry) {
              final report = entry.value as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (report['reason'] as String?) ?? 'No reason provided',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Reported by: ${(report['reportedBy'] as String?) ?? "Unknown"}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildContentEditor(artwork_pkg.ArtworkModel artwork) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Content',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                label: Text('admin_admin_artwork_management_title_title'.tr()),
                border: OutlineInputBorder(),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                label: Text('admin_admin_artwork_management_message_description'.tr()),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              readOnly: true,
            ),
            const SizedBox(height: 12),
            Text(
              'Tags: ${artwork.tags?.join(", ") ?? "None"}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsSection(List<artwork_pkg.CommentModel> comments) {
    if (comments.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'No comments',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Comments',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${comments.length} total',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...comments.map((comment) {
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          comment.userName,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem<String>(
                              value: 'delete',
                              child: Text('admin_admin_artwork_management_text_delete'.tr()),
                              onTap: () => _showDeleteCommentDialog(comment.id),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(comment.content),
                    const SizedBox(height: 4),
                    Text(
                      comment.createdAt.toDate().toString().split('.')[0],
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(artwork_pkg.ArtworkModel artwork) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: Text('admin_admin_artwork_management_text_approve'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    onPressed: () =>
                        _updateArtworkStatus('approved', reason: 'Approved by admin'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.block),
                    label: Text('admin_admin_artwork_management_text_reject'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    onPressed: () => _showRejectDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.flag),
                    label: Text('admin_admin_artwork_management_text_flag'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                    ),
                    onPressed: () =>
                        _updateArtworkStatus('flagged', reason: 'Flagged by admin'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.delete),
                    label: Text('admin_admin_artwork_management_text_delete'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    onPressed: () => _showDeleteDialog(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog() {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_artwork_management_text_reject_artwork'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_artwork_management_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              _updateArtworkStatus('rejected', reason: reasonController.text);
              Navigator.pop(context);
            },
            child: Text('admin_admin_artwork_management_text_reject'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog() {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_artwork_management_text_delete_artwork'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason for deletion'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_artwork_management_text_cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteArtwork(reasonController.text);
              Navigator.pop(context);
            },
            child: Text('admin_admin_artwork_management_text_delete'.tr()),
          ),
        ],
      ),
    );
  }

  void _showDeleteCommentDialog(String commentId) {
    final reasonController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('admin_admin_artwork_management_text_delete_comment'.tr()),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Reason for deletion'),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_artwork_management_text_cancel'.tr()),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _deleteComment(commentId, reasonController.text);
              Navigator.pop(context);
            },
            child: Text('admin_admin_artwork_management_text_delete'.tr()),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(artwork_pkg.ArtworkModerationStatus status) {
    switch (status) {
      case artwork_pkg.ArtworkModerationStatus.approved:
        return Colors.green;
      case artwork_pkg.ArtworkModerationStatus.rejected:
        return Colors.red;
      case artwork_pkg.ArtworkModerationStatus.flagged:
        return Colors.orange;
      case artwork_pkg.ArtworkModerationStatus.pending:
        return Colors.blue;
      case artwork_pkg.ArtworkModerationStatus.underReview:
        return Colors.amber;
    }
  }
}
