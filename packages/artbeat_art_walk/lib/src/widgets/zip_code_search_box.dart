import 'package:artbeat_art_walk/src/widgets/glass_secondary_button.dart';
import 'package:artbeat_art_walk/src/widgets/typography.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:artbeat_core/shared_widgets.dart';

class ZipCodeSearchBox extends StatefulWidget {
  final String initialValue;
  final void Function(String) onZipCodeSubmitted;
  final bool isLoading;
  final VoidCallback? onNavigateToMap;

  const ZipCodeSearchBox({
    super.key,
    required this.initialValue,
    required this.onZipCodeSubmitted,
    this.isLoading = false,
    this.onNavigateToMap,
  });

  @override
  State<ZipCodeSearchBox> createState() => _ZipCodeSearchBoxState();
}

class _ZipCodeSearchBoxState extends State<ZipCodeSearchBox> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void didUpdateWidget(covariant ZipCodeSearchBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialValue != widget.initialValue) {
      _controller.text = widget.initialValue;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      withBlobs: false,
      child: GlassCard(
        borderRadius: 32,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'art_walk_zip_code_search_box_title'.tr(),
              style: AppTypography.screenTitle(),
            ),
            const SizedBox(height: 8),
            Text(
              'art_walk_zip_code_search_box_helper'.tr(),
              style: AppTypography.helper(),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: const Color(0xFFFFFFFF).withValues(
                  red: 255.0,
                  green: 255.0,
                  blue: 255.0,
                  alpha: (0.04 * 255),
                ),
                border: Border.all(
                  color: const Color(0xFFFFFFFF).withValues(
                    red: 255.0,
                    green: 255.0,
                    blue: 255.0,
                    alpha: (0.12 * 255),
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.white70,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: AppTypography.body(),
                      decoration: InputDecoration(
                        hintText: 'art_walk_zip_code_search_box_hint'.tr(),
                        hintStyle: AppTypography.helper(
                          const Color(0xFFFFFFFF).withValues(
                            red: 255.0,
                            green: 255.0,
                            blue: 255.0,
                            alpha: (0.7 * 255),
                          ),
                        ),
                        border: InputBorder.none,
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      onSubmitted: (_) => _submit(),
                    ),
                  ),
                  if (widget.isLoading)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF22D3EE)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GradientCTAButton(
              label: 'art_walk_zip_code_search_box_button_submit'.tr(),
              icon: Icons.location_searching,
              onPressed: widget.isLoading ? null : _submit,
            ),
            if (widget.onNavigateToMap != null) ...[
              const SizedBox(height: 12),
              GlassSecondaryButton(
                label: 'art_walk_zip_code_search_box_button_map'.tr(),
                icon: Icons.map_outlined,
                onTap: widget.onNavigateToMap!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _submit() {
    final zip = _controller.text.trim();
    if (zip.length == 5) {
      widget.onZipCodeSubmitted(zip);
      widget.onNavigateToMap?.call();
    }
  }
}
