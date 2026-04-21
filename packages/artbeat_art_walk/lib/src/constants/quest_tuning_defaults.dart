/// Centralized quest tuning defaults for daily/weekly systems.
///
/// This file is wired into service logic and supports build-time overrides.
class QuestTuningDefaults {
  // Exposure and cadence
  static const int dailyQuestsShown = 1;
  static const int weeklyGoalsShown = 3;

  // Target completion rates (observability targets)
  static const double dailyCompletionRateMin = 0.45;
  static const double dailyCompletionRateMax = 0.65;
  static const double weeklyGoalCompletionRateMin = 0.20;
  static const double weeklyGoalCompletionRateMax = 0.35;
  static const double perfectWeekRateMin = 0.05;
  static const double perfectWeekRateMax = 0.10;

  // Daily XP bands
  static const int dailyXpMin = 40;
  static const int dailyXpMax = 90;

  // Weekly XP bands
  static const int weeklyXpMin = 300;
  static const int weeklyXpMax = 700;

  // Login streak baseline
  static const int loginBaseXp = 10;
  static const int loginStreak2PlusXp = 15;
  static const int loginStreak3PlusXp = 25;
  static const int loginStreak7PlusXp = 50;
  static const int loginDay7BonusXp = 50;
  static const int loginDay30BonusXp = 100;
  static const int loginDay100BonusXp = 500;

  // Multiplier tuning
  static const double twoQuestsSameDayMultiplier = 1.15;
  static const double threePlusQuestsSameDayMultiplier = 1.30;
  static const double dailyWeeklyComboBonus = 0.15;
  static const double maxTotalQuestMultiplier = 1.50;

  // Economy guardrails
  static const int softMaxQuestXpPerDay = 350;
  static const int maxLoginClaimsPerDay = 1;

  // Scaling bands
  static const QuestScalingTier level1to5 = QuestScalingTier(
    minLevel: 1,
    maxLevel: 5,
    targetMultiplier: 1.00,
    rewardMultiplier: 1.00,
  );
  static const QuestScalingTier level6to10 = QuestScalingTier(
    minLevel: 6,
    maxLevel: 10,
    targetMultiplier: 1.15,
    rewardMultiplier: 1.10,
  );
  static const QuestScalingTier level11to20 = QuestScalingTier(
    minLevel: 11,
    maxLevel: 20,
    targetMultiplier: 1.30,
    rewardMultiplier: 1.20,
  );
  static const QuestScalingTier level21Plus = QuestScalingTier(
    minLevel: 21,
    maxLevel: 999,
    targetMultiplier: 1.45,
    rewardMultiplier: 1.30,
  );

  static const List<QuestScalingTier> scalingTiers = <QuestScalingTier>[
    level1to5,
    level6to10,
    level11to20,
    level21Plus,
  ];
}

/// Runtime controls for safer staged rollout.
///
/// These values can be overridden at build time:
/// - `--dart-define=QUEST_DYNAMIC_CONFIG=true`
/// - `--dart-define=QUEST_EVENT_LOGGING=true`
/// - `--dart-define=QUEST_UNIQUE_GUARDS=true`
/// - `--dart-define=QUEST_TWO_QUESTS_MULTIPLIER=1.15`
/// - `--dart-define=QUEST_THREE_PLUS_MULTIPLIER=1.30`
/// - `--dart-define=QUEST_DAILY_WEEKLY_BONUS=0.15`
/// - `--dart-define=QUEST_MAX_MULTIPLIER=1.50`
class QuestRuntimeConfig {
  static const bool dynamicConfigEnabled = bool.fromEnvironment(
    'QUEST_DYNAMIC_CONFIG',
    defaultValue: false,
  );
  static const bool eventLoggingEnabled = bool.fromEnvironment(
    'QUEST_EVENT_LOGGING',
    defaultValue: true,
  );
  static const bool uniqueDailyGuardsEnabled = bool.fromEnvironment(
    'QUEST_UNIQUE_GUARDS',
    defaultValue: true,
  );

  static const String _twoQuestsMultiplierRaw = String.fromEnvironment(
    'QUEST_TWO_QUESTS_MULTIPLIER',
    defaultValue: '',
  );
  static const String _threePlusMultiplierRaw = String.fromEnvironment(
    'QUEST_THREE_PLUS_MULTIPLIER',
    defaultValue: '',
  );
  static const String _dailyWeeklyBonusRaw = String.fromEnvironment(
    'QUEST_DAILY_WEEKLY_BONUS',
    defaultValue: '',
  );
  static const String _maxMultiplierRaw = String.fromEnvironment(
    'QUEST_MAX_MULTIPLIER',
    defaultValue: '',
  );

  static double get twoQuestsMultiplier => dynamicConfigEnabled
      ? (double.tryParse(_twoQuestsMultiplierRaw) ??
            QuestTuningDefaults.twoQuestsSameDayMultiplier)
      : QuestTuningDefaults.twoQuestsSameDayMultiplier;
  static double get threePlusMultiplier => dynamicConfigEnabled
      ? (double.tryParse(_threePlusMultiplierRaw) ??
            QuestTuningDefaults.threePlusQuestsSameDayMultiplier)
      : QuestTuningDefaults.threePlusQuestsSameDayMultiplier;
  static double get dailyWeeklyBonus => dynamicConfigEnabled
      ? (double.tryParse(_dailyWeeklyBonusRaw) ??
            QuestTuningDefaults.dailyWeeklyComboBonus)
      : QuestTuningDefaults.dailyWeeklyComboBonus;
  static double get maxMultiplier => dynamicConfigEnabled
      ? (double.tryParse(_maxMultiplierRaw) ??
            QuestTuningDefaults.maxTotalQuestMultiplier)
      : QuestTuningDefaults.maxTotalQuestMultiplier;
}

class QuestScalingTier {
  final int minLevel;
  final int maxLevel;
  final double targetMultiplier;
  final double rewardMultiplier;

  const QuestScalingTier({
    required this.minLevel,
    required this.maxLevel,
    required this.targetMultiplier,
    required this.rewardMultiplier,
  });

  bool containsLevel(int level) => level >= minLevel && level <= maxLevel;
}
