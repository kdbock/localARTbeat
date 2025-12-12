import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';
import 'package:easy_localization/easy_localization.dart';

class AdCarouselWidget extends StatefulWidget {
  final LocalAdZone zone;
  final double height;
  final Duration autoRotateDuration;

  const AdCarouselWidget({
    Key? key,
    required this.zone,
    this.height = 400,
    this.autoRotateDuration = const Duration(seconds: 4),
  }) : super(key: key);

  @override
  State<AdCarouselWidget> createState() => _AdCarouselWidgetState();
}

class _AdCarouselWidgetState extends State<AdCarouselWidget> {
  final LocalAdService _adService = LocalAdService();
  late PageController _pageController;
  int _currentIndex = 0;
  List<LocalAd> _ads = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _loadAds();
    _startAutoRotate();
  }

  void _loadAds() async {
    try {
      final ads = await _adService.getActiveAdsByZone(widget.zone);
      if (mounted) {
        setState(() {
          _ads = ads;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startAutoRotate() {
    Future.delayed(widget.autoRotateDuration, () {
      if (mounted && _ads.isNotEmpty) {
        final nextPage = (_currentIndex + 1) % _ads.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _startAutoRotate();
      }
    });
  }

  void _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_ads.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentIndex = index);
            },
            itemCount: _ads.length,
            itemBuilder: (context, index) {
              final ad = _ads[index];
              return _buildAdSlide(ad);
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _ads.length,
            (index) => GestureDetector(
              onTap: () {
                _pageController.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdSlide(LocalAd ad) {
    return Stack(
      children: [
        if (ad.imageUrl != null && ad.imageUrl!.isNotEmpty && (ad.imageUrl!.startsWith('http://') || ad.imageUrl!.startsWith('https://')))
          CachedNetworkImage(
            imageUrl: ad.imageUrl!,
            width: double.infinity,
            height: widget.height,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              child: const Icon(Icons.image_not_supported),
            ),
          )
        else
          Container(
            color: Colors.grey[300],
            width: double.infinity,
            height: widget.height,
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
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  ad.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ad.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Chip(
            label: Text('ads_ad_carousel_text_ad'.tr()),
            backgroundColor: Colors.black.withValues(alpha: 0.5),
            labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ),
        if (ad.websiteUrl != null)
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _launchUrl(ad.websiteUrl!),
              ),
            ),
          ),
      ],
    );
  }
}
