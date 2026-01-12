/// Enum for different ticket categories
enum TicketCategory {
  free,
  paid,
  vip;

  String get displayName {
    switch (this) {
      case TicketCategory.free:
        return 'Free';
      case TicketCategory.paid:
        return 'Paid';
      case TicketCategory.vip:
        return 'VIP';
    }
  }

  static TicketCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'free':
        return TicketCategory.free;
      case 'paid':
        return TicketCategory.paid;
      case 'vip':
        return TicketCategory.vip;
      default:
        return TicketCategory.free;
    }
  }
}

/// Model representing a ticket type for an event
class TicketType {
  final String id;
  final String
  name; // e.g., "General Admission", "VIP Access", "Student Discount"
  final String description;
  final TicketCategory category;
  final double price; // 0.0 for free tickets
  final int quantity; // total available
  final int? quantitySold; // tracks sold tickets
  final DateTime? saleStartDate; // when tickets go on sale
  final DateTime? saleEndDate; // when ticket sales end
  final List<String> benefits; // VIP benefits, inclusions, etc.
  final Map<String, dynamic>? metadata; // additional ticket-specific data

  const TicketType({
    required this.id,
    required this.name,
    this.description = '',
    required this.category,
    required this.price,
    required this.quantity,
    this.quantitySold,
    this.saleStartDate,
    this.saleEndDate,
    this.benefits = const [],
    this.metadata,
  });

  /// Factory constructor for free tickets
  factory TicketType.free({
    required String id,
    required String name,
    String description = '',
    required int quantity,
    int? quantitySold,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
    List<String> benefits = const [],
    Map<String, dynamic>? metadata,
  }) {
    return TicketType(
      id: id,
      name: name,
      description: description,
      category: TicketCategory.free,
      price: 0.0,
      quantity: quantity,
      quantitySold: quantitySold,
      saleStartDate: saleStartDate,
      saleEndDate: saleEndDate,
      benefits: benefits,
      metadata: metadata,
    );
  }

  /// Factory constructor for paid tickets
  factory TicketType.paid({
    required String id,
    required String name,
    String description = '',
    required double price,
    required int quantity,
    int? quantitySold,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
    List<String> benefits = const [],
    Map<String, dynamic>? metadata,
  }) {
    return TicketType(
      id: id,
      name: name,
      description: description,
      category: TicketCategory.paid,
      price: price,
      quantity: quantity,
      quantitySold: quantitySold,
      saleStartDate: saleStartDate,
      saleEndDate: saleEndDate,
      benefits: benefits,
      metadata: metadata,
    );
  }

  /// Factory constructor for VIP tickets
  factory TicketType.vip({
    required String id,
    required String name,
    String description = '',
    required double price,
    required int quantity,
    int? quantitySold,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
    List<String> benefits = const [],
    Map<String, dynamic>? metadata,
  }) {
    return TicketType(
      id: id,
      name: name,
      description: description,
      category: TicketCategory.vip,
      price: price,
      quantity: quantity,
      quantitySold: quantitySold,
      saleStartDate: saleStartDate,
      saleEndDate: saleEndDate,
      benefits: benefits,
      metadata: metadata,
    );
  }

  /// Create TicketType from Map (for Firestore)
  factory TicketType.fromMap(Map<String, dynamic> map) {
    return TicketType(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      category: TicketCategory.fromString(
        map['category']?.toString() ?? 'free',
      ),
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      quantity: map['quantity'] as int? ?? 0,
      quantitySold: map['quantitySold'] as int?,
      saleStartDate: map['saleStartDate'] != null
          ? DateTime.parse(map['saleStartDate'].toString())
          : null,
      saleEndDate: map['saleEndDate'] != null
          ? DateTime.parse(map['saleEndDate'].toString())
          : null,
      benefits: _parseStringList(map['benefits']),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert TicketType to Map (for Firestore)
  Map<String, dynamic> toMap() {
    final map = {
      'id': id,
      'name': name,
      'description': description,
      'category': category.name,
      'price': price,
      'quantity': quantity,
      'quantitySold': quantitySold,
      'saleStartDate': saleStartDate?.toIso8601String(),
      'saleEndDate': saleEndDate?.toIso8601String(),
      'benefits': benefits,
      'metadata': metadata,
    };
    // Remove null values to prevent iOS crash in cloud_firestore plugin
    map.removeWhere((key, value) => value == null);
    return map;
  }

  /// Create a copy of this TicketType with the given fields replaced
  TicketType copyWith({
    String? id,
    String? name,
    String? description,
    TicketCategory? category,
    double? price,
    int? quantity,
    int? quantitySold,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
    List<String>? benefits,
    Map<String, dynamic>? metadata,
  }) {
    return TicketType(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      quantitySold: quantitySold ?? this.quantitySold,
      saleStartDate: saleStartDate ?? this.saleStartDate,
      saleEndDate: saleEndDate ?? this.saleEndDate,
      benefits: benefits ?? this.benefits,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Check if tickets are available for purchase
  bool get isAvailable {
    final now = DateTime.now();
    final withinSalePeriod =
        (saleStartDate == null || now.isAfter(saleStartDate!)) &&
        (saleEndDate == null || now.isBefore(saleEndDate!));
    final hasStock = remainingQuantity > 0;
    return withinSalePeriod && hasStock;
  }

  /// Get remaining ticket quantity
  int get remainingQuantity => quantity - (quantitySold ?? 0);

  /// Check if this ticket type is sold out
  bool get isSoldOut => remainingQuantity <= 0;

  /// Check if this is a free ticket
  bool get isFree => category == TicketCategory.free || price == 0.0;

  /// Format price for display
  String get formattedPrice {
    if (isFree) return 'Free';
    return '\$${price.toStringAsFixed(2)}';
  }

  // Helper method to parse string lists
  static List<String> _parseStringList(dynamic data) {
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return [];
  }

  @override
  String toString() {
    return 'TicketType{id: $id, name: $name, category: $category, price: $price, quantity: $quantity}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketType && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
