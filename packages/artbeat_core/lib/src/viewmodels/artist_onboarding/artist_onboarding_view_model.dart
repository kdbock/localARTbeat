import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../models/artist_onboarding/artist_onboarding_data.dart';
import '../../storage/enhanced_storage_service.dart';
import '../../utils/logger.dart';

/// ViewModel managing artist onboarding state and persistence
///
/// Features:
/// - Auto-save every 2 seconds after changes
/// - Draft persistence to local storage
/// - Progress tracking
/// - Screen navigation logic
class ArtistOnboardingViewModel extends ChangeNotifier {
  static const String _storageKey = 'artist_onboarding_draft';
  static const Duration _autoSaveDelay = Duration(seconds: 2);

  ArtistOnboardingData _data = ArtistOnboardingData.initial();
  Timer? _autoSaveTimer;
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  ArtistOnboardingData get data => _data;
  int get currentStep => _data.currentStep;
  double get completionPercentage => _data.completionPercentage;
  bool get isComplete => _data.isComplete;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isSaving => _isSaving;

  /// Initialize and load saved draft if exists
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        _data = ArtistOnboardingData.fromJson(json);
        AppLogger.info('Loaded onboarding draft: ${_data.toString()}');
      } else {
        _data = ArtistOnboardingData.initial();
        AppLogger.info('Starting fresh onboarding');
      }

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to load onboarding draft',
        error: e,
        stackTrace: stackTrace,
      );
      // Continue with fresh data if load fails
      _data = ArtistOnboardingData.initial();
      notifyListeners();
    }
  }

  /// Save draft to local storage
  Future<void> saveDraft() async {
    if (_isSaving) return;

    try {
      _isSaving = true;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_data.toJson());
      await prefs.setString(_storageKey, jsonString);

      _hasUnsavedChanges = false;
      _isSaving = false;

      AppLogger.info('Saved onboarding draft: step ${_data.currentStep}');
      notifyListeners();
    } catch (e, stackTrace) {
      _isSaving = false;
      AppLogger.error(
        'Failed to save onboarding draft',
        error: e,
        stackTrace: stackTrace,
      );
      notifyListeners();
    }
  }

  /// Clear saved draft (used after successful completion)
  Future<void> clearDraft() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      AppLogger.info('Cleared onboarding draft');
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to clear onboarding draft',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Schedule auto-save after changes
  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _hasUnsavedChanges = true;

    _autoSaveTimer = Timer(_autoSaveDelay, () {
      if (_hasUnsavedChanges) {
        saveDraft();
      }
    });

    notifyListeners();
  }

  /// Update current step and auto-save
  void setCurrentStep(int step) {
    if (step < 0 || step > 7) return;

    _data = _data.copyWith(currentStep: step);
    _scheduleAutoSave();
  }

  /// Navigate to next step
  void nextStep() {
    if (_data.currentStep < 7) {
      setCurrentStep(_data.currentStep + 1);
    }
  }

  /// Navigate to previous step
  void previousStep() {
    if (_data.currentStep > 0) {
      setCurrentStep(_data.currentStep - 1);
    }
  }

  // Screen 2: Artist Introduction
  void updateArtistIntroduction(String introduction) {
    _data = _data.copyWith(artistIntroduction: introduction);
    _scheduleAutoSave();
  }

  void updateArtistType(String type) {
    _data = _data.copyWith(artistType: type);
    _scheduleAutoSave();
  }

  // Screen 3: Artist Story
  void updateStoryOrigin(String origin) {
    _data = _data.copyWith(storyOrigin: origin);
    _scheduleAutoSave();
  }

  void updateStoryInspiration(String inspiration) {
    _data = _data.copyWith(storyInspiration: inspiration);
    _scheduleAutoSave();
  }

  void updateStoryMessage(String message) {
    _data = _data.copyWith(storyMessage: message);
    _scheduleAutoSave();
  }

  void updateProfilePhoto({String? url, String? localPath}) {
    _data = _data.copyWith(
      profilePhotoUrl: url,
      profilePhotoLocalPath: localPath,
    );
    _scheduleAutoSave();
  }

  // Screen 4: Artwork Management
  String addArtwork({String? localImagePath}) {
    final id = const Uuid().v4();
    final artwork = ArtworkDraft.initial(
      id: id,
      localImagePath: localImagePath,
    );

    final updatedArtworks = List<ArtworkDraft>.from(_data.artworks)
      ..add(artwork);

    _data = _data.copyWith(artworks: updatedArtworks);
    _scheduleAutoSave();

    return id;
  }

  void updateArtwork(String id, ArtworkDraft updatedArtwork) {
    final artworks = _data.artworks.map((a) {
      return a.id == id ? updatedArtwork : a;
    }).toList();

    _data = _data.copyWith(artworks: artworks);
    _scheduleAutoSave();
  }

  void removeArtwork(String id) {
    final artworks = _data.artworks.where((a) => a.id != id).toList();
    _data = _data.copyWith(artworks: artworks);
    _scheduleAutoSave();
  }

  // Screen 5: Featured Artwork Selection
  void setFeaturedArtworks(List<String> artworkIds) {
    if (artworkIds.length > 3) {
      AppLogger.warning('Cannot feature more than 3 artworks');
      return;
    }

    _data = _data.copyWith(featuredArtworkIds: artworkIds);
    _scheduleAutoSave();
  }

  void toggleFeaturedArtwork(String artworkId) {
    final featured = List<String>.from(_data.featuredArtworkIds);

    if (featured.contains(artworkId)) {
      featured.remove(artworkId);
    } else if (featured.length < 3) {
      featured.add(artworkId);
    } else {
      AppLogger.warning('Maximum 3 featured artworks allowed');
      return;
    }

    _data = _data.copyWith(featuredArtworkIds: featured);
    _scheduleAutoSave();
  }

  // Screen 6: Benefits Tracking
  void trackTierViewed(String tier) {
    final viewed = List<String>.from(_data.viewedTiers);
    if (!viewed.contains(tier)) {
      viewed.add(tier);
      _data = _data.copyWith(
        viewedTiers: viewed,
        benefitsViewedAt: DateTime.now(),
      );
      _scheduleAutoSave();
    }
  }

  // Screen 7: Tier Selection
  void selectTier(String tier) {
    _data = _data.copyWith(selectedTier: tier, tierSelectedAt: DateTime.now());
    _scheduleAutoSave();
  }

  /// Upload profile photo and return URL
  Future<String?> _uploadProfilePhoto() async {
    if (_data.profilePhotoLocalPath == null) {
      return _data.profilePhotoUrl; // Return existing URL if already uploaded
    }

    try {
      final file = File(_data.profilePhotoLocalPath!);
      if (!await file.exists()) {
        AppLogger.warning(
          'Profile photo file not found: ${_data.profilePhotoLocalPath}',
        );
        return null;
      }

      AppLogger.info('Uploading profile photo...');
      final storage = EnhancedStorageService();
      final result = await storage.uploadImageWithOptimization(
        imageFile: file,
        category: 'artist_profiles',
        generateThumbnail: true,
        maxWidth: 800,
        maxHeight: 800,
        quality: 90,
      );

      return result['imageUrl'];
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to upload profile photo',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Upload artwork images and return updated artworks with URLs
  Future<List<ArtworkDraft>> _uploadArtworkImages() async {
    final updatedArtworks = <ArtworkDraft>[];
    final storage = EnhancedStorageService();

    for (var artwork in _data.artworks) {
      // Skip if already uploaded
      if (artwork.imageUrl != null && artwork.imageUrl!.isNotEmpty) {
        updatedArtworks.add(artwork);
        continue;
      }

      // Check if local file exists
      if (artwork.localImagePath == null) {
        AppLogger.warning('Artwork ${artwork.id} has no image');
        updatedArtworks.add(artwork);
        continue;
      }

      try {
        final file = File(artwork.localImagePath!);
        if (!await file.exists()) {
          AppLogger.warning(
            'Artwork image file not found: ${artwork.localImagePath}',
          );
          updatedArtworks.add(artwork);
          continue;
        }

        AppLogger.info('Uploading artwork ${artwork.id}...');
        final result = await storage.uploadImageWithOptimization(
          imageFile: file,
          category: 'artworks',
          generateThumbnail: true,
          maxWidth: 2048,
          maxHeight: 2048,
          quality: 90,
        );

        final updatedArtwork = artwork.copyWith(imageUrl: result['imageUrl']);
        updatedArtworks.add(updatedArtwork);
        AppLogger.info('Artwork ${artwork.id} uploaded successfully');
      } catch (e, stackTrace) {
        AppLogger.error(
          'Failed to upload artwork ${artwork.id}',
          error: e,
          stackTrace: stackTrace,
        );
        updatedArtworks.add(artwork);
      }
    }

    return updatedArtworks;
  }

  /// Save onboarding data to Firestore
  Future<void> _saveToFirestore({
    required String userId,
    required String? profilePhotoUrl,
    required List<ArtworkDraft> artworks,
  }) async {
    final firestore = FirebaseFirestore.instance;

    // Ensure user is marked as artist for artwork creation rules
    await firestore.collection('users').doc(userId).set({
      'userType': 'artist',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Prepare artist profile data
    final profileData = {
      'userId': userId,
      'displayName': _data.artistIntroduction ?? 'Artist',
      'bio': _data.storyMessage ?? '',
      'artistType': _data.artistType,
      'origin': _data.storyOrigin,
      'inspiration': _data.storyInspiration,
      'profileImageUrl': profilePhotoUrl ?? '',
      'isPortfolioPublic': true,
      'isFeatured': false,
      'selectedTier': _data.selectedTier ?? 'FREE',
      'tierSelectedAt': _data.tierSelectedAt ?? DateTime.now(),
      'onboardingCompletedAt': DateTime.now(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Save/update artist profile
    await firestore
        .collection('artistProfiles')
        .doc(userId)
        .set(profileData, SetOptions(merge: true));

    // Save artworks
    final batch = firestore.batch();
    for (var artwork in artworks) {
      if (artwork.imageUrl != null && artwork.imageUrl!.isNotEmpty) {
        final artworkData = {
          'artistId': userId,
          'title': artwork.title ?? 'Untitled',
          'contentType': 'visual',
          'yearCreated': artwork.yearCreated,
          'medium': artwork.medium ?? 'Mixed Media',
          'isForSale': artwork.isForSale,
          'price': artwork.price,
          'currency': artwork.currency,
          'dimensions': artwork.dimensions,
          'availability': artwork.availability,
          'shipping': artwork.shipping,
          'imageUrl': artwork.imageUrl,
          'isFeatured': _data.featuredArtworkIds.contains(artwork.id),
          'featuredOrder': _data.featuredArtworkIds.indexOf(artwork.id),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        final docRef = firestore.collection('artwork').doc();
        batch.set(docRef, artworkData);
      }
    }
    await batch.commit();

    AppLogger.info('Artist profile and artworks saved to Firestore');
  }

  /// Mark onboarding as complete - uploads images and saves to Firestore
  Future<void> completeOnboarding() async {
    try {
      AppLogger.info('Starting onboarding completion process...');

      // Get current user
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Upload profile photo
      AppLogger.info('Step 1/3: Uploading profile photo...');
      final profilePhotoUrl = await _uploadProfilePhoto();

      // Upload artwork images
      AppLogger.info(
        'Step 2/3: Uploading ${_data.artworks.length} artworks...',
      );
      final updatedArtworks = await _uploadArtworkImages();

      // Update local data with uploaded URLs
      _data = _data.copyWith(
        profilePhotoUrl: profilePhotoUrl,
        artworks: updatedArtworks,
      );

      // Save to Firestore
      AppLogger.info('Step 3/3: Saving to Firestore...');
      await _saveToFirestore(
        userId: user.uid,
        profilePhotoUrl: profilePhotoUrl,
        artworks: updatedArtworks,
      );

      // Mark as complete
      _data = _data.copyWith(isComplete: true, currentStep: 7);
      await saveDraft();

      AppLogger.info(
        '✅ Onboarding completed successfully: tier=${_data.selectedTier}, artworks=${_data.artworks.length}',
      );

      notifyListeners();
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to complete onboarding',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Validate current screen data
  bool validateCurrentScreen() {
    switch (_data.currentStep) {
      case 0: // Welcome - no validation needed
        return true;
      case 1: // Artist Introduction
        return _data.artistIntroduction?.isNotEmpty ?? false;
      case 2: // Artist Story - at least one field or allow skip
        return true; // Optional screen
      case 3: // Artwork Upload - at least one artwork
        return _data.artworks.isNotEmpty;
      case 4: // Featured Selection
        return _data.featuredArtworkIds.isNotEmpty ||
            _data.artworks.length <= 3;
      case 5: // Benefits - just tracking, no validation
        return true;
      case 6: // Tier Selection
        return _data.selectedTier != null;
      default:
        return true;
    }
  }

  /// Check if can proceed to next screen
  bool canProceedToNext() {
    return validateCurrentScreen();
  }

  /// Reset onboarding (for testing or start over)
  Future<void> reset() async {
    await clearDraft();
    _data = ArtistOnboardingData.initial();
    _hasUnsavedChanges = false;
    notifyListeners();
    AppLogger.info('Onboarding reset');
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }
}
