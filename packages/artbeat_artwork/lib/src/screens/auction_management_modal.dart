import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart' show GlassCard;

/// Modal for managing auction settings for an artwork
class AuctionManagementModal extends StatefulWidget {
  final ArtworkModel artwork;

  const AuctionManagementModal({super.key, required this.artwork});

  @override
  State<AuctionManagementModal> createState() => _AuctionManagementModalState();
}

class _AuctionManagementModalState extends State<AuctionManagementModal> {
  final _formKey = GlobalKey<FormState>();
  final ArtworkService _artworkService = ArtworkService();

  bool _isLoading = false;
  String? _errorMessage;

  // Auction settings
  bool _auctionEnabled = false;
  double? _startingPrice;
  double? _reservePrice;
  DateTime? _auctionEnd;

  @override
  void initState() {
    super.initState();
    _loadCurrentAuctionSettings();
  }

  void _loadCurrentAuctionSettings() {
    setState(() {
      _auctionEnabled = widget.artwork.auctionEnabled;
      _startingPrice = widget.artwork.startingPrice;
      _reservePrice = widget.artwork.reservePrice;
      _auctionEnd = widget.artwork.auctionEnd;
    });
  }

  Future<void> _saveAuctionSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Update artwork with auction settings
      await _artworkService.updateArtwork(
        artworkId: widget.artwork.id,
        auctionEnabled: _auctionEnabled,
        startingPrice: _startingPrice,
        reservePrice: _reservePrice,
        auctionEnd: _auctionEnd,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('auction.settings_saved'.tr()),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return success
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'auction.settings_save_error'.tr();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectAuctionEndDate() async {
    final now = DateTime.now();
    final initialDate = _auctionEnd ?? now.add(const Duration(days: 7));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)), // Max 30 days
    );

    if (!mounted) return;

    if (pickedDate != null) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_auctionEnd ?? now),
      );

      if (!mounted) return;

      if (pickedTime != null) {
        setState(() {
          _auctionEnd = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth,
                  maxHeight: constraints.maxHeight,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'auction.manage_auction'.tr(),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontFamily: 'SpaceGrotesk',
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Artwork preview
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child:
                                  widget.artwork.imageUrl.isNotEmpty &&
                                      widget.artwork.imageUrl
                                          .trim()
                                          .isNotEmpty &&
                                      Uri.tryParse(
                                            widget.artwork.imageUrl,
                                          )?.hasScheme ==
                                          true
                                  ? Image.network(
                                      widget.artwork.imageUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[800],
                                              child: const Icon(
                                                Icons.image_not_supported,
                                                color: Colors.grey,
                                                size: 30,
                                              ),
                                            );
                                          },
                                    )
                                  : Container(
                                      width: 60,
                                      height: 60,
                                      color: Colors.grey[800],
                                      child: const Icon(
                                        Icons.image_not_supported,
                                        color: Colors.grey,
                                        size: 30,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.artwork.title,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontFamily: 'SpaceGrotesk',
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    widget.artwork.artistName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Enable auction toggle
                        SwitchListTile(
                          title: Text(
                            'auction.enable_auction'.tr(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontFamily: 'SpaceGrotesk',
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          subtitle: Text(
                            'auction.enable_description'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          value: _auctionEnabled,
                          onChanged: (value) {
                            setState(() {
                              _auctionEnabled = value;
                            });
                          },
                        ),

                        if (_auctionEnabled) ...[
                          const SizedBox(height: 24),

                          // Starting price
                          TextFormField(
                            initialValue:
                                _startingPrice?.toStringAsFixed(2) ?? '',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'auction.starting_price'.tr(),
                              prefixText: '\$',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'auction.starting_price_required'.tr();
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'auction.invalid_price'.tr();
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _startingPrice = double.parse(value!);
                            },
                          ),

                          const SizedBox(height: 16),

                          // Reserve price
                          TextFormField(
                            initialValue:
                                _reservePrice?.toStringAsFixed(2) ?? '',
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              labelText: 'auction.reserve_price'.tr(),
                              prefixText: '\$',
                              border: const OutlineInputBorder(
                                borderRadius: BorderRadius.all(
                                  Radius.circular(12),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                              labelStyle: const TextStyle(color: Colors.white),
                            ),
                            style: const TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final price = double.tryParse(value);
                                if (price == null || price <= 0) {
                                  return 'auction.invalid_price'.tr();
                                }
                              }
                              return null;
                            },
                            onSaved: (value) {
                              _reservePrice = value != null && value.isNotEmpty
                                  ? double.parse(value)
                                  : null;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Auction end date/time
                          InkWell(
                            onTap: _selectAuctionEndDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'auction.end_date_time'.tr(),
                                border: const OutlineInputBorder(
                                  borderRadius: BorderRadius.all(
                                    Radius.circular(12),
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                  color: Colors.white,
                                ),
                                suffixIcon: const Icon(
                                  Icons.calendar_today,
                                  color: Colors.white,
                                ),
                              ),
                              child: Text(
                                _auctionEnd != null
                                    ? '${_auctionEnd!.toLocal().toString().split('.')[0]}'
                                    : 'auction.select_end_date'.tr(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Text(
                            'auction.end_date_note'.tr(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Save button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveAuctionSettings,
                            style:
                                ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ).copyWith(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith<Color>((
                                        states,
                                      ) {
                                        if (states.contains(
                                          WidgetState.disabled,
                                        )) {
                                          return Colors.grey.withValues(
                                            alpha: 0.3,
                                          );
                                        }
                                        return Colors.transparent;
                                      }),
                                  foregroundColor: WidgetStateProperty.all(
                                    Colors.white,
                                  ),
                                ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF7C4DFF),
                                    Color(0xFF22D3EE),
                                    Color(0xFF34D399),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: _isLoading
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : Text(
                                        'auction.save_settings'.tr(),
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              fontFamily: 'SpaceGrotesk',
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
