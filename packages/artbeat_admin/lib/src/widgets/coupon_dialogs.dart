import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

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
  final _codeController = TextEditingController();
  final _maxUsesController = TextEditingController();
  final _discountValueController = TextEditingController();

  CouponType _selectedType = CouponType.percentageDiscount;
  DateTime? _expiresAt;
  bool _isLoading = false;

  final CouponService _couponService = CouponService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _codeController.dispose();
    _maxUsesController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('admin_coupon_dialog_title_create'.tr()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g., Spring Sale 20% Off',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Brief description of the coupon',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Coupon Code',
                  hintText: 'e.g., SPRING20',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Coupon code is required';
                  }
                  if (value!.length < 3) {
                    return 'Code must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CouponType>(
                initialValue: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Coupon Type',
                ),
                items: CouponType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getCouponTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedType = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType == CouponType.percentageDiscount ||
                  _selectedType == CouponType.fixedDiscount)
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _selectedType == CouponType.percentageDiscount
                        ? 'Discount Percentage (%)'
                        : 'Discount Amount (\$)',
                    hintText: _selectedType == CouponType.percentageDiscount
                        ? 'e.g., 20'
                        : 'e.g., 10.00',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Discount value is required';
                    }
                    final numValue = double.tryParse(value!);
                    if (numValue == null) {
                      return 'Please enter a valid number';
                    }
                    if (_selectedType == CouponType.percentageDiscount) {
                      if (numValue <= 0 || numValue > 100) {
                        return 'Percentage must be between 1 and 100';
                      }
                    } else {
                      if (numValue <= 0) {
                        return 'Amount must be greater than 0';
                      }
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Uses (optional)',
                  hintText: 'Leave empty for unlimited uses',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final numValue = int.tryParse(value!);
                    if (numValue == null || numValue <= 0) {
                      return 'Please enter a valid number greater than 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiresAt != null
                          ? 'Expires: ${_formatDate(_expiresAt!)}'
                          : 'No expiration date',
                      style: TextStyle(
                        color: _expiresAt != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectExpirationDate,
                    child: Text(_expiresAt != null ? 'Change' : 'Set Expiry'),
                  ),
                  if (_expiresAt != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _expiresAt = null;
                        });
                      },
                      child: Text('admin_coupon_button_clear').tr()),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('admin_coupon_button_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createCoupon,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('admin_coupon_button_create'.tr()),
        ),
      ],
    );
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

  Future<void> _createCoupon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _couponService.createCoupon(
        code: _codeController.text.trim().toUpperCase(),
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        discountAmount: _selectedType == CouponType.fixedDiscount
            ? double.parse(_discountValueController.text)
            : null,
        discountPercentage: _selectedType == CouponType.percentageDiscount
            ? int.parse(_discountValueController.text)
            : null,
        maxUses: _maxUsesController.text.isNotEmpty
            ? int.parse(_maxUsesController.text)
            : null,
        expiresAt: _expiresAt,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_coupon_success_created'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_coupon_error_create'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getCouponTypeDisplayName(CouponType type) {
    switch (type) {
      case CouponType.fullAccess:
        return 'Full Access';
      case CouponType.percentageDiscount:
        return 'Percentage Discount';
      case CouponType.fixedDiscount:
        return 'Fixed Discount';
      case CouponType.freeTrial:
        return 'Free Trial';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
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
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _maxUsesController;
  late final TextEditingController _discountValueController;

  late CouponType _selectedType;
  late DateTime? _expiresAt;
  bool _isLoading = false;

  final CouponService _couponService = CouponService();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.coupon.title);
    _descriptionController =
        TextEditingController(text: widget.coupon.description);
    _maxUsesController = TextEditingController(
      text: widget.coupon.maxUses?.toString() ?? '',
    );
    _discountValueController = TextEditingController(
      text: widget.coupon.discountPercentage?.toString() ??
          widget.coupon.discountAmount?.toString() ??
          '',
    );
    _selectedType = widget.coupon.type;
    _expiresAt = widget.coupon.expiresAt;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxUsesController.dispose();
    _discountValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('admin_coupon_dialog_title_edit'.tr()),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Title is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                ),
                maxLines: 2,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _maxUsesController,
                decoration: const InputDecoration(
                  labelText: 'Maximum Uses (optional)',
                  hintText: 'Leave empty for unlimited uses',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isNotEmpty ?? false) {
                    final numValue = int.tryParse(value!);
                    if (numValue == null || numValue <= 0) {
                      return 'Please enter a valid number greater than 0';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              if (_selectedType == CouponType.percentageDiscount ||
                  _selectedType == CouponType.fixedDiscount)
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _selectedType == CouponType.percentageDiscount
                        ? 'Discount Percentage (%)'
                        : 'Discount Amount (\$)',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Discount value is required';
                    }
                    final numValue = double.tryParse(value!);
                    if (numValue == null) {
                      return 'Please enter a valid number';
                    }
                    if (_selectedType == CouponType.percentageDiscount) {
                      if (numValue <= 0 || numValue > 100) {
                        return 'Percentage must be between 1 and 100';
                      }
                    } else {
                      if (numValue <= 0) {
                        return 'Amount must be greater than 0';
                      }
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _expiresAt != null
                          ? 'Expires: ${_formatDate(_expiresAt!)}'
                          : 'No expiration date',
                      style: TextStyle(
                        color: _expiresAt != null
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _selectExpirationDate,
                    child: Text(_expiresAt != null ? 'Change' : 'Set Expiry'),
                  ),
                  if (_expiresAt != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _expiresAt = null;
                        });
                      },
                      child: Text('admin_coupon_button_clear').tr()),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('admin_coupon_button_cancel'.tr()),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _updateCoupon,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('admin_coupon_button_update'.tr()),
        ),
      ],
    );
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedCoupon = widget.coupon.copyWith(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        discountAmount: _selectedType == CouponType.fixedDiscount
            ? double.parse(_discountValueController.text)
            : null,
        discountPercentage: _selectedType == CouponType.percentageDiscount
            ? int.parse(_discountValueController.text)
            : null,
        maxUses: _maxUsesController.text.isNotEmpty
            ? int.parse(_maxUsesController.text)
            : null,
        expiresAt: _expiresAt,
        updatedAt: DateTime.now(),
      );

      await _couponService.updateCoupon(updatedCoupon);

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_coupon_success_updated'.tr())),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('admin_coupon_error_update'.tr(namedArgs: {'error': e.toString()}))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
