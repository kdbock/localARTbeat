import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/artbeat_event.dart';
import '../forms/event_form_builder.dart';
import '../services/event_service.dart';
import '../services/event_notification_service.dart';

/// Screen for creating new events
class CreateEventScreen extends StatefulWidget {
  final ArtbeatEvent? editEvent; // If editing an existing event

  const CreateEventScreen({super.key, this.editEvent});

  @override
  State<CreateEventScreen> createState() => _CreateEventScreenState();
}

class _CreateEventScreenState extends State<CreateEventScreen> {
  final EventService _eventService = EventService();
  final EventNotificationService _notificationService =
      EventNotificationService();
  final Logger _logger = Logger();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLoading,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isLoading) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            EventFormBuilder(
              initialEvent: widget.editEvent,
              onEventCreated: _handleEventCreated,
              onCancel: () => Navigator.pop(context),
              useEnhancedUniversalHeader:
                  true, // Tell the form builder to use universal header
              isLoading: _isLoading,
            ),
            if (_isLoading) _buildLoadingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 16),
            Text(
              'events_creating'.tr(),
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleEventCreated(ArtbeatEvent event) async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      String eventId;

      if (widget.editEvent != null) {
        // Update existing event
        await _eventService.updateEvent(event);
        eventId = event.id;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('events_updated_success'.tr()),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new event
        eventId = await _eventService.createEvent(event);

        // Schedule event reminders if enabled
        String successMessage = 'events_created_success'.tr();
        if (event.reminderEnabled) {
          try {
            // Initialize notification service first
            await _notificationService.initialize();
            await _notificationService.requestPermissions();

            final updatedEvent = event.copyWith(id: eventId);
            await _notificationService.scheduleEventReminders(updatedEvent);
          } on Exception catch (notificationError) {
            _logger.e('Failed to schedule reminders: $notificationError');
            successMessage =
                'Event created successfully! (Reminder notifications require permission)';
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      // Show success dialog with options
      if (mounted) {
        _showSuccessDialog(eventId, widget.editEvent != null);
      }
    } on Exception catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(e.toString());
      }
    }
  }

  void _showSuccessDialog(String eventId, bool isEdit) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          isEdit ? 'events_updated_title'.tr() : 'events_created_title'.tr(),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEdit
                  ? 'events_updated_success'.tr()
                  : 'events_created_success'.tr(),
            ),
            const SizedBox(height: 16),
            if (!isEdit) ...[
              Text('events_next_action'.tr()),
              const SizedBox(height: 16),
            ],
          ],
        ),
        actions: [
          if (!isEdit) ...[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                _shareEvent(eventId);
              },
              child: Text('events_share_button'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
                _viewEvent(eventId);
              },
              child: Text('events_view_button'.tr()),
            ),
          ],
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('events_done_button'.tr()),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('events_error_title'.tr()),
        content: Text('${'events_failed_save'.tr()}$error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('events_unsaved_changes'.tr()),
        content: const Text(
          'You have unsaved changes. Are you sure you want to leave?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Close dialog only
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _shareEvent(String eventId) {
    final eventUrl = 'https://artbeat.app/events/$eventId';
    SharePlus.instance.share(
      ShareParams(text: 'Check out this event on ARTbeat! $eventUrl'),
    );
  }

  void _viewEvent(String eventId) {
    Navigator.pushNamed(context, '/event/$eventId');
  }
}
