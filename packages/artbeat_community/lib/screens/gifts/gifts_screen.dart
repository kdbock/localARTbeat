import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import 'package:artbeat_core/src/services/in_app_gift_service.dart';
import '../../widgets/gift_card_widget.dart';
import '../../theme/community_colors.dart';
import 'gift_rules_screen.dart';

class ViewReceivedGiftsScreen extends StatefulWidget {
  const ViewReceivedGiftsScreen({super.key});

  @override
  State<ViewReceivedGiftsScreen> createState() =>
      _ViewReceivedGiftsScreenState();
}

class _ViewReceivedGiftsScreenState extends State<ViewReceivedGiftsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final InAppGiftService _giftService = InAppGiftService();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<GiftModel> _gifts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGifts();
  }

  Future<void> _loadGifts() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('gifts')
          .limit(20)
          .get();
      final gifts = querySnapshot.docs
          .map((doc) => GiftModel.fromFirestore(doc))
          .toList();
      setState(() {
        _gifts = gifts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading gifts: $e')));
    }
  }

  void _handleSendGift(GiftModel gift) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Processing gift...'),
        duration: Duration(seconds: 1),
      ),
    );

    final success = await _giftService.purchaseQuickGift(gift.recipientId);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gift purchase initiated! 🎁'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to send gift. Please try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1, // Not a main navigation screen
        scaffoldKey: _scaffoldKey,
        appBar: const EnhancedUniversalHeader(
          title: 'Gifts',
          showBackButton: true,
          showSearch: false,
          showDeveloperTools: true,
          backgroundGradient: CommunityColors.communityGradient,
          titleGradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foregroundColor: Colors.white,
        ),
        drawer: const ArtbeatDrawer(),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return MainLayout(
      currentIndex: -1, // Not a main navigation screen
      scaffoldKey: _scaffoldKey,
      appBar: const EnhancedUniversalHeader(
        title: 'Gifts',
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const ArtbeatDrawer(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                TextButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (context) => const GiftRulesScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Gift Guidelines'),
                ),
                const SizedBox(height: 16),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: _gifts.isEmpty
                ? SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        'No gifts yet',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                          childAspectRatio: 1.0,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => GiftCardWidget(
                        gift: _gifts[index],
                        onSendGift: () => _handleSendGift(_gifts[index]),
                      ),
                      childCount: _gifts.length,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
