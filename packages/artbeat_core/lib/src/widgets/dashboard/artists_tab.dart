import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/src/models/artist_profile_model.dart';

class ArtistsTab extends StatelessWidget {
  final bool isLoading;
  final List<ArtistProfileModel> artists;
  final Widget Function(ArtistProfileModel) buildArtistCard;

  const ArtistsTab({
    Key? key,
    required this.isLoading,
    required this.artists,
    required this.buildArtistCard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (artists.isEmpty) {
      return Center(child: Text('dashboard_no_artists_found'.tr()));
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
      itemCount: artists.length,
      itemBuilder: (context, index) {
        return buildArtistCard(artists[index]);
      },
    );
  }
}
