import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart';
import '../models/direct_commission_model.dart';
import '../services/direct_commission_service.dart';
import 'glass_card.dart';

/// Widget to browse artists accepting commissions
class CommissionArtistsBrowser extends StatefulWidget {
  final VoidCallback? onCommissionRequest;

  const CommissionArtistsBrowser({super.key, this.onCommissionRequest});

  @override
  State<CommissionArtistsBrowser> createState() =>
      _CommissionArtistsBrowserState();
}

class _CommissionArtistsBrowserState extends State<CommissionArtistsBrowser> {
  final DirectCommissionService _commissionService = DirectCommissionService();
  final artist.ArtistProfileService _artistProfileService =
      artist.ArtistProfileService();
  final Map<String, String> _artistNames = {};

  bool _isLoading = false;
  List<ArtistCommissionSettings> _artists = [];
  CommissionType? _selectedType;

  @override
  void initState() {
    super.initState();
    _loadCommissionArtists();
  }

  Future<void> _loadCommissionArtists() async {
    setState(() => _isLoading = true);

    try {
      final artists = await _commissionService.getAvailableArtists(
        type: _selectedType,
      );
      final names = await _fetchArtistNames(artists);
      if (mounted) {
        setState(() {
          _artists = artists;
          _artistNames.addAll(names);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading artists: $e')));
      }
    }
  }

  void _handleTypeFilter(CommissionType? type) {
    setState(() => _selectedType = type);
    _loadCommissionArtists();
  }

  Future<Map<String, String>> _fetchArtistNames(
    List<ArtistCommissionSettings> artists,
  ) async {
    final ids = artists
        .map((artist) => artist.artistId)
        .where((id) => id.isNotEmpty && !_artistNames.containsKey(id))
        .toSet();
    if (ids.isEmpty) {
      return {};
    }

    final results = await Future.wait(
      ids.map((id) async {
        try {
          final profile = await _artistProfileService.getArtistProfileByUserId(id);
          if (profile != null) {
            return MapEntry(id, profile.displayName);
          }
        } catch (_) {}
        return MapEntry(id, _buildFallbackName(id));
      }),
    );

    return Map.fromEntries(results);
  }

  String _resolveArtistName(ArtistCommissionSettings artist) {
    return _artistNames[artist.artistId] ?? _buildFallbackName(artist.artistId);
  }

  String _buildFallbackName(String artistId) {
    final shortId = _shortenArtistId(artistId);
    if (shortId.isEmpty) {
      return 'Artist';
    }
    return 'Artist $shortId';
  }

  String _shortenArtistId(String artistId) {
    if (artistId.isEmpty) {
      return '';
    }
    final length = math.min(artistId.length, 8);
    return artistId.substring(0, length);
  }

  void _handleCommissionRequest(ArtistCommissionSettings artist) {
    final artistName = _resolveArtistName(artist);
    Navigator.of(context).pushNamed(
      AppRoutes.commissionRequest,
      arguments: {
        'artistId': artist.artistId,
        'artistName': artistName,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.art_track,
                      color: Colors.blue.shade700,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'commission_artists_browser_title'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'commission_artists_browser_subtitle'.tr(
                            args: [_artists.length.toString()],
                          ),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: ArtbeatColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Type filter
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'commission_artists_browser_all_types'.tr(),
                      selected: _selectedType == null,
                      onSelected: () => _handleTypeFilter(null),
                    ),
                    ...CommissionType.values.map((type) {
                      return _buildFilterChip(
                        label: type.displayName,
                        selected: _selectedType == type,
                        onSelected: () => _handleTypeFilter(type),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Artists list
        if (_isLoading)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_artists.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'commission_artists_browser_no_artists_title'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: ArtbeatColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'commission_artists_browser_no_artists_subtitle'.tr(),
                    style: GoogleFonts.spaceGrotesk(
                      color: ArtbeatColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _artists.length,
              itemBuilder: (context, index) {
                final artist = _artists[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildArtistCard(artist),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        backgroundColor: Colors.white,
        selectedColor: Colors.blue.shade100,
        side: BorderSide(
          color: selected ? Colors.blue.shade300 : Colors.grey[300]!,
        ),
      ),
    );
  }

  Widget _buildArtistCard(ArtistCommissionSettings artist) {
    final artistName = _resolveArtistName(artist);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _handleCommissionRequest(artist),
        child: GlassCard(
          borderRadius: 24,
          child: SizedBox(
            width: 180,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: ArtbeatColors.primary.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.palette,
                      size: 48,
                      color: ArtbeatColors.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          artistName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'commission_artists_browser_artist_id'.tr(
                            args: [_shortenArtistId(artist.artistId)],
                          ),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: ArtbeatColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (artist.basePrice > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            'commission_artists_browser_price_from'.tr(
                              args: [artist.basePrice.toStringAsFixed(2)],
                            ),
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: ArtbeatColors.success,
                            ),
                          ),
                        ],
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _handleCommissionRequest(artist),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: ArtbeatColors.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(
                              'commission_artists_browser_request'.tr(),
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
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
    );
  }
}
