import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_capture/artbeat_capture.dart';

/// Admin screen for moderating pending captures
/// Relocated to artbeat_admin for unified administration
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
              'capture_admin_content_moderation_text_approve_capture'.tr()),
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
                  backgroundColor: Colors.green, foregroundColor: Colors.white),
              child: Text(
                  'admin_modern_unified_admin_dashboard_text_approve'.tr()),
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
                        .tr()),
                backgroundColor: Colors.green),
          );
          _loadCapturesByStatus(_selectedTab);
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
          title:
              Text('capture_admin_content_moderation_text_reject_capture'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'capture_admin_content_moderation_text_are_you_sure_15'.tr()),
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
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child:
                  Text('admin_modern_unified_admin_dashboard_text_reject'.tr()),
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
                    'capture_admin_content_moderation_text_capture_rejected'
                        .tr()),
                backgroundColor: Colors.orange),
          );
          _loadCapturesByStatus(_selectedTab);
        }
      }
    }
  }

  Future<void> _deleteCapture(core.CaptureModel capture) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title:
              Text('capture_admin_content_moderation_text_delete_capture'.tr()),
          content:
              Text('capture_admin_content_moderation_delete_confirmation'.tr()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('admin_admin_payment_text_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, foregroundColor: Colors.white),
              child:
                  Text('admin_modern_unified_admin_dashboard_text_delete'.tr()),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      final success = await _captureService.adminDeleteCapture(capture.id);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'capture_admin_content_moderation_text_capture_deleted_permanently'
                      .tr()),
              backgroundColor: Colors.red),
        );
        _loadCapturesByStatus(_selectedTab);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
            'capture_admin_content_moderation_text_content_moderation'.tr()),
        backgroundColor: Colors.white.withValues(alpha: 0.1),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildTabSelector(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _pendingCaptures.isEmpty
                    ? Center(
                        child: Text('No captures found',
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7))))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pendingCaptures.length,
                        itemBuilder: (context, index) =>
                            _buildCaptureCard(_pendingCaptures[index]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _buildTabItem('pending', 'Pending'),
            _buildTabItem('reported', 'Reported'),
            _buildTabItem('approved', 'Approved'),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(String status, String label) {
    final isSelected = _selectedTab == status;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedTab = status);
          _loadCapturesByStatus(status);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.6),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureCard(core.CaptureModel capture) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (capture.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                capture.imageUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: Colors.grey[800],
                    child:
                        const Icon(Icons.broken_image, color: Colors.white54)),
              ),
            ),
          const SizedBox(height: 12),
          Text(capture.title ?? 'Untitled Capture',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(capture.description ?? '',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_selectedTab != 'approved')
                IconButton(
                  onPressed: () => _approveCapture(capture),
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.green),
                  tooltip: 'Approve',
                ),
              if (_selectedTab == 'pending' || _selectedTab == 'reported')
                IconButton(
                  onPressed: () => _rejectCapture(capture),
                  icon: const Icon(Icons.highlight_off, color: Colors.orange),
                  tooltip: 'Reject',
                ),
              IconButton(
                onPressed: () => _deleteCapture(capture),
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
