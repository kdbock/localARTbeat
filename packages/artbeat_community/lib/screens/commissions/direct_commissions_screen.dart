import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../widgets/widgets.dart';
import 'artist_selection_screen.dart';
import 'commission_detail_screen.dart';

class DirectCommissionsScreen extends StatefulWidget {
  const DirectCommissionsScreen({super.key});

  @override
  State<DirectCommissionsScreen> createState() =>
      _DirectCommissionsScreenState();
}

class _DirectCommissionsScreenState extends State<DirectCommissionsScreen>
    with SingleTickerProviderStateMixin {
  final DirectCommissionService _commissionService = DirectCommissionService();
  late final TabController _tabController;
  final intl.NumberFormat _currencyFormatter = intl.NumberFormat.currency(
    symbol: '\$',
  );
  final intl.NumberFormat _compactCurrencyFormatter =
      intl.NumberFormat.compactSimpleCurrency(name: 'USD');
  final intl.DateFormat _dateFormat = intl.DateFormat('MMM d, yyyy');

  List<DirectCommissionModel> _allCommissions = [];
  bool _isLoading = true;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCommissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissions() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('direct_commissions_sign_in_required'.tr())),
          );
        }
        return;
      }

      _currentUserId = user.uid;
      final commissions = await _commissionService.getCommissionsByUser(
        user.uid,
      );

      setState(() {
        _allCommissions = commissions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'direct_commissions_error_loading'.tr(namedArgs: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  List<DirectCommissionModel> _getCommissionsByStatus(
    List<CommissionStatus> statuses,
  ) {
    return _allCommissions.where((c) => statuses.contains(c.status)).toList();
  }

  double _calculateTotalEarnings() {
    return _allCommissions
        .where(
          (c) =>
              c.artistId == _currentUserId &&
              [
                CommissionStatus.completed,
                CommissionStatus.delivered,
              ].contains(c.status),
        )
        .fold(0.0, (sum, c) => sum + c.totalPrice);
  }

  bool _isUserArtist(DirectCommissionModel commission) {
    return commission.artistId == _currentUserId;
  }

  @override
  Widget build(BuildContext context) {
    final activeCommissions = _getCommissionsByStatus([
      CommissionStatus.pending,
      CommissionStatus.quoted,
      CommissionStatus.accepted,
      CommissionStatus.inProgress,
    ]);
    final pendingCommissions = _getCommissionsByStatus([
      CommissionStatus.pending,
      CommissionStatus.quoted,
    ]);
    final completedCommissions = _getCommissionsByStatus([
      CommissionStatus.completed,
      CommissionStatus.delivered,
    ]);
    final totalEarnings = _calculateTotalEarnings();
    final totalCount = _allCommissions.length;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'direct_commissions_title'.tr(),
        glassBackground: true,
        actions: [
          IconButton(
            tooltip: 'direct_commissions_refresh'.tr(),
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _isLoading ? null : _loadCommissions,
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          0,
          24,
          bottomPadding == 0 ? 24 : bottomPadding,
        ),
        child: GradientCTAButton(
          text: 'direct_commissions_new_cta'.tr(),
          icon: Icons.add,
          onPressed: _isLoading ? null : _showArtistSelection,
          isLoading: _isLoading,
        ),
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    _buildHeroCard(totalCount),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      active: activeCommissions.length,
                      completed: completedCommissions.length,
                      earnings: totalEarnings,
                    ),
                    const SizedBox(height: 16),
                    _buildTabSwitcher(
                      active: activeCommissions.length,
                      pending: pendingCommissions.length,
                      completed: completedCommissions.length,
                      total: totalCount,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: GlassCard(
                    padding: EdgeInsets.zero,
                    child: _isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF7C4DFF),
                            ),
                          )
                        : TabBarView(
                            controller: _tabController,
                            children: [
                              _buildCommissionList(activeCommissions),
                              _buildCommissionList(pendingCommissions),
                              _buildCommissionList(completedCommissions),
                              _buildCommissionList(_allCommissions),
                            ],
                          ),
                  ),
                ),
              ),
              SizedBox(height: bottomPadding == 0 ? 96 : bottomPadding + 72),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(int totalCount) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      showAccentGlow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'direct_commissions_hero_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'direct_commissions_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'direct_commissions_hero_total'.tr(
              namedArgs: {'count': '$totalCount'},
            ),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required int active,
    required int completed,
    required double earnings,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryMetric(
            icon: Icons.timeline,
            value: '$active',
            label: 'direct_commissions_summary_active'.tr(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryMetric(
            icon: Icons.verified,
            value: '$completed',
            label: 'direct_commissions_summary_completed'.tr(),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryMetric(
            icon: Icons.attach_money,
            value: _compactCurrencyFormatter.format(earnings),
            label: 'direct_commissions_summary_earnings'.tr(),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryMetric({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher({
    required int active,
    required int pending,
    required int completed,
    required int total,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
        labelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
          ),
        ),
        indicatorPadding: const EdgeInsets.symmetric(
          vertical: 8,
          horizontal: 4,
        ),
        tabs: [
          _buildTabChip(
            icon: Icons.pending_actions,
            label: 'direct_commissions_tab_active'.tr(
              namedArgs: {'count': '$active'},
            ),
          ),
          _buildTabChip(
            icon: Icons.schedule,
            label: 'direct_commissions_tab_pending'.tr(
              namedArgs: {'count': '$pending'},
            ),
          ),
          _buildTabChip(
            icon: Icons.check_circle,
            label: 'direct_commissions_tab_completed'.tr(
              namedArgs: {'count': '$completed'},
            ),
          ),
          _buildTabChip(
            icon: Icons.list,
            label: 'direct_commissions_tab_all'.tr(
              namedArgs: {'count': '$total'},
            ),
          ),
        ],
      ),
    );
  }

  Tab _buildTabChip({required IconData icon, required String label}) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildCommissionList(List<DirectCommissionModel> commissions) {
    final bottomInset = MediaQuery.of(context).padding.bottom + 160;

    if (commissions.isEmpty) {
      return Center(
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 48,
                color: Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(height: 16),
              Text(
                'direct_commissions_empty_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'direct_commissions_empty_body'.tr(),
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF7C4DFF),
      onRefresh: _loadCommissions,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(8, 8, 8, bottomInset),
        itemCount: commissions.length,
        itemBuilder: (context, index) {
          final commission = commissions[index];
          return _buildCommissionCard(commission);
        },
      ),
    );
  }

  Widget _buildCommissionCard(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);
    final statusColor = _getStatusColor(commission.status);
    final budgetValue = commission.totalPrice > 0
        ? _currencyFormatter.format(commission.totalPrice)
        : null;
    final deadlineValue = commission.deadline != null
        ? _dateFormat.format(commission.deadline!)
        : null;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _openCommissionDetail(commission),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commission.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isArtist
                                ? 'direct_commissions_client_label'.tr(
                                    namedArgs: {'name': commission.clientName},
                                  )
                                : 'direct_commissions_artist_label'.tr(
                                    namedArgs: {'name': commission.artistName},
                                  ),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.32),
                        ),
                      ),
                      child: Text(
                        _localizedStatus(commission.status),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      _getTypeIcon(commission.type),
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _localizedType(commission.type),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'direct_commissions_requested_on'.tr(
                        namedArgs: {
                          'date': _formatDate(commission.requestedAt),
                        },
                      ),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
                if (budgetValue != null || deadlineValue != null) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (budgetValue != null)
                        _buildMetricChip(
                          label: 'direct_commissions_price_label'.tr(),
                          value: budgetValue,
                          valueColor: const Color(0xFF34D399),
                        ),
                      if (budgetValue != null && deadlineValue != null)
                        const SizedBox(width: 24),
                      if (deadlineValue != null)
                        _buildMetricChip(
                          label: 'direct_commissions_deadline_label'.tr(),
                          value: deadlineValue,
                          valueColor: _isDeadlineClose(commission.deadline!)
                              ? const Color(0xFFFF3D8D)
                              : Colors.white,
                        ),
                    ],
                  ),
                ],
                if (_shouldShowProgressBar(commission)) ...[
                  const SizedBox(height: 16),
                  _buildProgressBar(commission),
                ],
                if (_shouldShowActionButtons(commission)) ...[
                  const SizedBox(height: 16),
                  _buildActionButtons(commission),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricChip({
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.7),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: valueColor ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowProgressBar(DirectCommissionModel commission) {
    return [
      CommissionStatus.accepted,
      CommissionStatus.inProgress,
    ].contains(commission.status);
  }

  Widget _buildProgressBar(DirectCommissionModel commission) {
    final completedMilestones = commission.milestones
        .where(
          (m) =>
              m.status == MilestoneStatus.completed ||
              m.status == MilestoneStatus.paid,
        )
        .length;
    final totalMilestones = commission.milestones.length;
    final progress = totalMilestones > 0
        ? completedMilestones / totalMilestones
        : 0.0;
    final safeProgress = progress.isNaN ? 0.0 : progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'direct_commissions_progress_label'.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            Text(
              'direct_commissions_progress_count'.tr(
                namedArgs: {
                  'current': '$completedMilestones',
                  'total': '$totalMilestones',
                },
              ),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 8,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: safeProgress,
            child: Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);
    final buttonWidgets = <Widget>[];

    if (commission.status == CommissionStatus.pending && isArtist) {
      buttonWidgets.add(
        Expanded(
          child: HudButton.secondary(
            onPressed: () => _provideQuote(commission),
            text: 'direct_commissions_action_provide_quote'.tr(),
            icon: Icons.request_quote,
            height: 48,
          ),
        ),
      );
    }

    if (commission.status == CommissionStatus.quoted && !isArtist) {
      buttonWidgets.add(
        Expanded(
          child: HudButton.primary(
            onPressed: () => _acceptCommission(commission),
            text: 'direct_commissions_action_accept_quote'.tr(),
            icon: Icons.check,
            height: 48,
          ),
        ),
      );
    }

    if (commission.status == CommissionStatus.inProgress && isArtist) {
      buttonWidgets.add(
        Expanded(
          child: HudButton.primary(
            onPressed: () => _markCompleted(commission),
            text: 'direct_commissions_action_mark_complete'.tr(),
            icon: Icons.done,
            height: 48,
          ),
        ),
      );
    }

    if (buttonWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    final children = <Widget>[];
    for (var i = 0; i < buttonWidgets.length; i++) {
      children.add(buttonWidgets[i]);
      if (i < buttonWidgets.length - 1) {
        children.add(const SizedBox(width: 16));
      }
    }

    return Row(children: children);
  }

  bool _shouldShowActionButtons(DirectCommissionModel commission) {
    final isArtist = _isUserArtist(commission);
    return (commission.status == CommissionStatus.pending && isArtist) ||
        (commission.status == CommissionStatus.quoted && !isArtist) ||
        (commission.status == CommissionStatus.inProgress && isArtist);
  }

  String _localizedStatus(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return 'commission_status_pending'.tr();
      case CommissionStatus.quoted:
        return 'commission_status_quoted'.tr();
      case CommissionStatus.accepted:
        return 'commission_status_accepted'.tr();
      case CommissionStatus.inProgress:
        return 'commission_status_in_progress'.tr();
      case CommissionStatus.revision:
        return 'commission_status_revision'.tr();
      case CommissionStatus.completed:
        return 'commission_status_completed'.tr();
      case CommissionStatus.delivered:
        return 'commission_status_delivered'.tr();
      case CommissionStatus.cancelled:
        return 'commission_status_cancelled'.tr();
      case CommissionStatus.disputed:
        return 'commission_status_disputed'.tr();
    }
  }

  String _localizedType(CommissionType type) {
    switch (type) {
      case CommissionType.digital:
        return 'commission_type_digital'.tr();
      case CommissionType.physical:
        return 'commission_type_physical'.tr();
      case CommissionType.portrait:
        return 'commission_type_portrait'.tr();
      case CommissionType.commercial:
        return 'commission_type_commercial'.tr();
    }
  }

  Color _getStatusColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return const Color(0xFFFFC857);
      case CommissionStatus.quoted:
        return const Color(0xFF7C4DFF);
      case CommissionStatus.accepted:
        return const Color(0xFF34D399);
      case CommissionStatus.inProgress:
        return const Color(0xFF22D3EE);
      case CommissionStatus.revision:
        return const Color(0xFFFF3D8D);
      case CommissionStatus.completed:
        return const Color(0xFF34D399);
      case CommissionStatus.delivered:
        return const Color(0xFF22D3EE);
      case CommissionStatus.cancelled:
        return const Color(0xFFFF3D8D);
      case CommissionStatus.disputed:
        return const Color(0xFFFB7185);
    }
  }

  IconData _getTypeIcon(CommissionType type) {
    switch (type) {
      case CommissionType.digital:
        return Icons.computer;
      case CommissionType.physical:
        return Icons.brush;
      case CommissionType.portrait:
        return Icons.person;
      case CommissionType.commercial:
        return Icons.business;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'direct_commissions_date_today'.tr();
    } else if (difference.inDays == 1) {
      return 'direct_commissions_date_yesterday'.tr();
    } else if (difference.inDays < 7) {
      return 'direct_commissions_date_days_ago'.tr(
        namedArgs: {'count': '${difference.inDays}'},
      );
    }

    return _dateFormat.format(date);
  }

  bool _isDeadlineClose(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inDays <= 3;
  }

  void _openCommissionDetail(DirectCommissionModel commission) {
    Navigator.push(
      context,
      MaterialPageRoute<CommissionDetailScreen>(
        builder: (context) => CommissionDetailScreen(commission: commission),
      ),
    ).then((_) => _loadCommissions());
  }

  void _showArtistSelection() async {
    final selectedArtist = await Navigator.push<core.ArtistProfileModel>(
      context,
      MaterialPageRoute(builder: (context) => const ArtistSelectionScreen()),
    );

    if (selectedArtist != null && mounted) {
      _showCommissionRequestDialog(selectedArtist);
    }
  }

  Future<void> _provideQuote(DirectCommissionModel commission) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => _QuoteProvisionDialog(commission: commission),
    );

    if (result == true) {
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('direct_commissions_quote_success'.tr()),
            backgroundColor: const Color(0xFF34D399),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _acceptCommission(DirectCommissionModel commission) async {
    try {
      await _commissionService.acceptCommission(commission.id);
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('direct_commissions_accept_success'.tr()),
            backgroundColor: const Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'direct_commissions_accept_error'.tr(namedArgs: {'error': '$e'}),
            ),
          ),
        );
      }
    }
  }

  Future<void> _markCompleted(DirectCommissionModel commission) async {
    try {
      await _commissionService.completeCommission(commission.id);
      await _loadCommissions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('direct_commissions_complete_success'.tr()),
            backgroundColor: const Color(0xFF34D399),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'direct_commissions_complete_error'.tr(
                namedArgs: {'error': '$e'},
              ),
            ),
          ),
        );
      }
    }
  }

  void _showCommissionRequestDialog(core.ArtistProfileModel selectedArtist) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final budgetController = TextEditingController();
    final deadlineController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: GlassPanel(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'direct_commissions_request_title'.tr(
                    namedArgs: {'name': selectedArtist.displayName},
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: GlassInputDecoration(
                    labelText: 'direct_commissions_request_field_title_label'
                        .tr(),
                    hintText: 'direct_commissions_request_field_title_hint'
                        .tr(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: GlassInputDecoration(
                    labelText:
                        'direct_commissions_request_field_description_label'
                            .tr(),
                    hintText:
                        'direct_commissions_request_field_description_hint'
                            .tr(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: budgetController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: GlassInputDecoration(
                    labelText: 'direct_commissions_request_field_budget_label'
                        .tr(),
                    hintText: 'direct_commissions_request_field_budget_hint'
                        .tr(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: deadlineController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: GlassInputDecoration(
                    labelText: 'direct_commissions_request_field_deadline_label'
                        .tr(),
                    hintText: 'direct_commissions_request_field_deadline_hint'
                        .tr(),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    HudButton.secondary(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'common_cancel'.tr(),
                      height: 48,
                    ),
                    const SizedBox(width: 16),
                    HudButton.primary(
                      onPressed: () async {
                        if (titleController.text.isEmpty ||
                            descriptionController.text.isEmpty ||
                            budgetController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'direct_commissions_request_missing_fields'
                                    .tr(),
                              ),
                              backgroundColor: const Color(0xFFFF3D8D),
                            ),
                          );
                          return;
                        }

                        try {
                          final budget =
                              double.tryParse(budgetController.text) ?? 0.0;
                          final deadline = _parseDeadline(
                            deadlineController.text,
                          );

                          await _commissionService.createCommissionRequest(
                            artistId: selectedArtist.id,
                            artistName: selectedArtist.displayName,
                            type: CommissionType.digital,
                            title: titleController.text,
                            description: descriptionController.text,
                            specs: CommissionSpecs(
                              size: 'Custom',
                              medium: 'Digital',
                              style: 'Custom',
                              colorScheme: 'Full Color',
                              revisions: 2,
                              commercialUse: false,
                              deliveryFormat: 'Digital File',
                              customRequirements: {
                                'budget': budget,
                                'notes': descriptionController.text,
                              },
                            ),
                            deadline: deadline,
                            metadata: {
                              'requestedVia': 'direct_request',
                              'budget': budget,
                            },
                          );

                          if (mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'direct_commissions_request_success'.tr(
                                    namedArgs: {
                                      'name': selectedArtist.displayName,
                                    },
                                  ),
                                ),
                                backgroundColor: const Color(0xFF34D399),
                              ),
                            );
                            await _loadCommissions();
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'direct_commissions_request_error'.tr(
                                    namedArgs: {'error': '$e'},
                                  ),
                                ),
                                backgroundColor: const Color(0xFFFF3D8D),
                              ),
                            );
                          }
                        }
                      },
                      text: 'direct_commissions_request_submit'.tr(),
                      icon: Icons.send,
                      height: 48,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  DateTime? _parseDeadline(String deadline) {
    if (deadline.isEmpty) return null;

    final now = DateTime.now();
    final lowerDeadline = deadline.toLowerCase().trim();

    // Handle various deadline formats
    if (lowerDeadline.contains('week')) {
      // Extract number from "2-3 weeks", "1 week", etc.
      final weekMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*week',
      ).firstMatch(lowerDeadline);
      if (weekMatch != null) {
        final weeks = int.tryParse(weekMatch.group(1) ?? '1') ?? 1;
        return now.add(Duration(days: weeks * 7));
      }
    } else if (lowerDeadline.contains('month')) {
      // Extract number from "2-3 months", "1 month", etc.
      final monthMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*month',
      ).firstMatch(lowerDeadline);
      if (monthMatch != null) {
        final months = int.tryParse(monthMatch.group(1) ?? '1') ?? 1;
        return DateTime(now.year, now.month + months, now.day);
      }
    } else if (lowerDeadline.contains('day')) {
      // Extract number from "5-7 days", "1 day", etc.
      final dayMatch = RegExp(
        r'(\d+)(?:\s*-\s*\d+)?\s*day',
      ).firstMatch(lowerDeadline);
      if (dayMatch != null) {
        final days = int.tryParse(dayMatch.group(1) ?? '1') ?? 1;
        return now.add(Duration(days: days));
      }
    }

    // Try to parse as a direct date format (MM/dd/yyyy)
    try {
      final parts = deadline.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }

    // Default fallback: assume 30 days for unrecognized formats
    return now.add(const Duration(days: 30));
  }
}

/// Dialog for artists to provide quotes for commission requests
class _QuoteProvisionDialog extends StatefulWidget {
  final DirectCommissionModel commission;

  const _QuoteProvisionDialog({required this.commission});

  @override
  State<_QuoteProvisionDialog> createState() => _QuoteProvisionDialogState();
}

class _QuoteProvisionDialogState extends State<_QuoteProvisionDialog> {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  final _totalPriceController = TextEditingController();
  final _depositPercentageController = TextEditingController(text: '50');
  final _quoteMessageController = TextEditingController();

  final intl.NumberFormat _currencyFormatter = intl.NumberFormat.currency(
    symbol: '\$',
  );
  final intl.DateFormat _dateFormat = intl.DateFormat('MMM d, yyyy');

  // Milestones
  final List<_MilestoneData> _milestones = [];

  // Estimated completion
  DateTime? _estimatedCompletion;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Initialize with one default milestone
    _addMilestone();
  }

  @override
  void dispose() {
    _totalPriceController.dispose();
    _depositPercentageController.dispose();
    _quoteMessageController.dispose();
    for (final milestone in _milestones) {
      milestone.dispose();
    }
    super.dispose();
  }

  void _addMilestone() {
    setState(() {
      _milestones.add(_MilestoneData());
    });
  }

  void _removeMilestone(int index) {
    if (index < 0 || index >= _milestones.length) {
      return;
    }
    setState(() {
      _milestones[index].dispose();
      _milestones.removeAt(index);
    });
  }

  Future<void> _selectEstimatedCompletion() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _estimatedCompletion ?? now.add(const Duration(days: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _estimatedCompletion = picked;
      });
    }
  }

  Future<void> _submitQuote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_estimatedCompletion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('direct_commissions_quote_missing_date'.tr()),
          backgroundColor: const Color(0xFFFF3D8D),
        ),
      );
      return;
    }

    if (_milestones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('direct_commissions_quote_missing_milestone'.tr()),
          backgroundColor: const Color(0xFFFF3D8D),
        ),
      );
      return;
    }

    for (int i = 0; i < _milestones.length; i++) {
      if (!_milestones[i].validate()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'direct_commissions_quote_missing_milestone_fields'.tr(
                namedArgs: {'index': '${i + 1}'},
              ),
            ),
            backgroundColor: const Color(0xFFFF3D8D),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final totalPrice = double.parse(_totalPriceController.text);
      final depositPercentage = double.parse(_depositPercentageController.text);

      // Convert milestone data to CommissionMilestone objects
      final milestones = _milestones.map((m) {
        return CommissionMilestone(
          id:
              DateTime.now().millisecondsSinceEpoch.toString() +
              m.hashCode.toString(),
          title: m.titleController.text,
          description: m.descriptionController.text,
          amount: double.parse(m.amountController.text),
          dueDate: m.dueDate!,
          status: MilestoneStatus.pending,
        );
      }).toList();

      await _commissionService.provideQuote(
        commissionId: widget.commission.id,
        totalPrice: totalPrice,
        depositPercentage: depositPercentage,
        milestones: milestones,
        estimatedCompletion: _estimatedCompletion!,
        quoteMessage: _quoteMessageController.text.isNotEmpty
            ? _quoteMessageController.text
            : null,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'direct_commissions_quote_error'.tr(namedArgs: {'error': '$e'}),
            ),
            backgroundColor: const Color(0xFFFF3D8D),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount =
        _totalPriceController.text.isNotEmpty &&
            _depositPercentageController.text.isNotEmpty
        ? (double.tryParse(_totalPriceController.text) ?? 0) *
              (double.tryParse(_depositPercentageController.text) ?? 0) /
              100
        : 0.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: GlassPanel(
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.request_quote, color: Colors.white),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'direct_commissions_quote_title'.tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'direct_commissions_quote_for_client'.tr(
                              namedArgs: {'name': widget.commission.clientName},
                            ),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.commission.title,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.commission.description,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'direct_commissions_quote_section_pricing'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _totalPriceController,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                decoration: GlassInputDecoration(
                                  labelText:
                                      'direct_commissions_quote_total_label'
                                          .tr(),
                                  prefix: Text(
                                    '\$ ',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'direct_commissions_form_error_required'
                                        .tr();
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'direct_commissions_form_error_number'
                                        .tr();
                                  }
                                  if (double.parse(value) <= 0) {
                                    return 'direct_commissions_form_error_positive'
                                        .tr();
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _depositPercentageController,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                decoration: GlassInputDecoration(
                                  labelText:
                                      'direct_commissions_quote_deposit_label'
                                          .tr(),
                                  suffixText: '%',
                                ),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'direct_commissions_form_error_required'
                                        .tr();
                                  }
                                  final num = double.tryParse(value);
                                  if (num == null) {
                                    return 'direct_commissions_form_error_number'
                                        .tr();
                                  }
                                  if (num < 0 || num > 100) {
                                    return 'direct_commissions_form_error_range'
                                        .tr();
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}),
                              ),
                            ),
                          ],
                        ),
                        if (depositAmount > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'direct_commissions_quote_deposit_value'.tr(
                              namedArgs: {
                                'amount': _currencyFormatter.format(
                                  depositAmount,
                                ),
                              },
                            ),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text(
                          'direct_commissions_quote_estimated_label'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: _selectEstimatedCompletion,
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 20,
                                  color: Colors.white.withValues(alpha: 0.85),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    _estimatedCompletion != null
                                        ? _dateFormat.format(
                                            _estimatedCompletion!,
                                          )
                                        : 'direct_commissions_quote_estimated_placeholder'
                                              .tr(),
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'direct_commissions_quote_milestones_label'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            HudButton.secondary(
                              onPressed: _addMilestone,
                              text: 'direct_commissions_quote_add_milestone'
                                  .tr(),
                              icon: Icons.add,
                              height: 44,
                              width: 200,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(_milestones.length, (index) {
                          return _MilestoneCard(
                            milestone: _milestones[index],
                            index: index,
                            onRemove: _milestones.length > 1
                                ? () => _removeMilestone(index)
                                : null,
                          );
                        }),
                        const SizedBox(height: 24),
                        Text(
                          'direct_commissions_quote_message_label'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _quoteMessageController,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                          decoration: GlassInputDecoration(
                            hintText: 'direct_commissions_quote_message_hint'
                                .tr(),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: HudButton.secondary(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        text: 'common_cancel'.tr(),
                        height: 52,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: HudButton.primary(
                        onPressed: _isSubmitting ? null : _submitQuote,
                        text: 'direct_commissions_quote_submit'.tr(),
                        icon: Icons.send,
                        height: 52,
                        isLoading: _isSubmitting,
                      ),
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
}

/// Helper class to manage milestone form data
class _MilestoneData {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  DateTime? dueDate;

  bool validate() {
    return titleController.text.isNotEmpty &&
        descriptionController.text.isNotEmpty &&
        amountController.text.isNotEmpty &&
        double.tryParse(amountController.text) != null &&
        dueDate != null;
  }

  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    amountController.dispose();
  }
}

/// Widget for displaying and editing a milestone
class _MilestoneCard extends StatefulWidget {
  final _MilestoneData milestone;
  final int index;
  final VoidCallback? onRemove;

  const _MilestoneCard({
    required this.milestone,
    required this.index,
    this.onRemove,
  });

  @override
  State<_MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<_MilestoneCard> {
  final intl.DateFormat _milestoneDateFormat = intl.DateFormat('MMM d, yyyy');

  Future<void> _selectDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.milestone.dueDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        widget.milestone.dueDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'direct_commissions_milestone_label'.tr(
                  namedArgs: {'index': '${widget.index + 1}'},
                ),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              if (widget.onRemove != null)
                IconButton(
                  icon: const Icon(
                    Icons.delete,
                    size: 20,
                    color: Color(0xFFFF3D8D),
                  ),
                  onPressed: widget.onRemove,
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.milestone.titleController,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            decoration: GlassInputDecoration(
              labelText: 'direct_commissions_milestone_title_label'.tr(),
              isDense: true,
            ),
            validator: (value) => value?.isEmpty ?? true
                ? 'direct_commissions_form_error_required'.tr()
                : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: widget.milestone.descriptionController,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            decoration: GlassInputDecoration(
              labelText: 'direct_commissions_milestone_description_label'.tr(),
              isDense: true,
            ),
            maxLines: 2,
            validator: (value) => value?.isEmpty ?? true
                ? 'direct_commissions_form_error_required'.tr()
                : null,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.milestone.amountController,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: GlassInputDecoration(
                    labelText: 'direct_commissions_milestone_amount_label'.tr(),
                    prefixText: '\$ ',
                    isDense: true,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'direct_commissions_form_error_required'.tr();
                    }
                    if (double.tryParse(value) == null) {
                      return 'direct_commissions_form_error_number'.tr();
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: _selectDueDate,
                  child: GlassCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 18,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.milestone.dueDate != null
                                ? _milestoneDateFormat.format(
                                    widget.milestone.dueDate!,
                                  )
                                : 'direct_commissions_milestone_due_placeholder'
                                      .tr(),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
