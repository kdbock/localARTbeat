enum FirstSessionRolePath { fan, artist }

enum FirstSessionChecklistStep {
  fanDiscoverNearby,
  fanFollowArtist,
  fanSaveArtwork,
  artistCompleteProfile,
  artistUploadArtwork,
  artistOpenDashboardTool,
}

class FirstSessionChecklistState {
  const FirstSessionChecklistState({
    required this.rolePath,
    required this.completedSteps,
    required this.simpleModeEnabled,
    required this.exploreMoreOpened,
  });

  final FirstSessionRolePath rolePath;
  final Set<FirstSessionChecklistStep> completedSteps;
  final bool simpleModeEnabled;
  final bool exploreMoreOpened;

  bool get isCompleted {
    final requiredSteps = stepsForRole(rolePath);
    return requiredSteps.every(completedSteps.contains);
  }

  static List<FirstSessionChecklistStep> stepsForRole(
    FirstSessionRolePath rolePath,
  ) {
    switch (rolePath) {
      case FirstSessionRolePath.fan:
        return const [
          FirstSessionChecklistStep.fanDiscoverNearby,
          FirstSessionChecklistStep.fanFollowArtist,
          FirstSessionChecklistStep.fanSaveArtwork,
        ];
      case FirstSessionRolePath.artist:
        return const [
          FirstSessionChecklistStep.artistCompleteProfile,
          FirstSessionChecklistStep.artistUploadArtwork,
          FirstSessionChecklistStep.artistOpenDashboardTool,
        ];
    }
  }
}
