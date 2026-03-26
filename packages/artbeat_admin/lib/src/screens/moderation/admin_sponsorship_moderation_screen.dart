import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/admin_sponsorship.dart';
import '../../services/admin_sponsorship_moderation_service.dart';
import '../../widgets/admin_header.dart';
import '../../widgets/sponsorships/sponsorship_admin_card.dart';

class AdminSponsorshipModerationScreen extends StatefulWidget {
  const AdminSponsorshipModerationScreen({super.key});

  @override
  State<AdminSponsorshipModerationScreen> createState() =>
      _AdminSponsorshipModerationScreenState();
}

enum _SponsorshipFilter { all, pending, needsCreative, approved, rejected }

class _AdminSponsorshipModerationScreenState
    extends State<AdminSponsorshipModerationScreen> {
  final AdminSponsorshipModerationService _service =
      AdminSponsorshipModerationService();

  bool _isLoading = true;
  List<AdminSponsorship> _items = [];
  _SponsorshipFilter _filter = _SponsorshipFilter.pending;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final items = await _service.getAllSponsorships();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredItems();
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: const AdminHeader(
        title: 'Sponsorship Moderation',
        showBackButton: true,
        showSearch: false,
        showChat: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final filter in _SponsorshipFilter.values)
                        ChoiceChip(
                          label: Text(_filterLabel(filter)),
                          selected: _filter == filter,
                          onSelected: (_) => setState(() => _filter = filter),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(
                          child: Text(
                            'No sponsorships in this review state.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return SponsorshipAdminCard(
                              sponsorship: item,
                              onApprove: () => _updateStatus(
                                item,
                                'approved',
                                null,
                              ),
                              onNeedsCreative: () => _promptAndUpdateStatus(
                                item,
                                'needsCreative',
                                'What creative or link update is needed?',
                              ),
                              onReject: () => _promptAndUpdateStatus(
                                item,
                                'rejected',
                                'Why was this sponsorship rejected?',
                              ),
                              onViewDetails: () => _showDetails(item),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<AdminSponsorship> _filteredItems() {
    switch (_filter) {
      case _SponsorshipFilter.all:
        return _items;
      case _SponsorshipFilter.pending:
        return _items.where((item) => item.status == 'pending').toList();
      case _SponsorshipFilter.needsCreative:
        return _items.where((item) => item.status == 'needsCreative').toList();
      case _SponsorshipFilter.approved:
        return _items
            .where((item) => item.status == 'approved' || item.status == 'active')
            .toList();
      case _SponsorshipFilter.rejected:
        return _items.where((item) => item.status == 'rejected').toList();
    }
  }

  String _filterLabel(_SponsorshipFilter filter) {
    switch (filter) {
      case _SponsorshipFilter.all:
        return 'All';
      case _SponsorshipFilter.pending:
        return 'Pending';
      case _SponsorshipFilter.needsCreative:
        return 'Needs Creative';
      case _SponsorshipFilter.approved:
        return 'Approved';
      case _SponsorshipFilter.rejected:
        return 'Rejected';
    }
  }

  Future<void> _updateStatus(
    AdminSponsorship item,
    String status,
    String? notes,
  ) async {
    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
    await _service.updateSponsorshipStatus(
      sponsorshipId: item.id,
      status: status,
      adminId: adminId,
      moderationNotes: notes,
    );
    await _load();
  }

  Future<void> _promptAndUpdateStatus(
    AdminSponsorship item,
    String status,
    String prompt,
  ) async {
    final controller = TextEditingController(text: item.moderationNotes ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_filterLabel(
          status == 'needsCreative'
              ? _SponsorshipFilter.needsCreative
              : _SponsorshipFilter.rejected,
        )),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: InputDecoration(hintText: prompt),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await _updateStatus(item, status, result.isEmpty ? null : result);
  }

  void _showDetails(AdminSponsorship item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.businessName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detail('Tier', item.tier),
              _detail('Status', item.status),
              _detail('Business address', item.businessAddress ?? '--'),
              _detail('Related entity', item.relatedEntityName ?? '--'),
              _detail('Payment', item.paymentStatus ?? '--'),
              _detail('Payment follow-up', item.paymentFollowUpStatus ?? '--'),
              _detail(
                'Payment follow-up notes',
                item.paymentFollowUpNotes ?? '--',
              ),
              _detail('Email', item.contactEmail ?? '--'),
              _detail('Phone', item.phone ?? '--'),
              _detail('Placements', item.placementKeys.join(', ')),
              _detail('Stripe subscription', item.stripeSubscriptionId ?? '--'),
              _detail('Stripe price', item.stripePriceId ?? '--'),
              _detail(
                'Stripe payment intent',
                item.stripePaymentIntentStatus ?? '--',
              ),
              _detail('Logo URL', item.logoUrl ?? '--'),
              _detail('Link URL', item.linkUrl ?? '--'),
              _detail('Moderation notes', item.moderationNotes ?? '--'),
              _detail('Reviewed by', item.reviewedBy ?? '--'),
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

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text('$label: $value'),
    );
  }
}
