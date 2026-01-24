import 'dart:ui';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'art_market_screen.dart';

class ArtbeatStoreScreen extends StatefulWidget {
  const ArtbeatStoreScreen({super.key});

  @override
  State<ArtbeatStoreScreen> createState() => _ArtbeatStoreScreenState();
}

class _ArtbeatStoreScreenState extends State<ArtbeatStoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
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
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 12),
                _buildKioskLanePreview(),
                const SizedBox(height: 12),
                Expanded(child: _buildKioskShell()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  color: Colors.white.withValues(alpha: 0.08),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.store_mall_directory_outlined,
                        color: Color(0xFFFB7185), size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'store_kiosk_label'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.6,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Text(
                'store_swipe_to_browse'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white60,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'store_title'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            'store_subtitle'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'store_kiosk_tagline'.tr(),
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKioskShell() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.12)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                _buildAccessibleTabBar(),
                const SizedBox(height: 12),
                Expanded(child: _buildTabContent()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKioskLanePreview() {
    return SizedBox(
      height: 96,
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
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'dashboard_kiosk_lane_empty'.tr(),
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }

          final artists = snapshot.data!.docs
              .map((doc) => ArtistProfileModel.fromFirestore(doc))
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFF97316),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'dashboard_kiosk_lane_title'.tr(),
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: artists.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) =>
                      _buildKioskLaneChip(context, artists[index]),
                ),
              ),
            ],
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
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            BoostPulseRing(
              enabled: artist.hasActiveBoost || artist.hasKioskLane,
              ringPadding: 3,
              ringWidth: 2,
              child: CircleAvatar(
                radius: 18,
                backgroundImage: ImageUrlValidator.safeNetworkImage(
                  artist.profileImageUrl,
                ),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                child: !ImageUrlValidator.isValidImageUrl(
                  artist.profileImageUrl,
                )
                    ? Text(
                        artist.displayName.isNotEmpty
                            ? artist.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                artist.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessibleTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: const LinearGradient(
            colors: [Color(0xFFF97316), Color(0xFF22D3EE)],
          ),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.spaceGrotesk(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        tabs: [
          Tab(text: 'store_tab_boost'.tr(), icon: const Icon(Icons.rocket_launch, size: 20)),
          Tab(text: 'store_tab_buy_now'.tr(), icon: const Icon(Icons.shopping_bag, size: 20)),
          Tab(text: 'store_tab_auctions'.tr(), icon: const Icon(Icons.gavel, size: 20)),
          Tab(text: 'store_tab_subs'.tr(), icon: const Icon(Icons.workspace_premium, size: 20)),
          Tab(text: 'store_tab_ads'.tr(), icon: const Icon(Icons.ads_click, size: 20)),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: const [
        ArtistBoostsScreen(showAppBar: false),
        ArtMarketScreen(isAuction: false),
        ArtMarketScreen(isAuction: true),
        SubscriptionsScreen(showAppBar: false),
        AdsScreen(),
      ],
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
