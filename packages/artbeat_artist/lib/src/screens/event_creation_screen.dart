import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../services/event_service_adapter.dart';

/// Screen for creating and editing events (for Pro and Gallery plans)
class EventCreationScreen extends StatefulWidget {
  final String? eventId; // Null for new event, non-null for editing

  const EventCreationScreen({
    super.key,
    this.eventId,
  });

  @override
  State<EventCreationScreen> createState() => _EventCreationScreenState();
}

class _EventCreationScreenState extends State<EventCreationScreen> {
  final EventServiceAdapter _eventService = EventServiceAdapter();
  final core.SubscriptionService _subscriptionService =
      core.SubscriptionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _imagePicker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _startTime = TimeOfDay.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _endTime = TimeOfDay.now();

  bool _isPublic = true;
  bool _isLoading = false;
  bool _canCreateEvents = false;
  String? _errorMessage;
  File? _imageFile;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _checkSubscriptionStatus();
    if (widget.eventId != null) {
      _loadExistingEvent();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  /// Check if user's subscription allows event creation
  Future<void> _checkSubscriptionStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final subscription = await _subscriptionService.getUserSubscription();
      final canCreateEvents = subscription != null &&
          (subscription.tier == core.SubscriptionTier.creator ||
              subscription.tier == core.SubscriptionTier.business ||
              subscription.tier == core.SubscriptionTier.enterprise) &&
          subscription.isActive;

      setState(() {
        _canCreateEvents = canCreateEvents;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error checking subscription status: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Load existing event data for editing
  Future<void> _loadExistingEvent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final eventModel = await _eventService.getEventById(widget.eventId!);

      // Check if user has permission to edit
      if (eventModel.artistId != _auth.currentUser?.uid) {
        throw Exception('Permission denied');
      }

      _titleController.text = eventModel.title;
      _descriptionController.text = eventModel.description;
      _locationController.text = eventModel.location;
      _startDate = eventModel.startDate;
      _startTime = TimeOfDay.fromDateTime(eventModel.startDate);
      _isPublic = eventModel.isPublic;
      _existingImageUrl = eventModel.imageUrl;

      if (eventModel.endDate != null) {
        _endDate = eventModel.endDate!;
        _endTime = TimeOfDay.fromDateTime(eventModel.endDate!);
      }

      // ArtbeatEvent doesn't have endDate, we'll use the same date
      // This is a limitation we need to address in a proper migration
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading event: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  /// Select event image from gallery
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 800,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  tr('artist_event_creation_error_error_selecting_image'))),
        );
      }
    }
  }

  /// Select date from date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate = isStartDate ? _startDate : _endDate;
    final DateTime firstDate = isStartDate ? DateTime.now() : _startDate;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, update it
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  /// Select time from time picker
  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay initialTime = isStartTime ? _startTime : _endTime;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // If same day and end time is before start time, update it
          if (_startDate.year == _endDate.year &&
              _startDate.month == _endDate.month &&
              _startDate.day == _endDate.day &&
              _endTime.hour < _startTime.hour) {
            _endTime = TimeOfDay(
              hour: _startTime.hour + 1,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  /// Save event changes
  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) {
      // Show validation error message
      setState(() {
        _errorMessage = 'Please fill in all required fields correctly.';
      });
      return;
    }

    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      // Convert TimeOfDay to DateTime
      final startDateTime = DateTime(
        _startDate.year,
        _startDate.month,
        _startDate.day,
        _startTime.hour,
        _startTime.minute,
      );

      final endDateTime = DateTime(
        _endDate.year,
        _endDate.month,
        _endDate.day,
        _endTime.hour,
        _endTime.minute,
      );

      if (endDateTime.isBefore(startDateTime)) {
        throw Exception('End time cannot be before start time');
      }

      // Update existing event
      if (widget.eventId != null) {
        await _eventService.updateEvent(
          eventId: widget.eventId!,
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: startDateTime,
          endDate: endDateTime,
          location: _locationController.text,
          isPublic: _isPublic,
          imageFile: _imageFile,
        );
      } else {
        // Create new event
        await _eventService.createEvent(
          title: _titleController.text,
          description: _descriptionController.text,
          startDate: startDateTime,
          endDate: endDateTime,
          location: _locationController.text,
          isPublic: _isPublic,
          imageFile: _imageFile,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'artist_event_creation_success_event_saved_successfully'
                      .tr())),
        );
        Navigator.of(context).pop(true); // Return true to trigger refresh
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving event: ${e.toString()}';
        _isLoading = false;
      });
    } finally {
      // Ensure loading state is reset even if navigation fails
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('artist_event_creation_text_event'))),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Show upgrade prompt if user can't create events
    if (!_canCreateEvents) {
      return Scaffold(
        appBar: AppBar(
            title: Text(tr('artist_artist_dashboard_text_create_event'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.event_busy,
                  size: 80,
                  color: Colors.grey,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Event Creation',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _errorMessage ??
                      'Event creation is available with Artist Pro or Gallery Plan.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/artist/subscription');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  child: Text(tr('artist_event_creation_text_upgrade_to_pro')),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return core.MainLayout(
      currentIndex: 2, // Events tab in bottom navigation
      appBar: core.EnhancedUniversalHeader(
        title: widget.eventId == null ? 'Create Event' : 'Edit Event',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: false,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveEvent,
            child: Text(_isLoading ? 'SAVING...' : 'SAVE'),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),

              // Event cover image
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _imageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _existingImageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _existingImageUrl!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  size: 50,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(tr('art_walk_add_cover_image'),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),

              const SizedBox(height: 24),

              // Event title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an event title';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Event dates
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('art_walk_start_date'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                Text(DateFormat('MMM d, yyyy')
                                    .format(_startDate)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('art_walk_end_date'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                    DateFormat('MMM d, yyyy').format(_endDate)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Event times
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('art_walk_start_time'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 18),
                                const SizedBox(width: 8),
                                Text(_startTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tr('art_walk_end_time'),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectTime(context, false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 18),
                                const SizedBox(width: 8),
                                Text(_endTime.format(context)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a location';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Public/Private toggle
              SwitchListTile(
                title: Text(tr('artist_event_creation_text_public_event')),
                subtitle: const Text(
                    'Allow others to see and register for this event'),
                value: _isPublic,
                onChanged: (value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEvent,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.eventId == null
                              ? 'Create Event'
                              : 'Update Event',
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
