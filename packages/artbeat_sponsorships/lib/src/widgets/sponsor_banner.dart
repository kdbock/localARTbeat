import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/sponsorship.dart';
import '../models/sponsorship_tier.dart';
import '../services/sponsor_service.dart';

/// A lightweight, async-safe sponsor renderer.
///
/// - Never blocks layout
/// - Safe across rebuilds
/// - Cancels stale async results
/// - Renders nothing if no sponsor is found
class SponsorBanner extends StatefulWidget {
  const SponsorBanner({
    super.key,
    required this.placementKey,
    this.userLocation,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    this.showPlaceholder = false,
    this.onPlaceholderTap,
    this.sponsorService,
  });

  final String placementKey;
  final LatLng? userLocation;
  final EdgeInsets padding;
  final bool showPlaceholder;
  final VoidCallback? onPlaceholderTap;
  final SponsorService? sponsorService;

  @override
  State<SponsorBanner> createState() => _SponsorBannerState();
}

class _SponsorBannerState extends State<SponsorBanner> {
  late final SponsorService _service;

  Sponsorship? _sponsor;
  bool _isLoading = false;

  /// Used to discard stale async responses when the widget rebuilds
  int _requestToken = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.sponsorService ?? SponsorService();
    _loadSponsor();
  }

  @override
  void didUpdateWidget(covariant SponsorBanner oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Reload only when inputs that affect resolution change
    if (oldWidget.placementKey != widget.placementKey ||
        oldWidget.userLocation != widget.userLocation) {
      _loadSponsor();
    }
  }

  Future<void> _loadSponsor() async {
    final int token = ++_requestToken;

    setState(() {
      _isLoading = true;
      _sponsor = null;
    });

    try {
      final sponsor = await _service.getSponsorForPlacement(
        placementKey: widget.placementKey,
        userLocation: widget.userLocation,
      );

      // Drop stale responses
      if (!mounted || token != _requestToken) return;

      setState(() {
        _sponsor = sponsor;
        _isLoading = false;
      });
    } on Exception catch (_) {
      // Fail silently — sponsorships must never break UI
      if (!mounted || token != _requestToken) return;

      setState(() {
        _sponsor = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Never reserve space while loading
    if (_isLoading) {
      return const SizedBox.shrink();
    }

    if (_sponsor == null || !_sponsor!.hasRenderableCreative) {
      if (widget.showPlaceholder) {
        return Padding(
          padding: widget.padding,
          child: SponsorPlaceholder(onTap: widget.onPlaceholderTap),
        );
      }
      return const SizedBox.shrink();
    }

    return Padding(
      padding: widget.padding,
      child: _buildSponsorContent(context, _sponsor!),
    );
  }

  Widget _buildSponsorContent(BuildContext context, Sponsorship sponsor) {
    switch (sponsor.tier) {
      case SponsorshipTier.artWalk:
        return _LabeledBanner(
          sponsor: sponsor,
          label: 'Art Walk Sponsor',
          sublabel: 'Earn XP when you stop here',
        );

      case SponsorshipTier.capture:
        return _CompactBanner(sponsor: sponsor);

      case SponsorshipTier.discover:
        return _CompactBanner(sponsor: sponsor);
    }
  }
}

/* -------------------------------------------------------------------------- */
/*                               Render Variants                              */
/* -------------------------------------------------------------------------- */

class _LabeledBanner extends StatelessWidget {
  const _LabeledBanner({
    required this.sponsor,
    required this.label,
    this.sublabel,
  });

  final Sponsorship sponsor;
  final String label;
  final String? sublabel;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => unawaited(_openLink(context, sponsor.linkUrl)),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            blurRadius: 6,
            offset: const Offset(0, 3),
            color: Colors.black.withValues(alpha: 0.08),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              sponsor.logoUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.grey[600]),
                ),
                Text(
                  sponsor.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (sublabel != null)
                  Text(
                    sublabel!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _CompactBanner extends StatelessWidget {
  const _CompactBanner({required this.sponsor});

  final Sponsorship sponsor;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => unawaited(_openLink(context, sponsor.linkUrl)),
    child: Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.1),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Image.network(
              sponsor.logoUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sponsor.businessName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Capture Sponsor',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
          const SizedBox(width: 12),
        ],
      ),
    ),
  );
}

/// A placeholder shown when no sponsor is active, encouraging businesses to sponsor.
class SponsorPlaceholder extends StatelessWidget {
  const SponsorPlaceholder({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_business,
              color: Colors.white70,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sponsor this space',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Connect with local art explorers',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: Colors.white60),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.white38),
          const SizedBox(width: 12),
        ],
      ),
    ),
  );
}

/* -------------------------------------------------------------------------- */
/*                                   Helpers                                  */
/* -------------------------------------------------------------------------- */

Future<void> _openLink(BuildContext context, String url) async {
  final withScheme = url.contains('://') ? url : 'https://$url';
  final uri = Uri.tryParse(withScheme);
  if (uri == null || uri.host.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sponsor link is not available right now.')),
    );
    return;
  }

  try {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } on Exception catch (_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open sponsor link.')),
    );
  }
}
