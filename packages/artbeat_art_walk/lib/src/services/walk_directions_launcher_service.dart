import 'package:url_launcher/url_launcher.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Launches walking directions for a specific art piece destination.
class WalkDirectionsLauncherService {
  static Future<bool> launchWalkingDirections({
    required double latitude,
    required double longitude,
  }) async {
    final destination = '$latitude,$longitude';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'walking',
    });

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        AppLogger.warning('Could not launch walking directions: $uri');
      }
      return launched;
    } catch (e) {
      AppLogger.error('Error launching walking directions: $e');
      return false;
    }
  }
}
