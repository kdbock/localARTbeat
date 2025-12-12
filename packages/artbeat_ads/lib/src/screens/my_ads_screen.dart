import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/index.dart';
import '../services/local_ad_service.dart';
import '../widgets/ad_card.dart';
import 'create_local_ad_screen.dart';

class MyAdsScreen extends StatefulWidget {
  final bool showAppBar;
  const MyAdsScreen({Key? key, this.showAppBar = true}) : super(key: key);

  @override
  State<MyAdsScreen> createState() => _MyAdsScreenState();
}

class _MyAdsScreenState extends State<MyAdsScreen> {
  late final String _userId;
  final _adService = LocalAdService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }
    _userId = user.uid;
  }

  Future<void> _deleteAd(String adId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ads_my_ads_text_delete_ad'.tr()),
        content: Text('ads_my_ads_text_this_action_cannot'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'ads_my_ads_text_delete'.tr(),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _adService.deleteAd(adId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('ads_my_ads_text_ad_deleted'.tr())),
          );
          setState(() {});
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('admin_unified_admin_dashboard_error_error_e'.tr()),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(title: Text('ads_my_ads_text_my_ads'.tr()))
          : null,
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
      body: FutureBuilder<List<LocalAd>>(
        future: _adService.getMyAds(_userId),
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
          final activeAds = ads
              .where((ad) => ad.status == LocalAdStatus.active && !ad.isExpired)
              .toList();
          final expiredAds = ads
              .where(
                (ad) =>
                    ad.status == LocalAdStatus.expired ||
                    (ad.status == LocalAdStatus.active && ad.isExpired),
              )
              .toList();

          if (ads.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.ads_click, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'ads_my_ads_text_no_ads_yet'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ads_my_ads_text_post_first_ad'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              if (activeAds.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'ads_my_ads_text_active_ads'.tr().replaceAll(
                      '{count}',
                      '${activeAds.length}',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...activeAds.map(
                  (ad) => AdCard(ad: ad, onDelete: () => _deleteAd(ad.id)),
                ),
              ],
              if (expiredAds.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'ads_my_ads_text_expired_ads'.tr().replaceAll(
                      '{count}',
                      '${expiredAds.length}',
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...expiredAds.map(
                  (ad) => AdCard(ad: ad, onDelete: () => _deleteAd(ad.id)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
