import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chapter_partner.dart';
import '../services/chapter_partner_service.dart';
import '../utils/logger.dart';

class ChapterPartnerProvider with ChangeNotifier {
  final ChapterPartnerService _service = ChapterPartnerService();

  ChapterPartner? _currentChapter;
  List<ChapterPartner> _availableChapters = [];
  bool _isLoading = false;
  bool _isAutoDetecting = false;

  ChapterPartner? get currentChapter => _currentChapter;
  List<ChapterPartner> get availableChapters => _availableChapters;
  bool get isLoading => _isLoading;
  bool get isAutoDetecting => _isAutoDetecting;
  bool get isRegionalView => _currentChapter == null;

  String? get activeChapterId => _currentChapter?.id;

  /// Initialize provider, load available chapters and saved selection
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      _availableChapters = await _service.getActiveChapters();
      await _loadSavedChapter();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a chapter and save choice
  Future<void> selectChapter(ChapterPartner? chapter) async {
    _currentChapter = chapter;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (chapter == null) {
      await prefs.remove('selected_chapter_id');
    } else {
      await prefs.setString('selected_chapter_id', chapter.id);
    }
  }

  /// Switch back to regional view
  void switchToRegional() {
    selectChapter(null);
  }

  /// Load saved chapter from SharedPreferences
  Future<void> _loadSavedChapter() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('selected_chapter_id');

    if (savedId != null) {
      _currentChapter = _availableChapters.firstWhere(
        (c) => c.id == savedId,
        orElse: () => _availableChapters.isNotEmpty
            ? _availableChapters.first
            : _availableChapters[0], // fallback or null handling needed if list empty
      );
      // Re-validate if savedId exists in current available chapters
      final exists = _availableChapters.any((c) => c.id == savedId);
      if (!exists) {
        _currentChapter = null;
        await prefs.remove('selected_chapter_id');
      } else {
        _currentChapter = _availableChapters.firstWhere((c) => c.id == savedId);
      }
    }
  }

  /// Auto-detect nearby chapter based on GPS
  Future<void> autoDetectChapter() async {
    if (_isAutoDetecting) return;

    _isAutoDetecting = true;
    notifyListeners();

    try {
      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final position = await Geolocator.getCurrentPosition();

        // This is a placeholder logic for auto-detection.
        // In a real implementation, we would query chapters by coordinates or use GeoFirestore.
        // For now, we'll just log and maybe suggest the first available one if any.
        AppLogger.info(
          'Auto-detecting chapter at: ${position.latitude}, ${position.longitude}',
        );

        // TODO: Implement actual proximity check once chapter locations are added to the model
      }
    } catch (e) {
      AppLogger.error('Error auto-detecting chapter: $e');
    } finally {
      _isAutoDetecting = false;
      notifyListeners();
    }
  }
}
