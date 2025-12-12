import 'package:cloud_firestore/cloud_firestore.dart';
import 'local_ad_duration.dart';

class LocalAdPurchase {
  final String id;
  final String userId;
  final String iapTransactionId;
  final LocalAdDuration duration;
  final DateTime purchasedAt;
  final double price;

  LocalAdPurchase({
    required this.id,
    required this.userId,
    required this.iapTransactionId,
    required this.duration,
    required this.purchasedAt,
    required this.price,
  });

  factory LocalAdPurchase.fromMap(Map<String, dynamic> map, String id) {
    return LocalAdPurchase(
      id: id,
      userId: (map['userId'] ?? '') as String,
      iapTransactionId: (map['iapTransactionId'] ?? '') as String,
      duration: LocalAdDurationExtension.fromIndex(
        (map['duration'] ?? 0) as int,
      ),
      purchasedAt: ((map['purchasedAt']) as Timestamp).toDate(),
      price: ((map['price'] ?? 0.0) as num).toDouble(),
    );
  }

  factory LocalAdPurchase.fromSnapshot(DocumentSnapshot snapshot) {
    return LocalAdPurchase.fromMap(
      snapshot.data() as Map<String, dynamic>,
      snapshot.id,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'iapTransactionId': iapTransactionId,
      'duration': duration.index,
      'purchasedAt': Timestamp.fromDate(purchasedAt),
      'price': price,
    };
  }
}
