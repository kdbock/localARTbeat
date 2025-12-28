import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'package:artbeat_art_walk/src/models/models.dart';

/// Settings for audio navigation service
class AudioNavigationSettings {
  final bool enableVoiceDirections;
  final bool enableArtAnnouncements;
  final bool enableProgressUpdates;
  final double speechRate;
  final String voiceLanguage;
  final bool enableInBackground;
  final double volume;
  final double pitch;

  const AudioNavigationSettings({
    this.enableVoiceDirections = true,
    this.enableArtAnnouncements = true,
    this.enableProgressUpdates = true,
    this.speechRate = 0.5,
    this.voiceLanguage = 'en-US',
    this.enableInBackground = false,
    this.volume = 0.8,
    this.pitch = 1.0,
  });

  /// Create from map (for storage/retrieval)
  factory AudioNavigationSettings.fromMap(Map<String, dynamic> map) {
    return AudioNavigationSettings(
      enableVoiceDirections: map['enableVoiceDirections'] as bool? ?? true,
      enableArtAnnouncements: map['enableArtAnnouncements'] as bool? ?? true,
      enableProgressUpdates: map['enableProgressUpdates'] as bool? ?? true,
      speechRate: (map['speechRate'] as num? ?? 0.5).toDouble(),
      voiceLanguage: map['voiceLanguage'] as String? ?? 'en-US',
      enableInBackground: map['enableInBackground'] as bool? ?? false,
      volume: (map['volume'] as num? ?? 0.8).toDouble(),
      pitch: (map['pitch'] as num? ?? 1.0).toDouble(),
    );
  }

  /// Convert to map (for storage)
  Map<String, dynamic> toMap() {
    return {
      'enableVoiceDirections': enableVoiceDirections,
      'enableArtAnnouncements': enableArtAnnouncements,
      'enableProgressUpdates': enableProgressUpdates,
      'speechRate': speechRate,
      'voiceLanguage': voiceLanguage,
      'enableInBackground': enableInBackground,
      'volume': volume,
      'pitch': pitch,
    };
  }

  /// Create copy with updated values
  AudioNavigationSettings copyWith({
    bool? enableVoiceDirections,
    bool? enableArtAnnouncements,
    bool? enableProgressUpdates,
    double? speechRate,
    String? voiceLanguage,
    bool? enableInBackground,
    double? volume,
    double? pitch,
  }) {
    return AudioNavigationSettings(
      enableVoiceDirections:
          enableVoiceDirections ?? this.enableVoiceDirections,
      enableArtAnnouncements:
          enableArtAnnouncements ?? this.enableArtAnnouncements,
      enableProgressUpdates:
          enableProgressUpdates ?? this.enableProgressUpdates,
      speechRate: speechRate ?? this.speechRate,
      voiceLanguage: voiceLanguage ?? this.voiceLanguage,
      enableInBackground: enableInBackground ?? this.enableInBackground,
      volume: volume ?? this.volume,
      pitch: pitch ?? this.pitch,
    );
  }
}

/// Service for providing audio navigation and announcements during art walks
class AudioNavigationService {
  static final AudioNavigationService _instance =
      AudioNavigationService._internal();
  factory AudioNavigationService() => _instance;
  AudioNavigationService._internal();

  final FlutterTts _tts = FlutterTts();
  final Logger _logger = Logger();

  bool _isInitialized = false;
  bool _isEnabled = true;
  final String _language = 'en-US';
  final double _speechRate = 0.5;
  final double _volume = 0.8;
  final double _pitch = 1.0;

  // Audio settings
  AudioNavigationSettings _settings = const AudioNavigationSettings();

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Configure TTS settings
      await _tts.setLanguage(_language);
      await _tts.setSpeechRate(_speechRate);
      await _tts.setVolume(_volume);
      await _tts.setPitch(_pitch);

      // Set up callbacks
      _tts.setStartHandler(() {
        _logger.d('TTS started speaking');
      });

      _tts.setCompletionHandler(() {
        _logger.d('TTS completed speaking');
      });

      _tts.setErrorHandler((msg) {
        _logger.e('TTS error: $msg');
      });

      _isInitialized = true;
      _logger.i('Audio navigation service initialized');
    } catch (e) {
      _logger.e('Failed to initialize TTS: $e');
      _isInitialized = false;
    }
  }

  /// Update audio settings
  Future<void> updateSettings(AudioNavigationSettings settings) async {
    _settings = settings;
    _isEnabled = settings.enableVoiceDirections;

    if (_isInitialized) {
      await _tts.setLanguage(settings.voiceLanguage);
      await _tts.setSpeechRate(settings.speechRate);
    }
  }

  /// Speak a navigation direction
  Future<void> speakDirection(String instruction) async {
    if (!_settings.enableVoiceDirections || !_isEnabled) return;

    await _ensureInitialized();

    try {
      await _tts.speak(instruction);
      _logger.d('Speaking direction: $instruction');
    } catch (e) {
      _logger.e('Error speaking direction: $e');
    }
  }

  /// Announce approaching art piece
  Future<void> announceArtPieceApproach(
    PublicArtModel art,
    double distance,
  ) async {
    if (!_settings.enableArtAnnouncements || !_isEnabled) return;

    await _ensureInitialized();

    final message = generateApproachMessage(art, distance);

    try {
      await _tts.speak(message);
      _logger.d('Announcing art approach: $message');
    } catch (e) {
      _logger.e('Error announcing art approach: $e');
    }
  }

  /// Celebrate art visit with audio feedback
  Future<void> celebrateArtVisit(PublicArtModel art, int points) async {
    if (!_settings.enableArtAnnouncements || !_isEnabled) return;

    await _ensureInitialized();

    final message = generateArrivalMessage(art, points);

    try {
      await _tts.speak(message);
      _logger.d('Celebrating art visit: $message');
    } catch (e) {
      _logger.e('Error celebrating art visit: $e');
    }
  }

  /// Announce walk progress
  Future<void> announceWalkProgress(int visited, int total) async {
    if (!_settings.enableProgressUpdates || !_isEnabled) return;

    await _ensureInitialized();

    final percentage = ((visited / total) * 100).round();
    final message =
        'Walk progress: $visited of $total art pieces visited. $percentage percent complete.';

    try {
      await _tts.speak(message);
      _logger.d('Announcing progress: $message');
    } catch (e) {
      _logger.e('Error announcing progress: $e');
    }
  }

  /// Announce milestone achievement
  Future<void> announceMilestone(String milestone, int points) async {
    if (!_settings.enableProgressUpdates || !_isEnabled) return;

    await _ensureInitialized();

    final message =
        'Milestone achieved: $milestone! You earned $points points.';

    try {
      await _tts.speak(message);
      _logger.d('Announcing milestone: $message');
    } catch (e) {
      _logger.e('Error announcing milestone: $e');
    }
  }

  /// Generate approach message for art piece
  String generateApproachMessage(PublicArtModel art, double distance) {
    final distanceText = distance < 100
        ? '${distance.round()} meters'
        : '${(distance / 1000).toStringAsFixed(1)} kilometers';

    return 'Approaching "${art.title}" in $distanceText.';
  }

  /// Generate arrival message for art piece
  String generateArrivalMessage(PublicArtModel art, int points) {
    final messages = [
      'You\'ve arrived at "${art.title}". You earned $points points!',
      'Great! You found "${art.title}". $points points added to your score.',
      'Excellent! "${art.title}" discovered. You earned $points points.',
    ];

    // Rotate through different messages for variety
    final index = DateTime.now().millisecond % messages.length;
    return messages[index];
  }

  /// Generate direction message from navigation step
  String generateDirectionMessage(NavigationStepModel step) {
    final instruction = step.instruction;

    if (step.distanceMeters > 0) {
      final distanceText = step.distanceMeters < 1000
          ? '${step.distanceMeters.round()} meters'
          : '${(step.distanceMeters / 1000).toStringAsFixed(1)} kilometers';

      return '$instruction in $distanceText.';
    }

    return instruction;
  }

  /// Stop current speech
  Future<void> stop() async {
    if (_isInitialized) {
      await _tts.stop();
    }
  }

  /// Pause current speech
  Future<void> pause() async {
    if (_isInitialized) {
      await _tts.pause();
    }
  }

  /// Enable/disable audio navigation
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }

  /// Check if audio is currently enabled
  bool get isEnabled => _isEnabled && _settings.enableVoiceDirections;

  /// Get available languages
  Future<List<String>> getAvailableLanguages() async {
    await _ensureInitialized();

    try {
      final languages = await _tts.getLanguages;
      return List<String>.from(languages as List? ?? []);
    } catch (e) {
      _logger.e('Error getting available languages: $e');
      return ['en-US']; // Fallback
    }
  }

  /// Get available voices for current language
  Future<List<Map<String, String>>> getAvailableVoices() async {
    await _ensureInitialized();

    try {
      final voices = await _tts.getVoices;
      return List<Map<String, String>>.from(voices as List? ?? []);
    } catch (e) {
      _logger.e('Error getting available voices: $e');
      return []; // Fallback
    }
  }

  /// Ensure TTS is initialized
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Generic speak method for custom messages
  Future<void> speak(String message) async {
    if (!_isEnabled) return;

    await _ensureInitialized();

    try {
      await _tts.speak(message);
      _logger.d('Speaking message: $message');
    } catch (e) {
      _logger.e('Error speaking message: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _tts.stop();
    _isInitialized = false;
  }
}
