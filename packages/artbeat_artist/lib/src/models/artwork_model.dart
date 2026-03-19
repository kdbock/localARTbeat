import 'package:artbeat_core/artbeat_core.dart' show ArtworkContentType;

class WritingMetadata {
  final String? genre;
  final int? wordCount;

  const WritingMetadata({this.genre, this.wordCount});

  factory WritingMetadata.fromMap(Map<String, dynamic> map) {
    return WritingMetadata(
      genre: map['genre']?.toString(),
      wordCount: map['wordCount'] is int
          ? map['wordCount'] as int
          : (map['wordCount'] is num
                ? (map['wordCount'] as num).toInt()
                : int.tryParse(map['wordCount']?.toString() ?? '')),
    );
  }

  Map<String, dynamic> toMap() {
    return {'genre': genre, 'wordCount': wordCount};
  }
}

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
  final ArtworkContentType contentType;
  final WritingMetadata? writingMetadata;
  final bool auctionEnabled;
  final DateTime? auctionEnd;
  final double? startingPrice;
  final double? reservePrice;
  final double? currentHighestBid;

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
    this.contentType = ArtworkContentType.visual,
    this.writingMetadata,
    this.auctionEnabled = false,
    this.auctionEnd,
    this.startingPrice,
    this.reservePrice,
    this.currentHighestBid,
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
      contentType: _contentTypeFromRaw(map['contentType']),
      writingMetadata:
          map['writingMetadata'] is Map<String, dynamic>
              ? WritingMetadata.fromMap(map['writingMetadata'] as Map<String, dynamic>)
              : null,
      auctionEnabled: map['auctionEnabled'] is bool
          ? map['auctionEnabled'] as bool
          : false,
      auctionEnd: map['auctionEnd'] is DateTime
          ? map['auctionEnd'] as DateTime
          : map['auctionEnd'] is String
              ? DateTime.tryParse(map['auctionEnd'] as String)
              : map['auctionEnd'] != null
                  ? (map['auctionEnd'] as dynamic).toDate() as DateTime?
                  : null,
      startingPrice: map['startingPrice'] is num
          ? (map['startingPrice'] as num).toDouble()
          : null,
      reservePrice: map['reservePrice'] is num
          ? (map['reservePrice'] as num).toDouble()
          : null,
      currentHighestBid: map['currentHighestBid'] is num
          ? (map['currentHighestBid'] as num).toDouble()
          : null,
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
      'contentType': contentType.name,
      'writingMetadata': writingMetadata?.toMap(),
      'auctionEnabled': auctionEnabled,
      'auctionEnd': auctionEnd,
      'startingPrice': startingPrice,
      'reservePrice': reservePrice,
      'currentHighestBid': currentHighestBid,
    };
  }

  String get getId => id;
  String get getImageUrl => imageUrl;
  bool get getIsForSale => isForSale;
  double? get getPrice => price;
  String get getTitle => title;
  String get getMedium => medium;

  static ArtworkContentType _contentTypeFromRaw(Object? raw) {
    final value = raw?.toString().trim().toLowerCase();
    switch (value) {
      case 'written':
        return ArtworkContentType.written;
      case 'audio':
        return ArtworkContentType.audio;
      case 'comic':
        return ArtworkContentType.comic;
      case 'visual':
      default:
        return ArtworkContentType.visual;
    }
  }
}
