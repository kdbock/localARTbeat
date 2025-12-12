import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';
import 'package:easy_localization/easy_localization.dart';

class AdCtaCardWidget extends StatefulWidget {
  final LocalAdZone zone;
  final String? ctaText;
  final EdgeInsets padding;

  const AdCtaCardWidget({
    Key? key,
    required this.zone,
    this.ctaText = 'Learn More',
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) : super(key: key);

  @override
  State<AdCtaCardWidget> createState() => _AdCtaCardWidgetState();
}

class _AdCtaCardWidgetState extends State<AdCtaCardWidget> {
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
      padding: widget.padding,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          border: Border.all(color: Colors.green[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _ad!.title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _ad!.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_ad!.websiteUrl != null)
                  GestureDetector(
                    onTap: () {
                      setState(() => _isVisible = false);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_ad!.websiteUrl != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _launchUrl(_ad!.websiteUrl!),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    widget.ctaText ?? 'ads_ad_cta_text_learn_more'.tr(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
