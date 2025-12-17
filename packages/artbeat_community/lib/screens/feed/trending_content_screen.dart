import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart';
import '../../models/post_model.dart';
import '../../widgets/post_card.dart';
import '../../theme/community_colors.dart';

class TrendingContentScreen extends StatefulWidget {
  const TrendingContentScreen({super.key});

  @override
  State<TrendingContentScreen> createState() => _TrendingContentScreenState();
}

class _TrendingContentScreenState extends State<TrendingContentScreen> {
  final ScrollController _scrollController = ScrollController();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  List<PostModel> _trendingPosts = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _postsPerPage = 10;

  // Filter options
  String _selectedTimeFrame = 'Week';
  String _selectedCategory = 'All';

  final List<String> _timeFrames = ['Day', 'Week', 'Month', 'All Time'];
  final List<String> _categories = [
    'All',
    'Painting',
    'Digital',
    'Photography',
    'Sculpture',
    'Mixed Media',
  ];

  @override
  void initState() {
    super.initState();
    _loadTrendingContent();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _lastDocument != null) {
      _loadMoreTrendingContent();
    }
  }

  Future<void> _loadTrendingContent() async {
    setState(() {
      _isLoading = true;
      _trendingPosts = [];
      _lastDocument = null;
    });

    try {
      // Get cutoff date based on selected time frame
      DateTime cutoffDate;
      final now = DateTime.now();

      switch (_selectedTimeFrame) {
        case 'Day':
          cutoffDate = now.subtract(const Duration(days: 1));
          break;
        case 'Week':
          cutoffDate = now.subtract(const Duration(days: 7));
          break;
        case 'Month':
          cutoffDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'All Time':
        default:
          cutoffDate = DateTime(2000); // Far in the past
          break;
      }

      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .orderBy('createdAt', descending: true);

      // Apply category filter if not 'All'
      if (_selectedCategory != 'All') {
        query = query.where(
          'tags',
          arrayContains: _selectedCategory.toLowerCase(),
        );
      }

      // Order by applause count for trending
      query = query
          .orderBy('applauseCount', descending: true)
          .limit(_postsPerPage);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        setState(() {
          _trendingPosts = snapshot.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading trending content: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreTrendingContent() async {
    if (_isLoadingMore || _lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Get cutoff date based on selected time frame
      DateTime cutoffDate;
      final now = DateTime.now();

      switch (_selectedTimeFrame) {
        case 'Day':
          cutoffDate = now.subtract(const Duration(days: 1));
          break;
        case 'Week':
          cutoffDate = now.subtract(const Duration(days: 7));
          break;
        case 'Month':
          cutoffDate = DateTime(now.year, now.month - 1, now.day);
          break;
        case 'All Time':
        default:
          cutoffDate = DateTime(2000); // Far in the past
          break;
      }

      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('isPublic', isEqualTo: true)
          .where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoffDate),
          )
          .orderBy('createdAt', descending: true);

      // Apply category filter if not 'All'
      if (_selectedCategory != 'All') {
        query = query.where(
          'tags',
          arrayContains: _selectedCategory.toLowerCase(),
        );
      }

      // Order by applause count for trending
      query = query
          .orderBy('applauseCount', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_postsPerPage);

      final snapshot = await query.get();

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;

        final morePosts = snapshot.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        setState(() {
          _trendingPosts.addAll(morePosts);
          _isLoadingMore = false;
        });
      } else {
        setState(() {
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      AppLogger.error('Error loading more trending content: $e');
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _applyFilters() {
    _loadTrendingContent();
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: 3, // Community tab in bottom navigation
      scaffoldKey: _scaffoldKey,
      appBar: EnhancedUniversalHeader(
        title: 'screen_title_trending_content'.tr(),
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
      child: Column(
        children: [
          // Filter options
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Filter Trending Content',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Time Frame'),
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: DropdownButton<String>(
                                  value: _selectedTimeFrame,
                                  isExpanded: true,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTimeFrame = value!;
                                    });
                                  },
                                  underline: Container(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  items: _timeFrames.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Category'),
                              Material(
                                elevation: 4,
                                borderRadius: BorderRadius.circular(8),
                                child: DropdownButton<String>(
                                  value: _selectedCategory,
                                  isExpanded: true,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedCategory = value!;
                                    });
                                  },
                                  underline: Container(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  items: _categories.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _applyFilters,
                        child: const Text('Apply Filters'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _trendingPosts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.trending_up,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No trending content found',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try changing your filters or check back later',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: _trendingPosts.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _trendingPosts.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final post = _trendingPosts[index];
                      return PostCard(
                        post: post,
                        currentUserId:
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                        comments:
                            const [], // Empty list since we don't load comments here
                        onUserTap: (userId) {
                          // Navigate to user profile
                          AppLogger.info('Navigate to user profile: $userId');
                        },
                        // legacy applause removed - engagement handled by UniversalEngagementBar
                        onComment: (postId) {
                          // Navigate to comments screen
                          AppLogger.info(
                            'Navigate to comments for post: $postId',
                          );
                        },
                        // legacy share removed - engagement handled by UniversalEngagementBar
                        onToggleExpand: () {
                          // Toggle expanded view
                          AppLogger.info('Toggle expand for post: ${post.id}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
