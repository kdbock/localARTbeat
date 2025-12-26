import 'dart:async';
import 'dart:ui';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/in_app_gift_service.dart';

class GiftsScreen extends StatefulWidget {
  final bool showAppBar;
  const GiftsScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<GiftsScreen> createState() => _GiftsScreenState();
}

class _GiftsScreenState extends State<GiftsScreen> {
  final UserService _userService = UserService();

  List<UserModel> _artists = [];
  UserModel? _selectedArtist;
  bool _isLoadingArtists = true;
  String _searchQuery = '';
  StreamSubscription<PurchaseEvent>? _purchaseSubscription;

  @override
  void initState() {
    super.initState();
    _initializePurchases();
    _loadArtists();
  }

  Future<void> _initializePurchases() async {
    final setup = InAppPurchaseSetup();
    await setup.initialize();
    _purchaseSubscription = setup.purchaseManager.purchaseEventStream.listen(
      (event) {
        if (event.type == PurchaseEventType.completed) {
          _handlePurchaseCompleted(event.purchase!);
        } else if (event.type == PurchaseEventType.error) {
          _handlePurchaseError(event.error!);
        } else if (event.type == PurchaseEventType.cancelled) {
          _handlePurchaseCancelled();
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          print('Purchase event error: $error');
        }
      },
    );
  }

  Future<void> _loadArtists() async {
    try {
      final artistsData = await _userService.getUsersByRole('artist');
      final artists = artistsData
          .map(
            (data) => UserModel(
              id: data['uid'] as String? ?? '',
              email: data['email'] as String? ?? '',
              username: data['username'] as String? ?? '',
              fullName:
                  data['fullName'] as String? ??
                  data['displayName'] as String? ??
                  '',
              createdAt: DateTime.now(),
              profileImageUrl: data['profileImageUrl'] as String? ?? '',
            ),
          )
          .toList();

      if (mounted) {
        setState(() {
          _artists = artists;
          _isLoadingArtists = false;
        });
      }
    } catch (e, _) {
      if (mounted) {
        setState(() {
          _isLoadingArtists = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading artists: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<UserModel> _getFilteredArtists() {
    if (_searchQuery.isEmpty) return _artists;
    return _artists
        .where(
          (artist) =>
              artist.fullName.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ) ||
              artist.username.toLowerCase().contains(
                _searchQuery.toLowerCase(),
              ),
        )
        .toList();
  }

  Future<void> _purchaseGift(
    String productId,
    String giftName,
    double price,
  ) async {
    if (_selectedArtist == null) {
      if (kDebugMode) {
        print('🎁 No artist selected');
      }
      return;
    }

    if (kDebugMode) {
      print('🎁 Starting gift purchase flow');
      print(
        '   - Product: $productId ($giftName - \$${price.toStringAsFixed(2)})',
      );
      print(
        '   - Recipient: ${_selectedArtist!.fullName} (${_selectedArtist!.id})',
      );
    }

    try {
      final giftService = InAppGiftService();

      final success = await giftService.purchaseGift(
        giftProductId: productId,
        recipientId: _selectedArtist!.id,
        message: '',
      );

      if (kDebugMode) {
        print('🎁 Purchase initiation result: $success');
      }

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to start gift purchase. Please check:\n'
              '• Internet connection\n'
              '• In-app purchases are enabled\n'
              '• You\'re signed in with a valid account',
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('🎁 Exception during purchase: $e');
      }
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final body = Stack(
      children: [
        _buildWorldBackground(),
        Positioned.fill(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              16,
              widget.showAppBar ? 120 : 32,
              16,
              32,
            ),
            child: Column(
              children: [
                _buildHeroSection(),
                const SizedBox(height: 24),
                _buildArtistSelectionSection(),
                const SizedBox(height: 24),
                _buildGiftTiersSection(),
              ],
            ),
          ),
        ),
      ],
    );

    if (widget.showAppBar) {
      return Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Visibility Gifts',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: body,
      );
    }

    return body;
  }

  Widget _buildHeroSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            color: Colors.white.withValues(alpha: 0.06),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 40,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF22D3EE)],
                      ),
                    ),
                    child: const Icon(
                      Icons.celebration,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signal boost artists you love',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Gifts unlock featured artist slots, artwork highlights, event placement, and ad credits creators can reinvest.',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _HeroBadge(label: 'Artist spotlights'),
                  _HeroBadge(label: 'Artwork features'),
                  _HeroBadge(label: 'Event promos'),
                  _HeroBadge(label: 'Ad credits for creators'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildArtistSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Select an artist',
          'Search the community and decide who receives the visibility boost.',
        ),
        const SizedBox(height: 16),
        _buildGlassPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchField(),
              const SizedBox(height: 16),
              _buildArtistSelector(),
              _buildSelectedArtistBanner(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        color: Colors.white.withValues(alpha: 0.05),
      ),
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        style: GoogleFonts.spaceGrotesk(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search artists by name or handle',
          hintStyle: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.55),
          ),
          border: InputBorder.none,
          prefixIcon: const Icon(Icons.search, color: Colors.white70),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildArtistSelector() {
    final filteredArtists = _getFilteredArtists();

    if (_isLoadingArtists) {
      return _buildPanelPlaceholder(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading artists...',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    if (filteredArtists.isEmpty) {
      return _buildPanelPlaceholder(
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Colors.white.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isEmpty
                  ? 'No artists available yet'
                  : 'No artists match that search',
              style: GoogleFonts.spaceGrotesk(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 320),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          color: Colors.white.withValues(alpha: 0.02),
        ),
        child: ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: filteredArtists.length,
          itemBuilder: (context, index) {
            final artist = filteredArtists[index];
            final isSelected = _selectedArtist?.id == artist.id;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedArtist = artist;
                  _searchQuery = '';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.transparent,
                  border: Border(
                    bottom: index < filteredArtists.length - 1
                        ? BorderSide(
                            color: Colors.white.withValues(alpha: 0.06),
                          )
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundImage: ImageUrlValidator.safeNetworkImage(
                          artist.profileImageUrl,
                        ),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        child:
                            !ImageUrlValidator.isValidImageUrl(
                              artist.profileImageUrl,
                            )
                            ? Text(
                                artist.fullName.isNotEmpty
                                    ? artist.fullName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artist.fullName,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            '@${artist.username}',
                            style: GoogleFonts.spaceGrotesk(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected ? Icons.check_circle : Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPanelPlaceholder({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        color: Colors.white.withValues(alpha: 0.02),
      ),
      child: child,
    );
  }

  Widget _buildSelectedArtistBanner() {
    if (_selectedArtist == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        color: Colors.white.withValues(alpha: 0.04),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFF34D399), Color(0xFF22D3EE)],
              ),
            ),
            child: const Icon(Icons.favorite, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supporting ${_selectedArtist!.fullName}',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Pick a gift tier below to push them into featured lanes.',
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _selectedArtist = null;
              });
            },
            icon: const Icon(Icons.close, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftTiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'Send a visibility gift',
          'Each tier funds artist placements, artwork features, and ad budgets.',
        ),
        const SizedBox(height: 20),
        ..._buildGiftTierCards(),
      ],
    );
  }

  List<Widget> _buildGiftTierCards() {
    final giftTiers = [
      {
        'id': 'artbeat_gift_small',
        'name': 'Supporter',
        'price': 4.99,
        'credits': 50,
        'icon': Icons.favorite_border,
        'accentColor': const Color(0xFF7C4DFF),
        'benefits': [
          '30 days of artist discovery placement',
          'Boosted search placement for the artist',
          'One featured artwork slot',
        ],
        'isPopular': false,
      },
      {
        'id': 'artbeat_gift_medium',
        'name': 'Fan',
        'price': 9.99,
        'credits': 100,
        'icon': Icons.star_border,
        'accentColor': const Color(0xFF22D3EE),
        'benefits': [
          '90 days of artist discovery placement',
          'Artwork + upcoming event spotlight',
          'Ad credits for story placements',
        ],
        'isPopular': true,
      },
      {
        'id': 'artbeat_gift_large',
        'name': 'Patron',
        'price': 24.99,
        'credits': 250,
        'icon': Icons.diamond,
        'accentColor': const Color(0xFF34D399),
        'benefits': [
          '180 days of featured artist slots',
          'Five artwork highlights rotating weekly',
          'Promo credits for creator-led ads',
          'Priority event promotion',
        ],
        'isPopular': false,
      },
      {
        'id': 'artbeat_gift_premium',
        'name': 'Benefactor',
        'price': 49.99,
        'credits': 500,
        'icon': Icons.workspace_premium,
        'accentColor': const Color(0xFFFFA074),
        'benefits': [
          'One year of continuous discovery placement',
          'Artwork + event takeover slots',
          'Dedicated promo strategist session',
          'Legendary supporter halo on artist profile',
        ],
        'isPopular': false,
      },
    ];

    return giftTiers.map((tier) {
      final accentColor = tier['accentColor'] as Color;
      final isPopular = tier['isPopular'] as bool;
      final benefits = tier['benefits'] as List<String>;
      return Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: _buildGlassPanel(
          gradient: LinearGradient(
            colors: [
              accentColor.withValues(alpha: 0.2),
              Colors.white.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderColor: isPopular
              ? accentColor.withValues(alpha: 0.6)
              : Colors.white24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: Icon(
                      tier['icon'] as IconData,
                      color: accentColor,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tier['name'] as String,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${tier['credits']} visibility credits',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${(tier['price'] as double).toStringAsFixed(2)}',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'one-time',
                        style: GoogleFonts.spaceGrotesk(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              ...benefits.map(
                (benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Icon(Icons.bolt, color: accentColor, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          benefit,
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedArtist == null
                      ? null
                      : () => _purchaseGift(
                          tier['id'] as String,
                          tier['name'] as String,
                          tier['price'] as double,
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedArtist == null
                        ? Colors.white12
                        : accentColor,
                    foregroundColor: _selectedArtist == null
                        ? Colors.white38
                        : Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    _selectedArtist == null
                        ? 'Select an artist first'
                        : 'Send ${tier['name']} gift',
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.spaceGrotesk(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassPanel({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(24),
    Gradient? gradient,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: borderColor ?? Colors.white24),
            color: gradient == null
                ? Colors.white.withValues(alpha: 0.04)
                : null,
            gradient: gradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 32,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: child,
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

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _handlePurchaseCompleted(CompletedPurchase purchase) {
    if (purchase.category == PurchaseCategory.gifts && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gift sent successfully! Thank you for supporting artists.',
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _handlePurchaseError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Purchase failed: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handlePurchaseCancelled() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Purchase cancelled'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}

class _HeroBadge extends StatelessWidget {
  final String label;

  const _HeroBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
