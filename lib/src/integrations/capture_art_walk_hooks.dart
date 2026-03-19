import 'package:artbeat_art_walk/artbeat_art_walk.dart' as art_walk;
import 'package:artbeat_capture/artbeat_capture.dart';
import 'package:geolocator/geolocator.dart';

class CaptureArtWalkHooks implements CapturePostCaptureHooks {
  CaptureArtWalkHooks({
    art_walk.RewardsService? rewardsService,
    art_walk.ChallengeService? challengeService,
    art_walk.WeeklyGoalsService? weeklyGoalsService,
    art_walk.SocialService? socialService,
    art_walk.ArtWalkService? artWalkService,
  }) : _rewardsService = rewardsService ?? art_walk.RewardsService(),
       _challengeService = challengeService ?? art_walk.ChallengeService(),
       _weeklyGoalsService =
           weeklyGoalsService ?? art_walk.WeeklyGoalsService(),
       _socialService = socialService ?? art_walk.SocialService(),
       _artWalkService = artWalkService ?? art_walk.ArtWalkService();

  final art_walk.RewardsService _rewardsService;
  final art_walk.ChallengeService _challengeService;
  final art_walk.WeeklyGoalsService _weeklyGoalsService;
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
  }) => _socialService.postActivity(
      userId: capture.userId,
      userName: userName,
      userAvatar: userAvatar,
      type: art_walk.SocialActivityType.capture,
      message: 'captured new artwork',
      location: location,
      metadata: {
        'captureId': capture.id,
        'artTitle': capture.title ?? 'Untitled',
      },
    );

  @override
  Future<void> recordCaptureChallengeProgress() async {
    await Future.wait([
      _challengeService.recordPhotoCapture(),
      _challengeService.recordTimeBasedDiscovery(),
    ]);
  }

  @override
  Future<void> updateWeeklyPhotographyGoals() async {
    final currentGoals = await _weeklyGoalsService.getCurrentWeekGoals();
    final updates = currentGoals
        .where(
          (goal) =>
              goal.category == art_walk.WeeklyGoalCategory.photography &&
              !goal.isCompleted,
        )
        .map((goal) => _weeklyGoalsService.updateWeeklyGoalProgress(goal.id, 1))
        .toList();

    if (updates.isNotEmpty) {
      await Future.wait(updates);
    }
  }
}
