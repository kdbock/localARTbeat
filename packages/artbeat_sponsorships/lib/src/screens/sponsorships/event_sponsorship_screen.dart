import 'package:flutter/material.dart';
import '../../utils/tour_events.dart';
import '../../widgets/glass_input_field.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_form_section.dart';
import '../../widgets/sponsorship_price_summary.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';
import 'sponsorship_review_screen.dart';

class EventSponsorshipScreen extends StatefulWidget {
  const EventSponsorshipScreen({super.key});

  @override
  State<EventSponsorshipScreen> createState() => _EventSponsorshipScreenState();
}

class _EventSponsorshipScreenState extends State<EventSponsorshipScreen>
    with TickerProviderStateMixin {
  TourEvent? selectedEvent;
  final TextEditingController notesController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController ??= AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation ??= Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut));

    _slideAnimation ??= Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut));

    _fadeController!.forward();
  }

  void _selectEvent() {
    showModalBottomSheet<Widget>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 204), // 0.8 * 255
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Select Event',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search events...',
                        hintStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(
                          alpha: 25,
                        ), // 0.1 * 255
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() => searchQuery = value);
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filteredEvents = tourEvents.where((event) {
                      final query = searchQuery.toLowerCase();
                      return event.name.toLowerCase().contains(query) ||
                          event.venue.toLowerCase().contains(query);
                    }).toList();
                    return ListView.builder(
                      itemCount: filteredEvents.length,
                      itemBuilder: (context, index) {
                        final event = filteredEvents[index];
                        return ListTile(
                          title: Text(
                            event.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${event.venue} - ${event.startDate}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                          onTap: () {
                            this.setState(() => selectedEvent = event);
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      searchController.clear();
      searchQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) => WorldBackground(
    child: Column(
      children: [
        HudTopBar(
          title: 'Event Sponsorship',
          onBack: () => Navigator.pop(context),
        ),
        Expanded(
          child: FadeTransition(
            opacity: _fadeAnimation!,
            child: SlideTransition(
              position: _slideAnimation!,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  const SponsorshipSection(
                    title: 'What You Get',
                    child: Text(
                      'Sponsor a Local ARTbeat tour or event with equal branding, '
                      'signage, and callouts in promotional videos.',
                    ),
                  ),
                  const SponsorshipSection(
                    title: 'Pricing',
                    child: SponsorshipPriceSummary(
                      price: r'$1000',
                      duration: 'Per Event',
                    ),
                  ),
                  SponsorshipSection(
                    title: 'Event Details',
                    child: Column(
                      children: [
                        SponsorshipFormSection(
                          label: 'Select Event',
                          child: GestureDetector(
                            onTap: _selectEvent,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(
                                  alpha: 25,
                                ), // 0.1 * 255
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withValues(
                                    alpha: 51,
                                  ), // 0.2 * 255
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      selectedEvent?.displayName ??
                                          'Tap to select an event',
                                      style: TextStyle(
                                        color: selectedEvent != null
                                            ? Colors.white
                                            : Colors.white70,
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.white70,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SponsorshipFormSection(
                          label: 'Notes (optional)',
                          child: GlassInputField(
                            controller: notesController,
                            label: 'Any special requests',
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: GradientCtaButton(
            label: 'Continue',
            onPressed: () {
              if (selectedEvent == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please select an event to continue'),
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute<SponsorshipReviewScreen>(
                  builder: (context) => SponsorshipReviewScreen(
                    type: 'event',
                    duration: 'Per Event',
                    price: r'$1000',
                    selectedEvent: selectedEvent,
                    notes: notesController.text,
                  ),
                ),
              );
            },
            onTap: () {},
          ),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _fadeController?.dispose();
    notesController.dispose();
    searchController.dispose();
    super.dispose();
  }
}
