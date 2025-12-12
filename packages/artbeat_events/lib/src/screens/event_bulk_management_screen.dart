import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/artbeat_event.dart';
import '../services/event_bulk_management_service.dart';

/// Screen for bulk event management operations
/// Allows users to perform operations on multiple events at once
class EventBulkManagementScreen extends StatefulWidget {
  const EventBulkManagementScreen({super.key});

  @override
  State<EventBulkManagementScreen> createState() =>
      _EventBulkManagementScreenState();
}

class _EventBulkManagementScreenState extends State<EventBulkManagementScreen> {
  final EventBulkManagementService _bulkService = EventBulkManagementService();

  List<ArtbeatEvent> _events = [];
  final Set<String> _selectedEventIds = <String>{};
  bool _isLoading = true;
  bool _isPerformingBulkOperation = false;
  String? _errorMessage;

  // Filters
  String? _selectedCategory;
  String? _selectedStatus;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final events = await _bulkService.getBulkManageableEvents(
        category: _selectedCategory,
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _events = events;
        _selectedEventIds.clear(); // Clear selections when reloading
        _isLoading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('event_bulk_title'.tr()),
        actions: [
          if (_selectedEventIds.isNotEmpty)
            IconButton(
              icon: Badge(
                label: Text('${_selectedEventIds.length}'),
                child: const Icon(Icons.more_vert),
              ),
              onPressed: _showBulkActionsMenu,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFiltersCard(),
          _buildSelectionHeader(),
          Expanded(
            child: _isLoading || _isPerformingBulkOperation
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorWidget()
                : _buildEventsList(),
          ),
        ],
      ),
      floatingActionButton: _selectedEventIds.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showBulkActionsMenu,
              icon: const Icon(Icons.settings),
              label: Text(
                'event_bulk_selected_label'.tr().replaceFirst(
                  '{{count}}',
                  '${_selectedEventIds.length}',
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildFiltersCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'event_bulk_filters'.tr(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'event_bulk_category_label'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    initialValue: _selectedCategory,
                    items: [
                      DropdownMenuItem(
                        child: Text('event_bulk_all_categories'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'art-show',
                        child: Text('event_bulk_art_show'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'workshop',
                        child: Text('event_bulk_workshop'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'exhibition',
                        child: Text('event_bulk_exhibition'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'sale',
                        child: Text('event_bulk_sale'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'other',
                        child: Text('event_bulk_other'.tr()),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                      _loadEvents();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'event_bulk_status_label'.tr(),
                      border: const OutlineInputBorder(),
                    ),
                    initialValue: _selectedStatus,
                    items: [
                      DropdownMenuItem(
                        child: Text('event_bulk_all_statuses'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'active',
                        child: Text('event_bulk_active'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('event_bulk_inactive'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'cancelled',
                        child: Text('event_bulk_cancelled'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'postponed',
                        child: Text('event_bulk_postponed'.tr()),
                      ),
                      DropdownMenuItem(
                        value: 'draft',
                        child: Text('event_bulk_draft'.tr()),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                      _loadEvents();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _startDate != null
                          ? DateFormat('MMM dd, yyyy').format(_startDate!)
                          : 'event_bulk_start_date'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.date_range),
                    label: Text(
                      _endDate != null
                          ? DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'event_bulk_end_date'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearFilters,
                  child: Text('event_bulk_clear'.tr()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionHeader() {
    if (_events.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[100],
      child: Row(
        children: [
          Checkbox(
            value: _selectedEventIds.length == _events.length,
            tristate:
                _selectedEventIds.isNotEmpty &&
                _selectedEventIds.length < _events.length,
            onChanged: _toggleSelectAll,
          ),
          Text(
            _selectedEventIds.isEmpty
                ? 'event_bulk_select_events'.tr()
                : '${'event_bulk_of_selected'.tr().replaceFirst('{{count}}', '${_selectedEventIds.length}')} ${_events.length}',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_selectedEventIds.isNotEmpty)
            TextButton(
              onPressed: () => setState(_selectedEventIds.clear),
              child: Text('event_bulk_clear_selection'.tr()),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text(
            'event_bulk_error_loading'.tr(),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadEvents,
            child: Text('event_bulk_retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList() {
    if (_events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.event_busy, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'event_bulk_no_events'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text('event_bulk_no_events_hint'.tr()),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (context, index) {
          return _buildEventCard(_events[index]);
        },
      ),
    );
  }

  Widget _buildEventCard(ArtbeatEvent event) {
    final isSelected = _selectedEventIds.contains(event.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (selected) => _toggleEventSelection(event.id),
        ),
        title: Text(
          event.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              event.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 2),
                Text(
                  event.location,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                Text(
                  DateFormat('MMM dd, yyyy').format(event.dateTime),
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: _buildEventStatusChip(event),
        onTap: () => _toggleEventSelection(event.id),
      ),
    );
  }

  Widget _buildEventStatusChip(ArtbeatEvent event) {
    // Since ArtbeatEvent doesn't have status, use isPublic as indicator
    final status = event.isPublic ? 'active' : 'inactive';
    final color = status == 'active' ? Colors.green : Colors.grey;

    return Chip(
      label: Text(status.toUpperCase(), style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
    );
  }

  void _toggleEventSelection(String eventId) {
    setState(() {
      if (_selectedEventIds.contains(eventId)) {
        _selectedEventIds.remove(eventId);
      } else {
        _selectedEventIds.add(eventId);
      }
    });
  }

  void _toggleSelectAll(bool? selectAll) {
    setState(() {
      if (selectAll == true) {
        _selectedEventIds.addAll(_events.map((e) => e.id));
      } else {
        _selectedEventIds.clear();
      }
    });
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _startDate = date;
      });
      _loadEvents();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() {
        _endDate = date;
      });
      _loadEvents();
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedStatus = null;
      _startDate = null;
      _endDate = null;
    });
    _loadEvents();
  }

  void _showBulkActionsMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => _buildBulkActionsSheet(),
    );
  }

  Widget _buildBulkActionsSheet() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'event_bulk_bulk_actions'.tr().replaceFirst(
              '{{count}}',
              '${_selectedEventIds.length}',
            ),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: Text('event_bulk_update_status'.tr()),
            onTap: () {
              Navigator.pop(context);
              _showStatusUpdateDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.green),
            title: Text('event_bulk_assign_category'.tr()),
            onTap: () {
              Navigator.pop(context);
              _showCategoryAssignDialog();
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility_off, color: Colors.orange),
            title: Text('event_bulk_make_private'.tr()),
            onTap: () {
              Navigator.pop(context);
              _performBulkUpdate({'isPublic': false});
            },
          ),
          ListTile(
            leading: const Icon(Icons.visibility, color: Colors.blue),
            title: Text('event_bulk_make_public'.tr()),
            onTap: () {
              Navigator.pop(context);
              _performBulkUpdate({'isPublic': true});
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: Text('event_bulk_delete_events'.tr()),
            onTap: () {
              Navigator.pop(context);
              _confirmBulkDelete();
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('event_bulk_cancel'.tr()),
          ),
        ],
      ),
    );
  }

  void _showStatusUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('event_bulk_update_status'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('event_bulk_select_status'.tr()),
            const SizedBox(height: 16),
            ...['active', 'inactive', 'cancelled', 'postponed', 'draft'].map(
              (status) => ListTile(
                title: Text('event_bulk_$status'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkStatusChange(status);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryAssignDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('event_bulk_assign_category'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('event_bulk_select_category'.tr()),
            const SizedBox(height: 16),
            ...['art-show', 'workshop', 'exhibition', 'sale', 'other'].map((
              category,
            ) {
              final keyName = category.replaceAll('-', '_');
              return ListTile(
                title: Text('event_bulk_$keyName'.tr()),
                onTap: () {
                  Navigator.pop(context);
                  _performBulkCategoryAssign(category);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _confirmBulkDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('event_bulk_confirm_delete'.tr()),
        content: Text(
          'event_bulk_confirm_delete_message'.tr().replaceFirst(
            '{{count}}',
            '${_selectedEventIds.length}',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('event_bulk_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkDelete();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('event_bulk_delete'.tr()),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkUpdate(Map<String, dynamic> updates) async {
    await _performBulkOperation(
      'Update',
      () => _bulkService.bulkUpdateEvents(_selectedEventIds.toList(), updates),
    );
  }

  Future<void> _performBulkStatusChange(String status) async {
    await _performBulkOperation(
      'Status change',
      () => _bulkService.bulkStatusChange(_selectedEventIds.toList(), status),
    );
  }

  Future<void> _performBulkCategoryAssign(String category) async {
    await _performBulkOperation(
      'Category assignment',
      () =>
          _bulkService.bulkAssignCategory(_selectedEventIds.toList(), category),
    );
  }

  Future<void> _performBulkDelete() async {
    await _performBulkOperation(
      'Deletion',
      () => _bulkService.bulkDeleteEvents(_selectedEventIds.toList()),
      shouldReload: true,
    );
  }

  Future<void> _performBulkOperation(
    String operationName,
    Future<void> Function() operation, {
    bool shouldReload = false,
  }) async {
    setState(() {
      _isPerformingBulkOperation = true;
    });

    try {
      await operation();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'event_bulk_success'.tr().replaceFirst(
                '{{operation}}',
                operationName,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      setState(_selectedEventIds.clear);

      if (shouldReload) {
        await _loadEvents();
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'event_bulk_error'
                  .tr()
                  .replaceAll('{{operation}}', operationName)
                  .replaceFirst('{{error}}', e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isPerformingBulkOperation = false;
      });
    }
  }
}
