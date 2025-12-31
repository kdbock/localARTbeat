import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../utils/tour_events.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_review_row.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class SponsorshipReviewScreen extends StatefulWidget {
  const SponsorshipReviewScreen({
    super.key,
    required this.type,
    required this.duration,
    required this.price,
    this.selectedEvent,
    this.notes,
  });

  final String type;
  final String duration;
  final String price;
  final TourEvent? selectedEvent;
  final String? notes;

  @override
  State<SponsorshipReviewScreen> createState() =>
      _SponsorshipReviewScreenState();
}

class _SponsorshipReviewScreenState extends State<SponsorshipReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _brandingNotesController = TextEditingController();

  @override
  void dispose() {
    _businessNameController.dispose();
    _contactEmailController.dispose();
    _phoneController.dispose();
    _brandingNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Column(
          children: [
            HudTopBar(
              title: 'Review Sponsorship',
              onBack: () => Navigator.pop(context),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 160),
                  children: [
                    SponsorshipSection(
                      title: 'Summary',
                      child: Column(
                        children: [
                          SponsorshipReviewRow(
                            label: 'Type',
                            value: widget.type,
                          ),
                          SponsorshipReviewRow(
                            label: 'Duration',
                            value: widget.duration,
                          ),
                          SponsorshipReviewRow(
                            label: 'Price',
                            value: widget.price,
                          ),
                        ],
                      ),
                    ),
                    if (widget.selectedEvent != null)
                      SponsorshipSection(
                        title: 'Event Details',
                        child: Column(
                          children: [
                            SponsorshipReviewRow(
                              label: 'Event',
                              value: widget.selectedEvent!.name,
                            ),
                            SponsorshipReviewRow(
                              label: 'Venue',
                              value: widget.selectedEvent!.venue,
                            ),
                            SponsorshipReviewRow(
                              label: 'Date',
                              value: widget.selectedEvent!.startDate,
                            ),
                          ],
                        ),
                      ),
                    SponsorshipSection(
                      title: 'Your Information',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _businessNameController,
                            decoration: const InputDecoration(
                              labelText: 'Business Name',
                              hintText: 'Enter your business name',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your business name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contactEmailController,
                            decoration: const InputDecoration(
                              labelText: 'Contact Email',
                              hintText: 'Enter your email address',
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(
                                r'^[^@]+@[^@]+\.[^@]+',
                              ).hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone (Optional)',
                              hintText: 'Enter your phone number',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _brandingNotesController,
                            decoration: const InputDecoration(
                              labelText: 'Branding Notes',
                              hintText: 'Describe your branding, logo, etc.',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                    SponsorshipSection(
                      title: 'Thank You',
                      child: Text(
                        'Thank you for investing in the future of Local ARTbeat. Your support keeps the app independent and helps small towns circulate joy again.',
                        style: TextStyle(fontSize: 16, height: 1.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: GradientCtaButton(
            label: 'Submit for Approval',
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                try {
                  final data = {
                    'type': widget.type,
                    'duration': widget.duration,
                    'price': widget.price,
                    'businessName': _businessNameController.text,
                    'contactEmail': _contactEmailController.text,
                    'phone': _phoneController.text,
                    'brandingNotes': _brandingNotesController.text,
                    'timestamp': FieldValue.serverTimestamp(),
                    if (widget.selectedEvent != null) ...{
                      'eventName': widget.selectedEvent!.name,
                      'eventVenue': widget.selectedEvent!.venue,
                      'eventDate': widget.selectedEvent!.startDate,
                      'eventId': widget
                          .selectedEvent!
                          .name, // Using name as ID for now
                    },
                    if (widget.notes != null && widget.notes!.isNotEmpty)
                      'additionalNotes': widget.notes,
                  };
                  await FirebaseFirestore.instance
                      .collection('sponsorships')
                      .add(data);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Sponsorship submitted for approval!'),
                    ),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to submit: $e')),
                  );
                }
              }
            },
            onTap: () {},
          ),
        ),
      ),
    ),
  );
}
