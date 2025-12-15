import 'package:artbeat_core/artbeat_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
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

    // Listen to purchase events to show success messages
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
      // ignore: inference_failure_on_untyped_parameter
      onError: (error) {
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
    }
    if (kDebugMode) {
      print(
        '   - Product: $productId ($giftName - \$${price.toStringAsFixed(2)})',
      );
    }
    if (kDebugMode) {
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
      // Apple/Google will now show their native purchase dialog
      // Success message will be shown when purchase completes
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
    final content = Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ArtbeatColors.backgroundPrimary, Color(0xFFF8F9FA)],
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section
            _buildHeroSection(),
            const SizedBox(height: 32),

            // Artist Selection Section
            _buildArtistSelectionSection(),
            const SizedBox(height: 32),

            // Gift Tiers Section
            _buildGiftTiersSection(),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );

    if (widget.showAppBar) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Support Artists'),
          backgroundColor: ArtbeatColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: content,
      );
    } else {
      return content;
    }
  }

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [ArtbeatColors.primary, ArtbeatColors.primaryPurple],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.celebration,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support Your Favorite Artists',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Give gifts that boost their visibility and help them grow',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.white, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your gift gives artists real exposure - they get featured in discovery feeds, highlighted artworks, and ad placements!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistSelectionSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose an Artist to Support',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search and select the artist you want to help succeed',
            style: TextStyle(fontSize: 14, color: ArtbeatColors.textSecondary),
          ),
          const SizedBox(height: 20),
          _buildArtistSelector(),
        ],
      ),
    );
  }

  Widget _buildArtistSelector() {
    final filteredArtists = _getFilteredArtists();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search artists by name...',
              hintStyle: TextStyle(
                color: ArtbeatColors.textSecondary.withValues(alpha: 0.6),
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: ArtbeatColors.primary,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingArtists)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ArtbeatColors.primary,
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading artists...',
                    style: TextStyle(
                      color: ArtbeatColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        else if (filteredArtists.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: ArtbeatColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? 'No artists available'
                        : 'No artists match your search',
                    style: const TextStyle(
                      color: ArtbeatColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Container(
            constraints: const BoxConstraints(maxHeight: 300),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: filteredArtists.length,
                itemBuilder: (context, index) {
                  final artist = filteredArtists[index];
                  final isSelected = _selectedArtist?.id == artist.id;
                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? ArtbeatColors.primary.withValues(alpha: 0.05)
                          : Colors.white,
                      border: Border(
                        bottom: index < filteredArtists.length - 1
                            ? BorderSide(
                                color: Colors.grey.withValues(alpha: 0.1),
                                width: 1,
                              )
                            : BorderSide.none,
                      ),
                    ),
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          _selectedArtist = artist;
                          _searchQuery = '';
                        });
                      },
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? ArtbeatColors.primary
                                : Colors.grey.withValues(alpha: 0.2),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundImage: ImageUrlValidator.safeNetworkImage(
                            artist.profileImageUrl,
                          ),
                          backgroundColor: Colors.grey.withValues(alpha: 0.1),
                          child:
                              !ImageUrlValidator.isValidImageUrl(
                                artist.profileImageUrl,
                              )
                              ? Text(
                                  artist.fullName.isNotEmpty
                                      ? artist.fullName[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ArtbeatColors.textPrimary,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      title: Text(
                        artist.fullName,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: ArtbeatColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        '@${artist.username}',
                        style: const TextStyle(
                          color: ArtbeatColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      trailing: isSelected
                          ? Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: ArtbeatColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            )
                          : Icon(
                              Icons.chevron_right,
                              color: ArtbeatColors.textSecondary.withValues(
                                alpha: 0.5,
                              ),
                            ),
                    ),
                  );
                },
              ),
            ),
          ),
        if (_selectedArtist != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ArtbeatColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ArtbeatColors.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: ArtbeatColors.primary,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supporting ${_selectedArtist!.fullName}',
                        style: const TextStyle(
                          color: ArtbeatColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const Text(
                        'Choose a gift tier below to boost their visibility!',
                        style: TextStyle(
                          color: ArtbeatColors.textSecondary,
                          fontSize: 14,
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
                  icon: Icon(
                    Icons.close,
                    color: ArtbeatColors.textSecondary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildGiftTiersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choose Your Gift',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ArtbeatColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Each gift provides real exposure benefits for the artist',
            style: TextStyle(fontSize: 14, color: ArtbeatColors.textSecondary),
          ),
          const SizedBox(height: 24),
          ..._buildGiftTierCards(),
        ],
      ),
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
        'gradient': const [Color(0xFFE8F5E8), Color(0xFFF1F8E9)],
        'accentColor': const Color(0xFF4CAF50),
        'benefits': [
          '🎯 Artist featured in discovery for 30 days',
          '📱 Increased visibility in search results',
          '⭐ Special "Featured" badge',
        ],
        'isPopular': false,
      },
      {
        'id': 'artbeat_gift_medium',
        'name': 'Fan',
        'price': 9.99,
        'credits': 100,
        'icon': Icons.star_border,
        'gradient': const [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        'accentColor': const Color(0xFF2196F3),
        'benefits': [
          '🎯 Artist featured in discovery for 90 days',
          '🖼️ 1 artwork featured for 90 days',
          '📈 Enhanced search ranking',
          '⭐ Premium "Featured" badge',
        ],
        'isPopular': false,
      },
      {
        'id': 'artbeat_gift_large',
        'name': 'Patron',
        'price': 24.99,
        'credits': 250,
        'icon': Icons.diamond,
        'gradient': const [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
        'accentColor': const Color(0xFF9C27B0),
        'benefits': [
          '🎯 Artist featured in discovery for 180 days',
          '🖼️ 5 artworks featured for 180 days',
          '📢 Artist ads in rotation for 180 days',
          '🏆 "Top Supporter" recognition',
        ],
        'isPopular': true,
      },
      {
        'id': 'artbeat_gift_premium',
        'name': 'Benefactor',
        'price': 49.99,
        'credits': 500,
        'icon': Icons.workspace_premium,
        'gradient': const [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        'accentColor': const Color(0xFFFF9800),
        'benefits': [
          '🎯 Artist featured in discovery for 1 year',
          '🖼️ 5 artworks featured for 1 year',
          '📢 Artist ads in rotation for 1 year',
          '👑 "Legendary Supporter" status',
          '📊 Priority support access',
        ],
        'isPopular': false,
      },
    ];

    return giftTiers.map((tier) {
      final isPopular = tier['isPopular'] as bool;
      final benefits = tier['benefits'] as List<String>;
      final gradient = tier['gradient'] as List<Color>;
      final accentColor = tier['accentColor'] as Color;

      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
          border: isPopular ? Border.all(color: accentColor, width: 2) : null,
        ),
        child: Stack(
          children: [
            if (isPopular)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Most Popular',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          tier['icon'] as IconData,
                          color: accentColor,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tier['name'] as String,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ArtbeatColors.textPrimary,
                              ),
                            ),
                            Text(
                              '${tier['credits']} Credits',
                              style: const TextStyle(
                                fontSize: 14,
                                color: ArtbeatColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${tier['price']}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                          const Text(
                            'one-time',
                            style: TextStyle(
                              fontSize: 12,
                              color: ArtbeatColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Benefits for the artist:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: ArtbeatColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...benefits.map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: accentColor,
                            size: 18,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              benefit,
                              style: const TextStyle(
                                fontSize: 14,
                                color: ArtbeatColors.textPrimary,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                            ? Colors.grey[300]
                            : accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: _selectedArtist == null ? 0 : 4,
                        shadowColor: accentColor.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        _selectedArtist == null
                            ? 'Select an artist first'
                            : 'Send ${tier['name']} Gift',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }

  void _handlePurchaseCompleted(CompletedPurchase purchase) {
    if (purchase.category == PurchaseCategory.gifts) {
      if (mounted) {
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
