import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/coupon_model.dart';
import '../services/coupon_service.dart';

class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  final CouponService _couponService = CouponService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'core_coupon_title'.tr(),
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showCreateCouponDialog,
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'core_coupon_create'.tr(),
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildWorldBackground(),
          Positioned.fill(
            child: StreamBuilder<List<CouponModel>>(
              stream: _couponService.getActiveCoupons(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildStatusState(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Syncing coupons...',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return _buildStatusState(
                    Text(
                      'Error: ${snapshot.error}',
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                final coupons = snapshot.data ?? [];

                if (coupons.isEmpty) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 140, 16, 40),
                    child: Column(
                      children: [
                        _buildHeroSection(coupons),
                        const SizedBox(height: 20),
                        _buildEmptyState(),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 120, 16, 40),
                  itemCount: coupons.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        children: [
                          _buildHeroSection(coupons),
                          const SizedBox(height: 20),
                        ],
                      );
                    }
                    final coupon = coupons[index - 1];
                    return CouponCard(
                      coupon: coupon,
                      onEdit: () => _showEditCouponDialog(coupon),
                      onDelete: () => _showDeleteConfirmation(coupon),
                      onToggleStatus: () => _toggleCouponStatus(coupon),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusState(Widget child) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: _buildGlassPanel(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    );
  }

  Widget _buildHeroSection(List<CouponModel> coupons) {
    final active = coupons.where((c) => c.status == CouponStatus.active).length;
    final paused = coupons
        .where((c) => c.status == CouponStatus.inactive)
        .length;
    final limited = coupons
        .where(
          (c) =>
              c.status == CouponStatus.expired ||
              c.status == CouponStatus.exhausted,
        )
        .length;
    final totalUses = coupons.fold<int>(
      0,
      (sum, coupon) => sum + coupon.currentUses,
    );

    return _buildGlassPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'core_coupon_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visibility passes, promo credits, and trials all live here.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatTile(
                icon: Icons.bolt,
                label: 'Active',
                value: active.toString(),
              ),
              const SizedBox(width: 12),
              _buildStatTile(
                icon: Icons.pause_circle_outline,
                label: 'Paused',
                value: paused.toString(),
              ),
              const SizedBox(width: 12),
              _buildStatTile(
                icon: Icons.event_busy,
                label: 'Expired',
                value: limited.toString(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timeline, color: Colors.white70, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Lifetime uses · $totalUses',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _GradientButton(
            label: 'core_coupon_create'.tr(),
            icon: Icons.add,
            onPressed: _showCreateCouponDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
          color: Colors.white.withValues(alpha: 0.04),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return _buildGlassPanel(
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          const Icon(
            Icons.confirmation_number_outlined,
            color: Colors.white70,
            size: 48,
          ),
          const SizedBox(height: 14),
          Text(
            'No coupons yet',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first code to unlock promo drops, trials, and VIP access.',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _GradientButton(
            label: 'core_coupon_create'.tr(),
            icon: Icons.add,
            onPressed: _showCreateCouponDialog,
          ),
        ],
      ),
    );
  }

  void _showCreateCouponDialog() {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => const CreateCouponDialog(),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showEditCouponDialog(CouponModel coupon) {
    showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => EditCouponDialog(coupon: coupon),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  Future<void> _showDeleteConfirmation(CouponModel coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => _GlassDialog(
        title: 'core_coupon_delete'.tr(),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Text(
            'Are you sure you want to delete the coupon "${coupon.title}"? This action cannot be undone.',
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'core_coupon_cancel'.tr(),
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _GradientButton(
            label: 'core_coupon_delete_button'.tr(),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _couponService.deleteCoupon(coupon.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('core_coupon_success_deleted'.tr())),
          );
        }
        setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete coupon: $e')),
          );
        }
      }
    }
  }

  Future<void> _toggleCouponStatus(CouponModel coupon) async {
    try {
      final newStatus = coupon.status == CouponStatus.active
          ? CouponStatus.inactive
          : CouponStatus.active;
      await _couponService.updateCouponStatus(coupon.id, newStatus);
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Coupon ${newStatus == CouponStatus.active ? 'activated' : 'deactivated'}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update coupon: $e')));
      }
    }
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(34),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            color: Colors.white.withValues(alpha: 0.05),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 36,
                offset: const Offset(0, 22),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildWorldBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF03050F), Color(0xFF09122B), Color(0xFF021B17)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-160, -60), Colors.purpleAccent),
            _buildGlow(const Offset(140, 260), Colors.cyanAccent),
            _buildGlow(const Offset(-40, 420), Colors.pinkAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.2,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(Offset offset, Color color) {
    return Positioned(
      left: offset.dx < 0 ? null : offset.dx,
      right: offset.dx < 0 ? -offset.dx : null,
      top: offset.dy,
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 110,
              spreadRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class CouponCard extends StatelessWidget {
  final CouponModel coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;

  const CouponCard({
    super.key,
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final usesLabel = '${coupon.currentUses}/${coupon.maxUses ?? '∞'} uses';
    final expiresLabel = coupon.expiresAt != null
        ? 'Expires ${_formatDate(coupon.expiresAt!)}'
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              color: Colors.white.withValues(alpha: 0.04),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 18),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: _statusColor().withValues(alpha: 0.18),
                        border: Border.all(
                          color: _statusColor().withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        _statusLabel(),
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      coupon.code,
                      style: GoogleFonts.spaceGrotesk(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  coupon.title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  coupon.description,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildInfoChip(Icons.loyalty, _typeLabel()),
                    _buildInfoChip(Icons.repeat, usesLabel),
                    if (expiresLabel != null)
                      _buildInfoChip(Icons.event, expiresLabel),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    _GlassIconButton(
                      icon: coupon.status == CouponStatus.active
                          ? Icons.pause_circle
                          : Icons.play_circle,
                      tooltip: coupon.status == CouponStatus.active
                          ? 'Pause'
                          : 'Activate',
                      onPressed: onToggleStatus,
                    ),
                    const SizedBox(width: 10),
                    _GlassIconButton(
                      icon: Icons.edit,
                      tooltip: 'Edit',
                      onPressed: onEdit,
                    ),
                    const SizedBox(width: 10),
                    _GlassIconButton(
                      icon: Icons.delete_outline,
                      tooltip: 'Delete',
                      color: Colors.redAccent,
                      onPressed: onDelete,
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

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _typeLabel() {
    switch (coupon.type) {
      case CouponType.fullAccess:
        return 'Full access';
      case CouponType.percentageDiscount:
        final percent = coupon.discountPercentage ?? 0;
        return '$percent% off';
      case CouponType.fixedDiscount:
        final amount = coupon.discountAmount?.toStringAsFixed(2) ?? '0.00';
        return '\$${amount} off';
      case CouponType.freeTrial:
        return 'Free trial';
    }
  }

  String _statusLabel() {
    switch (coupon.status) {
      case CouponStatus.active:
        return 'Active';
      case CouponStatus.inactive:
        return 'Inactive';
      case CouponStatus.expired:
        return 'Expired';
      case CouponStatus.exhausted:
        return 'Exhausted';
    }
  }

  Color _statusColor() {
    switch (coupon.status) {
      case CouponStatus.active:
        return const Color(0xFF34D399);
      case CouponStatus.inactive:
        return Colors.white70;
      case CouponStatus.expired:
        return const Color(0xFFFF3D8D);
      case CouponStatus.exhausted:
        return const Color(0xFFFFC857);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class CreateCouponDialog extends StatefulWidget {
  const CreateCouponDialog({super.key});

  @override
  State<CreateCouponDialog> createState() => _CreateCouponDialogState();
}

class _CreateCouponDialogState extends State<CreateCouponDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountController = TextEditingController();
  final _maxUsesController = TextEditingController();

  CouponType _selectedType = CouponType.fullAccess;
  DateTime? _expiresAt;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _discountController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassDialog(
      title: 'core_coupon_create'.tr(),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 520),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  decoration: _glassInputDecoration(
                    'Title',
                    hint: 'e.g., Beta Access Code',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Title is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  maxLines: 2,
                  decoration: _glassInputDecoration(
                    'Description',
                    hint: 'core_coupon_description_hint'.tr(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Description is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CouponType>(
                  initialValue: _selectedType,
                  decoration: _glassInputDecoration('Coupon Type'),
                  dropdownColor: const Color(0xFF050914),
                  iconEnabledColor: Colors.white,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  items: CouponType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(
                            _getCouponTypeDisplayName(type),
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedType = value;
                      });
                    }
                  },
                ),
                if (_selectedType == CouponType.percentageDiscount ||
                    _selectedType == CouponType.fixedDiscount) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _discountController,
                    style: GoogleFonts.spaceGrotesk(color: Colors.white),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _glassInputDecoration(
                      _selectedType == CouponType.percentageDiscount
                          ? 'Discount Percentage'
                          : 'Discount Amount',
                      hint: _selectedType == CouponType.percentageDiscount
                          ? 'e.g., 50'
                          : 'e.g., 9.99',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true)
                        return 'Discount value is required';
                      final parsed = double.tryParse(value!);
                      if (parsed == null) return 'Invalid number';
                      if (_selectedType == CouponType.percentageDiscount) {
                        if (parsed <= 0 || parsed > 100) {
                          return 'Percentage must be between 1 and 100';
                        }
                      } else {
                        if (parsed <= 0) return 'Amount must be greater than 0';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
                TextFormField(
                  controller: _maxUsesController,
                  style: GoogleFonts.spaceGrotesk(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: _glassInputDecoration(
                    'Maximum Uses (optional)',
                    hint: 'Leave empty for unlimited',
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _selectExpirationDate,
                  child: InputDecorator(
                    decoration: _glassInputDecoration(
                      'Expiration Date (optional)',
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _expiresAt != null
                              ? '${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}'
                              : 'No expiration',
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        ),
                        const Icon(
                          Icons.calendar_today,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'core_coupon_cancel'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _GradientButton(
          label: 'core_coupon_create_button'.tr(),
          loading: _isLoading,
          onPressed: _isLoading ? null : _createCoupon,
        ),
      ],
    );
  }

  String _getCouponTypeDisplayName(CouponType type) {
    switch (type) {
      case CouponType.fullAccess:
        return 'Full Access (Free)';
      case CouponType.percentageDiscount:
        return 'Percentage Discount';
      case CouponType.fixedDiscount:
        return 'Fixed Amount Discount';
      case CouponType.freeTrial:
        return 'Free Trial';
    }
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _createCoupon() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final couponService = context.read<CouponService>();
      double? discountAmount;
      int? discountPercentage;

      if (_selectedType == CouponType.percentageDiscount) {
        discountPercentage = int.parse(_discountController.text);
      } else if (_selectedType == CouponType.fixedDiscount) {
        discountAmount = double.parse(_discountController.text);
      }

      await couponService.createCoupon(
        code: '',
        title: _titleController.text,
        description: _descriptionController.text,
        type: _selectedType,
        discountAmount: discountAmount,
        discountPercentage: discountPercentage,
        maxUses: _maxUsesController.text.isNotEmpty
            ? int.parse(_maxUsesController.text)
            : null,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('core_coupon_success_created'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to create coupon: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class EditCouponDialog extends StatefulWidget {
  final CouponModel coupon;

  const EditCouponDialog({super.key, required this.coupon});

  @override
  State<EditCouponDialog> createState() => _EditCouponDialogState();
}

class _EditCouponDialogState extends State<EditCouponDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxUsesController;

  late CouponStatus _selectedStatus;
  DateTime? _expiresAt;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.coupon.title);
    _descriptionController = TextEditingController(
      text: widget.coupon.description,
    );
    _maxUsesController = TextEditingController(
      text: widget.coupon.maxUses?.toString() ?? '',
    );
    _selectedStatus = widget.coupon.status;
    _expiresAt = widget.coupon.expiresAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxUsesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _GlassDialog(
      title: 'Edit Coupon',
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 480),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
                decoration: _glassInputDecoration('Title'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
                maxLines: 2,
                decoration: _glassInputDecoration('Description'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CouponStatus>(
                initialValue: _selectedStatus,
                decoration: _glassInputDecoration('Status'),
                dropdownColor: const Color(0xFF050914),
                iconEnabledColor: Colors.white,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
                items: CouponStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(
                          _getStatusDisplayName(status),
                          style: GoogleFonts.spaceGrotesk(color: Colors.white),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedStatus = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsesController,
                style: GoogleFonts.spaceGrotesk(color: Colors.white),
                keyboardType: TextInputType.number,
                decoration: _glassInputDecoration(
                  'Maximum Uses',
                  hint: 'Leave empty for unlimited',
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _selectExpirationDate,
                child: InputDecorator(
                  decoration: _glassInputDecoration('Expiration Date'),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiresAt != null
                            ? '${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}'
                            : 'No expiration',
                        style: GoogleFonts.spaceGrotesk(color: Colors.white),
                      ),
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            'core_coupon_cancel'.tr(),
            style: GoogleFonts.spaceGrotesk(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _GradientButton(
          label: 'Update',
          loading: _isLoading,
          onPressed: _isLoading ? null : _updateCoupon,
        ),
      ],
    );
  }

  String _getStatusDisplayName(CouponStatus status) {
    switch (status) {
      case CouponStatus.active:
        return 'Active';
      case CouponStatus.inactive:
        return 'Inactive';
      case CouponStatus.expired:
        return 'Expired';
      case CouponStatus.exhausted:
        return 'Exhausted';
    }
  }

  Future<void> _selectExpirationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _expiresAt = picked;
      });
    }
  }

  Future<void> _updateCoupon() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final couponService = context.read<CouponService>();
      await couponService.updateCouponStatus(widget.coupon.id, _selectedStatus);
      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('core_coupon_success_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update coupon: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

class _GlassDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;

  const _GlassDialog({
    required this.title,
    required this.content,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(34),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              color: Colors.black.withValues(alpha: 0.65),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 40,
                  offset: const Offset(0, 30),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 18),
                content,
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const _GradientButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: isDisabled || loading ? null : onPressed,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: isDisabled
                  ? [
                      Colors.white.withValues(alpha: 0.2),
                      Colors.white.withValues(alpha: 0.1),
                    ]
                  : const [
                      Color(0xFF7C4DFF),
                      Color(0xFF22D3EE),
                      Color(0xFF34D399),
                    ],
            ),
            boxShadow: isDisabled
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                  ],
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color? color;
  final String? tooltip;

  const _GlassIconButton({
    required this.icon,
    required this.onPressed,
    this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            color: Colors.white.withValues(alpha: 0.04),
          ),
          child: Icon(icon, color: color ?? Colors.white, size: 20),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

InputDecoration _glassInputDecoration(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    labelStyle: GoogleFonts.spaceGrotesk(color: Colors.white70, fontSize: 13),
    hintStyle: GoogleFonts.spaceGrotesk(color: Colors.white54, fontSize: 13),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.04),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.16)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(22),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.34)),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
  );
}
