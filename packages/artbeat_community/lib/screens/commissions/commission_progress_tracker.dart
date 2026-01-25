import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart' as intl;

import '../../models/direct_commission_model.dart';
import '../../widgets/widgets.dart';
import 'commission_detail_screen.dart';

class CommissionProgressTracker extends StatelessWidget {
  const CommissionProgressTracker({super.key, required this.commission});

  final DirectCommissionModel commission;

  static const List<CommissionStatus> _statusSequence = [
    CommissionStatus.pending,
    CommissionStatus.quoted,
    CommissionStatus.accepted,
    CommissionStatus.inProgress,
    CommissionStatus.revision,
    CommissionStatus.completed,
    CommissionStatus.delivered,
    CommissionStatus.cancelled,
    CommissionStatus.disputed,
  ];

  static final intl.NumberFormat _currencyFormatter =
      intl.NumberFormat.currency(symbol: r'$');
  static final intl.DateFormat _dateFormat = intl.DateFormat('MMM d, yyyy');

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 32;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: HudTopBar(
        title: 'commission_progress_app_bar'.tr(),
        glassBackground: true,
        subtitle: '',
      ),
      body: WorldBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
            children: [
              _buildSummaryCard(context),
              const SizedBox(height: 16),
              _buildTimelineCard(context),
              const SizedBox(height: 16),
              _buildMilestonesCard(context),
              const SizedBox(height: 16),
              _buildImportantDatesCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final accent = _statusAccentColor(commission.status);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      showAccentGlow: true,
      accentColor: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _statusIcon(commission.status),
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(commission.status),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            commission.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: _ProgressPalette.textPrimary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'commission_progress_header_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ProgressPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildParticipantChip(
                icon: Icons.brush,
                label: 'commission_progress_artist_label'.tr(),
                value: commission.artistName,
              ),
              _buildParticipantChip(
                icon: Icons.person,
                label: 'commission_progress_client_label'.tr(),
                value: commission.clientName,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'commission_progress_budget_label'.tr(),
                  value: _currencyFormatter.format(commission.totalPrice),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  label: 'commission_progress_deposit_label'.tr(),
                  value: _currencyFormatter.format(commission.depositAmount),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricTile(
                  label: 'commission_progress_remaining_label'.tr(),
                  value: _currencyFormatter.format(commission.remainingAmount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: GradientCTAButton(
                  text: 'commission_progress_primary_cta'.tr(),
                  icon: Icons.open_in_new,
                  onPressed: () => _openCommissionDetail(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: HudButton.secondary(
                  onPressed: () => Navigator.of(context).pop(),
                  text: 'commission_progress_secondary_cta'.tr(),
                  icon: Icons.close,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    final rawIndex = _statusSequence.indexOf(commission.status);
    final currentIndex = rawIndex == -1 ? 0 : rawIndex;
    final progress = _statusSequence.length <= 1
        ? 1.0
        : currentIndex / (_statusSequence.length - 1);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'commission_progress_timeline_title'.tr(),
            subtitle: 'commission_progress_timeline_subtitle'.tr(),
          ),
          const SizedBox(height: 24),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        _ProgressPalette.purpleAccent,
                        _ProgressPalette.tealAccent,
                        _ProgressPalette.greenAccent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: _statusSequence.map((status) {
              final index = _statusSequence.indexOf(status);
              final isCompleted = index <= currentIndex;
              final isCurrent = index == currentIndex;

              return _StatusBadge(
                label: _statusLabel(status),
                icon: _statusIcon(status),
                accent: _statusAccentColor(status),
                isCompleted: isCompleted,
                isCurrent: isCurrent,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestonesCard(BuildContext context) {
    final milestones = commission.milestones;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'commission_progress_milestones_title'.tr(),
            subtitle: 'commission_progress_milestones_subtitle'.tr(),
          ),
          const SizedBox(height: 24),
          if (milestones.isEmpty)
            _buildEmptyState(
              icon: Icons.flag_circle,
              message: 'commission_progress_milestones_empty'.tr(),
            )
          else
            Column(
              children: [
                for (var i = 0; i < milestones.length; i++) ...[
                  _MilestoneTile(
                    milestone: milestones[i],
                    amount: _currencyFormatter.format(milestones[i].amount),
                    dueLabel: 'commission_progress_milestone_due'.tr(
                      args: [_formatDate(milestones[i].dueDate)],
                    ),
                    statusLabel: _milestoneStatusLabel(milestones[i].status),
                    accent: _milestoneAccent(milestones[i].status),
                    completedLabel: _milestoneCompletionLabel(milestones[i]),
                  ),
                  if (i != milestones.length - 1) const SizedBox(height: 16),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildImportantDatesCard() {
    final entries = <_DateEntry>[
      _DateEntry(
        label: 'commission_progress_date_requested'.tr(),
        date: commission.requestedAt,
        icon: Icons.bolt,
      ),
      if (commission.acceptedAt != null)
        _DateEntry(
          label: 'commission_progress_date_accepted'.tr(),
          date: commission.acceptedAt!,
          icon: Icons.check_circle,
        ),
      if (commission.deadline != null)
        _DateEntry(
          label: 'commission_progress_date_deadline'.tr(),
          date: commission.deadline!,
          icon: Icons.calendar_today,
        ),
      if (commission.completedAt != null)
        _DateEntry(
          label: 'commission_progress_date_completed'.tr(),
          date: commission.completedAt!,
          icon: Icons.done_all,
        ),
    ];

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            title: 'commission_progress_important_dates_title'.tr(),
            subtitle: 'commission_progress_important_dates_subtitle'.tr(),
          ),
          const SizedBox(height: 24),
          Column(
            children: entries
                .map((entry) => _buildDateRow(entry))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _ProgressPalette.textPrimary,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _ProgressPalette.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: _ProgressPalette.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _ProgressPalette.textSecondary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ProgressPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _ProgressPalette.textSecondary,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: _ProgressPalette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: _ProgressPalette.textSecondary),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _ProgressPalette.textSecondary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateRow(_DateEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Icon(entry.icon, color: _ProgressPalette.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _ProgressPalette.textSecondary,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(entry.date),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: _ProgressPalette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCommissionDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => CommissionDetailScreen(commission: commission),
      ),
    );
  }

  String _statusLabel(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return 'commission_hub_status_pending'.tr();
      case CommissionStatus.quoted:
        return 'commission_hub_status_quoted'.tr();
      case CommissionStatus.accepted:
        return 'commission_hub_status_accepted'.tr();
      case CommissionStatus.inProgress:
        return 'commission_hub_status_in_progress'.tr();
      case CommissionStatus.revision:
        return 'commission_hub_status_revision'.tr();
      case CommissionStatus.completed:
        return 'commission_hub_status_completed'.tr();
      case CommissionStatus.delivered:
        return 'commission_hub_status_delivered'.tr();
      case CommissionStatus.cancelled:
        return 'commission_hub_status_cancelled'.tr();
      case CommissionStatus.disputed:
        return 'commission_hub_status_disputed'.tr();
    }
  }

  IconData _statusIcon(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return Icons.schedule;
      case CommissionStatus.quoted:
        return Icons.description;
      case CommissionStatus.accepted:
        return Icons.verified;
      case CommissionStatus.inProgress:
        return Icons.brush;
      case CommissionStatus.revision:
        return Icons.edit;
      case CommissionStatus.completed:
        return Icons.done_all;
      case CommissionStatus.delivered:
        return Icons.local_shipping;
      case CommissionStatus.cancelled:
        return Icons.close;
      case CommissionStatus.disputed:
        return Icons.warning_amber;
    }
  }

  Color _statusAccentColor(CommissionStatus status) {
    switch (status) {
      case CommissionStatus.pending:
        return _ProgressPalette.yellowAccent;
      case CommissionStatus.quoted:
        return _ProgressPalette.tealAccent;
      case CommissionStatus.accepted:
        return _ProgressPalette.greenAccent;
      case CommissionStatus.inProgress:
        return _ProgressPalette.purpleAccent;
      case CommissionStatus.revision:
        return _ProgressPalette.yellowAccent;
      case CommissionStatus.completed:
        return _ProgressPalette.greenAccent;
      case CommissionStatus.delivered:
        return _ProgressPalette.greenAccent;
      case CommissionStatus.cancelled:
        return _ProgressPalette.pinkAccent;
      case CommissionStatus.disputed:
        return _ProgressPalette.pinkAccent;
    }
  }

  String _milestoneStatusLabel(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.pending:
        return 'commission_progress_milestone_status_pending'.tr();
      case MilestoneStatus.inProgress:
        return 'commission_progress_milestone_status_in_progress'.tr();
      case MilestoneStatus.completed:
        return 'commission_progress_milestone_status_completed'.tr();
      case MilestoneStatus.paid:
        return 'commission_progress_milestone_status_paid'.tr();
    }
  }

  Color _milestoneAccent(MilestoneStatus status) {
    switch (status) {
      case MilestoneStatus.pending:
        return _ProgressPalette.yellowAccent;
      case MilestoneStatus.inProgress:
        return _ProgressPalette.tealAccent;
      case MilestoneStatus.completed:
        return _ProgressPalette.purpleAccent;
      case MilestoneStatus.paid:
        return _ProgressPalette.greenAccent;
    }
  }

  String? _milestoneCompletionLabel(CommissionMilestone milestone) {
    if (milestone.completedAt == null) {
      return null;
    }
    final formatted = _formatDate(milestone.completedAt!);
    final key = milestone.status == MilestoneStatus.paid
        ? 'commission_progress_milestone_paid_on'
        : 'commission_progress_milestone_completed_on';
    return key.tr(args: [formatted]);
  }

  String _formatDate(DateTime date) => _dateFormat.format(date);
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.icon,
    required this.accent,
    required this.isCompleted,
    required this.isCurrent,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final borderColor = isCurrent
        ? accent
        : Colors.white.withValues(alpha: 0.18);
    final fillColor = isCompleted
        ? accent.withValues(alpha: 0.15)
        : Colors.white.withValues(alpha: 0.04);

    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: isCurrent ? 1.5 : 1),
        color: fillColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted
                  ? accent.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
              color: Colors.white,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.amount,
    required this.dueLabel,
    required this.statusLabel,
    required this.accent,
    this.completedLabel,
  });

  final CommissionMilestone milestone;
  final String amount;
  final String dueLabel;
  final String statusLabel;
  final Color accent;
  final String? completedLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
        color: accent.withValues(alpha: 0.08),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  milestone.title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _ProgressPalette.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            milestone.description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _ProgressPalette.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    amount,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _ProgressPalette.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dueLabel,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _ProgressPalette.textSecondary,
                    ),
                  ),
                ],
              ),
              if (completedLabel != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Icon(Icons.verified, color: accent),
                    const SizedBox(height: 4),
                    Text(
                      completedLabel!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ProgressPalette.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateEntry {
  const _DateEntry({
    required this.label,
    required this.date,
    required this.icon,
  });

  final String label;
  final DateTime date;
  final IconData icon;
}

class _ProgressPalette {
  static const Color textPrimary = Color(0xFFF6F7FF);
  static const Color textSecondary = Color(0xCCF6F7FF);
  static const Color purpleAccent = Color(0xFF7C4DFF);
  static const Color tealAccent = Color(0xFF22D3EE);
  static const Color greenAccent = Color(0xFF34D399);
  static const Color pinkAccent = Color(0xFFFF3D8D);
  static const Color yellowAccent = Color(0xFFFFC857);
}
