import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/artist_profile_model.dart';
import '../utils/artist_logger.dart';
import 'error_monitoring_service.dart';

/// @deprecated This service is deprecated. Use ArtistService from artbeat_core instead.
///
/// This service has been consolidated into artbeat_core/ArtistService which provides
/// all the functionality from this service plus additional enhanced features.
///
/// Migration Guide:
/// ```dart
/// // OLD (artbeat_artist)
/// import 'package:artbeat_artist/artbeat_artist.dart' as artist;
/// final service = artist.ArtistService();
///
/// // NEW (artbeat_core)
/// import 'package:artbeat_core/artbeat_core.dart';
/// final service = ArtistService();
/// final profiles = await service.getFeaturedArtistProfiles(); // Enhanced version
/// ```
@Deprecated('Use ArtistService from artbeat_core package instead')
class ArtistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// @deprecated Use getFeaturedArtistProfiles() from artbeat_core.ArtistService instead
  @Deprecated('Use getFeaturedArtistProfiles() from artbeat_core.ArtistService')
  Future<List<ArtistProfileModel>> getFeaturedArtists() async {
    return ErrorMonitoringService.safeExecute(
      'getFeaturedArtists',
      () async {
        ArtistLogger.warning(
          'DEPRECATED: artbeat_artist.ArtistService.getFeaturedArtists()',
        );
        ArtistLogger.info(
          'Please migrate to: artbeat_core.ArtistService.getFeaturedArtistProfiles()',
        );
        ArtistLogger.artistService('Fetching featured artists');

        final snapshot = await _firestore
            .collection('artists')
            .where('isFeatured', isEqualTo: true)
            .get()
            .timeout(const Duration(seconds: 10));

        final artists = snapshot.docs
            .map(
              (doc) => ArtistProfileModel.fromMap(doc.data()..['id'] = doc.id),
            )
            .toList();

        ArtistLogger.artistService(
          'Fetched featured artists',
          details: '${artists.length} artists loaded',
        );
        return artists;
      },
      fallbackValue: [],
      context: {'operation': 'getFeaturedArtists'},
    );
  }
}
