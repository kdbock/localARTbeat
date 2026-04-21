import 'package:flutter_test/flutter_test.dart';
import 'package:artbeat_art_walk/src/constants/quest_tuning_defaults.dart';

void main() {
  group('QuestRuntimeConfig defaults', () {
    test('defaults align with tuning defaults when dynamic config disabled', () {
      expect(QuestRuntimeConfig.dynamicConfigEnabled, isFalse);
      expect(
        QuestRuntimeConfig.twoQuestsMultiplier,
        QuestTuningDefaults.twoQuestsSameDayMultiplier,
      );
      expect(
        QuestRuntimeConfig.threePlusMultiplier,
        QuestTuningDefaults.threePlusQuestsSameDayMultiplier,
      );
      expect(
        QuestRuntimeConfig.dailyWeeklyBonus,
        QuestTuningDefaults.dailyWeeklyComboBonus,
      );
      expect(
        QuestRuntimeConfig.maxMultiplier,
        QuestTuningDefaults.maxTotalQuestMultiplier,
      );
    });

    test('feature flags default to safe rollout values', () {
      expect(QuestRuntimeConfig.eventLoggingEnabled, isTrue);
      expect(QuestRuntimeConfig.uniqueDailyGuardsEnabled, isTrue);
    });
  });
}
