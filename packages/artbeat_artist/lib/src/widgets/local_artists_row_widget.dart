import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';

/// Widget that displays a horizontal list of local artists
class LocalArtistsRowWidget extends StatelessWidget {
  final String zipCode;
  final VoidCallback? onSeeAllPressed;

  const LocalArtistsRowWidget({
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
              const Text('art_walk_local_artists'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onSeeAllPressed,
                child: const Text('art_walk_see_all'.tr()),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150, // Increased height to accommodate badges
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('artistProfiles')
                .where('location', isEqualTo: zipCode)
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
                        Text('art_walk_error_loading_artists'.tr(),
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
                          Icons.brush_outlined,
                          size: 40,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No local artists found in ${zipCode}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final artists = snapshot.data!.docs.map((doc) {
                return ArtistProfileModel.fromFirestore(doc);
              }).toList();

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: artists.length,
                itemBuilder: (context, index) {
                  final artist = artists[index];
                  return Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 16.0 : 8.0,
                      right: index == artists.length - 1 ? 16.0 : 8.0,
                    ),
                    child: SizedBox(
                      width: 120,
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  border: artist.isVerified
                                      ? Border.all(
                                          color: Colors.blue,
                                          width: 2,
                                        )
                                      : artist.isFeatured
                                          ? Border.all(
                                              color: Colors.amber,
                                              width: 2,
                                            )
                                          : null,
                                  borderRadius: BorderRadius.circular(12),
                                  image: (artist.profileImageUrl != null &&
                                          artist.profileImageUrl!.isNotEmpty &&
                                          (artist.profileImageUrl!
                                                  .startsWith('http://') ||
                                              artist.profileImageUrl!
                                                  .startsWith('https://')) &&
                                          artist.profileImageUrl !=
                                              'placeholder_headshot_url')
                                      ? DecorationImage(
                                          image: NetworkImage(
                                              artist.profileImageUrl!),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: !(artist.profileImageUrl != null &&
                                        artist.profileImageUrl!.isNotEmpty &&
                                        (artist.profileImageUrl!
                                                .startsWith('http://') ||
                                            artist.profileImageUrl!
                                                .startsWith('https://')) &&
                                        artist.profileImageUrl !=
                                            'placeholder_headshot_url')
                                    ? const Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey,
                                      )
                                    : null,
                              ),
                              if (artist.isVerified || artist.isFeatured)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: artist.isVerified
                                          ? Colors.blue
                                          : Colors.amber,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      artist.isVerified
                                          ? Icons.verified
                                          : Icons.star,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artist.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
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
