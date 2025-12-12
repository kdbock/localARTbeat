import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_ads/artbeat_ads.dart';
import 'package:easy_localization/easy_localization.dart';

/// Admin widget for managing advertisements
class AdminAdManagementWidget extends StatefulWidget {
  const AdminAdManagementWidget({super.key});

  @override
  State<AdminAdManagementWidget> createState() =>
      _AdminAdManagementWidgetState();
}

class _AdminAdManagementWidgetState extends State<AdminAdManagementWidget> {
  final LocalAdService _adService = LocalAdService();
  final AdReportService _reportService = AdReportService();

  List<LocalAd> _adsForReview = [];
  List<AdReportModel> _pendingReports = [];
  Map<String, int> _adStats = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final [adsForReview, adStats] = await Future.wait([
        _adService.getAdsForReview(),
        _adService.getAdStatistics(),
      ]);

      setState(() {
        _adsForReview = adsForReview as List<LocalAd>;
        _adStats = adStats as Map<String, int>;
        _isLoading = false;
      });

      // Load pending reports separately as it's a stream
      _reportService.getPendingReports().listen((reports) {
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
            Text(
              'admin_ad_management_title'.tr(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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
            'Pending Review',
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
    final filters = [
      'admin_ad_filter_all'.tr(),
      'admin_ad_filter_pending_review'.tr(),
      'admin_ad_filter_flagged'.tr(),
      'admin_ad_filter_reports'.tr(),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filter;
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
      case 'Pending Review':
        return _buildAdsForReview();
      case 'Flagged':
        return _buildFlaggedAds();
      case 'Reports':
        return _buildReportsView();
      default:
        return _buildAllAdsView();
    }
  }

  Widget _buildAdsForReview() {
    final pendingAds = _adsForReview
        .where((ad) => ad.status == LocalAdStatus.pendingReview)
        .toList();

    if (pendingAds.isEmpty) {
      return Center(
        child: Text(
          'admin_ad_empty_pending'.tr(),
          style: const TextStyle(color: Colors.grey),
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
        .where((ad) => ad.status == LocalAdStatus.flagged)
        .toList();

    if (flaggedAds.isEmpty) {
      return Center(
        child: Text(
          'admin_ad_empty_flagged'.tr(),
          style: const TextStyle(color: Colors.grey),
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
      return Center(
        child: Text(
          'admin_ad_empty_reports'.tr(),
          style: const TextStyle(color: Colors.grey),
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

  Widget _buildAllAdsView() {
    return ListView.builder(
      itemCount: _adsForReview.length,
      itemBuilder: (context, index) {
        return _buildAdReviewCard(_adsForReview[index]);
      },
    );
  }

  Widget _buildAdReviewCard(LocalAd ad) {
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
                ad.zone.displayName,
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
          const SizedBox(height: 16),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _approveAd(ad),
                  icon: const Icon(Icons.check, color: Colors.green, size: 16),
                  label: const Text(
                    'Approve',
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

  Widget _buildReportCard(AdReportModel report) {
    final reasonData = AdReportReasons.getReasonByValue(report.reason);

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
                      _reviewReport(report, AdReportStatus.dismissed),
                  child: Text('admin_ad_button_dismiss'.tr()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () =>
                      _reviewReport(report, AdReportStatus.actionTaken),
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

  Widget _buildStatusChip(LocalAdStatus status) {
    Color color;
    switch (status) {
      case LocalAdStatus.active:
        color = Colors.green;
        break;
      case LocalAdStatus.pendingReview:
        color = Colors.orange;
        break;
      case LocalAdStatus.flagged:
        color = Colors.red;
        break;
      case LocalAdStatus.rejected:
        color = Colors.red.shade700;
        break;
      case LocalAdStatus.expired:
        color = Colors.grey;
        break;
      case LocalAdStatus.deleted:
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

  Future<void> _approveAd(LocalAd ad) async {
    try {
      // TODO: Get current admin ID
      await _reportService.approveAd(
        adId: ad.id,
        adminId: 'admin', // This should be the current admin's ID
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

  Future<void> _rejectAd(LocalAd ad) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _RejectAdDialog(),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await _reportService.rejectAd(
          adId: ad.id,
          adminId: 'admin', // This should be the current admin's ID
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
      AdReportModel report, AdReportStatus status) async {
    try {
      await _reportService.reviewReport(
        reportId: report.id,
        newStatus: status,
        adminId: 'admin', // This should be the current admin's ID
        adminNotes: status == AdReportStatus.actionTaken
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
              status == AdReportStatus.actionTaken ? Colors.red : Colors.green,
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

  void _viewAdDetails(LocalAd ad) {
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
        'Reject Advertisement',
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Please provide a reason for rejection:',
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
  final LocalAd ad;

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
                    'Ad Details',
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
                    _buildDetailRow('Zone', ad.zone.displayName),
                    _buildDetailRow('Size', ad.size.displayName),
                    _buildDetailRow('Status', ad.status.displayName),
                    _buildDetailRow(
                        'Created', ad.createdAt.toString().substring(0, 16)),
                    _buildDetailRow(
                        'Expires', ad.expiresAt.toString().substring(0, 16)),
                    _buildDetailRow('Report Count', ad.reportCount.toString()),
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
