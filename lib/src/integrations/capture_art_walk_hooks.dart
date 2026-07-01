import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:geolocator/geolocator.dart';

class CaptureArtWalkHooks implements CapturePostCaptureHooks {
  CaptureArtWalkHooks({
    art_walk.RewardsService? rewardsService,
    art_walk.SocialService? socialService,
    art_walk.ArtWalkService? artWalkService,
  }) : _rewardsService = rewardsService ?? art_walk.RewardsService(),
       _socialService = socialService ?? art_walk.SocialService(),
       _artWalkService = artWalkService ?? art_walk.ArtWalkService();

  final art_walk.RewardsService _rewardsService;
  final art_walk.SocialService _socialService;
  final art_walk.ArtWalkService _artWalkService;

  @override
  Future<void> awardCaptureApprovedXp() =>
      _rewardsService.awardXP('art_capture_approved');

  @override
  Future<void> awardCaptureCreatedXp() =>
      _rewardsService.awardXP('art_capture_created');

  @override
  Future<void> checkCaptureAchievements(String userId) =>
      _artWalkService.checkCaptureAchievements(userId);

  @override
  Future<void> postCaptureActivity({
    required CaptureModel capture,
    required String userName,
    String? userAvatar,
    Position? location,
  }) {
    final locationLabel = (capture.locationName?.trim().isNotEmpty ?? false)
        ? capture.locationName!.trim()
        : 'their area';

    return _socialService.postActivity(
      userId: capture.userId,
      userName: userName,
      userAvatar: userAvatar,
      type: art_walk.SocialActivityType.capture,
      message:
          '$userName discovered outdoor artwork in $locationLabel and got XP points',
      location: location,
      metadata: {
        'captureId': capture.id,
        if (capture.title != null && capture.title!.trim().isNotEmpty)
          'artTitle': capture.title!.trim(),
        'locationName': capture.locationName,
        'photoUrl': capture.imageUrl,
        'imageUrl': capture.imageUrl,
        if (capture.thumbnailUrl != null &&
            capture.thumbnailUrl!.trim().isNotEmpty)
          'thumbnailUrl': capture.thumbnailUrl!.trim(),
        'capture': {
          'id': capture.id,
          'imageUrl': capture.imageUrl,
          if (capture.thumbnailUrl != null &&
              capture.thumbnailUrl!.trim().isNotEmpty)
            'thumbnailUrl': capture.thumbnailUrl!.trim(),
          if (capture.title != null && capture.title!.trim().isNotEmpty)
            'title': capture.title!.trim(),
        },
      },
    );
  }

  @override
  Future<void> recordCaptureChallengeProgress() async {}

  @override
  Future<void> updateWeeklyPhotographyGoals() async {}
}
