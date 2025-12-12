import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';
import 'package:easy_localization/easy_localization.dart';

class AdBadgeWidget extends StatefulWidget {
  final LocalAdZone zone;
  final double width;
  final double height;

  const AdBadgeWidget({
    Key? key,
    required this.zone,
    this.width = 200,
    this.height = 80,
  }) : super(key: key);

  @override
  State<AdBadgeWidget> createState() => _AdBadgeWidgetState();
}

class _AdBadgeWidgetState extends State<AdBadgeWidget> {
  final LocalAdService _adService = LocalAdService();
  LocalAd? _ad;
  bool _isLoading = true;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() async {
    try {
      final ads = await _adService.getActiveAdsByZone(widget.zone);
      if (ads.isNotEmpty && mounted) {
        setState(() {
          _ad = ads.first;
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

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _ad == null || !_isVisible) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: _ad!.websiteUrl != null
          ? () => _launchUrl(_ad!.websiteUrl!)
          : null,
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ads_ad_badge_text_featured'.tr(),
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _ad!.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Positioned(
              right: 8,
              top: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() => _isVisible = false);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 12, color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
