import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart' as intl;
import 'package:path_provider/path_provider.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_core/shared_widgets.dart';

import '../../models/direct_commission_model.dart';
import '../../services/direct_commission_service.dart';
import '../../services/stripe_service.dart';

class CommissionDetailScreen extends StatefulWidget {
  const CommissionDetailScreen({super.key, required this.commission});

  final DirectCommissionModel commission;

  @override
  State<CommissionDetailScreen> createState() => _CommissionDetailScreenState();
}

class _CommissionDetailScreenState extends State<CommissionDetailScreen>
    with SingleTickerProviderStateMixin {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final StripeService _stripeService = StripeService();
  final TextEditingController _messageController = TextEditingController();

  late final TabController _tabController;
  DirectCommissionModel? _commission;
  String? _currentUserId;

  final intl.DateFormat _dateFormatter = intl.DateFormat('MMM d, yyyy');
  final intl.DateFormat _dateTimeFormatter = intl.DateFormat(
    'MMM d, yyyy • h:mm a',
  );
  final intl.NumberFormat _currencyFormatter = intl.NumberFormat.currency(
    symbol: '\$',
  );

  final Map<CommissionStatus, IconData> _statusIcons = {
    CommissionStatus.pending: Icons.schedule,
    CommissionStatus.quoted: Icons.request_quote,
    CommissionStatus.accepted: Icons.handshake,
    CommissionStatus.inProgress: Icons.brush,
    CommissionStatus.revision: Icons.edit,
    CommissionStatus.completed: Icons.check_circle,
    CommissionStatus.delivered: Icons.local_shipping,
    CommissionStatus.cancelled: Icons.cancel,
    CommissionStatus.disputed: Icons.warning,
  };

  final Map<CommissionStatus, String> _statusLabelKeys = {
    CommissionStatus.pending: 'commission_status_pending',
    CommissionStatus.quoted: 'commission_status_quoted',
    CommissionStatus.accepted: 'commission_status_accepted',
    CommissionStatus.inProgress: 'commission_status_in_progress',
    CommissionStatus.revision: 'commission_status_revision',
    CommissionStatus.completed: 'commission_status_completed',
    CommissionStatus.delivered: 'commission_status_delivered',
    CommissionStatus.cancelled: 'commission_status_cancelled',
    CommissionStatus.disputed: 'commission_status_disputed',
  };

  final Map<CommissionStatus, String> _statusDescriptionArtistKeys = {
    CommissionStatus.pending: 'commission_detail_status_pending_artist',
    CommissionStatus.quoted: 'commission_detail_status_quoted_artist',
    CommissionStatus.inProgress: 'commission_detail_status_in_progress_artist',
  };

  final Map<CommissionStatus, String> _statusDescriptionClientKeys = {
    CommissionStatus.pending: 'commission_detail_status_pending_client',
    CommissionStatus.quoted: 'commission_detail_status_quoted_client',
    CommissionStatus.accepted: 'commission_detail_status_accepted_client',
    CommissionStatus.revision: 'commission_detail_status_revision_client',
  };

  final Map<CommissionStatus, String> _statusDescriptionNeutralKeys = {
    CommissionStatus.accepted: 'commission_detail_status_accepted_neutral',
    CommissionStatus.inProgress: 'commission_detail_status_in_progress_neutral',
    CommissionStatus.completed: 'commission_detail_status_completed_neutral',
    CommissionStatus.delivered: 'commission_detail_status_delivered_neutral',
    CommissionStatus.cancelled: 'commission_detail_status_cancelled_neutral',
    CommissionStatus.disputed: 'commission_detail_status_disputed_neutral',
  };

  final Map<CommissionStatus, Color> _statusColors = {
    CommissionStatus.pending: const Color(0xFFFFC857),
    CommissionStatus.quoted: const Color(0xFF22D3EE),
    CommissionStatus.accepted: const Color(0xFF34D399),
    CommissionStatus.inProgress: const Color(0xFF7C4DFF),
    CommissionStatus.revision: const Color(0xFFFFA63D),
    CommissionStatus.completed: const Color(0xFF34D399),
    CommissionStatus.delivered: const Color(0xFF0FB9B1),
    CommissionStatus.cancelled: const Color(0xFFFF3D8D),
    CommissionStatus.disputed: const Color(0xFFFF5F6D),
  };

  final Map<MilestoneStatus, Color> _milestoneStatusColors = {
    MilestoneStatus.pending: const Color(0xFFFFC857),
    MilestoneStatus.inProgress: const Color(0xFF22D3EE),
    MilestoneStatus.completed: const Color(0xFF34D399),
    MilestoneStatus.paid: const Color(0xFF0FB9B1),
  };

  final Map<MilestoneStatus, String> _milestoneStatusKeys = {
    MilestoneStatus.pending: 'commission_detail_milestone_status_pending',
    MilestoneStatus.inProgress:
        'commission_detail_milestone_status_in_progress',
    MilestoneStatus.completed: 'commission_detail_milestone_status_completed',
    MilestoneStatus.paid: 'commission_detail_milestone_status_paid',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _commission = widget.commission;
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _loadCommissionDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadCommissionDetails() async {
    try {
      final commission = await _commissionService.getCommission(
        widget.commission.id,
      );
      if (!mounted) return;
      setState(() {
        _commission = commission;
      });
    } catch (e) {
      core.AppLogger.error('Failed to load commission details: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_error_loading'.tr(namedArgs: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  bool get _isArtist => _commission?.artistId == _currentUserId;
  bool get _isClient => _commission?.clientId == _currentUserId;

  @override
  Widget build(BuildContext context) {
    final commission = _commission;

    return WorldBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: HudTopBar(
          title: 'commission_detail_title'.tr(),
          glassBackground: true,
          actions: [
            if (commission != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: _handleMenuAction,
                itemBuilder: (context) => _buildMenuItems(commission),
              ),
          ],
          subtitle: '',
        ),
        body: SafeArea(
          child: commission == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    _buildStatusBanner(),
                    const SizedBox(height: 16),
                    GlassCard(
                      padding: const EdgeInsets.all(8),
                      child: TabBar(
                        controller: _tabController,
                        labelStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        unselectedLabelColor: Colors.white.withValues(
                          alpha: 0.6,
                        ),
                        labelColor: Colors.white,
                        indicator: BoxDecoration(
                          gradient: _DetailPalette.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: 'commission_detail_tab_overview'.tr()),
                          Tab(text: 'commission_detail_tab_messages'.tr()),
                          Tab(text: 'commission_detail_tab_files'.tr()),
                          Tab(text: 'commission_detail_tab_milestones'.tr()),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildMessagesTab(),
                          _buildFilesTab(),
                          _buildMilestonesTab(),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    final status = _commission!.status;
    final statusColor = _statusColors[status] ?? Colors.white;
    final title = _statusLabelKeys[status]?.tr() ?? status.name;

    String? descriptionKey;
    if (_isArtist) {
      descriptionKey = _statusDescriptionArtistKeys[status];
    } else if (_isClient) {
      descriptionKey = _statusDescriptionClientKeys[status];
    }
    descriptionKey ??= _statusDescriptionNeutralKeys[status];

    final description = descriptionKey != null
        ? descriptionKey.tr()
        : status.displayName;

    return GlassCard(
      showAccentGlow: true,
      accentColor: statusColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: _DetailPalette.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(_statusIcons[status], color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              if (_shouldShowActionButton())
                HudButton.primary(
                  onPressed: _handlePrimaryAction,
                  text: _getPrimaryActionText(),
                  icon: Icons.flash_on,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final commission = _commission!;

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_detail_section_info_title'.tr(),
                'commission_detail_section_info_subtitle'.tr(),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'commission_detail_info_type'.tr(),
                commission.type.displayName,
              ),
              _buildInfoRow(
                'commission_detail_info_client'.tr(),
                commission.clientName,
              ),
              _buildInfoRow(
                'commission_detail_info_artist'.tr(),
                commission.artistName,
              ),
              _buildInfoRow(
                'commission_detail_info_requested'.tr(),
                _dateTimeFormatter.format(commission.requestedAt),
              ),
              if (commission.deadline != null)
                _buildInfoRow(
                  'commission_detail_info_deadline'.tr(),
                  _dateTimeFormatter.format(commission.deadline!),
                ),
              if (commission.totalPrice > 0)
                _buildInfoRow(
                  'commission_detail_info_total'.tr(),
                  _currencyFormatter.format(commission.totalPrice),
                ),
              if (commission.depositAmount > 0)
                _buildInfoRow(
                  'commission_detail_info_deposit'.tr(),
                  _currencyFormatter.format(commission.depositAmount),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_detail_section_description_title'.tr(),
                'commission_detail_section_description_subtitle'.tr(),
              ),
              const SizedBox(height: 12),
              Text(
                commission.description.isEmpty
                    ? 'commission_detail_description_empty'.tr()
                    : commission.description,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'commission_detail_section_specs_title'.tr(),
                'commission_detail_section_specs_subtitle'.tr(),
              ),
              const SizedBox(height: 16),
              _buildInfoRow(
                'commission_detail_specs_size'.tr(),
                commission.specs.size,
              ),
              _buildInfoRow(
                'commission_detail_specs_medium'.tr(),
                commission.specs.medium,
              ),
              _buildInfoRow(
                'commission_detail_specs_style'.tr(),
                commission.specs.style,
              ),
              _buildInfoRow(
                'commission_detail_specs_color'.tr(),
                commission.specs.colorScheme,
              ),
              _buildInfoRow(
                'commission_detail_specs_revisions'.tr(),
                commission.specs.revisions.toString(),
              ),
              _buildInfoRow(
                'commission_detail_specs_commercial'.tr(),
                commission.specs.commercialUse
                    ? 'commission_detail_value_yes'.tr()
                    : 'commission_detail_value_no'.tr(),
              ),
              _buildInfoRow(
                'commission_detail_specs_delivery'.tr(),
                commission.specs.deliveryFormat,
              ),
              if (commission.specs.customRequirements.isNotEmpty)
                _buildInfoRow(
                  'commission_detail_specs_custom'.tr(),
                  commission.specs.customRequirements['description']
                          ?.toString() ??
                      'commission_detail_specs_custom_default'.tr(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesTab() {
    final messages = _commission!.messages;

    return Column(
      children: [
        Expanded(
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: messages.isEmpty
                ? _buildEmptyState(
                    'commission_detail_messages_empty_title',
                    'commission_detail_messages_empty_subtitle',
                    Icons.chat_bubble_outline,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isCurrentUser = message.senderId == _currentUserId;
                      final bubbleColor = isCurrentUser
                          ? _DetailPalette.primaryGradient
                          : _DetailPalette.secondaryGradient;

                      return Align(
                        alignment: isCurrentUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          decoration: BoxDecoration(
                            gradient: bubbleColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(isCurrentUser ? 16 : 6),
                              topRight: Radius.circular(isCurrentUser ? 6 : 16),
                              bottomLeft: const Radius.circular(16),
                              bottomRight: const Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isCurrentUser)
                                Text(
                                  message.senderName,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              if (!isCurrentUser) const SizedBox(height: 4),
                              Text(
                                message.message,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _dateTimeFormatter.format(message.timestamp),
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: GlassTextField(
                  controller: _messageController,
                  hintText: 'commission_detail_message_placeholder'.tr(),
                  maxLines: 3,
                ),
              ),
              const SizedBox(width: 12),
              HudButton.primary(
                width: 140,
                onPressed: _sendMessage,
                text: 'commission_detail_message_send'.tr(),
                icon: Icons.send,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilesTab() {
    final files = _commission!.files;

    if (files.isEmpty) {
      return GlassCard(
        padding: EdgeInsets.zero,
        child: _buildEmptyState(
          'commission_detail_files_empty_title',
          'commission_detail_files_empty_subtitle',
          Icons.folder_open,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: files.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final file = files[index];
        final uploadedByYou = file.uploadedBy == _currentUserId;
        final uploaderKey = uploadedByYou
            ? 'commission_detail_file_uploaded_by_you'
            : 'commission_detail_file_uploaded_by_other';

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: _DetailPalette.secondaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_getFileIcon(file.name), color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          uploaderKey.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  HudButton.secondary(
                    width: 120,
                    onPressed: () => _downloadFile(file),
                    text: 'commission_detail_file_download'.tr(),
                    icon: Icons.download,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildInfoRow('commission_detail_file_type'.tr(), file.type),
              _buildInfoRow(
                'commission_detail_file_size'.tr(),
                _formatFileSize(file.sizeBytes),
              ),
              if (file.description != null && file.description!.isNotEmpty)
                _buildInfoRow(
                  'commission_detail_file_description'.tr(),
                  file.description!,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMilestonesTab() {
    final milestones = _commission!.milestones;

    if (milestones.isEmpty) {
      return GlassCard(
        padding: EdgeInsets.zero,
        child: _buildEmptyState(
          'commission_detail_milestones_empty_title',
          'commission_detail_milestones_empty_subtitle',
          Icons.flag_outlined,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 32),
      itemCount: milestones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final milestone = milestones[index];
        final statusColor =
            _milestoneStatusColors[milestone.status] ?? Colors.white;
        final statusLabel =
            _milestoneStatusKeys[milestone.status]?.tr() ??
            milestone.status.name;

        return GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      milestone.title,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                milestone.description,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 12),
              _buildInfoRow(
                'commission_detail_milestone_amount'.tr(),
                _currencyFormatter.format(milestone.amount),
              ),
              _buildInfoRow(
                'commission_detail_milestone_due'.tr(),
                _dateFormatter.format(milestone.dueDate),
              ),
              if (milestone.status == MilestoneStatus.pending && _isClient)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: HudButton.primary(
                    onPressed: () => _payMilestone(milestone),
                    text: 'commission_detail_milestone_pay'.tr(),
                    icon: Icons.credit_card,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty
                  ? 'commission_detail_value_not_provided'.tr()
                  : value,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String titleKey, String subtitleKey, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.6), size: 48),
            const SizedBox(height: 12),
            Text(
              titleKey.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitleKey.tr(),
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    DirectCommissionModel commission,
  ) {
    final items = <PopupMenuEntry<String>>[];

    if (_isArtist && commission.status == CommissionStatus.pending) {
      items.add(
        PopupMenuItem(
          value: 'provide_quote',
          child: Text('commission_detail_menu_provide_quote'.tr()),
        ),
      );
    }

    if (_isClient && commission.status == CommissionStatus.quoted) {
      items.add(
        PopupMenuItem(
          value: 'accept_quote',
          child: Text('commission_detail_menu_accept_quote'.tr()),
        ),
      );
    }

    if (_isClient && _shouldShowDepositAction()) {
      items.add(
        PopupMenuItem(
          value: 'pay_deposit',
          child: Text('commission_detail_menu_pay_deposit'.tr()),
        ),
      );
    }

    if (_isArtist && commission.status == CommissionStatus.inProgress) {
      items.add(
        PopupMenuItem(
          value: 'mark_complete',
          child: Text('commission_detail_menu_mark_complete'.tr()),
        ),
      );
    }

    items.add(
      PopupMenuItem(
        value: 'cancel',
        child: Text('commission_detail_menu_cancel'.tr()),
      ),
    );

    return items;
  }

  bool _shouldShowDepositAction() {
    final commission = _commission;
    if (commission == null) return false;
    return commission.status == CommissionStatus.accepted &&
        _isClient &&
        commission.depositAmount > 0;
  }

  bool _shouldShowActionButton() {
    final status = _commission!.status;
    return (status == CommissionStatus.pending && _isArtist) ||
        (status == CommissionStatus.quoted && _isClient) ||
        _shouldShowDepositAction() ||
        (status == CommissionStatus.inProgress && _isArtist);
  }

  String _getPrimaryActionText() {
    final status = _commission!.status;
    if (status == CommissionStatus.pending && _isArtist) {
      return 'commission_detail_action_provide_quote'.tr();
    } else if (status == CommissionStatus.quoted && _isClient) {
      return 'commission_detail_action_accept_quote'.tr();
    } else if (_shouldShowDepositAction()) {
      return 'commission_detail_action_pay_deposit'.tr(
        namedArgs: {
          'amount': _currencyFormatter.format(_commission!.depositAmount),
        },
      );
    } else if (status == CommissionStatus.inProgress && _isArtist) {
      return 'commission_detail_action_mark_complete'.tr();
    }
    return '';
  }

  void _handlePrimaryAction() {
    final status = _commission!.status;
    if (status == CommissionStatus.pending && _isArtist) {
      _provideQuote();
    } else if (status == CommissionStatus.quoted && _isClient) {
      _acceptQuote();
    } else if (_shouldShowDepositAction()) {
      _payDeposit();
    } else if (status == CommissionStatus.inProgress && _isArtist) {
      _markComplete();
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'provide_quote':
        _provideQuote();
        break;
      case 'accept_quote':
        _acceptQuote();
        break;
      case 'pay_deposit':
        _payDeposit();
        break;
      case 'mark_complete':
        _markComplete();
        break;
      case 'cancel':
        _cancelCommission();
        break;
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    try {
      await _commissionService.addMessage(
        _commission!.id,
        _messageController.text.trim(),
      );
      _messageController.clear();
      await _loadCommissionDetails();
    } catch (e) {
      core.AppLogger.error('Failed to send commission message: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_error_message_send'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  void _provideQuote() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const QuoteProvisionDialog(),
    ).then((result) {
      if (result != null) {
        _submitQuote(
          result['price'] as double,
          result['description'] as String,
          result['timeline'] as String,
          result['milestones'] as List<Map<String, dynamic>>,
        );
      }
    });
  }

  Future<void> _submitQuote(
    double price,
    String description,
    String timeline,
    List<Map<String, dynamic>> milestoneMaps,
  ) async {
    final milestones = milestoneMaps
        .map(
          (m) => CommissionMilestone(
            id:
                DateTime.now().millisecondsSinceEpoch.toString() +
                m['title'].hashCode.toString(),
            title: m['title'] as String,
            description: m['description'] as String,
            amount: m['amount'] as double,
            dueDate: m['dueDate'] as DateTime,
            status: MilestoneStatus.pending,
          ),
        )
        .toList();

    try {
      await _commissionService.provideQuote(
        commissionId: _commission!.id,
        totalPrice: price,
        depositPercentage: 50.0,
        milestones: milestones,
        estimatedCompletion: _parseTimeline(timeline),
        quoteMessage: description,
      );
      await _loadCommissionDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_detail_toast_quote_success'.tr())),
      );
    } catch (e) {
      core.AppLogger.error('Failed to submit commission quote: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_quote_error'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _acceptQuote() async {
    try {
      await _commissionService.acceptCommission(_commission!.id);
      await _loadCommissionDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_detail_toast_accept_success'.tr())),
      );
    } catch (e) {
      core.AppLogger.error('Failed to accept commission quote: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_accept_error'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _payDeposit() async {
    try {
      await _stripeService.processCommissionDeposit(
        commissionId: _commission!.id,
        amount: _commission!.depositAmount,
        message: 'commission_detail_payment_deposit_memo'.tr(
          namedArgs: {'title': _commission!.title},
        ),
      );
      await _loadCommissionDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_detail_toast_deposit_success'.tr())),
      );
    } catch (e) {
      core.AppLogger.error('Failed to process commission deposit: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_deposit_error'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _markComplete() async {
    try {
      await _commissionService.completeCommission(_commission!.id);
      await _loadCommissionDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('commission_detail_toast_complete_success'.tr()),
        ),
      );
    } catch (e) {
      core.AppLogger.error('Failed to mark commission complete: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_complete_error'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  void _cancelCommission() {
    showDialog<String>(
      context: context,
      builder: (context) => const CancellationDialog(),
    ).then((reason) {
      if (reason != null && reason.isNotEmpty) {
        _submitCancellation(reason);
      }
    });
  }

  Future<void> _submitCancellation(String reason) async {
    try {
      await _commissionService.cancelCommission(_commission!.id, reason);
      await _loadCommissionDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_detail_toast_cancel_success'.tr())),
      );
    } catch (e) {
      core.AppLogger.error('Failed to cancel commission: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_cancel_error'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _payMilestone(CommissionMilestone milestone) async {
    try {
      await _stripeService.processCommissionMilestone(
        commissionId: _commission!.id,
        milestoneId: milestone.id,
        amount: milestone.amount,
        message: 'commission_detail_payment_milestone_memo'.tr(
          namedArgs: {'title': milestone.title},
        ),
      );
      await _loadCommissionDetails();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('commission_detail_toast_milestone_success'.tr()),
        ),
      );
    } catch (e) {
      core.AppLogger.error('Failed to process commission milestone: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_milestone_error'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  Future<void> _downloadFile(CommissionFile file) async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_download_start'.tr(
              namedArgs: {'name': file.name},
            ),
          ),
        ),
      );

      final response = await http.get(Uri.parse(file.url));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final directory = await getApplicationDocumentsDirectory();
      final downloadsDir = Directory('${directory.path}/Downloads');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }

      final extension = _getFileExtension(file.name);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final localFile = File(
        '${downloadsDir.path}/${safeName}_$timestamp$extension',
      );
      await localFile.writeAsBytes(response.bodyBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_download_success'.tr(
              namedArgs: {'path': localFile.path},
            ),
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      core.AppLogger.error('Failed to download commission file: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'commission_detail_toast_download_error'.tr(
              namedArgs: {'error': '$e'},
            ),
          ),
        ),
      );
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = _getFileExtension(fileName).toLowerCase();
    if (extension == '.pdf') return Icons.picture_as_pdf;
    if (['.png', '.jpg', '.jpeg', '.gif', '.webp'].contains(extension)) {
      return Icons.image;
    }
    if (['.mp4', '.mov', '.avi', '.mkv'].contains(extension)) {
      return Icons.movie;
    }
    if (['.mp3', '.wav', '.aac', '.flac'].contains(extension)) {
      return Icons.music_note;
    }
    if (['.zip', '.rar', '.7z'].contains(extension)) {
      return Icons.archive;
    }
    if (['.psd', '.ai', '.svg'].contains(extension)) {
      return Icons.brush;
    }
    if (['.doc', '.docx', '.txt', '.rtf'].contains(extension)) {
      return Icons.description;
    }
    return Icons.insert_drive_file;
  }

  String _getFileExtension(String fileName) {
    final lastDot = fileName.lastIndexOf('.');
    if (lastDot != -1 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot);
    }
    return '.file';
  }

  DateTime _parseTimeline(String timeline) {
    final now = DateTime.now();
    final lowerTimeline = timeline.toLowerCase().trim();

    final weekMatch = RegExp(
      r'(\d+)(?:\s*-\s*\d+)?\s*week',
    ).firstMatch(lowerTimeline);
    if (weekMatch != null) {
      final weeks = int.tryParse(weekMatch.group(1) ?? '1') ?? 1;
      return now.add(Duration(days: weeks * 7));
    }

    final monthMatch = RegExp(
      r'(\d+)(?:\s*-\s*\d+)?\s*month',
    ).firstMatch(lowerTimeline);
    if (monthMatch != null) {
      final months = int.tryParse(monthMatch.group(1) ?? '1') ?? 1;
      return DateTime(now.year, now.month + months, now.day);
    }

    final dayMatch = RegExp(
      r'(\d+)(?:\s*-\s*\d+)?\s*day',
    ).firstMatch(lowerTimeline);
    if (dayMatch != null) {
      final days = int.tryParse(dayMatch.group(1) ?? '1') ?? 1;
      return now.add(Duration(days: days));
    }

    return now.add(const Duration(days: 30));
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class QuoteProvisionDialog extends StatefulWidget {
  const QuoteProvisionDialog({super.key});

  @override
  State<QuoteProvisionDialog> createState() => _QuoteProvisionDialogState();
}

class _QuoteProvisionDialogState extends State<QuoteProvisionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timelineController = TextEditingController();
  final List<Map<String, dynamic>> _milestones = [];

  @override
  void dispose() {
    _priceController.dispose();
    _descriptionController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'commission_detail_quote_title'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'commission_detail_quote_subtitle'.tr(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _priceController,
                  decoration: GlassInputDecoration(
                    labelText: 'commission_detail_quote_price_label'.tr(),
                    hintText: 'commission_detail_quote_price_hint'.tr(),
                    prefixIcon: const Icon(
                      Icons.attach_money,
                      color: Colors.white,
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'commission_detail_quote_price_error'.tr();
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'commission_detail_quote_price_invalid'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: GlassInputDecoration(
                    labelText: 'commission_detail_quote_description_label'.tr(),
                    hintText: 'commission_detail_quote_description_hint'.tr(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'commission_detail_quote_description_error'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _timelineController,
                  decoration: GlassInputDecoration(
                    labelText: 'commission_detail_quote_timeline_label'.tr(),
                    hintText: 'commission_detail_quote_timeline_hint'.tr(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'commission_detail_quote_timeline_error'.tr();
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'commission_detail_quote_milestones_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    HudButton.secondary(
                      width: 160,
                      onPressed: _addMilestone,
                      text: 'commission_detail_quote_add_milestone'.tr(),
                      icon: Icons.add,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_milestones.isEmpty)
                  Text(
                    'commission_detail_quote_milestones_empty'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _milestones.length,
                    itemBuilder: (context, index) {
                      final milestone = _milestones[index];
                      return GlassCard(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: milestone['title'] as String,
                                    decoration: GlassInputDecoration(
                                      labelText:
                                          'commission_detail_quote_milestone_title'
                                              .tr(),
                                    ),
                                    onChanged: (value) =>
                                        _updateMilestone(index, 'title', value),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => _removeMilestone(index),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              initialValue: milestone['description'] as String,
                              decoration: GlassInputDecoration(
                                labelText:
                                    'commission_detail_quote_milestone_description'
                                        .tr(),
                              ),
                              maxLines: 2,
                              onChanged: (value) =>
                                  _updateMilestone(index, 'description', value),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: milestone['amount']
                                        .toString(),
                                    decoration: GlassInputDecoration(
                                      labelText:
                                          'commission_detail_quote_milestone_amount'
                                              .tr(),
                                      prefixIcon: const Icon(
                                        Icons.payments,
                                        color: Colors.white,
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) {
                                      final amount =
                                          double.tryParse(value) ?? 0.0;
                                      _updateMilestone(index, 'amount', amount);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: _formatDate(
                                      milestone['dueDate'] as DateTime,
                                    ),
                                    decoration: GlassInputDecoration(
                                      labelText:
                                          'commission_detail_quote_milestone_due'
                                              .tr(),
                                      hintText:
                                          'commission_detail_quote_date_hint'
                                              .tr(),
                                    ),
                                    onChanged: (value) {
                                      final date = _parseDate(value);
                                      if (date != null) {
                                        _updateMilestone(
                                          index,
                                          'dueDate',
                                          date,
                                        );
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: HudButton.secondary(
                        onPressed: () => Navigator.of(context).pop(),
                        text: 'commission_detail_action_cancel'.tr(),
                        icon: Icons.close,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: HudButton.primary(
                        onPressed: _submit,
                        text: 'commission_detail_action_submit_quote'.tr(),
                        icon: Icons.send,
                      ),
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

  void _addMilestone() {
    setState(() {
      _milestones.add({
        'title': '',
        'description': '',
        'amount': 0.0,
        'dueDate': DateTime.now().add(const Duration(days: 7)),
      });
    });
  }

  void _removeMilestone(int index) {
    setState(() {
      _milestones.removeAt(index);
    });
  }

  void _updateMilestone(int index, String field, dynamic value) {
    setState(() {
      _milestones[index][field] = value;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final month = int.parse(parts[0]);
        final day = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    for (final milestone in _milestones) {
      if ((milestone['title'] as String).isEmpty ||
          (milestone['description'] as String).isEmpty ||
          (milestone['amount'] as double) <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('commission_detail_quote_milestones_error'.tr()),
          ),
        );
        return;
      }
    }

    Navigator.of(context).pop({
      'price': double.parse(_priceController.text),
      'description': _descriptionController.text,
      'timeline': _timelineController.text,
      'milestones': _milestones,
    });
  }
}

class CancellationDialog extends StatefulWidget {
  const CancellationDialog({super.key});

  @override
  State<CancellationDialog> createState() => _CancellationDialogState();
}

class _CancellationDialogState extends State<CancellationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  String _selectedReason = '';

  final List<String> _predefinedReasons = [
    'commission_detail_cancel_reason_change',
    'commission_detail_cancel_reason_alternative',
    'commission_detail_cancel_reason_budget',
    'commission_detail_cancel_reason_timeline',
    'commission_detail_cancel_reason_communication',
    'commission_detail_cancel_reason_other',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'commission_detail_cancel_title'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'commission_detail_cancel_subtitle'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _predefinedReasons
                    .map(
                      (reasonKey) => ChoiceChip(
                        label: Text(reasonKey.tr()),
                        selected: _selectedReason == reasonKey,
                        onSelected: (selected) {
                          setState(() {
                            _selectedReason = selected ? reasonKey : '';
                            if (reasonKey !=
                                'commission_detail_cancel_reason_other') {
                              _reasonController.clear();
                            }
                          });
                        },
                        selectedColor: const Color(
                          0xFFFF3D8D,
                        ).withValues(alpha: 0.2),
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                        labelStyle: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (_selectedReason == 'commission_detail_cancel_reason_other')
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextField(
                    controller: _reasonController,
                    maxLines: 3,
                    decoration: GlassInputDecoration(
                      hintText: 'commission_detail_cancel_reason_hint'.tr(),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: HudButton.secondary(
                      onPressed: () => Navigator.of(context).pop(),
                      text: 'commission_detail_action_keep'.tr(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: HudButton.destructive(
                      onPressed: _submit,
                      text: 'commission_detail_action_confirm_cancel'.tr(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    String reason;
    if (_selectedReason == 'commission_detail_cancel_reason_other') {
      reason = _reasonController.text.trim();
      if (reason.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('commission_detail_cancel_reason_required'.tr()),
          ),
        );
        return;
      }
    } else if (_selectedReason.isNotEmpty) {
      reason = _selectedReason.tr();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('commission_detail_cancel_reason_select'.tr())),
      );
      return;
    }

    Navigator.of(context).pop(reason);
  }
}

class _DetailPalette {
  static const Gradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE), Color(0xFF34D399)],
  );

  static const Gradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF3D8D), Color(0xFF7C4DFF)],
  );
}
