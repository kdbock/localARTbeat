import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/artbeat_capture.dart';

/// Admin screen for moderating pending captures
class AdminContentModerationScreen extends StatefulWidget {
  const AdminContentModerationScreen({Key? key}) : super(key: key);

  @override
  State<AdminContentModerationScreen> createState() =>
      _AdminContentModerationScreenState();
}

class _AdminContentModerationScreenState
    extends State<AdminContentModerationScreen> {
  final CaptureService _captureService = CaptureService();
  List<core.CaptureModel> _pendingCaptures = [];
  bool _loading = true;
  String _selectedTab = 'pending';

  @override
  void initState() {
    super.initState();
    _loadPendingCaptures();
  }

  Future<void> _loadPendingCaptures() async {
    setState(() => _loading = true);

    try {
      final captures = await _captureService.getPendingCaptures(limit: 50);
      if (mounted) {
        setState(() {
          _pendingCaptures = captures;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_admin_content_moderation_error_error_loading_captures'
                  .tr(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _loadCapturesByStatus(String status) async {
    setState(() => _loading = true);

    try {
      List<core.CaptureModel> captures;
      if (status == 'pending') {
        captures = await _captureService.getPendingCaptures(limit: 50);
      } else if (status == 'reported') {
        captures = await _captureService.getReportedCaptures(limit: 50);
      } else {
        captures = await _captureService.getCapturesByStatus(status, limit: 50);
      }

      if (mounted) {
        setState(() {
          _pendingCaptures = captures;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_admin_content_moderation_error_error_loading_captures'
                  .tr(),
            ),
          ),
        );
      }
    }
  }

  Future<void> _approveCapture(core.CaptureModel capture) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'capture_admin_content_moderation_text_approve_capture'.tr(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('capture_admin_content_moderation_text_are_you_sure'.tr()),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Moderation Notes (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('admin_admin_payment_text_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'admin_modern_unified_admin_dashboard_text_approve'.tr(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.approveCapture(
        capture.id,
        moderationNotes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'capture_admin_content_moderation_success_capture_approved_successfully'
                    .tr(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadCapturesByStatus(_selectedTab);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'capture_admin_content_moderation_error_failed_to_approve'.tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _rejectCapture(core.CaptureModel capture) async {
    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'capture_admin_content_moderation_text_reject_capture'.tr(),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'capture_admin_content_moderation_text_are_you_sure_15'.tr(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(
                  labelText: 'Reason for rejection (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('admin_admin_payment_text_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'admin_modern_unified_admin_dashboard_text_reject'.tr(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.rejectCapture(
        capture.id,
        moderationNotes: notesController.text.trim().isEmpty
            ? null
            : notesController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'capture_admin_content_moderation_text_capture_rejected'.tr(),
              ),
              backgroundColor: Colors.orange,
            ),
          );
          _loadCapturesByStatus(_selectedTab);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'capture_admin_content_moderation_error_failed_to_reject'.tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteCapture(core.CaptureModel capture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'capture_admin_content_moderation_text_delete_capture'.tr(),
          ),
          content: Text(
            'capture_admin_content_moderation_delete_confirmation'.tr(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('admin_admin_payment_text_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'admin_modern_unified_admin_dashboard_text_delete'.tr(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.adminDeleteCapture(capture.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'capture_admin_content_moderation_text_capture_deleted_permanently'
                    .tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
          _loadCapturesByStatus(_selectedTab);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'capture_admin_content_moderation_error_failed_to_delete'.tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearReports(core.CaptureModel capture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'art_walk_admin_art_walk_moderation_text_clear_reports'.tr(),
          ),
          content: Text(
            'capture_admin_content_moderation_clear_reports_confirmation'
                .tr()
                .replaceAll('{count}', capture.reportCount.toString()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('admin_admin_payment_text_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'art_walk_admin_art_walk_moderation_text_clear_reports'.tr(),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.clearCaptureReports(capture.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'art_walk_admin_art_walk_moderation_success_reports_cleared_successfully'
                    .tr(),
              ),
              backgroundColor: Colors.green,
            ),
          );
          _loadCapturesByStatus(_selectedTab);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'capture_admin_content_moderation_error_failed_to_clear'.tr(),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewCaptureDetails(core.CaptureModel capture) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.white),
                      const SizedBox(width: 8),
                      const Text(
                        'Capture Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Image
                        Container(
                          height: 300,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              capture.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.error, size: 48),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Details
                        _buildDetailRow('Title', capture.title ?? 'No title'),
                        _buildDetailRow('Status', capture.status.displayName),
                        if (capture.reportCount > 0)
                          _buildDetailRow(
                            'Reports',
                            '${capture.reportCount} report${capture.reportCount > 1 ? 's' : ''}',
                            isWarning: true,
                          ),
                        if (capture.artistName != null)
                          _buildDetailRow('Artist', capture.artistName!),
                        if (capture.artType != null)
                          _buildDetailRow('Art Type', capture.artType!),
                        if (capture.artMedium != null)
                          _buildDetailRow('Medium', capture.artMedium!),
                        if (capture.description != null)
                          _buildDetailRow('Description', capture.description!),
                        if (capture.locationName != null)
                          _buildDetailRow('Location', capture.locationName!),
                        _buildDetailRow(
                          'Created',
                          capture.createdAt.toString(),
                        ),
                        if (capture.moderationNotes != null)
                          _buildDetailRow(
                            'Moderation Notes',
                            capture.moderationNotes!,
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isWarning ? Colors.red.shade800 : null,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                if (isWarning)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.flag,
                      size: 16,
                      color: Colors.red.shade800,
                    ),
                  ),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isWarning ? Colors.red.shade800 : null,
                      fontWeight: isWarning ? FontWeight.w600 : null,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CaptureDrawer(),
      appBar: core.EnhancedUniversalHeader(
        title: 'Content Moderation',
        showLogo: false,
        showBackButton: true,
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
        titleGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.topRight,
          colors: [core.ArtbeatColors.primaryPurple, Colors.pink],
        ),
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          // Tab bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [
                          ButtonSegment(
                            value: 'pending',
                            label: Text(
                              'capture_admin_content_moderation_text_pending'
                                  .tr(),
                            ),
                            icon: const Icon(Icons.schedule),
                          ),
                          ButtonSegment(
                            value: 'approved',
                            label: Text(
                              'capture_admin_content_moderation_text_approved'
                                  .tr(),
                            ),
                            icon: const Icon(Icons.check_circle),
                          ),
                          ButtonSegment(
                            value: 'rejected',
                            label: Text(
                              'capture_admin_content_moderation_text_rejected'
                                  .tr(),
                            ),
                            icon: const Icon(Icons.cancel),
                          ),
                          ButtonSegment(
                            value: 'reported',
                            label: Text(
                              'art_walk_admin_art_walk_moderation_text_reported'
                                  .tr(),
                            ),
                            icon: const Icon(Icons.flag),
                          ),
                        ],
                        selected: {_selectedTab},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _selectedTab = newSelection.first;
                          });
                          _loadCapturesByStatus(_selectedTab);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: () => _loadCapturesByStatus(_selectedTab),
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _pendingCaptures.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedTab == 'pending'
                              ? Icons.schedule
                              : _selectedTab == 'approved'
                              ? Icons.check_circle
                              : _selectedTab == 'rejected'
                              ? Icons.cancel
                              : Icons.flag,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No ${_selectedTab} captures found',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All caught up!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _pendingCaptures.length,
                    itemBuilder: (context, index) {
                      final capture = _pendingCaptures[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Image thumbnail
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    capture.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      capture.title ?? 'Untitled',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    if (capture.artistName != null)
                                      Text(
                                        'capture_admin_content_moderation_label_artist_captureartistname'
                                            .tr(),
                                      ),
                                    if (capture.artType != null)
                                      Text(
                                        'capture_admin_content_moderation_hint_type_capturearttype'
                                            .tr(),
                                      ),
                                    Text(
                                      'Created: ${capture.createdAt.toLocal().toString().split(' ')[0]}',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                capture.status ==
                                                    core.CaptureStatus.pending
                                                ? Colors.orange.shade100
                                                : capture.status ==
                                                      core
                                                          .CaptureStatus
                                                          .approved
                                                ? Colors.green.shade100
                                                : Colors.red.shade100,
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            capture.status.displayName,
                                            style: TextStyle(
                                              color:
                                                  capture.status ==
                                                      core.CaptureStatus.pending
                                                  ? Colors.orange.shade800
                                                  : capture.status ==
                                                        core
                                                            .CaptureStatus
                                                            .approved
                                                  ? Colors.green.shade800
                                                  : Colors.red.shade800,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        if (capture.reportCount > 0) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.flag,
                                                  size: 12,
                                                  color: Colors.red.shade800,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${capture.reportCount} report${capture.reportCount > 1 ? 's' : ''}',
                                                  style: TextStyle(
                                                    color: Colors.red.shade800,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Actions
                              Column(
                                children: [
                                  IconButton(
                                    onPressed: () =>
                                        _viewCaptureDetails(capture),
                                    icon: const Icon(Icons.visibility),
                                    tooltip: 'View Details',
                                  ),
                                  if (_selectedTab == 'pending') ...[
                                    IconButton(
                                      onPressed: () => _approveCapture(capture),
                                      icon: const Icon(Icons.check_circle),
                                      color: Colors.green,
                                      tooltip: 'Approve',
                                    ),
                                    IconButton(
                                      onPressed: () => _rejectCapture(capture),
                                      icon: const Icon(Icons.cancel),
                                      color: Colors.orange,
                                      tooltip: 'Reject',
                                    ),
                                  ],
                                  if (capture.reportCount > 0)
                                    IconButton(
                                      onPressed: () => _clearReports(capture),
                                      icon: const Icon(Icons.flag_outlined),
                                      color: Colors.blue,
                                      tooltip: 'Clear Reports',
                                    ),
                                  IconButton(
                                    onPressed: () => _deleteCapture(capture),
                                    icon: const Icon(Icons.delete),
                                    color: Colors.red,
                                    tooltip: 'Delete',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
