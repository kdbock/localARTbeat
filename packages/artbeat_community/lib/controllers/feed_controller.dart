import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' show AppLogger;
import '../models/artwork_model.dart';
import '../services/community_artwork_read_service.dart';

class FeedController extends ChangeNotifier {
  final CommunityArtworkReadService _artworkService;

  FeedController(this._artworkService);

  List<ArtworkModel> _feedItems = [];
  List<ArtworkModel> get feedItems => _feedItems;

  Future<void> fetchFeed(String userId) async {
    try {
      _feedItems = await _artworkService.getArtworkByArtistProfileId(userId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Error fetching feed: $e');
    }
  }

  Future<void> refreshFeed(String userId) async {
    await fetchFeed(userId);
  }
}
