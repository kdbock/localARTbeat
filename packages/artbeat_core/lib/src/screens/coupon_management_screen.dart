import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/coupon_model.dart';
import '../services/coupon_service.dart';
import 'package:easy_localization/easy_localization.dart';

/// Admin screen for managing promotional coupons
class CouponManagementScreen extends StatefulWidget {
  const CouponManagementScreen({super.key});

  @override
  State<CouponManagementScreen> createState() => _CouponManagementScreenState();
}

class _CouponManagementScreenState extends State<CouponManagementScreen> {
  final CouponService _couponService = CouponService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('core_coupon_title'.tr()),
        actions: [
          IconButton(
            onPressed: _showCreateCouponDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Create Coupon',
          ),
        ],
      ),
      body: StreamBuilder<List<CouponModel>>(
        stream: _couponService.getActiveCoupons(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final coupons = snapshot.data ?? [];

          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No coupons found',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first coupon to get started',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _showCreateCouponDialog,
                    icon: const Icon(Icons.add),
                    label: Text('core_coupon_create'.tr()),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
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
    );
  }

  void _showCreateCouponDialog() {
    showDialog<bool>(
      context: context,
      builder: (context) => const CreateCouponDialog(),
    ).then((result) {
      if (result == true) {
        // Refresh the list
        setState(() {});
      }
    });
  }

  void _showEditCouponDialog(CouponModel coupon) {
    showDialog<bool>(
      context: context,
      builder: (context) => EditCouponDialog(coupon: coupon),
    ).then((result) {
      if (result == true) {
        setState(() {});
      }
    });
  }

  void _showDeleteConfirmation(CouponModel coupon) {
    showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('core_coupon_delete'.tr()),
        content: Text(
          'Are you sure you want to delete the coupon "${coupon.title}"? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('core_coupon_cancel'.tr()),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _couponService.deleteCoupon(coupon.id);
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                setState(() {});
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('core_coupon_success_deleted'.tr())),
                  );
                }
              } catch (e) {
                // ignore: use_build_context_synchronously
                Navigator.of(context).pop();
                if (mounted) {
                  // ignore: use_build_context_synchronously
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete coupon: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('core_coupon_delete_button'.tr()),
          ),
        ],
      ),
    );
  }

  void _toggleCouponStatus(CouponModel coupon) async {
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
}

/// Card widget to display coupon information
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
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        coupon.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        coupon.code,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontFamily: 'monospace',
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(theme),
              ],
            ),
            const SizedBox(height: 8),
            Text(coupon.description, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildTypeChip(theme),
                const SizedBox(width: 8),
                Text(
                  '${coupon.currentUses}/${coupon.maxUses ?? '∞'} uses',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (coupon.expiresAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Expires: ${_formatDate(coupon.expiresAt!)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: onToggleStatus,
                  icon: Icon(
                    coupon.status == CouponStatus.active
                        ? Icons.pause
                        : Icons.play_arrow,
                  ),
                  tooltip: coupon.status == CouponStatus.active
                      ? 'Deactivate'
                      : 'Activate',
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  color: theme.colorScheme.primary,
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete),
                  tooltip: 'core_coupon_delete_button'.tr(),
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color backgroundColor;
    Color textColor;
    String text;

    switch (coupon.status) {
      case CouponStatus.active:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        text = 'Active';
        break;
      case CouponStatus.inactive:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        text = 'Inactive';
        break;
      case CouponStatus.expired:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        text = 'Expired';
        break;
      case CouponStatus.exhausted:
        backgroundColor = theme.colorScheme.errorContainer;
        textColor = theme.colorScheme.onErrorContainer;
        text = 'Exhausted';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTypeChip(ThemeData theme) {
    String text;
    switch (coupon.type) {
      case CouponType.fullAccess:
        text = 'Full Access';
        break;
      case CouponType.percentageDiscount:
        text = '${coupon.discountPercentage}% Off';
        break;
      case CouponType.fixedDiscount:
        text = '\$${coupon.discountAmount} Off';
        break;
      case CouponType.freeTrial:
        text = 'Free Trial';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: theme.colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

/// Dialog for creating new coupons
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('core_coupon_create'.tr()),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Beta Access Code',
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'core_coupon_description_hint'.tr(),
                ),
                maxLines: 2,
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Description is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CouponType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Coupon Type'),
                items: CouponType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getCouponTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                  });
                },
              ),
              if (_selectedType == CouponType.percentageDiscount ||
                  _selectedType == CouponType.fixedDiscount) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _discountController,
                  decoration: InputDecoration(
                    labelText: _selectedType == CouponType.percentageDiscount
                        ? 'Discount Percentage'
                        : 'Discount Amount',
                    hintText: _selectedType == CouponType.percentageDiscount
                        ? 'e.g., 50'
                        : 'e.g., 9.99',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true)
                      return 'Discount value is required';
                    final numValue = double.tryParse(value!);
                    if (numValue == null) return 'Invalid number';
                    if (_selectedType == CouponType.percentageDiscount) {
                      if (numValue <= 0 || numValue > 100) {
                        return 'Percentage must be between 1 and 100';
                      }
                    } else {
                      if (numValue <= 0) return 'Amount must be greater than 0';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Uses (optional)',
                  hintText: 'Leave empty for unlimited',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectExpirationDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiration Date (optional)',
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _expiresAt != null
                            ? '${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}'
                            : 'No expiration',
                        style: theme.textTheme.bodyMedium,
                      ),
                      const Icon(Icons.calendar_today, size: 20),
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
          child: Text('core_coupon_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCoupon,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('core_coupon_create_button'.tr()),
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

  void _selectExpirationDate() async {
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

  void _createCoupon() async {
    if (!_formKey.currentState!.validate()) return;

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
        code: '', // Will be auto-generated
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

/// Dialog for editing existing coupons
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
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit Coupon'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CouponStatus>(
              initialValue: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: CouponStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusDisplayName(status)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxUsesController,
              decoration: const InputDecoration(
                labelText: 'Maximum Uses',
                hintText: 'Leave empty for unlimited',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selectExpirationDate,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Expiration Date'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _expiresAt != null
                          ? '${_expiresAt!.month}/${_expiresAt!.day}/${_expiresAt!.year}'
                          : 'No expiration',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Icon(Icons.calendar_today, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('core_coupon_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCoupon,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
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

  void _selectExpirationDate() async {
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

  void _updateCoupon() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final couponService = context.read<CouponService>();

      // Update basic fields
      await couponService.updateCouponStatus(widget.coupon.id, _selectedStatus);

      // For more complex updates, you might need additional methods in CouponService
      // For now, we'll just update the status

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
