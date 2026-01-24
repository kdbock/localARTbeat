import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtMarketScreen extends StatefulWidget {
  final bool isAuction;
  
  const ArtMarketScreen({
    super.key,
    required this.isAuction,
  });

  @override
  State<ArtMarketScreen> createState() => _ArtMarketScreenState();
}

class _ArtMarketScreenState extends State<ArtMarketScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _artistSearchController = TextEditingController();
  String _artistQuery = '';

  @override
  void dispose() {
    _artistSearchController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _getArtworkStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final docs = snapshot.data?.docs ?? [];
        final filteredDocs = _filterByArtistQuery(docs);
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isAuction ? Icons.gavel_rounded : Icons.shopping_bag_rounded,
                  size: 64,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.isAuction ? 'No active auctions' : 'No items for sale',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _buildArtistSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.local_fire_department_outlined,
                    size: 16,
                    color: Colors.white.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.isAuction ? 'Live bidding' : 'Ready to collect',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${filteredDocs.length} items',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: filteredDocs.isEmpty
                  ? _buildNoArtistResults()
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.75,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final artwork = ArtworkModel.fromFirestore(doc);
                        final artistName = _extractArtistName(doc);
                        return _buildArtworkCard(
                          artwork,
                          artistName: artistName,
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Stream<QuerySnapshot> _getArtworkStream() {
    Query query = _firestore.collection('artwork')
        .where('isPublic', isEqualTo: true);
    
    if (widget.isAuction) {
      query = query.where('auctionEnabled', isEqualTo: true);
    } else {
      query = query.where('isForSale', isEqualTo: true);
    }
    
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  List<QueryDocumentSnapshot> _filterByArtistQuery(
    List<QueryDocumentSnapshot> docs,
  ) {
    final query = _artistQuery.trim().toLowerCase();
    if (query.isEmpty) return docs;

    return docs.where((doc) {
      final artistName = _extractArtistName(doc).toLowerCase();
      return artistName.contains(query);
    }).toList();
  }

  String _extractArtistName(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final candidate = data['artistName'] ??
        data['artistDisplayName'] ??
        data['displayName'] ??
        data['creatorName'] ??
        data['artist'] ??
        data['artistHandle'];
    if (candidate is String && candidate.trim().isNotEmpty) {
      return candidate.trim();
    }
    return 'Unknown Artist';
  }

  Widget _buildArtistSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: Colors.black.withValues(alpha: 0.35),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search, color: Colors.white70, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _artistSearchController,
              onChanged: (value) {
                setState(() {
                  _artistQuery = value;
                });
              },
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              cursorColor: const Color(0xFF22D3EE),
              decoration: InputDecoration(
                hintText: 'Type an artist name to find their work',
                hintStyle: GoogleFonts.spaceGrotesk(
                  color: Colors.white54,
                  fontSize: 13,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          if (_artistQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 18),
              onPressed: () {
                _artistSearchController.clear();
                setState(() {
                  _artistQuery = '';
                });
              },
            ),
        ],
      ),
    );
  }

  Widget _buildNoArtistResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_search_outlined,
            size: 60,
            color: Colors.white.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 14),
          Text(
            'No artists match that search yet',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try another name or browse the full collection.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtworkCard(ArtworkModel artwork, {required String artistName}) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          AppRoutes.artworkDetail,
          arguments: artwork.id,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: SecureNetworkImage(
                  imageUrl: artwork.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    artwork.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    artistName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white60,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (widget.isAuction) ...[
                    Text(
                      'Current Bid',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        color: Colors.white60,
                      ),
                    ),
                    Text(
                      '\$${(artwork.currentHighestBid ?? artwork.startingPrice ?? 0).toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF22D3EE),
                      ),
                    ),
                  ] else ...[
                    Text(
                      '\$${(artwork.price ?? 0).toStringAsFixed(0)}',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
