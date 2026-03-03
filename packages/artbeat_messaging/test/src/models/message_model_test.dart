import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:artbeat_messaging/src/models/message_model.dart';

void main() {
  group('MessageModel', () {
    test('fromMap uses defaults and parses enum type', () {
      final now = DateTime.now();
      final model = MessageModel.fromMap({
        'id': 'm1',
        'senderId': 'u1',
        'content': 'Hello',
        'timestamp': Timestamp.fromDate(now),
        'type': MessageType.image.toString(),
      });

      expect(model.id, 'm1');
      expect(model.senderId, 'u1');
      expect(model.content, 'Hello');
      expect(model.type, MessageType.image);
      expect(model.isRead, isFalse);
    });

    test('fromFirestore prioritizes text key and read map', () async {
      final firestore = FakeFirebaseFirestore();
      await firestore.collection('messages').doc('m2').set({
        'senderId': 'u2',
        'text': 'From text field',
        'content': 'From content field',
        'timestamp': Timestamp.fromDate(DateTime.now()),
        'type': MessageType.text.toString(),
        'read': {'u1': false, 'u2': true},
      });

      final doc = await firestore.collection('messages').doc('m2').get();
      final model = MessageModel.fromFirestore(doc);

      expect(model.id, 'm2');
      expect(model.content, 'From text field');
      expect(model.isRead, isTrue);
    });

    test('toMap includes optional file metadata when provided', () {
      final model = MessageModel(
        id: 'm3',
        senderId: 'u3',
        content: 'image://abc',
        timestamp: DateTime.now(),
        type: MessageType.image,
        storagePath: '/chat/u3/file.jpg',
        uploaderId: 'u3',
        chatId: 'c1',
      );

      final map = model.toMap();

      expect(map['storagePath'], '/chat/u3/file.jpg');
      expect(map['uploaderId'], 'u3');
      expect(map['chatId'], 'c1');
    });
  });
}
