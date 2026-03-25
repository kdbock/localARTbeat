import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';

import '../models/admin_ad_report_model.dart';
import '../models/admin_local_ad_purchase_recovery.dart';
import '../models/admin_local_ad.dart';
import '../services/admin_ad_moderation_service.dart';

/// Admin widget for managing advertisements
class AdminAdManagementWidget extends StatefulWidget {
  const AdminAdManagementWidget({super.key});

  @override
  State<AdminAdManagementWidget> createState() =>
      _AdminAdManagementWidgetState();
}

enum _AdminAdFilter { all, needsReview, paymentIssues, flagged, reports }

class _AdminAdManagementWidgetState extends State<AdminAdManagementWidget> {
  final AdminAdModerationService _moderationService = AdminAdModerationService();

  List<AdminLocalAd> _adsForReview = [];
  List<AdminLocalAd> _adsNeedingPaymentFollowUp = [];
  List<AdminLocalAdPurchaseRecovery> _purchaseRecoveries = [];
  List<AdminAdReportModel> _pendingReports = [];
  Map<String, int> _adStats = {};
  bool _isLoading = true;
  _AdminAdFilter _selectedFilter = _AdminAdFilter.all;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [adsForReview, adStats, paymentFollowUpAds, recoveries] =
          await Future.wait([
        _moderationService.getAdsForReview(),
        _moderationService.getAdStatistics(),
        _moderationService.getAdsNeedingPaymentFollowUp(),
        _moderationService.getPurchaseRecoveries(),
      ]);

      setState(() {
        _adsForReview = adsForReview as List<AdminLocalAd>;
        _adStats = adStats as Map<String, int>;
        _adsNeedingPaymentFollowUp = paymentFollowUpAds as List<AdminLocalAd>;
        _purchaseRecoveries =
            recoveries as List<AdminLocalAdPurchaseRecovery>;
        _isLoading = false;
      });

      // Load pending reports separately as it's a stream
      _moderationService.getPendingReports().listen((reports) {
        if (mounted) {
          setState(() {
            _pendingReports = reports;
          });
        }
      });
    } catch (e) {
      AppLogger.error('Failed to load ad management data: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ArtbeatColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.campaign,
                color: ArtbeatColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'admin_ad_management_title'.tr(),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted ads stay pending until they are approved and published.',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Statistics Cards
        _buildStatsCards(),
        const SizedBox(height: 20),

        // Filter Tabs
        _buildFilterTabs(),
        const SizedBox(height: 16),

        // Content based on filter
        Expanded(
          child: _buildFilteredContent(),
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Needs Review',
            (_adStats['Pending Review'] ?? 0).toString(),
            Icons.pending_actions,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Flagged',
            (_adStats['Flagged'] ?? 0).toString(),
            Icons.flag,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Active',
            (_adStats['Active'] ?? 0).toString(),
            Icons.check_circle,
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Reports',
            _pendingReports.length.toString(),
            Icons.report_problem,
            Colors.amber,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Payment Issues',
            (_adsNeedingPaymentFollowUp.length + _purchaseRecoveries.length)
                .toString(),
            Icons.receipt_long,
            Colors.deepOrange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = <(_AdminAdFilter, String)>[
      (_AdminAdFilter.all, 'admin_ad_filter_all'.tr()),
      (_AdminAdFilter.needsReview, 'admin_ad_filter_pending_review'.tr()),
      (_AdminAdFilter.paymentIssues, 'Payment issues'),
      (_AdminAdFilter.flagged, 'admin_ad_filter_flagged'.tr()),
      (_AdminAdFilter.reports, 'admin_ad_filter_reports'.tr()),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.$2),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter.$1;
                });
              },
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              selectedColor: ArtbeatColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? ArtbeatColors.primary : Colors.grey[400],
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected
                    ? ArtbeatColors.primary
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFilteredContent() {
    switch (_selectedFilter) {
      case _AdminAdFilter.needsReview:
        return _buildAdsForReview();
      case _AdminAdFilter.paymentIssues:
        return _buildPaymentIssuesView();
      case _AdminAdFilter.flagged:
        return _buildFlaggedAds();
      case _AdminAdFilter.reports:
        return _buildReportsView();
      case _AdminAdFilter.all:
        return _buildAllAdsView();
    }
  }

  Widget _buildAdsForReview() {
    final pendingAds = _adsForReview
        .where((ad) => ad.status == AdminLocalAdStatus.pendingReview)
        .toList();

    if (pendingAds.isEmpty) {
      return const Center(
        child: Text(
          'No ad placements are waiting for review.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: pendingAds.length,
      itemBuilder: (context, index) {
        return _buildAdReviewCard(pendingAds[index]);
      },
    );
  }

  Widget _buildFlaggedAds() {
    final flaggedAds = _adsForReview
        .where((ad) => ad.status == AdminLocalAdStatus.flagged)
        .toList();

    if (flaggedAds.isEmpty) {
      return const Center(
        child: Text(
          'No flagged ad placements right now.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: flaggedAds.length,
      itemBuilder: (context, index) {
        return _buildAdReviewCard(flaggedAds[index]);
      },
    );
  }

  Widget _buildReportsView() {
    if (_pendingReports.isEmpty) {
      return const Center(
        child: Text(
          'No ad reports need attention right now.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _pendingReports.length,
      itemBuilder: (context, index) {
        return _buildReportCard(_pendingReports[index]);
      },
    );
  }

  Widget _buildPaymentIssuesView() {
    if (_purchaseRecoveries.isEmpty && _adsNeedingPaymentFollowUp.isEmpty) {
      return const Center(
        child: Text(
          'No paid ad recoveries or refund follow-up items right now.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView(
      children: [
        for (final recovery in _purchaseRecoveries)
          _buildRecoveryCard(recovery),
        for (final ad in _adsNeedingPaymentFollowUp)
          _buildPaymentFollowUpAdCard(ad),
      ],
    );
  }

  Widget _buildAllAdsView() {
    return ListView.builder(
      itemCount: _adsForReview.length,
      itemBuilder: (context, index) {
        return _buildAdReviewCard(_adsForReview[index]);
      },
    );
  }

  Widget _buildAdReviewCard(AdminLocalAd ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with status
          Row(
            children: [
              Expanded(
                child: Text(
                  ad.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildStatusChip(ad.status),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            ad.description,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),

          // Ad details
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                ad.zone.placementDisplayName,
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                _formatDate(ad.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
              if (ad.reportCount > 0) ...[
                const SizedBox(width: 16),
                Icon(Icons.flag, size: 16, color: Colors.red[400]),
                const SizedBox(width: 4),
                Text(
                  '${ad.reportCount} reports',
                  style: TextStyle(color: Colors.red[400], fontSize: 12),
                ),
              ],
            ],
          ),
          if (ad.hasPaidSubscription) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.subscriptions, size: 16, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    ad.purchaseFollowUpStatus ?? 'Paid submission',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _approveAd(ad),
                  icon: const Icon(Icons.check, color: Colors.green, size: 16),
                  label: const Text(
                    'Approve & publish',
                    style: TextStyle(color: Colors.green),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _rejectAd(ad),
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  label: const Text(
                    'Reject',
                    style: TextStyle(color: Colors.red),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () => _viewAdDetails(ad),
                icon: const Icon(Icons.visibility, color: Colors.blue),
                tooltip: 'admin_ad_tooltip_view_details'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(AdminAdReportModel report) {
    final reasonData = AdminAdReportReasons.getReasonByValue(report.reason);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.flag, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reasonData?['label'] ?? report.reason,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                _formatDate(report.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          if (report.additionalDetails != null) ...[
            Text(
              report.additionalDetails!,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () =>
                      _reviewReport(report, AdminAdReportStatus.dismissed),
                  child: Text('admin_ad_button_dismiss'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _reviewReport(report, AdminAdReportStatus.actionTaken),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  child: Text(
                    'admin_ad_button_take_action'.tr(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryCard(AdminLocalAdPurchaseRecovery recovery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepOrange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepOrange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: Colors.deepOrange),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Paid ad recovery needed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Text(
                _formatDate(recovery.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recovery.error ?? 'Ad document creation failed after payment.',
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildMiniMeta('User', recovery.userId),
          if (recovery.subscriptionProductId != null)
            _buildMiniMeta('Subscription', recovery.subscriptionProductId!),
          if (recovery.purchaseId != null)
            _buildMiniMeta('Purchase ID', recovery.purchaseId!),
          if (recovery.transactionId != null)
            _buildMiniMeta('Transaction ID', recovery.transactionId!),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: () => _markRecoveryReviewed(recovery),
              icon: const Icon(Icons.task_alt, size: 16),
              label: const Text('Mark follow-up complete'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentFollowUpAdCard(AdminLocalAd ad) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ad.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              _buildStatusChip(ad.status),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ad.purchaseFollowUpNotes ??
                'This paid ad needs subscription refund/cancellation review.',
            style: TextStyle(color: Colors.grey[300], fontSize: 13),
          ),
          const SizedBox(height: 12),
          _buildMiniMeta('Placement', ad.zone.placementDisplayName),
          if (ad.subscriptionProductId != null)
            _buildMiniMeta('Subscription', ad.subscriptionProductId!),
          if (ad.transactionId != null)
            _buildMiniMeta('Transaction ID', ad.transactionId!),
          if (ad.purchaseId != null)
            _buildMiniMeta('Purchase ID', ad.purchaseId!),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _setAdPurchaseFollowUp(
                    ad,
                    status: 'refund_requested',
                    notes:
                        'Refund or cancellation request has been submitted for store review.',
                  ),
                  icon: const Icon(Icons.undo, size: 16),
                  label: const Text('Refund requested'),
                ),
                TextButton.icon(
                  onPressed: () => _setAdPurchaseFollowUp(
                    ad,
                    status: 'refund_completed',
                    notes:
                        'Refund follow-up completed. Confirm store-side resolution if needed.',
                    autoRenewing: false,
                  ),
                  icon: const Icon(Icons.task_alt, size: 16),
                  label: const Text('Refund completed'),
                ),
                TextButton.icon(
                  onPressed: () => _setAdPurchaseFollowUp(
                    ad,
                    status: 'subscription_canceled',
                    notes:
                        'Monthly ad subscription was canceled or marked to not renew.',
                    autoRenewing: false,
                  ),
                  icon: const Icon(Icons.cancel, size: 16),
                  label: const Text('Subscription canceled'),
                ),
                TextButton.icon(
                  onPressed: () => _viewAdDetails(ad),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('View payment details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMeta(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        '$label: $value',
        style: TextStyle(color: Colors.grey[400], fontSize: 12),
      ),
    );
  }

  Widget _buildStatusChip(AdminLocalAdStatus status) {
    Color color;
    switch (status) {
      case AdminLocalAdStatus.active:
        color = Colors.green;
        break;
      case AdminLocalAdStatus.pendingReview:
        color = Colors.orange;
        break;
      case AdminLocalAdStatus.flagged:
        color = Colors.red;
        break;
      case AdminLocalAdStatus.rejected:
        color = Colors.red.shade700;
        break;
      case AdminLocalAdStatus.expired:
        color = Colors.grey;
        break;
      case AdminLocalAdStatus.deleted:
        color = Colors.grey.shade700;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _approveAd(AdminLocalAd ad) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      await _moderationService.approveAd(
        adId: ad.id,
        adminId: adminId,
        adminNotes: 'Approved via admin dashboard',
      );

      _loadData(); // Refresh data

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'admin_ad_success_approved'.tr(namedArgs: {'title': ad.title})),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'admin_ad_error_approve'.tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectAd(AdminLocalAd ad) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RejectAdDialog(),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
        await _moderationService.rejectAd(
          adId: ad.id,
          adminId: adminId,
          reason: result,
        );

        _loadData(); // Refresh data

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'admin_ad_success_rejected'.tr(namedArgs: {'title': ad.title})),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'admin_ad_error_reject'.tr(namedArgs: {'error': e.toString()})),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _reviewReport(
      AdminAdReportModel report, AdminAdReportStatus status) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      await _moderationService.reviewReport(
        reportId: report.id,
        newStatus: status,
        adminId: adminId,
        adminNotes: status == AdminAdReportStatus.actionTaken
            ? 'admin_ad_report_action_taken'.tr()
            : 'admin_ad_report_dismissed'.tr(),
      );

      _loadData(); // Refresh data

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin_ad_report_reviewed'
              .tr(namedArgs: {'status': status.displayName.toLowerCase()})),
          backgroundColor:
              status == AdminAdReportStatus.actionTaken
                  ? Colors.red
                  : Colors.green,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('admin_ad_error_review_report'
              .tr(namedArgs: {'error': e.toString()})),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _markRecoveryReviewed(
    AdminLocalAdPurchaseRecovery recovery,
  ) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      await _moderationService.markPurchaseRecoveryReviewed(
        recoveryId: recovery.id,
        adminId: adminId,
        resolutionNotes: 'Manual follow-up completed in admin dashboard.',
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ad payment recovery marked as reviewed.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update recovery status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setAdPurchaseFollowUp(
    AdminLocalAd ad, {
    required String status,
    required String notes,
    bool? autoRenewing,
  }) async {
    try {
      final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'system';
      await _moderationService.updateAdPurchaseFollowUp(
        adId: ad.id,
        status: status,
        adminId: adminId,
        notes: notes,
        autoRenewing: autoRenewing,
      );
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated payment follow-up: $status'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update payment follow-up: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _viewAdDetails(AdminLocalAd ad) {
    showDialog<void>(
      context: context,
      builder: (context) => _AdDetailsDialog(ad: ad),
    );
  }
}

class _RejectAdDialog extends StatefulWidget {
  @override
  State<_RejectAdDialog> createState() => _RejectAdDialogState();
}

class _RejectAdDialogState extends State<_RejectAdDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ArtbeatColors.backgroundDark,
      title: const Text(
        'Reject Ad Submission',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please provide a short reason so the business knows what to fix before resubmitting.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            maxLines: 3,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Enter rejection reason...',
              hintStyle: TextStyle(color: Colors.grey[600]),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: ArtbeatColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('admin_ad_button_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              Navigator.of(context).pop(_controller.text.trim());
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('admin_ad_button_reject'.tr(),
              style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

class _AdDetailsDialog extends StatelessWidget {
  final AdminLocalAd ad;

  const _AdDetailsDialog({required this.ad});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ArtbeatColors.backgroundDark,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.campaign, color: ArtbeatColors.primary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Ad Submission Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Ad content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ad.imageUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          ad.imageUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 200,
                              color: Colors.grey.withValues(alpha: 0.2),
                              child: const Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                                size: 50,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Title
                    Text(
                      ad.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Description
                    Text(
                      ad.description,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Details grid
                    _buildDetailRow('Placement', ad.zone.placementDisplayName),
                    _buildDetailRow('Size', ad.size.displayName),
                    _buildDetailRow('Status', ad.status.displayName),
                    _buildDetailRow(
                        'Created', ad.createdAt.toString().substring(0, 16)),
                    _buildDetailRow(
                        'Expires', ad.expiresAt.toString().substring(0, 16)),
                    _buildDetailRow('Report Count', ad.reportCount.toString()),
                    if (ad.subscriptionProductId != null)
                      _buildDetailRow(
                        'Subscription Product',
                        ad.subscriptionProductId!,
                      ),
                    if (ad.purchaseId != null)
                      _buildDetailRow('Purchase ID', ad.purchaseId!),
                    if (ad.transactionId != null)
                      _buildDetailRow('Transaction ID', ad.transactionId!),
                    if (ad.monthlyPrice != null)
                      _buildDetailRow(
                        'Monthly Price',
                        ad.currencyCode != null
                            ? '${ad.currencyCode} ${ad.monthlyPrice!.toStringAsFixed(2)}'
                            : ad.monthlyPrice!.toStringAsFixed(2),
                      ),
                    if (ad.subscriptionProductId != null)
                      _buildDetailRow(
                        'Auto Renewing',
                        ad.autoRenewing ? 'Yes' : 'No',
                      ),
                    if (ad.purchaseFollowUpStatus != null)
                      _buildDetailRow(
                        'Purchase Follow-Up',
                        ad.purchaseFollowUpStatus!,
                      ),
                    if (ad.purchaseFollowUpNotes != null)
                      _buildDetailRow(
                        'Follow-Up Notes',
                        ad.purchaseFollowUpNotes!,
                      ),
                    if (ad.contactInfo != null)
                      _buildDetailRow('Contact', ad.contactInfo!),
                    if (ad.websiteUrl != null)
                      _buildDetailRow('Website', ad.websiteUrl!),
                    if (ad.reviewedBy != null)
                      _buildDetailRow('Reviewed By', ad.reviewedBy!),
                    if (ad.rejectionReason != null)
                      _buildDetailRow('Rejection Reason', ad.rejectionReason!),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
