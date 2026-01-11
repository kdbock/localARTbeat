// FULL FILE — paste over existing

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart' hide GradientCTAButton;
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart' hide GradientCTAButton;
import '../widgets/widgets.dart';

import '../models/artbeat_event.dart';
import '../services/event_bulk_management_service.dart';

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
  final bool _isPerformingBulkOperation = false;
  String? _errorMessage;

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
        _selectedEventIds.clear();
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
    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            EventsHudTopBar(
              title: 'event_bulk_title'.tr(),
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Column(
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
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Filters -----------------

  Widget _buildFiltersCard() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'event_bulk_filters'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(child: _categoryDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _statusDropdown()),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectStartDate,
                    icon: const Icon(Icons.date_range, color: Colors.white70),
                    label: Text(
                      _startDate != null
                          ? intl.DateFormat('MMM dd, yyyy').format(_startDate!)
                          : 'event_bulk_start_date'.tr(),
                      style: GoogleFonts.spaceGrotesk(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _selectEndDate,
                    icon: const Icon(Icons.date_range, color: Colors.white70),
                    label: Text(
                      _endDate != null
                          ? intl.DateFormat('MMM dd, yyyy').format(_endDate!)
                          : 'event_bulk_end_date'.tr(),
                      style: GoogleFonts.spaceGrotesk(color: Colors.white70),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GradientCTAButton(
                  text: 'event_bulk_clear'.tr(),
                  onPressed: _clearFilters,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCategory,
      dropdownColor: Colors.black87,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Category',
      ),
      items: const [
        DropdownMenuItem(child: Text('All')),
        DropdownMenuItem(value: 'art-show', child: Text('Art Show')),
        DropdownMenuItem(value: 'workshop', child: Text('Workshop')),
        DropdownMenuItem(value: 'exhibition', child: Text('Exhibition')),
        DropdownMenuItem(value: 'sale', child: Text('Sale')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: (value) {
        setState(() => _selectedCategory = value);
        _loadEvents();
      },
    );
  }

  Widget _statusDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedStatus,
      dropdownColor: Colors.black87,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: 'Status',
      ),
      items: const [
        DropdownMenuItem(child: Text('All')),
        DropdownMenuItem(value: 'active', child: Text('Active')),
        DropdownMenuItem(value: 'inactive', child: Text('Inactive')),
        DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
        DropdownMenuItem(value: 'postponed', child: Text('Postponed')),
        DropdownMenuItem(value: 'draft', child: Text('Draft')),
      ],
      onChanged: (value) {
        setState(() => _selectedStatus = value);
        _loadEvents();
      },
    );
  }

  // ---------------- Selection Header -----------------

  Widget _buildSelectionHeader() {
    if (_events.isEmpty) return const SizedBox.shrink();

    final total = _events.length;
    final selected = _selectedEventIds.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        child: Row(
          children: [
            Checkbox(
              value: selected == total && total > 0,
              tristate: selected > 0 && selected < total,
              onChanged: _toggleSelectAll,
            ),
            Text(
              selected == 0
                  ? 'event_bulk_select_events'.tr()
                  : '${'event_bulk_of_selected'.tr().replaceFirst('{{count}}', '$selected')} $total',
              style: GoogleFonts.spaceGrotesk(color: Colors.white),
            ),
            const Spacer(),
            if (selected > 0)
              TextButton(
                onPressed: () => setState(_selectedEventIds.clear),
                child: Text(
                  'event_bulk_clear_selection'.tr(),
                  style: GoogleFonts.spaceGrotesk(color: Colors.white70),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------------- Error -----------------

  Widget _buildErrorWidget() {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error, color: Colors.red[300], size: 64),
            const SizedBox(height: 12),
            Text(
              'event_bulk_error_loading'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
            ),
            const SizedBox(height: 14),
            GradientCTAButton(
              text: 'event_bulk_retry'.tr(),
              onPressed: _loadEvents,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- List -----------------

  Widget _buildEventsList() {
    if (_events.isEmpty) {
      return Center(
        child: GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.event_busy, color: Colors.white70, size: 56),
              const SizedBox(height: 10),
              Text(
                'event_bulk_no_events'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'event_bulk_no_events_hint'.tr(),
                style: GoogleFonts.spaceGrotesk(color: Colors.white70),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvents,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _events.length,
        itemBuilder: (_, i) => _buildEventCard(_events[i]),
      ),
    );
  }

  Widget _buildEventCard(ArtbeatEvent event) {
    final isSelected = _selectedEventIds.contains(event.id);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        child: InkWell(
          onTap: () => _toggleEventSelection(event.id),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (_) => _toggleEventSelection(event.id),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      event.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _buildEventStatusChip(event),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventStatusChip(ArtbeatEvent event) {
    final status = event.isPublic ? 'active' : 'inactive';
    final color = status == 'active' ? Colors.green : Colors.grey;

    return Chip(
      label: Text(
        status.toUpperCase(),
        style: GoogleFonts.spaceGrotesk(fontSize: 10),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      side: BorderSide(color: color),
    );
  }

  // ---------------- Selection logic -----------------

  void _toggleEventSelection(String eventId) {
    setState(() {
      _selectedEventIds.contains(eventId)
          ? _selectedEventIds.remove(eventId)
          : _selectedEventIds.add(eventId);
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

  // ---------------- Date filters -----------------

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _startDate = date);
      _loadEvents();
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate:
          _startDate ?? DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _endDate = date);
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

  // ---------------- Bulk actions UI -----------------

  // ---------------- Dialogs -----------------

  // ---------------- Bulk Ops -----------------
}
