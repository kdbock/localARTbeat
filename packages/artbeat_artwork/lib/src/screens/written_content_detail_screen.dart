import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:share_plus/share_plus.dart';

/// Screen for reading written content (books, stories, etc.)
class WrittenContentDetailScreen extends StatefulWidget {
  final String artworkId;

  const WrittenContentDetailScreen({
    super.key,
    required this.artworkId,
  });

  @override
  State<WrittenContentDetailScreen> createState() =>
      _WrittenContentDetailScreenState();
}

class _WrittenContentDetailScreenState
    extends State<WrittenContentDetailScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final ChapterService _chapterService = ChapterService();
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();
  final artist.AnalyticsService _analyticsService = artist.AnalyticsService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  ArtworkModel? _artwork;
  ArtistProfileModel? _artist;
  List<ChapterModel> _chapters = [];
  ChapterModel? _currentChapter;
  int _currentChapterIndex = 0;
  String? _fallbackArtistName;
  bool _isOwner = false;
  bool _hasAccess = false;

  // Reading progress
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _scrollController.addListener(_updateScrollProgress);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollProgress() {
    if (_scrollController.hasClients &&
        _scrollController.position.maxScrollExtent > 0) {
      setState(() {
        _scrollProgress = _scrollController.position.pixels /
            _scrollController.position.maxScrollExtent;
      });
    }
  }

  Future<void> _loadContent() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load artwork details
      final artwork = await _artworkService.getArtworkById(widget.artworkId);
      if (artwork == null) {
        throw Exception('Artwork not found');
      }

      // Check if this is written content
      if (artwork.contentType != ArtworkContentType.written) {
        throw Exception('This artwork is not written content');
      }

      _artwork = artwork;

      // Check ownership and access
      final currentUser = _auth.currentUser;
      _isOwner = currentUser?.uid == artwork.artistProfileId;

      // Load artist info
      try {
        final artistProfile = await _subscriptionService
            .getArtistProfileById(artwork.artistProfileId);
        _artist = artistProfile;

        // If artist profile not found, try to get user information as fallback
        if (artistProfile == null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(artwork.artistProfileId)
              .get();
          final userData = userDoc.data();
          _fallbackArtistName = (userData?['fullName'] as String?) ??
              (userData?['displayName'] as String?) ??
              'Unknown Artist';
        }
      } catch (e) {
        _fallbackArtistName = 'Unknown Artist';
      }

      // Load chapters if serialized
      if (artwork.isSerializing) {
        _chapters = await _chapterService.getReleasedChapters(widget.artworkId);
        _chapters.sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));

        if (_chapters.isNotEmpty) {
          _currentChapter = _chapters[0];
        }
      }

      // Check access (free content or purchased/paid)
      _hasAccess = _isOwner ||
          !artwork.isForSale ||
          artwork.price == null ||
          artwork.price == 0;

      // Track view analytics
      await _analyticsService.trackArtworkView(
        artworkId: widget.artworkId,
        artistId: artwork.artistProfileId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('art_walk_error_loading_content'.tr().replaceAll('{error}', e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToChapter(int index) {
    if (index >= 0 && index < _chapters.length) {
      setState(() {
        _currentChapterIndex = index;
        _currentChapter = _chapters[index];
        _scrollProgress = 0.0;
      });
      _scrollController.jumpTo(0);
    }
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: _artwork?.imageUrl != null
            ? Image.network(
                _artwork!.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.book, size: 64),
                ),
              )
            : Container(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.book, size: 64),
              ),
        title: Text(
          _artwork?.title ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black, blurRadius: 4)],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: _shareContent,
        ),
        if (_isOwner)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              '/artwork/edit',
              arguments: _artwork,
            ),
          ),
      ],
    );
  }

  Widget _buildContentHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and author
            Text(
              _artwork?.title ?? '',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: _artist?.profileImageUrl != null
                      ? NetworkImage(_artist!.profileImageUrl!)
                      : null,
                  child: _artist?.profileImageUrl == null
                      ? Text((_artist?.displayName ??
                              _fallbackArtistName ??
                              'A')[0]
                          .toUpperCase())
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  _artist?.displayName ??
                      _fallbackArtistName ??
                      'Unknown Artist',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),

            // Description
            if (_artwork!.description.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                _artwork!.description,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],

            // Reading metadata
            if (_artwork?.readingMetadata != null) ...[
              const SizedBox(height: 16),
              _buildReadingMetadata(),
            ],

            // Chapter selector for serialized content
            if (_artwork?.isSerializing == true && _chapters.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildChapterSelector(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReadingMetadata() {
    final metadata = _artwork!.readingMetadata!;
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (metadata['wordCount'] != null)
          Chip(
            label: Text('${metadata['wordCount']} words'),
            avatar: const Icon(Icons.text_fields, size: 16),
          ),
        if (metadata['estimatedReadingTime'] != null)
          Chip(
            label: Text('${metadata['estimatedReadingTime']} min read'),
            avatar: const Icon(Icons.schedule, size: 16),
          ),
        if (metadata['language'] != null)
          Chip(
            label: Text(metadata['language'].toString().toUpperCase()),
            avatar: const Icon(Icons.language, size: 16),
          ),
      ],
    );
  }

  Widget _buildChapterSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chapters',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _chapters.length,
            itemBuilder: (context, index) {
              final chapter = _chapters[index];
              final isSelected = index == _currentChapterIndex;

              return Card(
                margin: const EdgeInsets.only(right: 8),
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: InkWell(
                  onTap: () => _navigateToChapter(index),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 200,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chapter ${chapter.chapterNumber}',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          chapter.title,
                          style: Theme.of(context).textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.schedule,
                                size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${chapter.estimatedReadingTime}min',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (!_hasAccess) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Premium Content',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'This content requires purchase to read',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _purchaseContent,
                child: Text(
                    'Purchase for \$${_artwork?.price?.toStringAsFixed(2) ?? '0.00'}'),
              ),
            ],
          ),
        ),
      );
    }

    final content = _currentChapter?.content ?? _artwork?.description ?? '';

    return SliverToBoxAdapter(
      child: Container(
        constraints: const BoxConstraints(minHeight: 400),
        child: Markdown(
          data: content,
          controller: _scrollController,
          styleSheet: MarkdownStyleSheet(
            p: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.6,
                ),
            h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
            h2: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
            h3: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  height: 1.4,
                ),
            blockquote: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey[600],
                ),
            code: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey[100],
                ),
          ),
          onTapLink: (text, href, title) {
            // Handle link taps
            if (href != null) {
              // Open URL or handle internal links
            }
          },
        ),
      ),
    );
  }

  Widget _buildReadingProgress() {
    if (_artwork?.isSerializing != true || _chapters.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          children: [
            // Previous chapter button
            IconButton(
              onPressed: _currentChapterIndex > 0
                  ? () => _navigateToChapter(_currentChapterIndex - 1)
                  : null,
              icon: const Icon(Icons.chevron_left),
            ),

            // Progress indicator
            Expanded(
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: (_currentChapterIndex + _scrollProgress) /
                        _chapters.length,
                    backgroundColor: Colors.grey[300],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chapter ${_currentChapterIndex + 1} of ${_chapters.length}',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Next chapter button
            IconButton(
              onPressed: _currentChapterIndex < _chapters.length - 1
                  ? () => _navigateToChapter(_currentChapterIndex + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareContent() async {
    final title = _artwork?.title ?? 'Written Content';
    final url = 'https://artbeat.app/artwork/${widget.artworkId}';

    // ignore: deprecated_member_use
    await Share.share('$title\n\n$url');
  }

  Future<void> _purchaseContent() async {
    // TODO: Implement purchase flow
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('art_walk_purchase_functionality_coming_soon'.tr())),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_artwork == null) {
      return Scaffold(
        appBar: AppBar(title: Text('art_walk_content_not_found'.tr())),
        body: Center(child: Text('art_walk_content_not_found'.tr())),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              _buildContentHeader(),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: _buildContent(),
              ),
            ],
          ),
          _buildReadingProgress(),
        ],
      ),
    );
  }
}
