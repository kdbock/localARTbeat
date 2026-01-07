import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import 'package:artbeat_core/artbeat_core.dart'
    hide GlassCard, WorldBackground, HudTopBar, GradientCTAButton;
import 'package:artbeat_art_walk/src/models/models.dart';
import 'package:artbeat_art_walk/src/services/art_walk_service.dart';
import 'package:artbeat_art_walk/src/widgets/widgets.dart';
import 'package:artbeat_art_walk/src/widgets/text_styles.dart';

class SearchResultsScreen extends StatefulWidget {
  final String? initialQuery;
  final String? searchType;

  const SearchResultsScreen({
    Key? key,
    this.initialQuery,
    this.searchType = 'art_walks',
  }) : super(key: key);

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen>
    with TickerProviderStateMixin {
  late final ArtWalkService _artWalkService;
  late final TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;
  int _currentTabIndex = 0;

  ArtWalkSearchCriteria _artWalkCriteria = const ArtWalkSearchCriteria();
  PublicArtSearchCriteria _publicArtCriteria = const PublicArtSearchCriteria();

  List<ArtWalkModel> _artWalkResults = [];
  List<PublicArtModel> _publicArtResults = [];

  @override
  void initState() {
    super.initState();

    _artWalkService = context.read<ArtWalkService>();
    _tabController = TabController(length: 2, vsync: this);

    if (widget.searchType == 'public_art') {
      _currentTabIndex = 1;
      _tabController.animateTo(1);
    }

    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      _updateCriteria(widget.initialQuery!);
      _performSearch();
    }

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() => _currentTabIndex = _tabController.index);
      }
    });
  }

  void _updateCriteria(String query) {
    if (_currentTabIndex == 0) {
      _artWalkCriteria = _artWalkCriteria.copyWith(searchQuery: query);
    } else {
      _publicArtCriteria = _publicArtCriteria.copyWith(searchQuery: query);
    }
  }

  Future<void> _performSearch() async {
    setState(() => _isSearching = true);
    try {
      if (_currentTabIndex == 0) {
        final result = await _artWalkService.searchArtWalks(_artWalkCriteria);
        setState(() => _artWalkResults = result.results);
      } else {
        final result = await _artWalkService.searchPublicArt(
          _publicArtCriteria,
        );
        setState(() => _publicArtResults = result.results);
      }
    } catch (e) {
      AppLogger.error('Search failed: $e');
    } finally {
      setState(() => _isSearching = false);
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WorldBackground(
      child: Column(
        children: [
          HudTopBar(title: 'art_walk_search_title'.tr()),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    style: AppTextStyles.body,
                    decoration: GlassInputDecoration.search(
                      hintText: _currentTabIndex == 0
                          ? 'art_walk_search_hint_walks'.tr()
                          : 'art_walk_search_hint_public_art'.tr(),
                      prefixIcon: const Icon(Icons.search, color: Colors.white70),
                    ),
                    onSubmitted: (q) {
                      _updateCriteria(q);
                      _performSearch();
                    },
                  ),
                  const SizedBox(height: 12),
                  GradientCTAButton(
                    label: _isSearching
                        ? 'art_walk_search_button_searching'.tr()
                        : 'art_walk_search_button_search'.tr(),
                    icon: Icons.search,
                    onPressed: _performSearch,
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassCard(
              child: Material(
                color: Colors.transparent,
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: Theme.of(context).colorScheme.secondary,
                  labelColor: Theme.of(context).colorScheme.onSurface,
                  tabs: [
                    Tab(text: 'art_walk_search_tab_walks'.tr()),
                    Tab(text: 'art_walk_search_tab_public_art'.tr()),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildArtWalkResults(), _buildPublicArtResults()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtWalkResults() {
    if (_isSearching && _artWalkResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_artWalkResults.isEmpty) {
      return _buildEmptyState('art_walk_search_empty_walks'.tr());
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _artWalkResults.length,
      itemBuilder: (context, index) {
        final artWalk = _artWalkResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ArtWalkCard(
            artWalk: artWalk,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/art-walk/detail',
                arguments: {'artWalkId': artWalk.id},
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPublicArtResults() {
    if (_isSearching && _publicArtResults.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_publicArtResults.isEmpty) {
      return _buildEmptyState('art_walk_search_empty_public_art'.tr());
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _publicArtResults.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final publicArt = _publicArtResults[index];
        return PublicArtCard(
          publicArt: publicArt,
          onTap: () {
            Navigator.pushNamed(
              context,
              '/public-art/detail',
              arguments: {'publicArtId': publicArt.id},
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTextStyles.body.copyWith(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
