import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../models/sponsorship.dart';
import '../../services/sponsorship_repository.dart';
import '../../widgets/gradient_cta_button.dart';
import '../../widgets/sponsorship_card.dart';
import '../../widgets/sponsorship_empty_state.dart';
import '../../widgets/sponsorship_section.dart';
import 'sponsorship_detail_screen.dart';

class SponsorshipDashboardScreen extends StatefulWidget {
  const SponsorshipDashboardScreen({super.key, required this.businessId});

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
          title: 'sponsorship_dashboard_title'.tr(),
          onBackPressed: () => Navigator.pop(context),
        ),
        Expanded(
          child: FutureBuilder<List<Sponsorship>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final sponsorships = snapshot.data ?? [];

              if (sponsorships.isEmpty) {
                return SponsorshipEmptyState(
                  title: 'sponsorship_dashboard_empty_title'.tr(),
                  subtitle: 'sponsorship_dashboard_empty_subtitle'.tr(),
                  ctaLabel: 'sponsorship_dashboard_create_button'.tr(),
                  onCta: _goToCreate,
                );
              }

              return ListView(
                padding: const EdgeInsets.only(bottom: 120),
                children: [
                  SponsorshipSection(
                    title: 'sponsorship_dashboard_list_title'.tr(),
                    child: Column(
                      children: sponsorships
                          .map(
                            (s) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: SponsorshipCard(
                                sponsorship: s,
                                onTap: () => _openDetails(s.id),
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
            label: 'sponsorship_dashboard_create_button'.tr(),
            onPressed: _goToCreate,
          ),
        ),
      ],
    ),
  );

  void _goToCreate() {
    Navigator.pushNamed(context, AppRoutes.sponsorshipCreate);
  }

  void _openDetails(String id) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => SponsorshipDetailScreen(sponsorshipId: id),
      ),
    );
  }
}
