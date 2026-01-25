import 'dart:ui';

import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_community/artbeat_community.dart'
    show CommissionArtistsBrowser;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtbeatStoreScreen extends StatefulWidget {
  const ArtbeatStoreScreen({super.key});

  @override
  State<ArtbeatStoreScreen> createState() => _ArtbeatStoreScreenState();
}

class _ArtbeatStoreScreenState extends State<ArtbeatStoreScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          _buildWorldBackground(),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildSliverAppBar(),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _buildImpulseBuyRow(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'store_tab_auctions'.tr(),
                        Icons.gavel_rounded,
                        const Color(0xFFF97316),
                        onTap: () => _showAllMarket(true),
                      ),
                      _buildAuctionsPreview(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'store_tab_buy_now'.tr(),
                        Icons.shopping_bag_rounded,
                        const Color(0xFF34D399),
                        onTap: () => _showAllMarket(false),
                      ),
                      _buildArtMarketPreview(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Artists Available For Commission',
                        Icons.palette_rounded,
                        const Color(0xFFFBBF24),
                      ),
                      _buildCommissionArtistsPreview(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'store_tab_subs'.tr(),
                        Icons.workspace_premium_rounded,
                        const Color(0xFFA855F7),
                      ),
                      _buildSubscriptionsPreview(),
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        'Local Ads',
                        Icons.ads_click_rounded,
                        const Color(0xFF22D3EE),
                        subtitle:
                            'Keep local eyes on local ads with Local ARTbeat',
                        onTap: () => _showAds(),
                      ),
                      _buildAdsPreview(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      leading: const SizedBox.shrink(),
      elevation: 0,
      pinned: true,
      expandedHeight: 60,
      flexibleSpace: FlexibleSpaceBar(
        background: Center(child: _buildKioskLanePreview()),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color color, {
    String? subtitle,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white70,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 12),
            _buildGlassButton(
              'store_view_all'.tr(),
              onTap,
              color: color,
              small: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGlassButton(
    String label,
    VoidCallback onTap, {
    Color color = Colors.white,
    bool small = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(small ? 12 : 16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: small ? 12 : 20,
              vertical: small ? 6 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(small ? 12 : 16),
              border: Border.all(color: color.withValues(alpha: 0.3)),
              color: color.withValues(alpha: 0.1),
            ),
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: small ? 12 : 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImpulseBuyRow() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildImpulseItem(
            'Give Boost',
            'Upgrades for Artists',
            Icons.rocket_launch_rounded,
            const Color(0xFFF97316),
            () => _showBoosts(),
          ),
          _buildImpulseItem(
            'Local Ads',
            'Keep Business Local',
            Icons.ads_click_rounded,
            const Color(0xFF22D3EE),
            () => _showAds(),
          ),
          _buildImpulseItem(
            'Subscribe',
            'Share Your Art',
            Icons.workspace_premium_rounded,
            const Color(0xFFA855F7),
            () => _showArtistOnboarding(),
          ),
          _buildImpulseItem(
            'Commission',
            'Art Your Way',
            Icons.palette_rounded,
            const Color(0xFFFBBF24),
            () => _showCommissions(),
          ),
        ],
      ),
    );
  }

  Widget _buildImpulseItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuctionsPreview() {
    return SizedBox(
      height: 200,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artwork')
            .where('isPublic', isEqualTo: true)
            .where('isAuction', isEqualTo: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            // Fallback to auctionEnabled if isAuction is not yet used in DB
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('artwork')
                  .where('isPublic', isEqualTo: true)
                  .where('auctionEnabled', isEqualTo: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snap2) {
                if (!snap2.hasData || snap2.data!.docs.isEmpty) {
                  return _buildEmptySection('store_empty_auctions'.tr());
                }
                final artworks = snap2.data!.docs
                    .map((doc) => ArtworkModel.fromFirestore(doc))
                    .toList();
                return _buildMarketList(artworks);
              },
            );
          }
          final artworks = snapshot.data!.docs
              .map((doc) => ArtworkModel.fromFirestore(doc))
              .toList();
          return _buildMarketList(artworks);
        },
      ),
    );
  }

  Widget _buildMarketList(List<ArtworkModel> artworks) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      scrollDirection: Axis.horizontal,
      itemCount: artworks.length,
      separatorBuilder: (_, __) => const SizedBox(width: 16),
      itemBuilder: (context, index) => _buildMarketCard(artworks[index]),
    );
  }

  Widget _buildArtMarketPreview() {
    return SizedBox(
      height: 240,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artwork')
            .where('isPublic', isEqualTo: true)
            .where('isForSale', isEqualTo: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptySection('store_empty_sale'.tr());
          }
          final artworks = snapshot.data!.docs
              .map((doc) => ArtworkModel.fromFirestore(doc))
              .toList();
          return _buildMarketList(artworks);
        },
      ),
    );
  }

  Widget _buildMarketCard(ArtworkModel artwork) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.artworkDetail,
        arguments: {'artworkId': artwork.id},
      ),
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white.withValues(alpha: 0.05),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: SecureNetworkImage(
                  imageUrl: artwork.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      artwork.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      artwork.auctionEnabled
                          ? '\$${(artwork.currentHighestBid ?? artwork.startingPrice ?? 0).toStringAsFixed(0)}'
                          : '\$${(artwork.price ?? 0).toStringAsFixed(0)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: artwork.auctionEnabled
                            ? const Color(0xFF22D3EE)
                            : const Color(0xFF34D399),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionsPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => _showAllSubscriptions(),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: [
                const Color(0xFFA855F7).withValues(alpha: 0.2),
                const Color(0xFFA855F7).withValues(alpha: 0.05),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFA855F7).withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xFFA855F7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'store_artist_cta_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'store_artist_cta_subtitle'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white54),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdsPreview() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: AdsScreen(isPreview: true),
    );
  }

  Widget _buildCommissionArtistsPreview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: const CommissionArtistsBrowser(showHeader: false),
      ),
    );
  }

  Widget _buildEmptySection(String text) {
    return Center(
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: Colors.white38,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAllMarket(bool isAuction) {
    Navigator.pushNamed(
      context,
      isAuction ? AppRoutes.artworkTrending : AppRoutes.artworkBrowse,
      arguments: {'isAuction': isAuction},
    );
  }

  void _showAllSubscriptions() {
    Navigator.pushNamed(context, AppRoutes.subscriptions);
  }

  void _showAds() {
    Navigator.pushNamed(context, AppRoutes.ads);
  }

  void _showBoosts() {
    Navigator.pushNamed(context, AppRoutes.boosts);
  }

  void _showCommissions() {
    Navigator.pushNamed(context, AppRoutes.commissionHub);
  }

  void _showArtistOnboarding() {
    Navigator.pushNamed(context, AppRoutes.artistOnboardingIntroduction);
  }

  Widget _buildKioskLanePreview() {
    return SizedBox(
      height: 60,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('artistProfiles')
            .where(
              'kioskLaneUntil',
              isGreaterThan: Timestamp.fromDate(DateTime.now()),
            )
            .orderBy('kioskLaneUntil', descending: true)
            .limit(10)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const SizedBox();
          }

          final artists = snapshot.data!.docs
              .map((doc) => ArtistProfileModel.fromFirestore(doc))
              .toList();

          return ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) =>
                _buildKioskLaneChip(context, artists[index]),
          );
        },
      ),
    );
  }

  Widget _buildKioskLaneChip(BuildContext context, ArtistProfileModel artist) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        '/artist/public-profile',
        arguments: {'artistId': artist.userId},
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 12,
              backgroundImage: ImageUrlValidator.safeNetworkImage(
                artist.profileImageUrl,
              ),
              backgroundColor: Colors.white.withValues(alpha: 0.15),
            ),
            const SizedBox(width: 8),
            Text(
              artist.displayName,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorldBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF03050F), Color(0xFF09122B), Color(0xFF021B17)],
          ),
        ),
        child: Stack(
          children: [
            _buildGlow(const Offset(-140, -80), Colors.purpleAccent),
            _buildGlow(const Offset(120, 220), Colors.cyanAccent),
            _buildGlow(const Offset(-20, 340), Colors.pinkAccent),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.1,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlow(Offset offset, Color color) {
    return Positioned(
      left: offset.dx < 0 ? null : offset.dx,
      right: offset.dx < 0 ? -offset.dx : null,
      top: offset.dy,
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.35),
              blurRadius: 110,
              spreadRadius: 16,
            ),
          ],
        ),
      ),
    );
  }
}
