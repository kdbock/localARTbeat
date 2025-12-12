import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:easy_localization/easy_localization.dart';

/// Widget for displaying local artwork in a horizontal scrollable row
class LocalArtworkRowWidget extends StatelessWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const LocalArtworkRowWidget({
    super.key,
    required this.zipCode,
    this.onSeeAllPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Local Artwork',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAllPressed,
                child: Text('art_walk_see_all'.tr()),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 250, // Increased height for price and badge
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('artwork')
                .where('location', isEqualTo: zipCode)
                .orderBy('createdAt', descending: true)
                .limit(10)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 36,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Error loading artwork',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.art_track,
                          size: 40,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'No artwork found in your area',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final artworks = snapshot.data!.docs
                  .map((doc) => ArtworkModel.fromFirestore(doc))
                  .toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: artworks.length,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemBuilder: (context, index) {
                  final artwork = artworks[index];
                  return GestureDetector(
                    onTap: () => Navigator.pushNamed(
                        context, '/artist/artwork-detail',
                        arguments: {'artworkId': artwork.id}),
                    child: Container(
                      width: 170, // Increased width for better display
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Artwork image with sold badge if applicable
                            Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(12.0)),
                                  child: SecureNetworkImage(
                                    imageUrl: artwork.imageUrl,
                                    width: 170,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    enableThumbnailFallback:
                                        true, // Enable fallback for artwork
                                    errorWidget: Container(
                                      width: 170,
                                      height: 150,
                                      color: Colors.grey.shade300,
                                      child:
                                          const Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                                if (artwork.isForSale == false)
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'SOLD',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    artwork.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  FutureBuilder<DocumentSnapshot>(
                                    future: FirebaseFirestore.instance
                                        .collection('artistProfiles')
                                        .doc(artwork.artistProfileId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      String artistName = 'Unknown Artist';
                                      if (snapshot.hasData &&
                                          snapshot.data != null) {
                                        final artistData = snapshot.data!.data()
                                            as Map<String, dynamic>?;
                                        if (artistData != null &&
                                            artistData
                                                .containsKey('displayName')) {
                                          artistName = artistData['displayName']
                                              as String;
                                        }
                                      }
                                      return Text(
                                        artistName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade700,
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    artwork.price != null
                                        ? '\$${artwork.price!.toStringAsFixed(2)}'
                                        : 'Not for sale',
                                    style: TextStyle(
                                      color: Theme.of(context).primaryColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
