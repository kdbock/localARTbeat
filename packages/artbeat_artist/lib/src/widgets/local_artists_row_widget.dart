import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/utils/coordinate_validator.dart'
    show SimpleLatLng;
import 'package:easy_localization/easy_localization.dart';

/// Widget that displays a horizontal list of local artists
class LocalArtistsRowWidget extends StatefulWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;
  static const int _maxArtists = 50;

  const LocalArtistsRowWidget({
    super.key,
    required this.zipCode,
    this.onSeeAllPressed,
  });

  @override
  State<LocalArtistsRowWidget> createState() => _LocalArtistsRowWidgetState();
}

class _LocalArtistsRowWidgetState extends State<LocalArtistsRowWidget> {
  late Future<List<ArtistProfileModel>> _artistsFuture;

  @override
  @override
  void initState() {
    super.initState();
    _artistsFuture = _fetchAndSortArtists();
  }

  @override
  void didUpdateWidget(LocalArtistsRowWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zipCode != widget.zipCode) {
      _refreshArtists();
    }
  }

  Future<List<ArtistProfileModel>> _fetchAndSortArtists() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('artistProfiles')
        .where('isPortfolioPublic', isEqualTo: true)
        .limit(LocalArtistsRowWidget._maxArtists)
        .get();

    final artists = snapshot.docs
        .map((doc) => ArtistProfileModel.fromFirestore(doc))
        .toList();

    final viewerLocation = await _resolveViewerLocation();

    return GeoWeightingUtils.sortByDistance<ArtistProfileModel>(
      items: artists,
      idOf: (artist) => artist.userId,
      locationOf: (artist) => artist.location,
      coordsOf: (artist) {
        final lat = artist.locationLat;
        final lng = artist.locationLng;
        if (lat == null || lng == null) return null;
        return SimpleLatLng(lat, lng);
      },
      viewerLocation: viewerLocation,
      tieBreaker: (a, b) {
        final scoreCompare = b.boostScore.compareTo(a.boostScore);
        if (scoreCompare != 0) return scoreCompare;
        final aBoost = a.lastBoostAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final bBoost = b.lastBoostAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final boostTimeCompare = bBoost.compareTo(aBoost);
        if (boostTimeCompare != 0) return boostTimeCompare;
        return a.displayName.compareTo(b.displayName);
      },
    );
  }

  void _refreshArtists() {
    setState(() {
      _artistsFuture = _fetchAndSortArtists();
    });
  }

  Future<SimpleLatLng?> _resolveViewerLocation() async {
    final zipCoords = await LocationUtils.getCoordinatesFromZipCode(
      widget.zipCode,
    );
    if (zipCoords != null) {
      return zipCoords;
    }
    return GeoWeightingUtils.resolveViewerLocation(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                tr('art_walk_local_artists'),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: widget.onSeeAllPressed,
                child: Text(tr('art_walk_see_all')),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: FutureBuilder<List<ArtistProfileModel>>(
            future: _artistsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingState();
              }

              if (snapshot.hasError) {
                return _ErrorState(displayText: tr('art_walk_error_loading_artists'));
              }

              final artists = snapshot.data ?? const [];
              if (artists.isEmpty) {
                return _EmptyState(zipCode: widget.zipCode);
              }

              return _LocalArtistList(artists: artists);
            },
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String displayText;

  const _ErrorState({Key? key, required this.displayText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 36,
            ),
            const SizedBox(height: 8),
            Text(
              displayText,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String zipCode;

  const _EmptyState({Key? key, required this.zipCode}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.brush_outlined,
              size: 40,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 8),
            Text(
              'No local artists found in $zipCode',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalArtistList extends StatelessWidget {
  final List<ArtistProfileModel> artists;

  const _LocalArtistList({Key? key, required this.artists}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final isFirst = index == 0;
        final isLast = index == artists.length - 1;
        return Padding(
          padding: EdgeInsets.only(
            left: isFirst ? 16.0 : 8.0,
            right: isLast ? 16.0 : 8.0,
          ),
          child: _LocalArtistCard(artist: artist),
        );
      },
    );
  }
}

class _LocalArtistCard extends StatelessWidget {
  final ArtistProfileModel artist;

  const _LocalArtistCard({Key? key, required this.artist}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasValidImage = artist.profileImageUrl != null &&
        artist.profileImageUrl!.isNotEmpty &&
        ImageUrlValidator.isValidImageUrl(artist.profileImageUrl);

    return SizedBox(
      width: 120,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              if (artist.hasActiveBoost)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Tooltip(
                    message: 'boost_badge_tooltip'.tr(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFF97316),
                            Color(0xFF22D3EE),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF22D3EE,
                            ).withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              BoostPulseRing(
                enabled: artist.hasActiveBoost,
                ringPadding: 4,
                ringWidth: 2,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    border: artist.isVerified
                        ? Border.all(
                            color: Colors.blue,
                            width: 2,
                          )
                        : artist.isFeatured
                            ? Border.all(
                                color: Colors.amber,
                                width: 2,
                              )
                            : null,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: artist.hasMapGlow
                        ? [
                            BoxShadow(
                              color: const Color(
                                0xFF22D3EE,
                              ).withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                            BoxShadow(
                              color: const Color(
                                0xFFF97316,
                              ).withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                    image: hasValidImage
                        ? DecorationImage(
                            image: ImageUrlValidator.safeNetworkImage(
                              artist.profileImageUrl,
                            )!,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: !hasValidImage
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
              if (artist.isVerified || artist.isFeatured)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: artist.isVerified ? Colors.blue : Colors.amber,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      artist.isVerified ? Icons.verified : Icons.star,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            artist.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
