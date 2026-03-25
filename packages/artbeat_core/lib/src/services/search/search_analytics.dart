import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

class SearchAnalytics {
  static final SearchAnalytics _instance = SearchAnalytics._internal();
  factory SearchAnalytics() => _instance;
  SearchAnalytics._internal();

  FirebaseAnalytics? _analyticsInstance;
  FirebaseFirestore? _firestoreInstance;

  FirebaseAnalytics get _analytics =>
      _analyticsInstance ??= FirebaseAnalytics.instance;
  FirebaseFirestore get _firestore =>
      _firestoreInstance ??= FirebaseFirestore.instance;

  Future<void> trackSearch({
    required String query,
    required Map<String, dynamic> filters,
    required int resultCount,
    String? userId,
  }) async {
    // Track in Firebase Analytics
    await _analytics.logSearch(
      searchTerm: query,
      parameters: {
        'filters': filters.toString(),
        'resultCount': resultCount,
        'userId': userId ?? 'anonymous',
      },
    );

    // Store in Firestore for detailed analysis
    await _firestore.collection('searchAnalytics').add({
      'query': query,
      'filters': filters,
      'resultCount': resultCount,
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> getPopularSearches({
    int limit = 10,
    Duration timeWindow = const Duration(days: 7),
  }) async {
    final startDate = Timestamp.fromDate(DateTime.now().subtract(timeWindow));

    final snapshot = await _firestore
        .collection('searchAnalytics')
        .where('timestamp', isGreaterThan: startDate)
        .get();

    final Map<String, int> searchCounts = {};
    for (var doc in snapshot.docs) {
      final query = doc.data()['query'] as String;
      searchCounts[query] = (searchCounts[query] ?? 0) + 1;
    }

    final sortedSearches = searchCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedSearches.take(limit));
  }
}
