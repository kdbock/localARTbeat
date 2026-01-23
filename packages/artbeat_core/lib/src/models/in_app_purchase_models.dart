import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum for different types of in-app purchases
enum PurchaseType {
  consumable, // Ads, boosts - can be purchased multiple times
  nonConsumable, // One-time purchases like premium features
  subscription, // Recurring subscriptions
}

/// Enum for purchase categories
enum PurchaseCategory {
  ads, // Advertisement purchases
  boosts, // Boost purchases
  subscription, // Subscription purchases
  premium, // Premium features
}

/// Model for in-app purchase products
class InAppPurchaseProduct {
  final String id;
  final String title;
  final String description;
  final String price;
  final double priceAmountMicros;
  final String priceCurrencyCode;
  final PurchaseType type;
  final PurchaseCategory category;
  final Map<String, dynamic> metadata;

  InAppPurchaseProduct({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.priceAmountMicros,
    required this.priceCurrencyCode,
    required this.type,
    required this.category,
    this.metadata = const {},
  });

  factory InAppPurchaseProduct.fromJson(Map<String, dynamic> json) {
    return InAppPurchaseProduct(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      priceAmountMicros: (json['priceAmountMicros'] as num).toDouble(),
      priceCurrencyCode: json['priceCurrencyCode'] as String,
      type: PurchaseType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PurchaseType.consumable,
      ),
      category: PurchaseCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => PurchaseCategory.premium,
      ),
      metadata: Map<String, dynamic>.from(
        json['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'priceAmountMicros': priceAmountMicros,
      'priceCurrencyCode': priceCurrencyCode,
      'type': type.name,
      'category': category.name,
      'metadata': metadata,
    };
  }
}

/// Model for completed purchases
class CompletedPurchase {
  final String purchaseId;
  final String productId;
  final String userId;
  final DateTime purchaseDate;
  final String status;
  final PurchaseType type;
  final PurchaseCategory category;
  final double amount;
  final String currency;
  final String? transactionId;
  final String? originalTransactionId;
  final Map<String, dynamic> metadata;
  final DateTime? expiryDate; // For subscriptions

  CompletedPurchase({
    required this.purchaseId,
    required this.productId,
    required this.userId,
    required this.purchaseDate,
    required this.status,
    required this.type,
    required this.category,
    required this.amount,
    required this.currency,
    this.transactionId,
    this.originalTransactionId,
    this.metadata = const {},
    this.expiryDate,
  });

  factory CompletedPurchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CompletedPurchase(
      purchaseId: doc.id,
      productId: data['productId'] as String,
      userId: data['userId'] as String,
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      status: data['status'] as String,
      type: PurchaseType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => PurchaseType.consumable,
      ),
      category: PurchaseCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => PurchaseCategory.premium,
      ),
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      transactionId: data['transactionId'] as String?,
      originalTransactionId: data['originalTransactionId'] as String?,
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'status': status,
      'type': type.name,
      'category': category.name,
      'amount': amount,
      'currency': currency,
      if (transactionId != null) 'transactionId': transactionId,
      if (originalTransactionId != null)
        'originalTransactionId': originalTransactionId,
      'metadata': metadata,
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
    };
  }

  bool get isActive {
    if (type == PurchaseType.subscription && expiryDate != null) {
      return DateTime.now().isBefore(expiryDate!);
    }
    return status == 'completed';
  }

  bool get isExpired {
    if (type == PurchaseType.subscription && expiryDate != null) {
      return DateTime.now().isAfter(expiryDate!);
    }
    return false;
  }
}

/// Model for subscription details
class SubscriptionDetails {
  final String subscriptionId;
  final String productId;
  final String userId;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // active, cancelled, expired, pending
  final bool autoRenewing;
  final String? cancellationReason;
  final DateTime? nextBillingDate;
  final double price;
  final String currency;

  SubscriptionDetails({
    required this.subscriptionId,
    required this.productId,
    required this.userId,
    required this.startDate,
    this.endDate,
    required this.status,
    required this.autoRenewing,
    this.cancellationReason,
    this.nextBillingDate,
    required this.price,
    required this.currency,
  });

  factory SubscriptionDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SubscriptionDetails(
      subscriptionId: doc.id,
      productId: data['productId'] as String,
      userId: data['userId'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null
          ? (data['endDate'] as Timestamp).toDate()
          : null,
      status: data['status'] as String,
      autoRenewing: data['autoRenewing'] as bool? ?? true,
      cancellationReason: data['cancellationReason'] as String?,
      nextBillingDate: data['nextBillingDate'] != null
          ? (data['nextBillingDate'] as Timestamp).toDate()
          : null,
      price: (data['price'] as num).toDouble(),
      currency: data['currency'] as String,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'status': status,
      'autoRenewing': autoRenewing,
      if (cancellationReason != null) 'cancellationReason': cancellationReason,
      if (nextBillingDate != null)
        'nextBillingDate': Timestamp.fromDate(nextBillingDate!),
      'price': price,
      'currency': currency,
    };
  }

  bool get isActive =>
      status == 'active' &&
      (endDate == null || DateTime.now().isBefore(endDate!));
  bool get isExpired => endDate != null && DateTime.now().isAfter(endDate!);
  bool get isCancelled => status == 'cancelled';
}

/// Model for boost purchases using in-app purchases
class ArtistBoostPurchase {
  final String id;
  final String senderId;
  final String recipientId;
  final String productId;
  final double amount;
  final String currency;
  final String message;
  final DateTime purchaseDate;
  final String status;
  final String? transactionId;

  ArtistBoostPurchase({
    required this.id,
    required this.senderId,
    required this.recipientId,
    required this.productId,
    required this.amount,
    required this.currency,
    required this.message,
    required this.purchaseDate,
    required this.status,
    this.transactionId,
  });

  factory ArtistBoostPurchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ArtistBoostPurchase(
      id: doc.id,
      senderId: data['senderId'] as String,
      recipientId: data['recipientId'] as String,
      productId: data['productId'] as String,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      message: data['message'] as String? ?? '',
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      status: data['status'] as String,
      transactionId: data['transactionId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'recipientId': recipientId,
      'productId': productId,
      'amount': amount,
      'currency': currency,
      'message': message,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      'status': status,
      if (transactionId != null) 'transactionId': transactionId,
    };
  }
}

/// Model for ad purchases using in-app purchases
class InAppAdPurchase {
  final String id;
  final String userId;
  final String productId;
  final String adType; // banner, interstitial, video, etc.
  final int quantity; // Number of ad impressions/clicks purchased
  final double amount;
  final String currency;
  final DateTime purchaseDate;
  final DateTime? expiryDate;
  final String status;
  final String? transactionId;
  final Map<String, dynamic> metadata;

  InAppAdPurchase({
    required this.id,
    required this.userId,
    required this.productId,
    required this.adType,
    required this.quantity,
    required this.amount,
    required this.currency,
    required this.purchaseDate,
    this.expiryDate,
    required this.status,
    this.transactionId,
    this.metadata = const {},
  });

  factory InAppAdPurchase.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InAppAdPurchase(
      id: doc.id,
      userId: data['userId'] as String,
      productId: data['productId'] as String,
      adType: data['adType'] as String,
      quantity: data['quantity'] as int,
      amount: (data['amount'] as num).toDouble(),
      currency: data['currency'] as String,
      purchaseDate: (data['purchaseDate'] as Timestamp).toDate(),
      expiryDate: data['expiryDate'] != null
          ? (data['expiryDate'] as Timestamp).toDate()
          : null,
      status: data['status'] as String,
      transactionId: data['transactionId'] as String?,
      metadata: Map<String, dynamic>.from(
        data['metadata'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'productId': productId,
      'adType': adType,
      'quantity': quantity,
      'amount': amount,
      'currency': currency,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
      if (expiryDate != null) 'expiryDate': Timestamp.fromDate(expiryDate!),
      'status': status,
      if (transactionId != null) 'transactionId': transactionId,
      'metadata': metadata,
    };
  }

  bool get isActive {
    if (expiryDate != null) {
      return DateTime.now().isBefore(expiryDate!) && status == 'completed';
    }
    return status == 'completed';
  }

  bool get isExpired {
    if (expiryDate != null) {
      return DateTime.now().isAfter(expiryDate!);
    }
    return false;
  }
}
