import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';

class AdNativeCardWidget extends StatefulWidget {
  final LocalAdZone zone;
  final EdgeInsets padding;

  const AdNativeCardWidget({
    Key? key,
    required this.zone,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  }) : super(key: key);

  @override
  State<AdNativeCardWidget> createState() => _AdNativeCardWidgetState();
}

class _AdNativeCardWidgetState extends State<AdNativeCardWidget> {
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
      child: GestureDetector(
        onTap: _ad!.websiteUrl != null
            ? () => _launchUrl(_ad!.websiteUrl!)
            : null,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_ad!.imageUrl != null && _ad!.imageUrl!.isNotEmpty && (_ad!.imageUrl!.startsWith('http://') || _ad!.imageUrl!.startsWith('https://')))
                      CachedNetworkImage(
                        imageUrl: _ad!.imageUrl!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 180,
                          color: Colors.grey[300],
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 180,
                          color: Colors.grey[300],
                          child: const Icon(Icons.image_not_supported),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _ad!.title,
                            style: Theme.of(context).textTheme.titleMedium,
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
                  ],
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Chip(
                    label: Text('ads_ad_native_text_sponsored'.tr()),
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    labelStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                    ),
                    padding: EdgeInsets.zero,
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _isVisible = false);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
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
