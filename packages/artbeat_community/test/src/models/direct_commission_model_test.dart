import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_community/models/direct_commission_model.dart';

void main() {
  group('DirectCommissionModel', () {
    test(
      'fromFirestore defaults to digital/pending on unknown enum values',
      () async {
        final firestore = FakeFirebaseFirestore();
        await firestore.collection('direct_commissions').doc('d1').set({
          'clientId': 'c1',
          'clientName': 'Client',
          'artistId': 'a1',
          'artistName': 'Artist',
          'type': 'unknown_type',
          'title': 'Commission',
          'description': 'Test',
          'status': 'unknown_status',
          'requestedAt': Timestamp.now(),
          'specs': <String, dynamic>{},
        });

        final doc = await firestore
            .collection('direct_commissions')
            .doc('d1')
            .get();
        final model = DirectCommissionModel.fromFirestore(doc);

        expect(model.type, CommissionType.digital);
        expect(model.status, CommissionStatus.pending);
      },
    );

    test('toFirestore serializes nested milestones/files/messages', () {
      final model = DirectCommissionModel(
        id: 'd2',
        clientId: 'c1',
        clientName: 'Client',
        artistId: 'a1',
        artistName: 'Artist',
        type: CommissionType.portrait,
        title: 'Portrait',
        description: 'Portrait request',
        status: CommissionStatus.quoted,
        totalPrice: 300,
        depositAmount: 100,
        remainingAmount: 200,
        requestedAt: DateTime.now(),
        milestones: [
          CommissionMilestone(
            id: 'm1',
            title: 'Sketch',
            description: 'Initial sketch',
            amount: 100,
            dueDate: DateTime.now(),
            status: MilestoneStatus.pending,
          ),
        ],
        files: [
          CommissionFile(
            id: 'f1',
            name: 'ref.png',
            url: 'https://example.com/ref.png',
            type: 'reference',
            sizeBytes: 1024,
            uploadedAt: DateTime.now(),
            uploadedBy: 'c1',
          ),
        ],
        messages: [
          CommissionMessage(
            id: 'msg1',
            senderId: 'c1',
            senderName: 'Client',
            message: 'Looking forward to it',
            timestamp: DateTime.now(),
            attachments: const [],
          ),
        ],
        specs: CommissionSpecs.fromMap(const {}),
        metadata: const {'priority': 'high'},
      );

      final map = model.toFirestore();
      expect(map['type'], CommissionType.portrait.name);
      expect(map['status'], CommissionStatus.quoted.name);
      expect((map['milestones'] as List).length, 1);
      expect((map['files'] as List).length, 1);
      expect((map['messages'] as List).length, 1);
    });
  });
}
