import 'dart:async';
import 'dart:ui';

import 'package:artbeat_core/artbeat_core.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ArtistBoostsScreen extends StatefulWidget {
  final bool showAppBar;
  const ArtistBoostsScreen({Key? key, this.showAppBar = true})
    : super(key: key);

  @override
  State<ArtistBoostsScreen> createState() => _ArtistBoostsScreenState();
}

class _ArtistBoostsScreenState extends State<ArtistBoostsScreen> {
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
    
    if (kDebugMode) {
      print('📱 ArtistBoostsScreen: Setting up purchase event listener...');
    }
    
    _purchaseSubscription = setup.purchaseManager.purchaseEventStream.listen(
      (event) {
        if (kDebugMode) {
          print('📱 ArtistBoostsScreen: Received purchase event: ${event.type}');
        }
        
        if (event.type == PurchaseEventType.completed) {
          if (kDebugMode) {
            print('📱 ArtistBoostsScreen: Handling completed purchase');
          }
          _handlePurchaseCompleted(event.purchase!);
        } else if (event.type == PurchaseEventType.error) {
          if (kDebugMode) {
            print('📱 ArtistBoostsScreen: Handling purchase error');
          }
          _handlePurchaseError(event.error!);
        } else if (event.type == PurchaseEventType.cancelled) {
          if (kDebugMode) {
            print('📱 ArtistBoostsScreen: Handling purchase cancellation');
          }
          _handlePurchaseCancelled();
        }
      },
      onError: (Object error) {
        if (kDebugMode) {
          print('Purchase event error: $error');
        }
      },
    );
    
    if (kDebugMode) {
      print('📱 ArtistBoostsScreen: Purchase event listener set up successfully');
    }
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

  Future<void> _purchaseBoost(
    String productId,
    String boostName,
    double price,
  ) async {
    if (_selectedArtist == null) {
      if (kDebugMode) {
        print('⚡ No artist selected');
      }
      return;
    }

    if (kDebugMode) {
      print('⚡ Starting boost purchase flow');
      print(
        '   - Product: $productId ($boostName - \$${price.toStringAsFixed(2)})',
      );
      print(
        '   - Recipient: ${_selectedArtist!.fullName} (${_selectedArtist!.id})',
      );
    }

    try {
      final boostService = ArtistBoostService();

      final success = await boostService.purchaseBoost(
        boostProductId: productId,
        recipientId: _selectedArtist!.id,
        message: '',
      );

      if (kDebugMode) {
        print('⚡ Purchase initiation result: $success');
      }

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Failed to start boost purchase. Please check:\n'
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
        print('⚡ Exception during purchase: $e');
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
                _buildBoostTiersSection(),
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
            'boosts_title'.tr(),
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                          'boosts_hero_title'.tr(),
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'boosts_hero_subtitle'.tr(),
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
          'boosts_section_select_title'.tr(),
          'boosts_section_select_subtitle'.tr(),
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
          hintText: 'boosts_search_hint'.tr(),
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
              'boosts_loading_artists'.tr(),
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
                  ? 'boosts_empty_artists'.tr()
                  : 'boosts_empty_search'.tr(),
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
                  'boosts_supporting_artist'.tr(
                    namedArgs: {'name': _selectedArtist!.fullName},
                  ),
                  style: GoogleFonts.spaceGrotesk(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'boosts_supporting_subtitle'.tr(),
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

  Widget _buildBoostTiersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'boosts_section_send_title'.tr(),
          'boosts_section_send_subtitle'.tr(),
        ),
        const SizedBox(height: 20),
        ..._buildBoostTierCards(),
      ],
    );
  }

  List<Widget> _buildBoostTierCards() {
    final boostTiers = [
      {
        'id': 'artbeat_boost_spark',
        'name': 'Spark',
        'price': 4.99,
        'momentum': 50,
        'image': 'assets/images/spark_boost.png',
        'accentColor': const Color(0xFFFB7185),
        'benefits': [
          'boosts_tier_spark_benefit_1'.tr(),
          'boosts_tier_spark_benefit_2'.tr(),
          'boosts_tier_spark_benefit_3'.tr(),
        ],
        'isPopular': false,
      },
      {
        'id': 'artbeat_boost_surge',
        'name': 'Surge',
        'price': 9.99,
        'momentum': 120,
        'image': 'assets/images/surge_boost.png',
        'accentColor': const Color(0xFFF97316),
        'benefits': [
          'boosts_tier_surge_benefit_1'.tr(),
          'boosts_tier_surge_benefit_2'.tr(),
          'boosts_tier_surge_benefit_3'.tr(),
        ],
        'isPopular': true,
      },
      {
        'id': 'artbeat_boost_overdrive',
        'name': 'Overdrive',
        'price': 24.99,
        'momentum': 350,
        'image': 'assets/images/overdrive_boost.png',
        'accentColor': const Color(0xFF22D3EE),
        'benefits': [
          'boosts_tier_overdrive_benefit_1'.tr(),
          'boosts_tier_overdrive_benefit_2'.tr(),
          'boosts_tier_overdrive_benefit_3'.tr(),
        ],
        'isPopular': false,
      },
    ];

    return boostTiers.map((tier) {
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
                    padding: EdgeInsets.zero,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        tier['image'] as String,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
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
                          '+${tier['momentum']} Momentum',
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
                        'boosts_one_time'.tr(),
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
                      : () => _purchaseBoost(
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
                        ? 'boosts_select_artist_first'.tr()
                        : 'boosts_deploy_boost'.tr(
                            namedArgs: {'name': tier['name'] as String},
                          ),
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
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
    if (kDebugMode) {
      print('📱 _handlePurchaseCompleted called');
      print('   - Category: ${purchase.category}');
      print('   - Product: ${purchase.productId}');
      print('   - Mounted: $mounted');
    }
    
    if (purchase.category == PurchaseCategory.boosts && mounted) {
      if (kDebugMode) {
        print('📱 Showing success snackbar...');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('boosts_success_message'.tr()),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _handlePurchaseError(String error) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'boosts_purchase_failed'.tr(namedArgs: {'error': error}),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _handlePurchaseCancelled() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('boosts_purchase_cancelled'.tr()),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
}
