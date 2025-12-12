import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';
import '../models/refund_policy.dart';
import '../widgets/ticket_type_builder.dart';
import 'package:easy_localization/easy_localization.dart';

/// Form builder for creating and editing ARTbeat events
/// Includes all required fields from the specification
class EventFormBuilder extends StatefulWidget {
  final ArtbeatEvent? initialEvent;
  final Function(ArtbeatEvent) onEventCreated;
  final VoidCallback? onCancel;
  final bool useEnhancedUniversalHeader;
  final bool isLoading;

  const EventFormBuilder({
    super.key,
    this.initialEvent,
    required this.onEventCreated,
    this.onCancel,
    this.useEnhancedUniversalHeader = false,
    this.isLoading = false,
  });

  @override
  State<EventFormBuilder> createState() => _EventFormBuilderState();
}

class _EventFormBuilderState extends State<EventFormBuilder> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final _maxAttendeesController = TextEditingController();

  DateTime? _selectedDateTime;
  final List<File> _eventImages = [];
  File? _artistHeadshot;
  File? _eventBanner;
  List<TicketType> _ticketTypes = [];
  RefundPolicy _refundPolicy = RefundPolicy.standard();
  bool _isPublic = true;
  bool _reminderEnabled = true;
  List<String> _tags = [];

  // Recurring event fields
  bool _isRecurring = false;
  String _recurrencePattern = 'daily';
  final _recurrenceIntervalController = TextEditingController(text: '1');
  DateTime? _recurrenceEndDate;
  final List<String> _availableTags = [
    'Art Exhibition',
    'Gallery Opening',
    'Workshop',
    'Artist Talk',
    'Live Performance',
    'Interactive Art',
    'Sculpture',
    'Painting',
    'Photography',
    'Digital Art',
    'Mixed Media',
    'Contemporary Art',
    'Abstract Art',
    'Pop Art',
    'Street Art',
    'Installation',
    'Art Fair',
    'Community Event',
    'Educational',
    'Networking',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.initialEvent != null) {
      final event = widget.initialEvent!;
      _titleController.text = event.title;
      _descriptionController.text = event.description;
      _locationController.text = event.location;
      _contactEmailController.text = event.contactEmail;
      _contactPhoneController.text = event.contactPhone ?? '';
      _maxAttendeesController.text = event.maxAttendees.toString();
      _selectedDateTime = event.dateTime;
      _ticketTypes = List.from(event.ticketTypes);
      _refundPolicy = event.refundPolicy;
      _isPublic = event.isPublic;
      _reminderEnabled = event.reminderEnabled;
      _tags = List.from(event.tags);
      _isRecurring = event.isRecurring;
      _recurrencePattern = event.recurrencePattern ?? 'daily';
      _recurrenceIntervalController.text =
          event.recurrenceInterval?.toString() ?? '1';
      _recurrenceEndDate = event.recurrenceEndDate;
    } else {
      _maxAttendeesController.text = '100';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    _maxAttendeesController.dispose();
    _recurrenceIntervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.useEnhancedUniversalHeader
          ? PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight + 4),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      core.ArtbeatColors.primaryPurple,
                      core.ArtbeatColors.primaryGreen,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: core.EnhancedUniversalHeader(
                  title: widget.initialEvent == null
                      ? 'Create Event'
                      : 'Edit Event',
                  showLogo: false,
                  showDeveloperTools: true,
                  showBackButton: true,
                  onBackPressed: () => Navigator.of(context).pop(),
                  onSearchPressed: (query) => _showSearchModal(context),
                  onProfilePressed: () => _showProfileMenu(context),
                  onDeveloperPressed: () => _showDeveloperTools(context),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                ),
              ),
            )
          : AppBar(
              title: Text(
                widget.initialEvent == null
                    ? 'events_create_event'.tr()
                    : 'events_edit_event'.tr(),
              ),
            ),
      body: Container(
        decoration: widget.useEnhancedUniversalHeader
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    core.ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
                    core.ArtbeatColors.backgroundPrimary,
                    core.ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                  ],
                ),
              )
            : null,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 20),
                _buildImageSection(),
                const SizedBox(height: 20),
                _buildDateTimeSection(),
                const SizedBox(height: 20),
                _buildLocationSection(),
                const SizedBox(height: 20),
                _buildContactSection(),
                const SizedBox(height: 20),
                _buildCapacitySection(),
                const SizedBox(height: 20),
                _buildTicketTypesSection(),
                const SizedBox(height: 20),
                _buildRefundPolicySection(),
                const SizedBox(height: 20),
                _buildSettingsSection(),
                const SizedBox(height: 20),
                _buildRecurringEventSection(),
                const SizedBox(height: 20),
                _buildTagsSection(),
                const SizedBox(height: 32),
                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: widget.isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: core.ArtbeatColors.primaryPurple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: widget.isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            widget.initialEvent == null
                                ? 'events_create_event'.tr()
                                : 'events_update_event'.tr(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: core.ArtbeatColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: core.ArtbeatColors.border),
        boxShadow: [
          BoxShadow(
            color: core.ArtbeatColors.primaryPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_basic_information'.tr(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: core.ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'events_event_title'.tr(),
              hintText: 'events_enter_event_title'.tr(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an event title';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: 'events_event_description'.tr(),
              hintText: 'events_describe_event'.tr(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an event description';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'events_event_images'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Artist Headshot
            _buildImageUploadSection(
              title: 'events_artist_headshot'.tr(),
              image: _artistHeadshot,
              onImageSelected: (file) => setState(() => _artistHeadshot = file),
            ),
            const SizedBox(height: 16),

            // Event Banner
            _buildImageUploadSection(
              title: 'events_event_banner'.tr(),
              image: _eventBanner,
              onImageSelected: (file) => setState(() => _eventBanner = file),
            ),
            const SizedBox(height: 16),

            // Additional Event Images
            Text('events_additional_images'.tr()),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._eventImages.map(
                  (image) => _buildImagePreview(image, () {
                    setState(() => _eventImages.remove(image));
                  }),
                ),
                _buildAddImageButton(() async {
                  final image = await _imagePicker.pickImage(
                    source: ImageSource.gallery,
                  );
                  if (image != null) {
                    setState(() => _eventImages.add(File(image.path)));
                  }
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageUploadSection({
    required String title,
    required File? image,
    required Function(File?) onImageSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final pickedImage = await _imagePicker.pickImage(
              source: ImageSource.gallery,
            );
            if (pickedImage != null) {
              onImageSelected(File(pickedImage.path));
            }
          },
          child: Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: image != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_photo_alternate,
                        size: 48,
                        color: Colors.grey,
                      ),
                      Text('events_tap_to_select_image'.tr()),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(File image, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(image, width: 80, height: 80, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add, color: Colors.grey),
            Text('events_add'.tr(), style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                _selectedDateTime != null
                    ? DateFormat(
                        'EEEE, MMMM d, y \'at\' h:mm a',
                      ).format(_selectedDateTime!)
                    : 'Select date and time *',
              ),
              onTap: _selectDateTime,
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Event Location *',
                hintText: 'Enter venue address or location',
                prefixIcon: Icon(Icons.location_on),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter event location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactEmailController,
              decoration: const InputDecoration(
                labelText: 'Contact Email *',
                hintText: 'Enter contact email',
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter contact email';
                }
                if (!value.contains('@')) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contactPhoneController,
              decoration: const InputDecoration(
                labelText: 'Contact Phone (Optional)',
                hintText: 'Enter contact phone number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Capacity',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxAttendeesController,
              decoration: const InputDecoration(
                labelText: 'Maximum Attendees *',
                hintText: 'Enter maximum number of attendees',
                prefixIcon: Icon(Icons.people),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter maximum attendees';
                }
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Tags',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _tags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _tags.add(tag);
                      } else {
                        _tags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketTypesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Ticket Types',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _addTicketType,
                  icon: const Icon(Icons.add),
                  label: Text('events_add_ticket'.tr()),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_ticketTypes.isEmpty)
              const Text(
                'No ticket types added yet. Add at least one ticket type.',
              )
            else
              ..._ticketTypes.asMap().entries.map((entry) {
                final index = entry.key;
                final ticket = entry.value;
                return TicketTypeBuilder(
                  ticketType: ticket,
                  onChanged: (updatedTicket) {
                    setState(() {
                      _ticketTypes[index] = updatedTicket;
                    });
                  },
                  onRemove: () {
                    setState(() {
                      _ticketTypes.removeAt(index);
                    });
                  },
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildRefundPolicySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Refund Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _getRefundPolicyKey(),
              decoration: const InputDecoration(
                labelText: 'Refund Policy',
                filled: true,
                fillColor:
                    core.ArtbeatColors.backgroundPrimary, // match login_screen
                border: OutlineInputBorder(),
              ),
              dropdownColor: core.ArtbeatColors.backgroundPrimary,
              style: const TextStyle(color: core.ArtbeatColors.textPrimary),
              items: const [
                DropdownMenuItem(
                  value: 'standard',
                  child: Text(
                    'Standard (24 hours)',
                    style: TextStyle(color: core.ArtbeatColors.textPrimary),
                  ),
                ),
                DropdownMenuItem(
                  value: 'flexible',
                  child: Text(
                    'Flexible (7 days)',
                    style: TextStyle(color: core.ArtbeatColors.textPrimary),
                  ),
                ),
                DropdownMenuItem(
                  value: 'no_refunds',
                  child: Text(
                    'No Refunds',
                    style: TextStyle(color: core.ArtbeatColors.textPrimary),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  switch (value) {
                    case 'standard':
                      _refundPolicy = RefundPolicy.standard();
                      break;
                    case 'flexible':
                      _refundPolicy = RefundPolicy.flexible();
                      break;
                    case 'no_refunds':
                      _refundPolicy = RefundPolicy.noRefunds();
                      break;
                  }
                });
              },
            ),
            const SizedBox(height: 8),
            Text(
              _refundPolicy.fullDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Event Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('events_public_event'.tr()),
              subtitle: Text('events_show_in_feed'.tr()),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              contentPadding: EdgeInsets.zero,
            ),
            SwitchListTile(
              title: Text('events_enable_reminders'.tr()),
              subtitle: Text('events_send_reminders'.tr()),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringEventSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recurring Event',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text('events_repeat_event'.tr()),
              subtitle: Text('events_create_recurring'.tr()),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
              contentPadding: EdgeInsets.zero,
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _recurrencePattern,
                decoration: const InputDecoration(
                  labelText: 'Repeat Pattern',
                  filled: true,
                  fillColor: core.ArtbeatColors.backgroundPrimary,
                  border: OutlineInputBorder(),
                ),
                dropdownColor: core.ArtbeatColors.backgroundPrimary,
                style: const TextStyle(color: core.ArtbeatColors.textPrimary),
                items: const [
                  DropdownMenuItem(
                    value: 'daily',
                    child: Text(
                      'Daily',
                      style: TextStyle(color: core.ArtbeatColors.textPrimary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(
                      'Weekly',
                      style: TextStyle(color: core.ArtbeatColors.textPrimary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text(
                      'Monthly',
                      style: TextStyle(color: core.ArtbeatColors.textPrimary),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text(
                      'Custom',
                      style: TextStyle(color: core.ArtbeatColors.textPrimary),
                    ),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recurrencePattern = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _recurrenceIntervalController,
                decoration: InputDecoration(
                  labelText: 'Repeat Every',
                  hintText: 'Enter interval',
                  suffixText: _recurrencePattern == 'daily'
                      ? 'day(s)'
                      : _recurrencePattern == 'weekly'
                      ? 'week(s)'
                      : _recurrencePattern == 'monthly'
                      ? 'month(s)'
                      : 'unit(s)',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_isRecurring) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an interval';
                    }
                    final interval = int.tryParse(value);
                    if (interval == null || interval < 1) {
                      return 'Please enter a valid number (1 or greater)';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('events_end_date'.tr()),
                subtitle: Text(
                  _recurrenceEndDate != null
                      ? '${_recurrenceEndDate!.month}/${_recurrenceEndDate!.day}/${_recurrenceEndDate!.year}'
                      : 'No end date (continues indefinitely)',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_recurrenceEndDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _recurrenceEndDate = null);
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: _selectRecurrenceEndDate,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _selectRecurrenceEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _recurrenceEndDate ??
          (_selectedDateTime ?? DateTime.now()).add(const Duration(days: 30)),
      firstDate: _selectedDateTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)), // 2 years
    );

    if (date != null) {
      setState(() => _recurrenceEndDate = date);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _selectedDateTime ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(
          _selectedDateTime ?? DateTime.now(),
        ),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _addTicketType() {
    // Add a default free ticket type
    final newTicket = TicketType.free(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'General Admission',
      quantity: 50,
    );

    setState(() {
      _ticketTypes.add(newTicket);
    });
  }

  String _getRefundPolicyKey() {
    if (_refundPolicy.fullRefundDeadline == const Duration(hours: 24)) {
      return 'standard';
    } else if (_refundPolicy.fullRefundDeadline == const Duration(days: 7)) {
      return 'flexible';
    } else {
      return 'no_refunds';
    }
  }

  // Helper to upload a file to Firebase Storage and get its download URL
  Future<String> _uploadImageToStorage(File file, String path) async {
    try {
      if (kIsWeb) {
        // For web, try the native Firebase Storage SDK first, fallback to REST API
        try {
          debugPrint('Attempting web upload using Firebase SDK for $path');
          final bytes = await file.readAsBytes();
          final storageRef = FirebaseStorage.instance.ref().child(path);

          // Use putData for web with bytes
          final uploadTask = await storageRef.putData(
            bytes,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploadedBy': 'artbeat_app',
                'uploadTime': DateTime.now().toIso8601String(),
              },
            ),
          );

          final downloadUrl = await uploadTask.ref.getDownloadURL();
          debugPrint('Successfully uploaded using Firebase SDK: $downloadUrl');
          return downloadUrl;
        } on Exception catch (sdkError) {
          debugPrint('Firebase SDK upload failed, trying REST API: $sdkError');

          // Fallback to REST API with better error handling
          final bytes = await file.readAsBytes();
          debugPrint('Uploading ${bytes.length} bytes to $path via REST API');

          // Get Firebase Auth token
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception('User not authenticated');
          }
          final token = await user.getIdToken();

          // Get storage bucket name
          final bucket = FirebaseStorage.instance.ref().bucket;

          // Encode path for URL
          final encodedPath = Uri.encodeComponent(path);

          // Upload using Firebase Storage REST API
          final uploadUrl =
              'https://firebasestorage.googleapis.com/v0/b/$bucket/o?name=$encodedPath';

          final response = await http.post(
            Uri.parse(uploadUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'image/jpeg',
            },
            body: bytes,
          );

          debugPrint('REST API Response status: ${response.statusCode}');
          debugPrint('REST API Response body: ${response.body}');

          if (response.statusCode != 200) {
            debugPrint(
              'Upload failed with status ${response.statusCode}: ${response.body}',
            );
            throw Exception(
              'Upload failed: ${response.statusCode} - ${response.body}',
            );
          }

          debugPrint('Upload complete, parsing response...');

          // Add better error handling for JSON parsing
          Map<String, dynamic> responseData;
          try {
            responseData = json.decode(response.body) as Map<String, dynamic>;
          } catch (parseError) {
            debugPrint('JSON parsing failed: $parseError');
            debugPrint('Raw response: ${response.body}');
            throw Exception('Failed to parse response JSON: $parseError');
          }

          // Construct download URL from response
          final downloadToken = responseData['downloadTokens'] as String?;
          if (downloadToken == null) {
            debugPrint('Response data: $responseData');
            throw Exception('No download token in response');
          }

          final downloadUrl =
              'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media&token=$downloadToken';
          debugPrint('Download URL: $downloadUrl');
          return downloadUrl;
        }
      } else {
        // For mobile, use putFile with better error handling
        try {
          debugPrint('Uploading file for mobile: $path');
          final storageRef = FirebaseStorage.instance.ref().child(path);

          // Add metadata for mobile uploads too
          final uploadTask = await storageRef.putFile(
            file,
            SettableMetadata(
              contentType: 'image/jpeg',
              customMetadata: {
                'uploadedBy': 'artbeat_app',
                'uploadTime': DateTime.now().toIso8601String(),
              },
            ),
          );

          final downloadUrl = await uploadTask.ref.getDownloadURL();
          debugPrint('Mobile upload successful: $downloadUrl');
          return downloadUrl;
        } on FirebaseException catch (firebaseError) {
          debugPrint(
            'Firebase mobile upload failed: ${firebaseError.code} - ${firebaseError.message}',
          );

          // Try alternative approach for mobile - using putData
          try {
            debugPrint('Trying mobile upload with putData approach...');
            final bytes = await file.readAsBytes();
            final storageRef = FirebaseStorage.instance.ref().child(path);

            final uploadTask = await storageRef.putData(
              bytes,
              SettableMetadata(
                contentType: 'image/jpeg',
                customMetadata: {
                  'uploadedBy': 'artbeat_app',
                  'uploadTime': DateTime.now().toIso8601String(),
                },
              ),
            );

            final downloadUrl = await uploadTask.ref.getDownloadURL();
            debugPrint('Mobile putData upload successful: $downloadUrl');
            return downloadUrl;
          } catch (putDataError) {
            debugPrint('Mobile putData also failed: $putDataError');
            rethrow;
          }
        }
      }
    } catch (e, stackTrace) {
      debugPrint('Error uploading image to $path: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_fill_required'.tr())));
      return;
    }

    if (_selectedDateTime == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_select_date'.tr())));
      return;
    }

    if (_artistHeadshot == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_select_headshot'.tr())));
      return;
    }

    if (_eventBanner == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_select_banner'.tr())));
      return;
    }

    if (_ticketTypes.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_add_ticket_type'.tr())));
      return;
    }

    // Upload images to Firebase Storage and get URLs
    // Get current user ID from UserService
    final userId = core.UserService().currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_not_logged_in'.tr())));
      return;
    }
    final eventId =
        widget.initialEvent?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    String headshotUrl = '';
    String bannerUrl = '';
    List<String> imageUrls = [];
    try {
      // Use debug_uploads path for more reliable web uploads
      headshotUrl = await _uploadImageToStorage(
        _artistHeadshot!,
        'debug_uploads/events/$userId/$eventId/headshot.jpg',
      );
      bannerUrl = await _uploadImageToStorage(
        _eventBanner!,
        'debug_uploads/events/$userId/$eventId/banner.jpg',
      );
      imageUrls = await Future.wait(
        _eventImages.asMap().entries.map(
          (entry) => _uploadImageToStorage(
            entry.value,
            'debug_uploads/events/$userId/$eventId/image_${entry.key}.jpg',
          ),
        ),
      );
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'events_upload_failed'.tr().replaceAll('{error}', e.toString()),
            ),
          ),
        );
      }
      return;
    }

    final event =
        widget.initialEvent?.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageUrls: imageUrls,
          artistHeadshotUrl: headshotUrl,
          eventBannerUrl: bannerUrl,
          dateTime: _selectedDateTime!,
          location: _locationController.text.trim(),
          ticketTypes: _ticketTypes,
          refundPolicy: _refundPolicy,
          reminderEnabled: _reminderEnabled,
          isPublic: _isPublic,
          maxAttendees: int.parse(_maxAttendeesController.text),
          tags: _tags,
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim().isEmpty
              ? null
              : _contactPhoneController.text.trim(),
          isRecurring: _isRecurring,
          recurrencePattern: _isRecurring ? _recurrencePattern : null,
          recurrenceInterval: _isRecurring
              ? int.tryParse(_recurrenceIntervalController.text)
              : null,
          recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
        ) ??
        ArtbeatEvent.create(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          artistId: userId,
          imageUrls: imageUrls,
          artistHeadshotUrl: headshotUrl,
          eventBannerUrl: bannerUrl,
          dateTime: _selectedDateTime!,
          location: _locationController.text.trim(),
          ticketTypes: _ticketTypes,
          refundPolicy: _refundPolicy,
          reminderEnabled: _reminderEnabled,
          isPublic: _isPublic,
          maxAttendees: int.parse(_maxAttendeesController.text),
          tags: _tags,
          contactEmail: _contactEmailController.text.trim(),
          contactPhone: _contactPhoneController.text.trim().isEmpty
              ? null
              : _contactPhoneController.text.trim(),
          isRecurring: _isRecurring,
          recurrencePattern: _isRecurring ? _recurrencePattern : null,
          recurrenceInterval: _isRecurring
              ? int.tryParse(_recurrenceIntervalController.text)
              : null,
          recurrenceEndDate: _isRecurring ? _recurrenceEndDate : null,
        );

    widget.onEventCreated(event);
  }

  void _showSearchModal(BuildContext context) {
    // Placeholder for search functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('events_search_unavailable'.tr())));
  }

  void _showProfileMenu(BuildContext context) {
    // Placeholder for profile menu
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('events_profile_unavailable'.tr())));
  }

  void _showDeveloperTools(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              const Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(
                      Icons.developer_mode,
                      color: core.ArtbeatColors.primaryPurple,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Developer Tools',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: core.ArtbeatColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Developer options
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDeveloperOption(
                      icon: Icons.bug_report,
                      title: 'Form Debug Info',
                      subtitle: 'View current form state',
                      color: core.ArtbeatColors.primaryPurple,
                      onTap: () => _showFormDebugInfo(context),
                    ),
                    _buildDeveloperOption(
                      icon: Icons.data_object,
                      title: 'Event Data Preview',
                      subtitle: 'Preview event JSON structure',
                      color: core.ArtbeatColors.primaryGreen,
                      onTap: () => _showEventDataPreview(context),
                    ),
                    _buildDeveloperOption(
                      icon: Icons.storage,
                      title: 'Firebase Storage',
                      subtitle: 'Check image upload paths',
                      color: core.ArtbeatColors.secondaryTeal,
                      onTap: () => _showStorageInfo(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeveloperOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: core.ArtbeatColors.textPrimary,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: core.ArtbeatColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFormDebugInfo(BuildContext context) {
    Navigator.pop(context); // Close developer tools
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('events_form_debug'.tr()),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Title: ${_titleController.text}'),
              Text('Description: ${_descriptionController.text}'),
              Text('Location: ${_locationController.text}'),
              Text('Date: ${_selectedDateTime?.toString() ?? 'Not set'}'),
              Text('Event Images: ${_eventImages.length}'),
              Text('Has Headshot: ${_artistHeadshot != null}'),
              Text('Has Banner: ${_eventBanner != null}'),
              Text('Ticket Types: ${_ticketTypes.length}'),
              Text('Tags: ${_tags.join(', ')}'),
              Text('Is Public: $_isPublic'),
              Text('Reminder Enabled: $_reminderEnabled'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showEventDataPreview(BuildContext context) {
    Navigator.pop(context); // Close developer tools
    // This would show a preview of the event data structure
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('events_preview_coming'.tr())));
  }

  void _showStorageInfo(BuildContext context) {
    Navigator.pop(context); // Close developer tools
    // This would show Firebase Storage path information
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('events_storage_coming'.tr())));
  }
}
