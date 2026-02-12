import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../services/flagging_queue_service.dart';
import '../../widgets/admin_drawer.dart';

class AdminFlaggingQueueScreen extends StatefulWidget {
  const AdminFlaggingQueueScreen({super.key});

  @override
  State<AdminFlaggingQueueScreen> createState() =>
      _AdminFlaggingQueueScreenState();
}

class _AdminFlaggingQueueScreenState extends State<AdminFlaggingQueueScreen> {
  final FlaggingQueueService _queueService = FlaggingQueueService();
  List<FlaggedItem> _flaggedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQueue();
  }

  Future<void> _loadQueue() async {
    setState(() => _isLoading = true);
    try {
      final items = await _queueService.getFlaggedQueue();
      setState(() {
        _flaggedItems = items;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading queue: $e')),
        );
      }
    }
  }

  Future<void> _handleResolve(FlaggedItem item, bool approve) async {
    final notesController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve Content' : 'Reject/Remove Content'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Are you sure you want to ${approve ? 'approve' : 'reject'} this ${item.type.name}?'),
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
              backgroundColor: approve ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(approve ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _queueService.resolveItem(item, approve,
            notes: notesController.text.trim().isEmpty
                ? null
                : notesController.text.trim());
        await _loadQueue();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    'Item ${approve ? 'approved' : 'rejected'} successfully')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      currentIndex: -1,
      appBar: core.EnhancedUniversalHeader(
        title: 'Flagging Queue',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: const LinearGradient(
          colors: [Colors.orange, Colors.red],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadQueue,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _flaggedItems.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadQueue,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _flaggedItems.length,
                    itemBuilder: (context, index) =>
                        _buildFlaggedItemCard(_flaggedItems[index]),
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: Colors.green[200]),
          const SizedBox(height: 16),
          const Text(
            'Queue is clear!',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            'No content currently requires moderation.',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildFlaggedItemCard(FlaggedItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getTypeChip(item.type),
                const Spacer(),
                Text(
                  _formatDate(item.flaggedAt),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              item.content,
              style: const TextStyle(fontSize: 16),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'By: ${item.authorName}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.bold),
                ),
                if (item.reason != null) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.warning_amber,
                      size: 16, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    item.reason!,
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _handleResolve(item, false),
                  icon: const Icon(Icons.close, color: Colors.red),
                  label:
                      const Text('Reject', style: TextStyle(color: Colors.red)),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () => _handleResolve(item, true),
                  icon: const Icon(Icons.check),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTypeChip(FlaggedItemType type) {
    Color color;
    switch (type) {
      case FlaggedItemType.post:
        color = Colors.blue;
        break;
      case FlaggedItemType.comment:
        color = Colors.purple;
        break;
      case FlaggedItemType.artwork:
        color = Colors.teal;
        break;
      case FlaggedItemType.capture:
        color = Colors.indigo;
        break;
      case FlaggedItemType.event:
        color = Colors.deepOrange;
        break;
      case FlaggedItemType.report:
        color = Colors.red;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        type.name.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
