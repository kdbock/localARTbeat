import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class ArtworkTab extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> artworks;
  final Widget Function(dynamic) buildArtworkCard;

  const ArtworkTab({
    Key? key,
    required this.isLoading,
    required this.artworks,
    required this.buildArtworkCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (artworks.isEmpty) {
      return Center(child: Text('dashboard_no_artwork_found'.tr()));
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        return buildArtworkCard(artworks[index]);
      },
    );
  }
}
