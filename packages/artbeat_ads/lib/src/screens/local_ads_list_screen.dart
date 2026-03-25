import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';
import '../widgets/ad_card.dart';
import '../widgets/zone_filter.dart';
import 'create_local_ad_screen.dart';

class LocalAdsListScreen extends StatefulWidget {
  final LocalAdZone? initialZone;

  const LocalAdsListScreen({Key? key, this.initialZone}) : super(key: key);

  @override
  State<LocalAdsListScreen> createState() => _LocalAdsListScreenState();
}

class _LocalAdsListScreenState extends State<LocalAdsListScreen> {
  late LocalAdZone _selectedPlacement;
  final _adService = LocalAdService();
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    final initialPlacement = widget.initialZone ?? LocalAdZone.community;
    _selectedPlacement = initialPlacement.isLaunchPlacement
        ? initialPlacement
        : LocalAdZone.community;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ads_local_ads_list_text_browse_ads'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              setState(() => _isSearching = !_isSearching);
              if (!_isSearching) {
                _searchController.clear();
              }
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push<void>(
            context,
            MaterialPageRoute<void>(
              builder: (context) => const CreateLocalAdScreen(),
            ),
          ).then((_) => setState(() {}));
        },
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_isSearching)
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search ads...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
          PlacementFilter(
            selectedPlacement: _selectedPlacement,
            onPlacementChanged: (zone) {
              setState(() {
                _selectedPlacement = zone;
                _searchController.clear();
                _isSearching = false;
              });
            },
          ),
          Expanded(
            child: _isSearching && _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildPlacementAds(),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementAds() {
    return FutureBuilder<List<LocalAd>>(
      future: _adService.getActiveAdsByZone(_selectedPlacement),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('ads_local_ads_list_error_error_snapshoterror'.tr()),
          );
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ads_click, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'ads_local_ads_list_text_no_ads_in_zone'.tr().replaceAll(
                    '{zone}',
                    _selectedPlacement.displayName,
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'ads_local_ads_list_text_be_first_to_post'.tr(),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) => AdCard(ad: ads[index]),
        );
      },
    );
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<LocalAd>>(
      future: _adService.searchAds(_searchController.text),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('ads_local_ads_list_error_error_snapshoterror'.tr()),
          );
        }

        final ads = snapshot.data ?? [];

        if (ads.isEmpty) {
          return Center(
            child: Text('ads_local_ads_list_hint_no_results_for'.tr()),
          );
        }

        return ListView.builder(
          itemCount: ads.length,
          itemBuilder: (context, index) => AdCard(ad: ads[index]),
        );
      },
    );
  }

}
