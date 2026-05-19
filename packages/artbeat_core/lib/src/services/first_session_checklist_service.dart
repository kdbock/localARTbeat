import 'package:shared_preferences/shared_preferences.dart';

import '../models/first_session_checklist_model.dart';
import '../utils/logger.dart';

class FirstSessionChecklistService {
  factory FirstSessionChecklistService() => _instance;
  FirstSessionChecklistService._internal();
  static final FirstSessionChecklistService _instance =
      FirstSessionChecklistService._internal();

  static const String _kRolePath = 'first_session_role_path';
  static const String _kCompletedSteps = 'first_session_completed_steps';
  static const String _kSimpleModeEnabled = 'first_session_simple_mode_enabled';
  static const String _kExploreMoreOpened = 'first_session_explore_more_opened';

  Future<FirstSessionChecklistState> getState({
    required FirstSessionRolePath defaultRolePath,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final roleRaw = prefs.getString(_kRolePath);
      final rolePath = _parseRole(roleRaw) ?? defaultRolePath;
      final completedRaw = prefs.getStringList(_kCompletedSteps) ?? const [];
      final completedSteps = completedRaw
          .map(_parseStep)
          .whereType<FirstSessionChecklistStep>()
          .toSet();
      final simpleModeEnabled = prefs.getBool(_kSimpleModeEnabled) ?? false;
      final exploreMoreOpened = prefs.getBool(_kExploreMoreOpened) ?? false;

      return FirstSessionChecklistState(
        rolePath: rolePath,
        completedSteps: completedSteps,
        simpleModeEnabled: simpleModeEnabled,
        exploreMoreOpened: exploreMoreOpened,
      );
    } catch (error) {
      AppLogger.error('Error loading first-session checklist state: $error');
      return FirstSessionChecklistState(
        rolePath: defaultRolePath,
        completedSteps: <FirstSessionChecklistStep>{},
        simpleModeEnabled: false,
        exploreMoreOpened: false,
      );
    }
  }

  Future<void> setRolePath(FirstSessionRolePath rolePath) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kRolePath, rolePath.name);
  }

  Future<void> markStepCompleted(FirstSessionChecklistStep step) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_kCompletedSteps) ?? <String>[];
    if (!raw.contains(step.name)) {
      raw.add(step.name);
      await prefs.setStringList(_kCompletedSteps, raw);
    }
  }

  Future<void> setSimpleModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSimpleModeEnabled, enabled);
  }

  Future<void> markExploreMoreOpened() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kExploreMoreOpened, true);
  }

  Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kRolePath);
    await prefs.remove(_kCompletedSteps);
    await prefs.remove(_kSimpleModeEnabled);
    await prefs.remove(_kExploreMoreOpened);
  }

  FirstSessionRolePath? _parseRole(String? value) {
    if (value == null) return null;
    return FirstSessionRolePath.values.where((r) => r.name == value).firstOrNull;
  }

  FirstSessionChecklistStep? _parseStep(String? value) {
    if (value == null) return null;
    return FirstSessionChecklistStep.values
        .where((s) => s.name == value)
        .firstOrNull;
  }
}
