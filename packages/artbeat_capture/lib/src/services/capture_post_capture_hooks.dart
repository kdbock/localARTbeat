import 'package:artbeat_core/artbeat_core.dart' show CaptureModel;
import 'package:geolocator/geolocator.dart';

abstract class CapturePostCaptureHooks {
  Future<void> awardCaptureCreatedXp();

  Future<void> awardCaptureApprovedXp();

  Future<void> recordCaptureChallengeProgress();

  Future<void> updateWeeklyPhotographyGoals();

  Future<void> postCaptureActivity({
    required CaptureModel capture,
    required String userName,
    String? userAvatar,
    Position? location,
  });

  Future<void> checkCaptureAchievements(String userId);
}

class NoopCapturePostCaptureHooks implements CapturePostCaptureHooks {
  const NoopCapturePostCaptureHooks();

  @override
  Future<void> awardCaptureApprovedXp() async {}

  @override
  Future<void> awardCaptureCreatedXp() async {}

  @override
  Future<void> checkCaptureAchievements(String userId) async {}

  @override
  Future<void> postCaptureActivity({
    required CaptureModel capture,
    required String userName,
    String? userAvatar,
    Position? location,
  }) async {}

  @override
  Future<void> recordCaptureChallengeProgress() async {}

  @override
  Future<void> updateWeeklyPhotographyGoals() async {}
}
