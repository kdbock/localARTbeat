import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart';
import 'package:artbeat_artist/artbeat_artist.dart' as artist;
import 'package:artbeat_core/artbeat_core.dart' hide ArtworkModel;
import 'package:share_plus/share_plus.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';

/// Screen for listening to audio content (music, podcasts, audiobooks, etc.)
class AudioContentDetailScreen extends StatefulWidget {
  final String artworkId;

  const AudioContentDetailScreen({
    super.key,
    required this.artworkId,
  });

  @override
  State<AudioContentDetailScreen> createState() =>
      _AudioContentDetailScreenState();
}

class _AudioContentDetailScreenState extends State<AudioContentDetailScreen> {
  final ArtworkService _artworkService = ArtworkService();
  final artist.SubscriptionService _subscriptionService =
      artist.SubscriptionService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = true;
  ArtworkModel? _artwork;
  ArtistProfileModel? _artist;
  String? _fallbackArtistName;
  bool _isOwner = false;
  bool _hasAccess = false;

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  bool _isBuffering = false;

  @override
  void initState() {
    super.initState();
    _loadContent();
    _setupAudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlaying = state == PlayerState.playing;
        // Note: buffering state might not be available in this version
        _isBuffering = false;
      });
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() {
        _duration = duration;
      });
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() {
        _position = position;
      });
    });
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

      // Check if this is audio content
      if (artwork.contentType != ArtworkContentType.audio) {
        throw Exception('This artwork is not audio content');
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
          final userData = await FirebaseFirestore.instance
              .collection('users')
              .doc(artwork.artistProfileId)
              .get();
          _fallbackArtistName = userData.data()?['displayName'] as String?;
        }
      } catch (e) {
        // Artist info loading failed, continue without it
        debugPrint('Failed to load artist info: $e');
      }

      // Check access permissions - audio is free if not for sale or price is 0
      _hasAccess = _isOwner ||
          !artwork.isForSale ||
          artwork.price == null ||
          artwork.price == 0;

      // Load audio if accessible
      if (_hasAccess && artwork.audioUrls.isNotEmpty) {
        await _audioPlayer.setSourceUrl(artwork.audioUrls.first);
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('art_walk_error_loading_audio_content'
                  .tr()
                  .replaceAll('{error}', e.toString()))),
        );
      }
    }
  }

  Future<void> _playPause() async {
    if (_artwork?.audioUrls.isEmpty ?? true) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.resume();
    }
  }

  Future<void> _seekTo(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MainLayout(
        currentIndex: 1,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_artwork == null) {
      return MainLayout(
        currentIndex: 1,
        child: Center(
          child: Text('art_walk_audio_content_not_found'.tr()),
        ),
      );
    }

    final artwork = _artwork!;
    final artist = _artist;

    return MainLayout(
      currentIndex: 1,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with back button
            EnhancedUniversalHeader(
              title: artwork.title,
              showBackButton: true,
            ),

            // Audio content display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Album art / thumbnail
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: artwork.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(artwork.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                      color: artwork.imageUrl.isEmpty
                          ? ArtbeatColors.primaryGreen.withValues(alpha: 0.1)
                          : null,
                    ),
                    child: artwork.imageUrl.isEmpty
                        ? const Icon(
                            Icons.music_note,
                            size: 100,
                            color: ArtbeatColors.primaryGreen,
                          )
                        : null,
                  ),

                  const SizedBox(height: 32),

                  // Audio controls
                  if (_hasAccess && artwork.audioUrls.isNotEmpty) ...[
                    // Progress bar
                    Slider(
                      value: _position.inSeconds.toDouble(),
                      max: _duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        _seekTo(Duration(seconds: value.toInt()));
                      },
                    ),

                    // Time display
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_position)),
                          Text(_formatDuration(_duration)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Play/pause button
                    Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: ArtbeatColors.primaryGreen,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _playPause,
                        icon: Icon(
                          _isBuffering
                              ? Icons.hourglass_empty
                              : _isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                    ),
                  ] else ...[
                    // Access required message
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color:
                            ArtbeatColors.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.lock,
                            size: 48,
                            color: ArtbeatColors.primaryGreen,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            !artwork.isForSale ||
                                    artwork.price == null ||
                                    artwork.price == 0
                                ? 'Loading audio...'
                                : 'Purchase required to listen',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (artwork.price != null && artwork.price! > 0) ...[
                            const SizedBox(height: 8),
                            Text(
                              '\$${artwork.price!.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: ArtbeatColors.primaryGreen,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // Content details
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          artwork.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Artist
                        Row(
                          children: [
                            const Text(
                              'by ',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              artist?.displayName ??
                                  _fallbackArtistName ??
                                  'Unknown Artist',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: ArtbeatColors.primaryGreen,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Description
                        if (artwork.description.isNotEmpty) ...[
                          const Text(
                            'Description',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            artwork.description,
                            style: const TextStyle(
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Audio metadata
                        if (artwork.readingMetadata != null) ...[
                          const Text(
                            'Audio Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildMetadataRow(
                              'Format',
                              (artwork.readingMetadata!['format'] as String?) ??
                                  'Unknown'),
                          _buildMetadataRow(
                              'Duration', _formatDuration(_duration)),
                          if (artwork.readingMetadata!['fileSize'] != null) ...[
                            _buildMetadataRow('File Size',
                                '${((artwork.readingMetadata!['fileSize'] as num) / 1024 / 1024).toStringAsFixed(1)} MB'),
                          ],
                          if (artwork.readingMetadata!['bitrate'] != null) ...[
                            _buildMetadataRow('Bitrate',
                                '${artwork.readingMetadata!['bitrate']} kbps'),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Share button
                      IconButton(
                        onPressed: () => _shareArtwork(artwork),
                        icon: const Icon(Icons.share),
                        tooltip: 'Share',
                      ),

                      const SizedBox(width: 16),

                      // Favorite button (placeholder)
                      IconButton(
                        onPressed: () {
                          // TODO: Implement favorite functionality
                        },
                        icon: const Icon(Icons.favorite_border),
                        tooltip: 'Add to favorites',
                      ),

                      if (_isOwner) ...[
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () {
                            // TODO: Navigate to edit screen
                          },
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit',
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: ArtbeatColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: ArtbeatColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _shareArtwork(ArtworkModel artwork) async {
    try {
      final artistName =
          _artist?.displayName ?? _fallbackArtistName ?? 'Unknown Artist';
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Check out "${artwork.title}" by $artistName on ArtBeat!\n\n${artwork.description}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('art_walk_failed_to_share_artwork'.tr())),
        );
      }
    }
  }
}
