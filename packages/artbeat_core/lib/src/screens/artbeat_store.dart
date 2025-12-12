import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart';

// Import the existing screens
// Removed unnecessary import for gifts_screen.dart
// Removed unnecessary import for subscriptions_screen.dart

class ArtbeatStoreScreen extends StatelessWidget {
  const ArtbeatStoreScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 3,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Gifts', icon: Icon(Icons.card_giftcard)),
              Tab(text: 'Ads', icon: Icon(Icons.ads_click)),
              Tab(text: 'Subscriptions', icon: Icon(Icons.subscriptions)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                GiftsScreen(showAppBar: false),
                AdsScreen(),
                SubscriptionsScreen(showAppBar: false),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
