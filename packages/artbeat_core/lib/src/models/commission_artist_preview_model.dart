import 'package:cloud_firestore/cloud_firestore.dart';

class CommissionArtistPreviewModel {
  const CommissionArtistPreviewModel({
    required this.artistId,
    required this.availableTypes,
    required this.basePrice,
    required this.portfolioImages,
  });

  final String artistId;
  final List<String> availableTypes;
  final double basePrice;
  final List<String> portfolioImages;

  factory CommissionArtistPreviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    return CommissionArtistPreviewModel(
      artistId: doc.id,
      availableTypes: List<String>.from(
        data['availableTypes'] as List<dynamic>? ?? const [],
      ),
      basePrice: (data['basePrice'] as num?)?.toDouble() ?? 0.0,
      portfolioImages: List<String>.from(
        data['portfolioImages'] as List<dynamic>? ?? const [],
      ),
    );
  }
}
