import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:share_plus/share_plus.dart';
import 'package:logger/logger.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:artbeat_core/shared_widgets.dart';

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
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            widget.editEvent == null
                ? 'events_create_event'.tr()
                : 'events_edit_event'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: WorldBackground(
          child: SafeArea(
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GlassCard(
                    child: EventFormBuilder(
                      initialEvent: widget.editEvent,
                      onEventCreated: _handleEventCreated,
                      onCancel: () => Navigator.pop(context),
                      useEnhancedUniversalHeader: true,
                      isLoading: _isLoading,
                    ),
                  ),
                ),
                if (_isLoading) _buildLoadingOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.3),
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: Color(0xFF22D3EE)),
              const SizedBox(height: 16),
              Text(
                'events_creating'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit
                    ? 'events_updated_title'.tr()
                    : 'events_created_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit
                    ? 'events_updated_success'.tr()
                    : 'events_created_success'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (!isEdit) ...[
                Text(
                  'events_next_action'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 24),
              ] else
                const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!isEdit) ...[
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        _shareEvent(eventId);
                      },
                      child: Text(
                        'events_share_button'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF22D3EE),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context);
                        _viewEvent(eventId);
                      },
                      child: Text(
                        'events_view_button'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          color: const Color(0xFF22D3EE),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  GradientCTAButton(
                    text: 'events_done_button'.tr(),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    width: 100,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'events_error_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${'events_failed_save'.tr()}$error',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.spaceGrotesk(
                      color: const Color(0xFF22D3EE),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'events_unsaved_changes'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You have unsaved changes. Are you sure you want to leave?',
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () =>
                        Navigator.pop(context), // Close dialog only
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Go back
                    },
                    child: Text(
                      'Leave',
                      style: GoogleFonts.spaceGrotesk(
                        color: const Color(0xFFFF3D8D),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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
    Navigator.pushNamed(
      context,
      '/events/detail',
      arguments: {'eventId': eventId},
    );
  }
}
