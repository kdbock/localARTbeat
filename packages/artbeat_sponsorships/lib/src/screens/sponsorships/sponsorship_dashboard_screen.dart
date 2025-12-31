import 'package:flutter/material.dart';

import '../../models/sponsorship.dart';
import '../../services/sponsorship_repository.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/hud_top_bar.dart';
import '../../widgets/sponsorship_card.dart';
import '../../widgets/sponsorship_empty_state.dart';
import '../../widgets/sponsorship_section.dart';
import '../../widgets/world_background.dart';

class SponsorshipDashboardScreen extends StatefulWidget {
  const SponsorshipDashboardScreen({
    super.key,
    required this.businessId,
  });

  final String businessId;

  @override
  State<SponsorshipDashboardScreen> createState() =>
      _SponsorshipDashboardScreenState();
}

class _SponsorshipDashboardScreenState
    extends State<SponsorshipDashboardScreen> {
  final SponsorshipRepository _repository = SponsorshipRepository();

  late Future<List<Sponsorship>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repository.getForBusiness(widget.businessId);
  }

  @override
  Widget build(BuildContext context) => WorldBackground(
      child: Column(
        children: [
          HudTopBar(
            title: 'Sponsorships',
            onBack: () => Navigator.pop(context),
          ),
          Expanded(
            child: FutureBuilder<List<Sponsorship>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final sponsorships = snapshot.data ?? [];

                if (sponsorships.isEmpty) {
                  return SponsorshipEmptyState(
                    title: 'No Sponsorships Yet',
                    subtitle:
                        'Promote your business by sponsoring art, tours, or discoveries.',
                    ctaLabel: 'Create Sponsorship',
                    onCta: _goToCreate,
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    SponsorshipSection(
                      title: 'Your Sponsorships',
                      child: Column(
                        children: sponsorships
                            .map(
                              (s) => Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 12),
                                child: SponsorshipCard(
                                  sponsorship: s,
                                  onTap: () =>
                                      _openDetails(s.id),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GradientCtaButton(
              label: 'Create Sponsorship',
              onPressed: _goToCreate,
            ),
          ),
        ],
      ),
    );

  void _goToCreate() {
    Navigator.pushNamed(context, '/create-sponsorship');
  }

  void _openDetails(String id) {
    Navigator.pushNamed(
      context,
      '/sponsorship-detail',
      arguments: id,
    );
  }
}
