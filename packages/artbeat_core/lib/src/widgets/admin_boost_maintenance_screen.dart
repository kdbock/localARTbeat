import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class AdminBoostMaintenanceScreen extends StatefulWidget {
  const AdminBoostMaintenanceScreen({super.key});

  @override
  State<AdminBoostMaintenanceScreen> createState() =>
      _AdminBoostMaintenanceScreenState();
}

class _AdminBoostMaintenanceScreenState
    extends State<AdminBoostMaintenanceScreen> {
  static const String _functionsBaseUrl =
      'https://us-central1-wordnerd-artbeat.cloudfunctions.net';

  final TextEditingController _migrateLimitController = TextEditingController(
    text: '200',
  );
  final TextEditingController _backfillLimitController = TextEditingController(
    text: '200',
  );

  bool _isMigrating = false;
  bool _isBackfilling = false;
  bool _isRotating = false;
  String? _migrateResult;
  String? _backfillResult;
  String? _rotateResult;

  @override
  void dispose() {
    _migrateLimitController.dispose();
    _backfillLimitController.dispose();
    super.dispose();
  }

  Future<void> _runMigration({required bool dryRun}) async {
    setState(() {
      _isMigrating = true;
      _migrateResult = null;
    });

    try {
      final result = await _callFunction('migrateGiftsToBoosts', {
        'limit': _migrateLimitController.text.trim(),
        'dryRun': dryRun.toString(),
      });

      setState(() {
        _migrateResult = result;
      });
    } catch (e) {
      setState(() {
        _migrateResult = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isMigrating = false;
        });
      }
    }
  }

  Future<void> _runBackfill() async {
    setState(() {
      _isBackfilling = true;
      _backfillResult = null;
    });

    try {
      final result = await _callFunction('backfillBoostMomentum', {
        'limit': _backfillLimitController.text.trim(),
      });

      setState(() {
        _backfillResult = result;
      });
    } catch (e) {
      setState(() {
        _backfillResult = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBackfilling = false;
        });
      }
    }
  }

  Future<void> _runRotationNow() async {
    setState(() {
      _isRotating = true;
      _rotateResult = null;
    });

    try {
      final result = await _callFunction('rotateKioskLaneNow', {});
      setState(() {
        _rotateResult = result;
      });
    } catch (e) {
      setState(() {
        _rotateResult = 'Error: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isRotating = false;
        });
      }
    }
  }

  Future<String> _callFunction(
    String endpoint,
    Map<String, String> queryParams,
  ) async {
    final query = Map<String, String>.from(queryParams)
      ..removeWhere((key, value) => value.isEmpty);
    final uri = Uri.parse(
      '$_functionsBaseUrl/$endpoint',
    ).replace(queryParameters: query);

    final response = await http.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('HTTP ${response.statusCode}: ${response.body}');
    }

    final body = response.body.trim();
    if (body.isEmpty) {
      return 'Success (empty response)';
    }

    try {
      final decoded = jsonDecode(body);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return body;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Boost Admin Maintenance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(
            'Gift → Boost Migration',
            'Run the legacy gift migration to create boosts.',
          ),
          const SizedBox(height: 12),
          _buildMigrationCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Backfill Boost Momentum',
            'Recompute momentum for historical boosts without notifications.',
          ),
          const SizedBox(height: 12),
          _buildBackfillCard(),
          const SizedBox(height: 24),
          _buildSectionHeader(
            'Kiosk Lane Ops',
            'Monitor current rotation status and recent lane rotations.',
          ),
          const SizedBox(height: 12),
          _buildKioskOpsCard(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }

  Widget _buildMigrationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _migrateLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit (max 1000)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMigrating
                        ? null
                        : () => _runMigration(dryRun: true),
                    icon: const Icon(Icons.visibility),
                    label: const Text('Run Dry Run'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isMigrating
                        ? null
                        : () => _runMigration(dryRun: false),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Migration'),
                  ),
                ),
              ],
            ),
            if (_isMigrating) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_migrateResult != null) ...[
              const SizedBox(height: 12),
              _buildResultBox(_migrateResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBackfillCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _backfillLimitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Limit (max 1000)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isBackfilling ? null : _runBackfill,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Run Backfill'),
                  ),
                ),
              ],
            ),
            if (_isBackfilling) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_backfillResult != null) ...[
              const SizedBox(height: 12),
              _buildResultBox(_backfillResult!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildKioskOpsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kiosk_lane_state')
                  .doc('current')
                  .snapshots(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final activeArtistId = data?['activeArtistId'];
                final totalActive = data?['totalActive'] ?? 0;
                final index = data?['index'] ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Active Artist: ${activeArtistId ?? 'None'}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text('Rotation Index: $index'),
                    const SizedBox(height: 4),
                    Text('Total Active Lane Artists: $totalActive'),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isRotating ? null : _runRotationNow,
              icon: const Icon(Icons.refresh),
              label: const Text('Rotate Now'),
            ),
            if (_isRotating) ...[
              const SizedBox(height: 10),
              const LinearProgressIndicator(),
            ],
            if (_rotateResult != null) ...[
              const SizedBox(height: 12),
              _buildResultBox(_rotateResult!),
            ],
            const SizedBox(height: 16),
            const Text(
              'Recent Rotations',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('kiosk_lane_metrics')
                  .orderBy('rotationAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('No rotation logs yet.');
                }

                return Column(
                  children: snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final active = data['activeArtistId'] ?? 'Unknown';
                    final total = data['totalActive'] ?? 0;
                    final reason = data['reason'] as String? ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_rounded),
                      title: Text('Active: $active'),
                      subtitle: Text(
                        'Total: $total${reason.isNotEmpty ? ' • $reason' : ''}',
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultBox(String result) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        result,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
    );
  }
}
