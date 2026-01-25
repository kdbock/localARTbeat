import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/artist_profile_model.dart';
import '../utils/artist_logger.dart';

/// Service for managing offline data storage and synchronization for artist module
class OfflineDataProvider {
  static const String _keyArtistProfile = 'offline_artist_profile';
  static const String _keyEarnings = 'offline_earnings';
  static const String _keyArtworks = 'offline_artworks';
  static const String _keyEvents = 'offline_events';
  static const String _keyAnalytics = 'offline_analytics';
  static const String _keySubscription = 'offline_subscription';
  static const String _keyLastSync = 'offline_last_sync';

  static final OfflineDataProvider _instance = OfflineDataProvider._internal();
  factory OfflineDataProvider() => _instance;
  OfflineDataProvider._internal();

  /// Store artist profile data offline
  Future<void> storeArtistProfile(ArtistProfileModel profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = jsonEncode(profile.toMap());
      await prefs.setString(_keyArtistProfile, profileJson);
      await _updateLastSyncTime();
    } catch (e) {
      ArtistLogger.error('Error storing artist profile offline: $e');
    }
  }

  /// Retrieve artist profile data from offline storage
  Future<ArtistProfileModel?> getArtistProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_keyArtistProfile);
      if (profileJson != null) {
        final profileData = jsonDecode(profileJson) as Map<String, dynamic>;
        return ArtistProfileModel.fromMap(profileData);
      }
      return null;
    } catch (e) {
      ArtistLogger.error(
        'Error retrieving artist profile from offline storage: $e',
      );
      return null;
    }
  }

  /// Store generic data offline
  Future<void> storeData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = jsonEncode(data);
      await prefs.setString(key, dataJson);
      await _updateLastSyncTime();
    } catch (e) {
      ArtistLogger.error('Error storing data offline for key $key: $e');
    }
  }

  /// Retrieve generic data from offline storage
  Future<Map<String, dynamic>?> getData(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataJson = prefs.getString(key);
      if (dataJson != null) {
        return jsonDecode(dataJson) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      ArtistLogger.error(
        'Error retrieving data from offline storage for key $key: $e',
      );
      return null;
    }
  }

  /// Store earnings data offline
  Future<void> storeEarnings(Map<String, dynamic> earnings) async {
    await storeData(_keyEarnings, earnings);
  }

  /// Retrieve earnings data from offline storage
  Future<Map<String, dynamic>?> getEarnings() async {
    return getData(_keyEarnings);
  }

  /// Store artworks list offline
  Future<void> storeArtworks(List<Map<String, dynamic>> artworks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final artworksJson = jsonEncode(artworks);
      await prefs.setString(_keyArtworks, artworksJson);
      await _updateLastSyncTime();
    } catch (e) {
      ArtistLogger.error('Error storing artworks offline: $e');
    }
  }

  /// Retrieve artworks from offline storage
  Future<List<Map<String, dynamic>>> getArtworks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final artworksJson = prefs.getString(_keyArtworks);
      if (artworksJson != null) {
        final artworksList = jsonDecode(artworksJson) as List<dynamic>;
        return artworksList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      ArtistLogger.error('Error retrieving artworks from offline storage: $e');
      return [];
    }
  }

  /// Store events list offline
  Future<void> storeEvents(List<Map<String, dynamic>> events) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = jsonEncode(events);
      await prefs.setString(_keyEvents, eventsJson);
      await _updateLastSyncTime();
    } catch (e) {
      ArtistLogger.error('Error storing events offline: $e');
    }
  }

  /// Retrieve events from offline storage
  Future<List<Map<String, dynamic>>> getEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_keyEvents);
      if (eventsJson != null) {
        final eventsList = jsonDecode(eventsJson) as List<dynamic>;
        return eventsList.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      ArtistLogger.error('Error retrieving events from offline storage: $e');
      return [];
    }
  }

  /// Store subscription data offline
  Future<void> storeSubscription(Map<String, dynamic> subscription) async {
    await storeData(_keySubscription, subscription);
  }

  /// Retrieve subscription from offline storage
  Future<Map<String, dynamic>?> getSubscription() async {
    return getData(_keySubscription);
  }

  /// Store analytics data offline
  Future<void> storeAnalytics(Map<String, dynamic> analytics) async {
    await storeData(_keyAnalytics, analytics);
  }

  /// Retrieve analytics from offline storage
  Future<Map<String, dynamic>?> getAnalytics() async {
    return getData(_keyAnalytics);
  }

  /// Get last synchronization time
  Future<DateTime?> getLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final syncTimeString = prefs.getString(_keyLastSync);
      if (syncTimeString != null) {
        return DateTime.parse(syncTimeString);
      }
      return null;
    } catch (e) {
      ArtistLogger.error('Error getting last sync time: $e');
      return null;
    }
  }

  /// Check if data needs synchronization (older than specified duration)
  Future<bool> needsSynchronization({
    Duration maxAge = const Duration(hours: 1),
  }) async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final now = DateTime.now();
    return now.difference(lastSync) > maxAge;
  }

  /// Clear all offline data
  Future<void> clearOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyArtistProfile);
      await prefs.remove(_keyEarnings);
      await prefs.remove(_keyArtworks);
      await prefs.remove(_keyEvents);
      await prefs.remove(_keyAnalytics);
      await prefs.remove(_keySubscription);
      await prefs.remove(_keyLastSync);
    } catch (e) {
      ArtistLogger.error('Error clearing offline data: $e');
    }
  }

  /// Check if offline data is available
  Future<bool> hasOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyArtistProfile) ||
          prefs.containsKey(_keyEarnings) ||
          prefs.containsKey(_keyArtworks) ||
          prefs.containsKey(_keyEvents) ||
          prefs.containsKey(_keyAnalytics) ||
          prefs.containsKey(_keySubscription);
    } catch (e) {
      ArtistLogger.error('Error checking offline data availability: $e');
      return false;
    }
  }

  /// Get offline data status
  Future<Map<String, bool>> getOfflineDataStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return {
        'profile': prefs.containsKey(_keyArtistProfile),
        'earnings': prefs.containsKey(_keyEarnings),
        'artworks': prefs.containsKey(_keyArtworks),
        'events': prefs.containsKey(_keyEvents),
        'analytics': prefs.containsKey(_keyAnalytics),
        'subscription': prefs.containsKey(_keySubscription),
      };
    } catch (e) {
      ArtistLogger.error('Error getting offline data status: $e');
      return {
        'profile': false,
        'earnings': false,
        'artworks': false,
        'events': false,
        'analytics': false,
        'subscription': false,
      };
    }
  }

  /// Batch store multiple data types
  Future<void> batchStore({
    ArtistProfileModel? profile,
    Map<String, dynamic>? earnings,
    List<Map<String, dynamic>>? artworks,
    List<Map<String, dynamic>>? events,
    Map<String, dynamic>? analytics,
    Map<String, dynamic>? subscription,
  }) async {
    try {
      if (profile != null) await storeArtistProfile(profile);
      if (earnings != null) await storeEarnings(earnings);
      if (artworks != null) await storeArtworks(artworks);
      if (events != null) await storeEvents(events);
      if (analytics != null) await storeAnalytics(analytics);
      if (subscription != null) await storeSubscription(subscription);
    } catch (e) {
      ArtistLogger.error('Error in batch store operation: $e');
    }
  }

  /// Update last synchronization time
  Future<void> _updateLastSyncTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastSync, DateTime.now().toIso8601String());
    } catch (e) {
      ArtistLogger.error('Error updating last sync time: $e');
    }
  }
}
