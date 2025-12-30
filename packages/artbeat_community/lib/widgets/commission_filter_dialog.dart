import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../models/direct_commission_model.dart';

/// Commission filter options
class CommissionFilters {
  final List<CommissionType> types;
  final double? maxPrice;
  final int? maxTurnaround;

  const CommissionFilters({
    this.types = const [],
    this.maxPrice,
    this.maxTurnaround,
  });

  CommissionFilters copyWith({
    List<CommissionType>? types,
    double? maxPrice,
    int? maxTurnaround,
  }) {
    return CommissionFilters(
      types: types ?? this.types,
      maxPrice: maxPrice ?? this.maxPrice,
      maxTurnaround: maxTurnaround ?? this.maxTurnaround,
    );
  }
}

/// Dialog for filtering commission artists
class CommissionFilterDialog extends StatefulWidget {
  final CommissionFilters initialFilters;
  final void Function(CommissionFilters) onApply;

  const CommissionFilterDialog({
    super.key,
    CommissionFilters? initialFilters,
    required this.onApply,
  }) : initialFilters = initialFilters ?? const CommissionFilters();

  @override
  State<CommissionFilterDialog> createState() => _CommissionFilterDialogState();
}

class _CommissionFilterDialogState extends State<CommissionFilterDialog> {
  late List<CommissionType> _selectedTypes;
  late double _maxPrice;
  late int _maxTurnaround;

  @override
  void initState() {
    super.initState();
    _selectedTypes = List.from(widget.initialFilters.types);
    _maxPrice = widget.initialFilters.maxPrice ?? 1000;
    _maxTurnaround = widget.initialFilters.maxTurnaround ?? 90;
  }

  void _applyFilters() {
    widget.onApply(
      CommissionFilters(
        types: _selectedTypes,
        maxPrice: _maxPrice,
        maxTurnaround: _maxTurnaround,
      ),
    );
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedTypes = [];
      _maxPrice = 1000;
      _maxTurnaround = 90;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'commission_filter_dialog_title'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(),

            // Commission Types
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'commission_filter_dialog_types_title'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CommissionType.values.map((type) {
                      final isSelected = _selectedTypes.contains(type);
                      return FilterChip(
                        label: Text(type.displayName),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedTypes.add(type);
                            } else {
                              _selectedTypes.remove(type);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Max Price
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'commission_filter_dialog_max_price_title'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'commission_filter_dialog_price_value'.tr(
                          args: [_maxPrice.toStringAsFixed(0)],
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: ArtbeatColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _maxPrice,
                    onChanged: (value) {
                      setState(() => _maxPrice = value);
                    },
                    min: 25,
                    max: 5000,
                    divisions: 99,
                    label: '\$${_maxPrice.toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),

            const Divider(),

            // Max Turnaround
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'commission_filter_dialog_max_turnaround_title'.tr(),
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'commission_filter_dialog_turnaround_value'.tr(
                          args: [_maxTurnaround.toString()],
                        ),
                        style: GoogleFonts.spaceGrotesk(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: ArtbeatColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: _maxTurnaround.toDouble(),
                    onChanged: (value) {
                      setState(() => _maxTurnaround = value.toInt());
                    },
                    min: 1,
                    max: 180,
                    divisions: 179,
                    label: '$_maxTurnaround days',
                  ),
                ],
              ),
            ),

            const Divider(),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetFilters,
                      child: Text('commission_filter_dialog_reset'.tr()),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      child: Text('commission_filter_dialog_apply'.tr()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
