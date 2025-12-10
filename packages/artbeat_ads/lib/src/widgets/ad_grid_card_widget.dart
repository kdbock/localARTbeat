import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';
import '../services/ad_report_service.dart';
import 'ad_report_dialog.dart';

class AdGridCardWidget extends StatefulWidget {
  final LocalAdZone zone;
  final double size;

  const AdGridCardWidget({Key? key, required this.zone, this.size = 150})
    : super(key: key);

  @override
  State<AdGridCardWidget> createState() => _AdGridCardWidgetState();
}

class _AdGridCardWidgetState extends State<AdGridCardWidget> {
  final LocalAdService _adService = LocalAdService();
  final AdReportService _reportService = AdReportService();
  LocalAd? _ad;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() async {
    try {
      final ads = await _adService.getActiveAdsByZone(widget.zone);
      // Filter to only show ads that should be visible to users
      final visibleAds = ads.where((ad) => ad.isVisibleToUsers).toList();

      if (visibleAds.isNotEmpty && mounted) {
        setState(() {
          _ad = visibleAds.first;
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Handle ad reporting
  Future<bool> _handleReport(
    String adId,
    String reason,
    String? details,
  ) async {
    try {
      await _reportService.reportAd(
        adId: adId,
        reason: reason,
        additionalDetails: details,
      );
      return true;
    } catch (e) {
      // Error is already logged by the service
      return false;
    }
  }

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ad == null) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _ad!.websiteUrl != null
          ? () => _launchUrl(_ad!.websiteUrl!)
          : null,
      child: Card(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              if (_ad!.imageUrl != null &&
                  _ad!.imageUrl!.isNotEmpty &&
                  (_ad!.imageUrl!.startsWith('http://') ||
                      _ad!.imageUrl!.startsWith('https://')))
                CachedNetworkImage(
                  imageUrl: _ad!.imageUrl!,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: widget.size,
                    height: widget.size,
                    color: Colors.grey[300],
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: widget.size,
                    height: widget.size,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                )
              else
                Container(
                  width: widget.size,
                  height: widget.size,
                  color: Colors.grey[300],
                ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _ad!.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Report button
                    if (_ad!.status.canBeReported)
                      AdReportButton(
                        adId: _ad!.id,
                        adTitle: _ad!.title,
                        adDescription: _ad!.description,
                        onReport: _handleReport,
                        showText: false,
                      ),
                    const SizedBox(width: 4),
                    // Ad label
                    Chip(
                      label: Text('ads_ad_grid_text_ad'.tr()),
                      backgroundColor: Colors.black.withValues(alpha: 0.5),
                      labelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                      ),
                      padding: EdgeInsets.zero,
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
