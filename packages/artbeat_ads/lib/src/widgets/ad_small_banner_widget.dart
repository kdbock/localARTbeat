import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';

class AdSmallBannerWidget extends StatefulWidget {
  final LocalAdZone zone;
  final double height;
  final bool isDismissible;

  const AdSmallBannerWidget({
    Key? key,
    required this.zone,
    this.height = 60,
    this.isDismissible = true,
  }) : super(key: key);

  @override
  State<AdSmallBannerWidget> createState() => _AdSmallBannerWidgetState();
}

class _AdSmallBannerWidgetState extends State<AdSmallBannerWidget> {
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GestureDetector(
        onTap: _ad!.websiteUrl != null
            ? () => _launchUrl(_ad!.websiteUrl!)
            : null,
        child: Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!, width: 1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ad!.title,
                            style: Theme.of(context).textTheme.labelMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _ad!.description,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'ads_ad_small_banner_text_learn'.tr(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.isDismissible)
                Positioned(
                  right: 8,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isVisible = false);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.grey[600],
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
  }
}
