// Create the missing artwork_model.dart file.
class ArtworkModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String medium;
  final List<String> styles;
  final double? price;
  final bool isForSale;
  final String? dimensions;
  final int? yearCreated;
  final String artistProfileId;
  final String userId;

  ArtworkModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.medium,
    required this.styles,
    this.price,
    required this.isForSale,
    this.dimensions,
    this.yearCreated,
    required this.artistProfileId,
    required this.userId,
  });

  factory ArtworkModel.fromMap(Map<String, dynamic> map) {
    return ArtworkModel(
      id: (map['id'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      medium: (map['medium'] ?? '').toString(),
      styles: map['styles'] is List
          ? (map['styles'] as List).map((e) => e.toString()).toList()
          : <String>[],
      price: map['price'] is num ? (map['price'] as num).toDouble() : null,
      isForSale: map['isForSale'] is bool ? map['isForSale'] as bool : false,
      dimensions: map['dimensions'] != null
          ? map['dimensions'].toString()
          : null,
      yearCreated: map['yearCreated'] is int
          ? map['yearCreated'] as int
          : (map['yearCreated'] != null
                ? int.tryParse(map['yearCreated'].toString())
                : null),
      artistProfileId: (map['artistProfileId'] ?? '').toString(),
      userId: (map['userId'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'medium': medium,
      'styles': styles,
      'price': price,
      'isForSale': isForSale,
      'dimensions': dimensions,
      'yearCreated': yearCreated,
      'artistProfileId': artistProfileId,
      'userId': userId,
    };
  }

  String get getId => id;
  String get getImageUrl => imageUrl;
  bool get getIsForSale => isForSale;
  double? get getPrice => price;
  String get getTitle => title;
  String get getMedium => medium;
}
