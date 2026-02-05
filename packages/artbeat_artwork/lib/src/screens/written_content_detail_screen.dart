import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';

/// Screen for reading written content (books, stories, etc.)
class WrittenContentDetailScreen extends StatefulWidget {
  final String artworkId;

  const WrittenContentDetailScreen({super.key, required this.artworkId});

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
  final artist.VisibilityService _visibilityService =
      artist.VisibilityService();
  final UnifiedPaymentService _paymentService = UnifiedPaymentService();
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
  bool _isAdmin = false;

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
        _scrollProgress =
            _scrollController.position.pixels /
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

      // Check if user is admin - more robust check
      try {
        final uid = currentUser?.uid ?? '';
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        final userData = userDoc.data();
        
        // Check multiple possible admin field names and values
        final userType = userData?['userType']?.toString().toLowerCase() ?? '';
        final role = userData?['role']?.toString().toLowerCase() ?? '';
        final isAdmin = userData?['isAdmin'] as bool? ?? false;
        
        _isAdmin = userType == 'admin' || role == 'admin' || isAdmin;
        AppLogger.info('🔑 Admin check for UID $uid: userType=$userType, role=$role, isAdmin=$isAdmin, result=$_isAdmin');
        AppLogger.info('📋 Full user data: $userData');
      } catch (e) {
        AppLogger.error('❌ Error checking admin status: $e');
        _isAdmin = false;
      }

      // Load artist info
      try {
        final artistProfile = await _subscriptionService.getArtistProfileById(
          artwork.artistProfileId,
        );
        _artist = artistProfile;

        // If artist profile not found, try to get user information as fallback
        if (artistProfile == null) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(artwork.artistProfileId)
              .get();
          final userData = userDoc.data();
          _fallbackArtistName =
              (userData?['fullName'] as String?) ??
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
      // Admins and owners ALWAYS bypass paywall for testing/viewing
      if (_isAdmin || _isOwner) {
        _hasAccess = true;
        AppLogger.info('✅ Access granted: admin=$_isAdmin, owner=$_isOwner');
      } else {
        // Regular users only access free content
        _hasAccess = !artwork.isForSale ||
            artwork.price == null ||
            artwork.price == 0;
        AppLogger.info('📖 Free content check: isForSale=${artwork.isForSale}, price=${artwork.price}, hasAccess=$_hasAccess');
      }
      
      AppLogger.info('Final access: _isAdmin=$_isAdmin, _isOwner=$_isOwner, isForSale=${artwork.isForSale}, price=${artwork.price}, _hasAccess=$_hasAccess');

      // Track view analytics
      await _visibilityService.trackArtworkView(
        artworkId: widget.artworkId,
        artistId: artwork.artistProfileId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'art_walk_error_loading_content'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
          ),
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
        IconButton(icon: const Icon(Icons.share), onPressed: _shareContent),
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
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: ImageUrlValidator.safeNetworkImage(
                    _artist?.profileImageUrl,
                  ),
                  child:
                      !ImageUrlValidator.isValidImageUrl(
                        _artist?.profileImageUrl,
                      )
                      ? Text(
                          (_artist?.displayName ??
                                  _fallbackArtistName ??
                                  'A')[0]
                              .toUpperCase(),
                        )
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
            if (_artwork?.writingMetadata != null) ...[
              const SizedBox(height: 16),
              _buildReadingMetadata(_artwork!.writingMetadata!),
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

  Widget _buildReadingMetadata(WritingMetadata metadata) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        if (metadata.wordCount != null)
          Chip(
            label: Text('${metadata.wordCount} words'),
            avatar: const Icon(Icons.text_fields, size: 16),
          ),
        if (metadata.estimatedReadMinutes != null)
          Chip(
            label: Text('${metadata.estimatedReadMinutes} min read'),
            avatar: const Icon(Icons.schedule, size: 16),
          ),
        if (metadata.language != null)
          Chip(
            label: Text(metadata.language!.toUpperCase()),
            avatar: const Icon(Icons.language, size: 16),
          ),
        if (metadata.genre != null)
          Chip(
            label: Text(metadata.genre!),
            avatar: const Icon(Icons.category, size: 16),
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
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${chapter.estimatedReadingTime}min',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
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

  Widget _buildChaptersPreview() {
    if (_chapters.isEmpty) {
      return SliverToBoxAdapter(child: const SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          border: Border.all(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chapters',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _chapters.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 12),
              itemBuilder: (context, index) {
                final chapter = _chapters[index];
                return Row(
                  children: [
                    if (!_hasAccess)
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.lock,
                          size: 20,
                          color: Colors.grey[400],
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chapter ${chapter.chapterNumber}: ${chapter.title}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${chapter.estimatedReadingTime}min',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                              const SizedBox(width: 12),
                              Icon(Icons.description,
                                  size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                '${chapter.wordCount} words',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_hasAccess)
                      Icon(Icons.check_circle,
                          size: 20, color: Colors.green[600]),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Only called when !_hasAccess - show purchase/chapter preview
    return SliverList(
      delegate: SliverChildListDelegate([
        _buildChaptersPreview(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                'Premium Content',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              // Purchase details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What you\'ll get:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPurchaseDetail(
                      Icons.book,
                      _artwork?.title ?? 'Book Title',
                      'Complete work',
                    ),
                    const SizedBox(height: 8),
                    if (_chapters.isNotEmpty) ...[
                      _buildPurchaseDetail(
                        Icons.layers,
                        '${_chapters.length} Chapter${_chapters.length != 1 ? 's' : ''}',
                        '${_chapters.fold<int>(0, (sum, ch) => sum + ch.wordCount)} words total',
                      ),
                      const SizedBox(height: 8),
                    ],
                    _buildPurchaseDetail(
                      Icons.schedule,
                      'Full Access',
                      'Read anytime, offline available',
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Price',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          '\$${_artwork?.price?.toStringAsFixed(2) ?? '0.00'}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _purchaseContent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(
                  'Purchase for \$${_artwork?.price?.toStringAsFixed(2) ?? '0.00'}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Secure payment via Stripe',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ]),
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
                    value:
                        (_currentChapterIndex + _scrollProgress) /
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

  Widget _buildPurchaseDetail(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blue[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _purchaseContent() async {
    if (_artwork == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final double totalAmount = (_artwork!.price ?? 0.0);

      // 1. Create payment intent on the backend
      final intentData = await _paymentService.createPaymentIntent(
        amount: totalAmount,
        currency: 'USD',
        description: 'Purchase of written content: ${_artwork!.title}',
        metadata: {
          'artworkId': widget.artworkId,
          'artistId': _artwork!.artistProfileId,
          'contentType': 'written',
        },
      );

      final String? clientSecret = intentData['clientSecret'] as String?;
      final String? paymentIntentId = intentData['paymentIntentId'] as String?;

      if (clientSecret == null || paymentIntentId == null) {
        throw Exception('Failed to initialize payment intent');
      }

      // 2. Initialize the payment sheet
      await _paymentService.initPaymentSheetForPayment(
        paymentIntentClientSecret: clientSecret,
      );

      // 3. Present the payment sheet
      await _paymentService.presentPaymentSheet();

      // 4. Complete purchase on backend
      final result = await _paymentService.processArtworkSalePayment(
        artworkId: widget.artworkId,
        artistId: _artwork!.artistProfileId,
        amount: totalAmount,
        paymentIntentId: paymentIntentId,
      );

      if (result.success) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Payment successful!')));

        // Reload content to check for updated access
        await _loadContent();
      } else {
        throw Exception(result.error ?? 'Payment verification failed');
      }
    } catch (e) {
      late final String errorMessage;
      if (e is StripeException) {
        errorMessage =
            e.error?.localizedMessage?.toString() ?? 'Payment failed';
      } else {
        errorMessage = e.toString();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Purchase failed: $errorMessage')));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.info('🎬 WrittenContentDetailScreen BUILD called: _isLoading=$_isLoading, _hasAccess=$_hasAccess, _isAdmin=$_isAdmin');
    
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
              if (_isAdmin && _artwork?.isForSale == true)
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.admin_panel_settings, 
                          size: 18, 
                          color: Colors.blue[700],
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin Preview: This is premium content (\$${_artwork?.price?.toStringAsFixed(2)}). Users will see a purchase screen.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (!_hasAccess) _buildContent(),
              if (_hasAccess) ...[
                SliverToBoxAdapter(child: const SizedBox(height: 32)),
                _buildChaptersPreview(),
                SliverPadding(
                  padding: const EdgeInsets.all(16.0),
                  sliver: SliverToBoxAdapter(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 400),
                      child: MarkdownBody(
                        data: _currentChapter?.content ?? _artwork?.description ?? '',
                        styleSheet: MarkdownStyleSheet(
                          p: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
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
                          if (href != null) {
                            // Handle link taps
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          _buildReadingProgress(),
        ],
      ),
    );
  }
}

class StripeException {
  dynamic get error => null;
}
