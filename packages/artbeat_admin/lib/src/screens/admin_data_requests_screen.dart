import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDataRequestsScreen extends StatefulWidget {
  const AdminDataRequestsScreen({super.key});

  @override
  State<AdminDataRequestsScreen> createState() =>
      _AdminDataRequestsScreenState();
}

class _AdminDataRequestsScreenState extends State<AdminDataRequestsScreen> {
  final _auth = FirebaseAuth.instance;
  final _functions = FirebaseFunctions.instance;

  String _statusFilter = 'all';

  Future<void> _updateStatus(
    DocumentReference<Map<String, dynamic>> ref,
    String newStatus,
    Map<String, dynamic> currentData, {
    String? reviewNotes,
  }) async {
    final reviewerId = _auth.currentUser?.uid;
    final updates = <String, dynamic>{
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerId,
    };

    if (reviewNotes != null && reviewNotes.trim().isNotEmpty) {
      updates['reviewNotes'] = reviewNotes.trim();
    }

    if (newStatus == 'in_review') {
      updates['acknowledgedAt'] = FieldValue.serverTimestamp();
    }
    if (newStatus == 'fulfilled') {
      updates['fulfilledAt'] = FieldValue.serverTimestamp();
      updates['acknowledgedAt'] =
          updates['acknowledgedAt'] ?? FieldValue.serverTimestamp();
    }
    if (newStatus == 'denied') {
      updates['deniedAt'] = FieldValue.serverTimestamp();
      updates['acknowledgedAt'] =
          updates['acknowledgedAt'] ?? FieldValue.serverTimestamp();
    }

    final requestType =
        (currentData['requestType'] ?? currentData['type'] ?? '').toString();
    final userId = (currentData['userId'] ?? '').toString();
    if (newStatus == 'fulfilled' && requestType == 'deletion') {
      final callable = _functions.httpsCallable('processDataDeletionRequest');
      await callable.call<Map<String, dynamic>>({
        'requestId': ref.id,
        'userId': userId,
        'reviewNotes': reviewNotes,
      });
      return;
    }

    await ref.update(updates);
  }

  Future<void> _showActionSheet(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> ref,
    Map<String, dynamic> data,
  ) async {
    final notesController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: notesController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Review notes',
                  hintText: 'Optional notes for audit trail',
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.hourglass_top_rounded),
                title: const Text('Set Pending'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _applyStatusChange(
                    ref,
                    'pending',
                    data,
                    reviewNotes: notesController.text,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_outlined),
                title: const Text('Set In Review'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _applyStatusChange(
                    ref,
                    'in_review',
                    data,
                    reviewNotes: notesController.text,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.check_circle_outline_rounded),
                title: const Text('Set Fulfilled'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _applyStatusChange(
                    ref,
                    'fulfilled',
                    data,
                    reviewNotes: notesController.text,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Set Denied'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _applyStatusChange(
                    ref,
                    'denied',
                    data,
                    reviewNotes: notesController.text,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    notesController.dispose();
  }

  Future<void> _applyStatusChange(
    DocumentReference<Map<String, dynamic>> ref,
    String status,
    Map<String, dynamic> data, {
    String? reviewNotes,
  }) async {
    try {
      await _updateStatus(ref, status, data, reviewNotes: reviewNotes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request set to $status.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  bool _isSlaOverdue(Map<String, dynamic> data) {
    final status = (data['status'] ?? 'pending').toString();
    final now = DateTime.now().toUtc();

    final acknowledgementDueAt = data['slaAcknowledgementDueAt'];
    if (status == 'pending' &&
        acknowledgementDueAt is Timestamp &&
        now.isAfter(acknowledgementDueAt.toDate().toUtc())) {
      return true;
    }

    final completionDueAt = data['slaCompletionDueAt'];
    if ((status == 'pending' || status == 'in_review') &&
        completionDueAt is Timestamp &&
        now.isAfter(completionDueAt.toDate().toUtc())) {
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    final baseQuery = FirebaseFirestore.instance
        .collection('dataRequests')
        .orderBy('requestedAt', descending: true)
        .limit(200);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Rights Requests'),
        actions: [
          PopupMenuButton<String>(
            initialValue: _statusFilter,
            onSelected: (value) => setState(() => _statusFilter = value),
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'all', child: Text('All statuses')),
              PopupMenuItem(value: 'pending', child: Text('Pending')),
              PopupMenuItem(value: 'in_review', child: Text('In Review')),
              PopupMenuItem(value: 'fulfilled', child: Text('Fulfilled')),
              PopupMenuItem(value: 'denied', child: Text('Denied')),
            ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: baseQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = (snapshot.data?.docs ?? []).where((doc) {
            if (_statusFilter == 'all') return true;
            return (doc.data()['status'] ?? '').toString() == _statusFilter;
          }).toList();

          if (docs.isEmpty) {
            return const Center(
                child: Text('No matching data-rights requests.'));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final status = (data['status'] ?? 'pending').toString();
              final requestType =
                  (data['requestType'] ?? data['type'] ?? 'unknown').toString();
              final userId = (data['userId'] ?? '').toString();
              final requestedAt = data['requestedAt'];
              final acknowledgedAt = data['acknowledgedAt'];
              final fulfilledAt = data['fulfilledAt'];
              final isOverdue = _isSlaOverdue(data);
              final ackDueAt = data['slaAcknowledgementDueAt'];
              final completionDueAt = data['slaCompletionDueAt'];
              final requestedLabel = requestedAt is Timestamp
                  ? requestedAt.toDate().toLocal().toString()
                  : 'Pending timestamp';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(
                    '${requestType.toUpperCase()} • $status${isOverdue ? ' • SLA OVERDUE' : ''}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    'User: $userId\nRequested: $requestedLabel\nAck due: ${ackDueAt is Timestamp ? ackDueAt.toDate().toLocal() : '-'}\nCompletion due: ${completionDueAt is Timestamp ? completionDueAt.toDate().toLocal() : '-'}\nAck: ${acknowledgedAt is Timestamp ? acknowledgedAt.toDate().toLocal() : '-'}\nDone: ${fulfilledAt is Timestamp ? fulfilledAt.toDate().toLocal() : '-'}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () =>
                        _showActionSheet(context, doc.reference, data),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
