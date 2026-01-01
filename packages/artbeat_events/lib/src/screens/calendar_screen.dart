import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';
import '../widgets/widgets.dart';

import '../models/artbeat_event.dart';
import '../services/event_service.dart';


class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final EventService _eventService = EventService();

  DateTime _focusedMonth = DateTime.now();
  DateTime? _selectedDate;

  bool _loading = true;
  String? _error;
  List<ArtbeatEvent> _events = [];

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final events = await _eventService.getEvents();
      setState(() {
        _events = events;
        _loading = false;
      });
    } on Exception catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<ArtbeatEvent> get _filteredEvents {
    if (_selectedDate == null) return _events;

    return _events.where((e) {
      final d = e.dateTime;
      return d.year == _selectedDate!.year &&
          d.month == _selectedDate!.month &&
          d.day == _selectedDate!.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: SafeArea(
        child: Column(
          children: [
            EventsHudTopBar(title: 'event_calendar_title'.tr(), showBack: true),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? _buildError()
                  : _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Text(
              'event_calendar_error'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _error ?? '',
              style: GoogleFonts.spaceGrotesk(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadEvents,
              child: Text(
                'event_calendar_retry'.tr(),
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildMonthHeader(),
        _buildCalendarGrid(),
        const SizedBox(height: 10),
        Expanded(child: _buildEventsList()),
      ],
    );
  }

  // ---------------- Month navigation ----------------

  Widget _buildMonthHeader() {
    final monthLabel = intl.DateFormat('MMMM yyyy').format(_focusedMonth);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: GlassCard(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month - 1,
                  );
                });
              },
            ),
            Text(
              monthLabel,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.white),
              onPressed: () {
                setState(() {
                  _focusedMonth = DateTime(
                    _focusedMonth.year,
                    _focusedMonth.month + 1,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- Calendar grid ----------------

  Widget _buildCalendarGrid() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month);

    final startWeekday = firstOfMonth.weekday;
    final daysInMonth = DateTime(
      _focusedMonth.year,
      _focusedMonth.month + 1,
      0,
    ).day;

    final tiles = <Widget>[];

    // padding before month start
    for (int i = 1; i < startWeekday; i++) {
      tiles.add(const SizedBox.shrink());
    }

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(_focusedMonth.year, _focusedMonth.month, d);

      final hasEvents = _events.any(
        (e) =>
            e.dateTime.year == date.year &&
            e.dateTime.month == date.month &&
            e.dateTime.day == date.day,
      );

      final isSelected =
          _selectedDate != null &&
          _selectedDate!.year == date.year &&
          _selectedDate!.month == date.month &&
          _selectedDate!.day == date.day;

      tiles.add(
        InkWell(
          onTap: () {
            setState(() => _selectedDate = date);
          },
          child: GlassCard(
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  Text(
                    '$d',
                    style: GoogleFonts.spaceGrotesk(
                      color: Colors.white,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w500,
                    ),
                  ),
                  if (hasEvents)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Colors.tealAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: 7,
        physics: const NeverScrollableScrollPhysics(),
        children: tiles,
      ),
    );
  }

  // ---------------- Event list ----------------

  Widget _buildEventsList() {
    if (_filteredEvents.isEmpty) {
      return Center(
        child: GlassCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'event_calendar_no_events'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredEvents.length,
      itemBuilder: (_, i) => _buildEventTile(_filteredEvents[i]),
    );
  }

  Widget _buildEventTile(ArtbeatEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassCard(
        child: ListTile(
          title: Text(
            event.title,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${intl.DateFormat('h:mm a').format(event.dateTime)}  •  ${event.location}',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              '/events/detail',
              arguments: {'eventId': event.id},
            );
          },
        ),
      ),
    );
  }
}
