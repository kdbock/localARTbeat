import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../theme/community_colors.dart';

class PortfoliosScreen extends StatefulWidget {
  const PortfoliosScreen({super.key});

  @override
  State<PortfoliosScreen> createState() => _PortfoliosScreenState();
}

class _PortfoliosScreenState extends State<PortfoliosScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map<String, dynamic>> _portfolios = [];
  List<Map<String, dynamic>> _filteredPortfolios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  Future<void> _loadPortfolios() async {
    setState(() => _isLoading = true);
    try {
      final querySnapshot = await _firestore
          .collection('artistProfiles')
          .where('isPortfolioPublic', isEqualTo: true)
          .orderBy('username')
          .limit(20)
          .get();

      setState(() {
        _portfolios = querySnapshot.docs
            .map((doc) => {...doc.data(), 'id': doc.id})
            .toList();
        _filteredPortfolios = _portfolios;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading portfolios: $e')));
    }
  }

  void _performSearch(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredPortfolios = _portfolios;
      } else {
        _filteredPortfolios = _portfolios.where((portfolio) {
          final name = (portfolio['name'] as String?)?.toLowerCase() ?? '';
          final username =
              (portfolio['username'] as String?)?.toLowerCase() ?? '';
          final bio = (portfolio['bio'] as String?)?.toLowerCase() ?? '';
          final location =
              (portfolio['location'] as String?)?.toLowerCase() ?? '';
          final searchLower = query.toLowerCase();

          return name.contains(searchLower) ||
              username.contains(searchLower) ||
              bio.contains(searchLower) ||
              location.contains(searchLower);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MainLayout(
        currentIndex: -1, // Not a main navigation screen
        scaffoldKey: _scaffoldKey,
        appBar: EnhancedUniversalHeader(
          title: 'screen_title_artist_portfolios'.tr(),
          showBackButton: true,
          showSearch: false,
          showDeveloperTools: true,
          backgroundGradient: CommunityColors.communityGradient,
          titleGradient: const LinearGradient(
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
      appBar: EnhancedUniversalHeader(
        title: 'screen_title_artist_portfolios'.tr(),
        showBackButton: true,
        showSearch: false,
        showDeveloperTools: true,
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      drawer: const ArtbeatDrawer(),
      child: CustomScrollView(
        slivers: [
          // Header with search and filter options
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SearchBar(
                hintText: 'Search artists...',
                leading: const Icon(Icons.search),
                onChanged: (value) {
                  _performSearch(value);
                },
              ),
            ),
          ),
          // Portfolio grid
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: _filteredPortfolios.isEmpty
                ? const SliverToBoxAdapter(
                    child: Center(child: Text('No portfolios available')),
                  )
                : SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          mainAxisSpacing: 16.0,
                          crossAxisSpacing: 16.0,
                        ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final portfolio = _filteredPortfolios[index];
                      return Card(
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Portfolio cover image
                            AspectRatio(
                              aspectRatio: 1.0,
                              child: portfolio['coverImageUrl'] != null
                                  ? ImageManagementService().getOptimizedImage(
                                      imageUrl:
                                          portfolio['coverImageUrl'] as String,
                                      fit: BoxFit.cover,
                                      isThumbnail: true,
                                      errorWidget: Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.broken_image),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            // Artist info
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (portfolio['username'] as String?) ??
                                        'Artist',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${portfolio['artworkCount'] ?? 0} works',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: _filteredPortfolios.length),
                  ),
          ),
        ],
      ),
    );
  }
}
