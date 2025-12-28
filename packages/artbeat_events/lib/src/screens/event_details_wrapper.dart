import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:artbeat_core/artbeat_core.dart';

import '../models/artbeat_event.dart';
import '../services/event_service.dart';
import 'event_details_screen.dart';

/// Wrapper screen that loads an event by ID and displays EventDetailsScreen
/// Uses Local ARTbeat visual language (glass panels, dark world background)
class EventDetailsWrapper extends StatefulWidget {
  final String eventId;

  const EventDetailsWrapper({super.key, required this.eventId});

  @override
  State<EventDetailsWrapper> createState() => _EventDetailsWrapperState();
}

class _EventDetailsWrapperState extends State<EventDetailsWrapper> {
  final EventService _eventService = EventService();

  ArtbeatEvent? _event;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEvent();
  }

  Future<void> _loadEvent() async {
    try {
      final event = await _eventService.getEvent(widget.eventId);

      if (!mounted) return;

      setState(() {
        _event = event;
        _isLoading = false;
      });
    } on Exception catch (e) {
      if (!mounted) return;

      setState(() {
        _error = '${'event_wrap_load_error'.tr()}: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If successfully loaded → go straight to details screen
    if (!_isLoading && _error == null && _event != null) {
      return EventDetailsScreen(eventId: _event!.id);
    }

    return MainLayout(
      currentIndex: 4,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 4),
        child: EnhancedUniversalHeader(
          title: _resolveTitle(),
          showLogo: false,
          showBackButton: true,
          backgroundColor: Colors.transparent,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: _buildStateContent()),
      ),
    );
  }

  // ---- Helper UI blocks ----

  String _resolveTitle() {
    if (_isLoading) return 'event_wrap_loading'.tr();
    if (_error != null) return 'event_wrap_not_found'.tr();
    if (_event == null) return 'event_wrap_not_found'.tr();
    return 'event_wrap_loading'.tr();
  }

  Widget _buildStateContent() {
    if (_isLoading) {
      return const CircularProgressIndicator();
    }

    if (_error != null) {
      return _GlassPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Colors.redAccent),
            const SizedBox(height: 14),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('event_wrap_go_back'.tr()),
            ),
          ],
        ),
      );
    }

    if (_event == null) {
      return _GlassPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.event_busy, size: 56, color: Colors.white70),
            const SizedBox(height: 14),
            Text(
              'event_wrap_unavailable'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('event_wrap_go_back'.tr()),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Local glass helper for transitional states
class _GlassPanel extends StatelessWidget {
  final Widget child;

  const _GlassPanel({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            borderRadius: BorderRadius.circular(26),
          ),
          child: child,
        ),
      ),
    );
  }
}
