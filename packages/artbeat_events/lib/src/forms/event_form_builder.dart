import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:image_picker/image_picker.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/artbeat_event.dart';
import '../models/ticket_type.dart';
import '../models/refund_policy.dart';
import '../widgets/ticket_type_builder.dart';

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

  // Helper method for glass input decoration
  InputDecoration _glassInputDecoration(
    String label, {
    String? hint,
    IconData? icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffixText,
      labelStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w600,
      ),
      hintStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white.withValues(alpha: 0.45),
        fontWeight: FontWeight.w500,
      ),
      suffixStyle: GoogleFonts.spaceGrotesk(
        color: Colors.white.withValues(alpha: 0.7),
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.12),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF22D3EE), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF3D8D), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFF3D8D), width: 2),
      ),
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF22D3EE))
          : null,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  List<TicketType> _ticketTypes = [];
  RefundPolicy _refundPolicy = RefundPolicy.standard();
  bool _isPublic = true;
  bool _reminderEnabled = true;
  List<String> _tags = [];
  String _category = 'Tour';
  String _artistHeadshotFit = 'cover';
  String _eventBannerFit = 'cover';
  String _imageFit = 'cover';
  final List<String> _categories = [
    'Tour',
    'Exhibition',
    'Workshop',
    'Opening',
    'Fair',
    'Class',
    'Performance',
    'Talk',
    'Networking',
    'Other',
  ];

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
      _category = event.category;
      _artistHeadshotFit = event.artistHeadshotFit;
      _eventBannerFit = event.eventBannerFit;
      _imageFit = event.imageFit;
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
    return Form(
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
            GradientCTAButton(
              text: widget.isLoading
                  ? 'events_creating'.tr()
                  : (widget.initialEvent == null
                        ? 'events_create_event'.tr()
                        : 'events_update_event'.tr()),
              onPressed: widget.isLoading ? null : _submitForm,
              width: double.infinity,
              height: 56,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'events_basic_information'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: _glassInputDecoration(
              'events_event_title'.tr(),
              hint: 'events_enter_event_title'.tr(),
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
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: _glassInputDecoration(
              'events_event_description'.tr(),
              hint: 'events_describe_event'.tr(),
            ),
            maxLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter an event description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          // Category Dropdown
          DropdownButtonFormField<String>(
            initialValue: _category,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            dropdownColor: Colors.grey[900],
            decoration: _glassInputDecoration('Category'),
            items: _categories.map((String category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (String? newValue) {
              if (newValue != null) {
                setState(() {
                  _category = newValue;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  BoxFit _getBoxFit(String fit) {
    switch (fit) {
      case 'cover':
        return BoxFit.cover;
      case 'contain':
        return BoxFit.contain;
      case 'fill':
        return BoxFit.fill;
      case 'fitWidth':
        return BoxFit.fitWidth;
      case 'fitHeight':
        return BoxFit.fitHeight;
      case 'scaleDown':
        return BoxFit.scaleDown;
      case 'none':
        return BoxFit.none;
      default:
        return BoxFit.cover;
    }
  }

  Widget _buildFitSelector(String currentFit, Function(String) onChanged) {
    return DropdownButton<String>(
      value: currentFit,
      dropdownColor: Colors.grey[900],
      style: GoogleFonts.spaceGrotesk(color: Colors.white, fontSize: 12),
      underline: const SizedBox(),
      items: [
        'cover',
        'contain',
        'fill',
        'fitWidth',
        'fitHeight',
        'scaleDown',
        'none'
      ].map((fit) {
        return DropdownMenuItem<String>(
          value: fit,
          child: Text(fit.toUpperCase()),
        );
      }).toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }

  Widget _buildImageSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'events_event_images'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 16),

            // Artist Headshot
            Row(
              children: [
                Column(
                  children: [
                    Text(
                      'events_artist_headshot'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        final image = await _imagePicker.pickImage(
                            source: ImageSource.gallery);
                        if (image != null) {
                          setState(() => _artistHeadshot = File(image.path));
                        }
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.06),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                            width: 1.5,
                          ),
                        ),
                        child: _artistHeadshot != null
                            ? ClipOval(
                                child: Image.file(
                                  _artistHeadshot!,
                                  fit: _getBoxFit(_artistHeadshotFit),
                                ),
                              )
                            : (widget.initialEvent?.artistHeadshotUrl != null &&
                                    widget.initialEvent!.artistHeadshotUrl
                                        .isNotEmpty)
                                ? ClipOval(
                                    child: Image.network(
                                      widget.initialEvent!.artistHeadshotUrl,
                                      fit: _getBoxFit(_artistHeadshotFit),
                                    ),
                                  )
                                : const Icon(Icons.person,
                                    size: 40, color: Colors.white30),
                      ),
                    ),
                    _buildFitSelector(_artistHeadshotFit, (val) {
                      setState(() => _artistHeadshotFit = val);
                    }),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Artist headshot as seen in app (CircleAvatar). Tap to change.',
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, color: Colors.white38),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Event Banner
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'events_event_banner'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white70,
                      ),
                    ),
                    _buildFitSelector(_eventBannerFit, (val) {
                      setState(() => _eventBannerFit = val);
                    }),
                  ],
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final image = await _imagePicker.pickImage(
                        source: ImageSource.gallery);
                    if (image != null) {
                      setState(() => _eventBanner = File(image.path));
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Container(
                      width: double.infinity,
                      height: 180, // Scaled down from 260 for form usability
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                          width: 1.5,
                        ),
                      ),
                      child: _eventBanner != null
                          ? Image.file(
                              _eventBanner!,
                              fit: _getBoxFit(_eventBannerFit),
                            )
                          : (widget.initialEvent?.eventBannerUrl != null &&
                                  widget.initialEvent!.eventBannerUrl
                                      .isNotEmpty)
                              ? Image.network(
                                  widget.initialEvent!.eventBannerUrl,
                                  fit: _getBoxFit(_eventBannerFit),
                                )
                              : const Center(
                                  child: Icon(Icons.image,
                                      size: 48, color: Colors.white30)),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Event banner as seen in hero section (Rounded 28). Tap to change.',
                  style: GoogleFonts.spaceGrotesk(
                      fontSize: 11, color: Colors.white38),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Additional Event Images
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'events_additional_images'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                _buildFitSelector(_imageFit, (val) {
                  setState(() => _imageFit = val);
                }),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                // Network images if editing
                if (widget.initialEvent != null)
                  ...widget.initialEvent!.imageUrls.map(
                    (url) => Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(url,
                              width: 80, height: 80, fit: _getBoxFit(_imageFit)),
                        ),
                        // Note: For now we don't handle removing existing network images individually in this form
                        // but they are shown to reflect the app appearance
                      ],
                    ),
                  ),
                // New local images
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

  Widget _buildImagePreview(File image, VoidCallback onRemove) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
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
                color: Color(0xFFFF3D8D),
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
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white.withValues(alpha: 0.7)),
            Text(
              'events_add'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date & Time',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _selectDateTime,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today,
                    color: Color(0xFF22D3EE),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _selectedDateTime != null
                          ? intl.DateFormat(
                              'EEEE, MMMM d, y \'at\' h:mm a',
                            ).format(_selectedDateTime!)
                          : 'Select date and time *',
                      style: GoogleFonts.spaceGrotesk(
                        color: _selectedDateTime != null
                            ? Colors.white.withValues(alpha: 0.92)
                            : Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _locationController,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: _glassInputDecoration(
              'Event Location *',
              hint: 'Enter venue address or location',
              icon: Icons.location_on,
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
    );
  }

  Widget _buildContactSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contactEmailController,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: _glassInputDecoration(
              'Contact Email *',
              hint: 'Enter contact email',
              icon: Icons.email,
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
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: _glassInputDecoration(
              'Contact Phone (Optional)',
              hint: 'Enter contact phone number',
              icon: Icons.phone,
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildCapacitySection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Capacity',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxAttendeesController,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            cursorColor: const Color(0xFF22D3EE),
            decoration: _glassInputDecoration(
              'Maximum Attendees *',
              hint: 'Enter maximum number of attendees',
              icon: Icons.people,
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
    );
  }

  Widget _buildTagsSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Event Tags',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _availableTags.map((tag) {
              final isSelected = _tags.contains(tag);
              return FilterChip(
                label: Text(
                  tag,
                  style: GoogleFonts.spaceGrotesk(
                    color: isSelected
                        ? Colors.white
                        : Colors.black.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                selectedColor: const Color(0xFF22D3EE).withValues(alpha: 0.3),
                checkmarkColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF22D3EE)
                        : Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketTypesSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ticket Types',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
              OutlinedButton.icon(
                onPressed: _addTicketType,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'events_add_ticket'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF22D3EE,
                  ).withValues(alpha: 0.2),
                  side: const BorderSide(color: Color(0xFF22D3EE), width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_ticketTypes.isEmpty)
            Text(
              'No ticket types added yet. Add at least one ticket type.',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
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
    );
  }

  Widget _buildRefundPolicySection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Refund Policy',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _getRefundPolicyKey(),
            decoration: InputDecoration(
              labelText: 'Refund Policy',
              labelStyle: GoogleFonts.spaceGrotesk(
                color: Colors.white.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                  width: 1.5,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: Color(0xFF22D3EE),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
            dropdownColor: Colors.black.withValues(alpha: 0.9),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            icon: Icon(
              Icons.arrow_drop_down,
              color: Colors.white.withValues(alpha: 0.7),
            ),
            items: [
              DropdownMenuItem(
                value: 'standard',
                child: Text(
                  'Standard (24 hours)',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'no_refunds',
                child: Text(
                  'No Refunds',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            onChanged: (String? value) {
              setState(() {
                switch (value) {
                  case 'standard':
                    _refundPolicy = const RefundPolicy();
                    break;
                  case 'flexible':
                    _refundPolicy = const RefundPolicy(
                      fullRefundDeadline: Duration(days: 7),
                      allowPartialRefunds: true,
                      partialRefundPercentage: 50.0,
                      terms:
                          'Full refund available up to 7 days before event. 50% refund available up to 24 hours before event.',
                    );
                    break;
                  case 'no_refunds':
                    _refundPolicy = const RefundPolicy(
                      fullRefundDeadline: Duration.zero,
                      terms: 'No refunds available for this event.',
                      exceptions: ['All sales are final'],
                    );
                    break;
                  default:
                    break;
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Event Settings',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'events_public_event'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'events_show_in_feed'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _isPublic,
              onChanged: (value) => setState(() => _isPublic = value),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: const Color(0xFF22D3EE),
              inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            ),
            SwitchListTile(
              title: Text(
                'events_enable_reminders'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'events_send_reminders'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: const Color(0xFF22D3EE),
              inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurringEventSection() {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recurring Event',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.white.withValues(alpha: 0.92),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(
                'events_repeat_event'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'events_create_recurring'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              value: _isRecurring,
              onChanged: (value) => setState(() => _isRecurring = value),
              contentPadding: EdgeInsets.zero,
              activeThumbColor: const Color(0xFF22D3EE),
              inactiveThumbColor: Colors.white.withValues(alpha: 0.5),
              inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
            ),
            if (_isRecurring) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _recurrencePattern,
                decoration: InputDecoration(
                  labelText: 'Repeat Pattern',
                  labelStyle: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF22D3EE),
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
                dropdownColor: Colors.black.withValues(alpha: 0.9),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
                ),
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                items: [
                  DropdownMenuItem(
                    value: 'daily',
                    child: Text(
                      'Daily',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'weekly',
                    child: Text(
                      'Weekly',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'monthly',
                    child: Text(
                      'Monthly',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'custom',
                    child: Text(
                      'Custom',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w600,
                      ),
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
                decoration: _glassInputDecoration(
                  'Repeat Every',
                  hint: 'Enter interval',
                  suffixText: _recurrencePattern == 'daily'
                      ? 'day(s)'
                      : _recurrencePattern == 'weekly'
                      ? 'week(s)'
                      : _recurrencePattern == 'monthly'
                      ? 'month(s)'
                      : 'unit(s)',
                ),
                style: GoogleFonts.spaceGrotesk(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontWeight: FontWeight.w600,
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
              InkWell(
                onTap: _selectRecurrenceEndDate,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'events_end_date'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _recurrenceEndDate != null
                                  ? '${_recurrenceEndDate!.month}/${_recurrenceEndDate!.day}/${_recurrenceEndDate!.year}'
                                  : 'No end date (continues indefinitely)',
                              style: GoogleFonts.spaceGrotesk(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_recurrenceEndDate != null)
                            IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              onPressed: () {
                                setState(() => _recurrenceEndDate = null);
                              },
                            ),
                          Icon(
                            Icons.calendar_today,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ],
                      ),
                    ],
                  ),
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

    if (_artistHeadshot == null && widget.initialEvent?.artistHeadshotUrl == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_select_headshot'.tr())));
      return;
    }

    if (_eventBanner == null && widget.initialEvent?.eventBannerUrl == null) {
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
    final userId = UserService().currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('events_not_logged_in'.tr())));
      return;
    }
    final eventId =
        widget.initialEvent?.id ??
        DateTime.now().millisecondsSinceEpoch.toString();
    String headshotUrl = widget.initialEvent?.artistHeadshotUrl ?? '';
    String bannerUrl = widget.initialEvent?.eventBannerUrl ?? '';
    List<String> imageUrls = widget.initialEvent?.imageUrls ?? [];
    try {
      // Use debug_uploads path for more reliable web uploads
      if (_artistHeadshot != null) {
        headshotUrl = await _uploadImageToStorage(
          _artistHeadshot!,
          'debug_uploads/events/$userId/$eventId/headshot.jpg',
        );
      }
      if (_eventBanner != null) {
        bannerUrl = await _uploadImageToStorage(
          _eventBanner!,
          'debug_uploads/events/$userId/$eventId/banner.jpg',
        );
      }
      if (_eventImages.isNotEmpty) {
        final newImageUrls = await Future.wait(
          _eventImages.asMap().entries.map(
            (entry) => _uploadImageToStorage(
              entry.value,
              'debug_uploads/events/$userId/$eventId/image_${entry.key}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ),
        );
        imageUrls = [...imageUrls, ...newImageUrls];
      }
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
          category: _category,
          artistHeadshotFit: _artistHeadshotFit,
          eventBannerFit: _eventBannerFit,
          imageFit: _imageFit,
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
          category: _category,
          artistHeadshotFit: _artistHeadshotFit,
          eventBannerFit: _eventBannerFit,
          imageFit: _imageFit,
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

  // ...existing code...
}
