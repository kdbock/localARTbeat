import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DefensibilityEventsDashboard extends StatefulWidget {
  const DefensibilityEventsDashboard({super.key});

  @override
  State<DefensibilityEventsDashboard> createState() =>
      _DefensibilityEventsDashboardState();
}

class _DefensibilityEventsDashboardState
    extends State<DefensibilityEventsDashboard> {
  bool _isLoading = true;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _events = [];
  Map<String, int> _eventCounts = {};

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('defensibility_events')
          .orderBy('timestamp', descending: true)
          .limit(150)
          .get();

      final counts = <String, int>{};
      for (final doc in snapshot.docs) {
        final eventName = (doc.data()['event_name'] as String?) ?? 'unknown';
        counts[eventName] = (counts[eventName] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _events = snapshot.docs;
        _eventCounts = counts;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load defensibility events: $error'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Defensibility Events'),
      actions: [
        IconButton(icon: const Icon(Icons.refresh), onPressed: _loadEvents),
      ],
    ),
    body: _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _loadEvents,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(),
                const SizedBox(height: 16),
                const Text(
                  'Recent Events',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                ..._events.map(_buildEventTile),
              ],
            ),
          ),
  );

  Widget _buildSummaryCard() {
    final sorted = _eventCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: core.ArtbeatColors.primaryPurple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: core.ArtbeatColors.primaryPurple.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total events loaded: ${_events.length}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          ...sorted
              .take(8)
              .map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('${entry.key}: ${entry.value}'),
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildEventTile(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final eventName = data['event_name'] ?? 'unknown';
    final surface = data['surface'] ?? 'unknown';
    final creatorId = data['creator_id'] ?? '-';
    final contentId = data['content_id'] ?? '-';
    final campaignId = data['campaign_id'] ?? '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text('$eventName  •  $surface'),
        subtitle: Text(
          'creator: $creatorId\ncontent: $contentId\ncampaign: $campaignId',
        ),
        isThreeLine: true,
      ),
    );
  }
}
