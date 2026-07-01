import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/capture_model.dart';
import '../utils/logger.dart';

class CaptureEditSuggestionService {
  CaptureEditSuggestionService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> submitSuggestion({
    required CaptureModel capture,
    String? suggestedTitle,
    String? suggestedArtistName,
    String? suggestedDescription,
    String? suggestedLocationName,
    String? suggestedArtType,
    required String note,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('Sign in is required to suggest capture edits.');
    }

    final proposedChanges = <String, String>{};
    void addChange(String key, String? original, String? proposed) {
      final normalized = proposed?.trim();
      if (normalized == null || normalized.isEmpty) return;
      if (normalized == (original ?? '').trim()) return;
      proposedChanges[key] = normalized;
    }

    addChange('title', capture.title, suggestedTitle);
    addChange('artistName', capture.artistName, suggestedArtistName);
    addChange('description', capture.description, suggestedDescription);
    addChange('locationName', capture.locationName, suggestedLocationName);
    addChange('artType', capture.artType, suggestedArtType);

    if (proposedChanges.isEmpty && note.trim().isEmpty) {
      throw ArgumentError('Add a correction or a note before submitting.');
    }

    final doc = await _firestore.collection('captureEditSuggestions').add({
      'captureId': capture.id,
      'captureOwnerId': capture.userId,
      'captureTitle': capture.title ?? 'Untitled',
      'captureImageUrl': capture.imageUrl,
      'captureLocationName': capture.locationName,
      'captureLatitude': capture.location?.latitude,
      'captureLongitude': capture.location?.longitude,
      'submittedBy': user.uid,
      'submittedByName': user.displayName ?? user.email ?? 'Local explorer',
      'submittedByEmail': user.email,
      'status': 'pending',
      'note': note.trim(),
      'originalValues': {
        'title': capture.title,
        'artistName': capture.artistName,
        'description': capture.description,
        'locationName': capture.locationName,
        'artType': capture.artType,
      },
      'proposedChanges': proposedChanges,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    AppLogger.info('Capture edit suggestion submitted: ${doc.id}');
    return doc.id;
  }
}
