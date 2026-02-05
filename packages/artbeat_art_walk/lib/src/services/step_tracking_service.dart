import 'dart:async';
import 'dart:io';
import 'package:pedometer/pedometer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'challenge_service.dart';

/// Service for tracking user steps and integrating with the challenge system
class StepTrackingService {
  static final StepTrackingService _instance = StepTrackingService._internal();
  factory StepTrackingService() => _instance;
  StepTrackingService._internal();

  final _logger = Logger('StepTrackingService');

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  ChallengeService? _challengeService;

  int _todaySteps = 0;
  int _baselineSteps = 0;
  String _lastResetDate = '';
  bool _isInitialized = false;
  bool _isTracking = false;
  bool _isSupported = true;

  // Stream controller for broadcasting step updates
  final _stepController = StreamController<int>.broadcast();
  Stream<int> get stepStream => _stepController.stream;

  int get todaySteps => _todaySteps;
  bool get isTracking => _isTracking;

  /// Initialize the step tracking service
  Future<void> initialize({ChallengeService? challengeService}) async {
    if (_isInitialized) {
      _logger.info('Step tracking already initialized');
      return;
    }

    // Step tracking is only supported on mobile platforms
    if (!Platform.isAndroid && !Platform.isIOS) {
      _isSupported = false;
      _isInitialized = true;
      _logger.info('Step tracking is not supported on this platform (${Platform.operatingSystem})');
      return;
    }

    _challengeService = challengeService;

    try {
      // Load saved step data
      await _loadStepData();

      // Check if we need to reset for a new day
      final today = _getTodayKey();
      if (_lastResetDate != today) {
        await _resetDailySteps();
      }

      _isInitialized = true;
      _logger.info('Step tracking service initialized');
    } catch (e) {
      _logger.severe('Failed to initialize step tracking: $e');
      rethrow;
    }
  }

  /// Start tracking steps
  Future<void> startTracking() async {
    if (!_isInitialized) {
      throw StateError(
        'StepTrackingService must be initialized before starting tracking',
      );
    }

    if (!_isSupported) {
      _logger.info('Step tracking skip: platform not supported');
      return;
    }

    if (_isTracking) {
      _logger.info('Step tracking already active');
      return;
    }

    try {
      // Listen to step count stream
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      // Listen to pedestrian status (optional, for detecting walking state)
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _isTracking = true;
      _logger.info('Step tracking started');
    } catch (e) {
      _logger.severe('Failed to start step tracking: $e');
      rethrow;
    }
  }

  /// Stop tracking steps
  Future<void> stopTracking() async {
    await _stepCountSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();
    _stepCountSubscription = null;
    _pedestrianStatusSubscription = null;
    _isTracking = false;
    _logger.info('Step tracking stopped');
  }

  /// Handle step count updates
  void _onStepCount(StepCount event) async {
    final today = _getTodayKey();

    // Check if we need to reset for a new day
    if (_lastResetDate != today) {
      await _resetDailySteps();
      _baselineSteps = event.steps;
    }

    // Calculate today's steps (total steps - baseline)
    final previousSteps = _todaySteps;
    _todaySteps = event.steps - _baselineSteps;

    // Ensure steps don't go negative (can happen on device restart)
    if (_todaySteps < 0) {
      _baselineSteps = event.steps;
      _todaySteps = 0;
    }

    // Save step data
    await _saveStepData(event.steps);

    // Broadcast step update
    _stepController.add(_todaySteps);

    // Update challenge progress if steps increased
    if (_todaySteps > previousSteps && _challengeService != null) {
      final stepIncrement = _todaySteps - previousSteps;
      try {
        await _challengeService!.recordSteps(stepIncrement);
      } catch (e) {
        _logger.warning('Failed to record steps to challenge: $e');
      }
    }

    _logger.fine(
      'Steps updated: $_todaySteps (total: ${event.steps}, baseline: $_baselineSteps)',
    );
  }

  /// Handle step count errors
  void _onStepCountError(Object error) {
    _logger.warning('Step count error: $error');
    // Don't stop tracking on error, pedometer might recover
  }

  /// Handle pedestrian status changes
  void _onPedestrianStatusChanged(PedestrianStatus event) {
    _logger.fine('Pedestrian status: ${event.status}');
    // Could be used for additional features like detecting when user is walking
  }

  /// Handle pedestrian status errors
  void _onPedestrianStatusError(Object error) {
    _logger.warning('Pedestrian status error: $error');
  }

  /// Reset daily steps for a new day
  Future<void> _resetDailySteps() async {
    _todaySteps = 0;
    _baselineSteps = 0;
    _lastResetDate = _getTodayKey();
    await _saveStepData(0);
    _logger.info('Daily steps reset for $_lastResetDate');
  }

  /// Load saved step data from SharedPreferences
  Future<void> _loadStepData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _todaySteps = prefs.getInt('today_steps') ?? 0;
      _baselineSteps = prefs.getInt('baseline_steps') ?? 0;
      _lastResetDate = prefs.getString('last_reset_date') ?? '';
      _logger.info(
        'Loaded step data: $_todaySteps steps, baseline: $_baselineSteps, date: $_lastResetDate',
      );
    } catch (e) {
      _logger.warning('Failed to load step data: $e');
    }
  }

  /// Save step data to SharedPreferences
  Future<void> _saveStepData(int totalSteps) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('today_steps', _todaySteps);
      await prefs.setInt('baseline_steps', _baselineSteps);
      await prefs.setString('last_reset_date', _lastResetDate);
      await prefs.setInt('total_steps', totalSteps);
    } catch (e) {
      _logger.warning('Failed to save step data: $e');
    }
  }

  /// Get today's date key (YYYY-MM-DD)
  String _getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Manually add steps (for testing or manual entry)
  Future<void> addSteps(int steps) async {
    if (steps <= 0) return;

    _todaySteps += steps;
    await _saveStepData(_baselineSteps + _todaySteps);
    _stepController.add(_todaySteps);

    if (_challengeService != null) {
      try {
        await _challengeService!.recordSteps(steps);
      } catch (e) {
        _logger.warning('Failed to record manual steps to challenge: $e');
      }
    }
  }

  /// Get step statistics
  Map<String, dynamic> getStepStats() {
    return {
      'todaySteps': _todaySteps,
      'isTracking': _isTracking,
      'lastResetDate': _lastResetDate,
    };
  }

  /// Dispose of resources
  void dispose() {
    stopTracking();
    _stepController.close();
    _isInitialized = false;
  }
}
