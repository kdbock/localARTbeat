import 'package:artbeat_core/artbeat_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SponsorArtSelectionWidget extends StatefulWidget {
  const SponsorArtSelectionWidget({
    super.key,
    required this.selectedArtIds,
    required this.onSelectionChanged,
  });

  final List<String> selectedArtIds;
  final void Function(List<String>) onSelectionChanged;

  @override
  State<SponsorArtSelectionWidget> createState() =>
      _SponsorArtSelectionWidgetState();
}

class _SponsorArtSelectionWidgetState extends State<SponsorArtSelectionWidget> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<_CaptureOption> _allCaptures = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadArt();
  }

  Future<void> _loadArt() async {
    try {
      final captures = await _fetchCaptureOptions();
      if (mounted) {
        setState(() {
          _allCaptures = captures;
          _isLoading = false;
        });
      }
    } on Exception catch (error, stackTrace) {
      AppLogger.warning(
        'SponsorArtSelectionWidget failed to load capture options.',
        logger: 'Sponsorships',
        error: error,
        stackTrace: stackTrace,
      );
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredCaptures = _allCaptures.where((capture) {
      final query = _searchQuery.toLowerCase();
      return capture.title.toLowerCase().contains(query) ||
          capture.artistName.toLowerCase().contains(query) ||
          capture.locationName.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: (value) => setState(() => _searchQuery = value),
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search for art pieces...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.75)),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.white.withValues(alpha: 0.85),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: filteredCaptures.length,
            itemBuilder: (context, index) {
              final capture = filteredCaptures[index];
              final isSelected = widget.selectedArtIds.contains(capture.id);

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: CheckboxListTile(
                    value: isSelected,
                    activeColor: const Color(0xFF22D3EE),
                    checkColor: Colors.black,
                    onChanged: (value) {
                      final newSelection = List<String>.from(
                        widget.selectedArtIds,
                      );
                      if (value ?? false) {
                        newSelection.add(capture.id);
                      } else {
                        newSelection.remove(capture.id);
                      }
                      widget.onSelectionChanged(newSelection);
                    },
                    title: Text(
                      capture.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${capture.artistName} • ${capture.locationName}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                    ),
                    secondary: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        capture.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported),
                      ),
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

  Future<List<_CaptureOption>> _fetchCaptureOptions() async {
    QuerySnapshot<Map<String, dynamic>> snapshot;

    try {
      snapshot = await _firestore
          .collection('captures')
          .where('isPublic', isEqualTo: true)
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .limit(150)
          .get();
    } on Exception {
      // Fallback for missing index or legacy data shape.
      snapshot = await _firestore
          .collection('captures')
          .where('isPublic', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(150)
          .get();
    }

    final options = snapshot.docs
        .map(_CaptureOption.fromDoc)
        .where((option) => option.imageUrl.isNotEmpty)
        .toList();

    return options;
  }
}

class _CaptureOption {
  const _CaptureOption({
    required this.id,
    required this.title,
    required this.artistName,
    required this.locationName,
    required this.imageUrl,
  });

  factory _CaptureOption.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final title = (data['title'] as String?)?.trim();
    final artistName = (data['artistName'] as String?)?.trim();
    final locationName =
        ((data['locationName'] as String?) ??
                (data['address'] as String?) ??
                (data['locationLabel'] as String?))
            ?.trim();
    final imageUrl =
        ((data['imageUrl'] as String?) ??
                (data['thumbnailUrl'] as String?) ??
                '')
            .trim();

    return _CaptureOption(
      id: doc.id,
      title: (title?.isNotEmpty ?? false) ? title! : 'Untitled Capture',
      artistName: (artistName?.isNotEmpty ?? false)
          ? artistName!
          : 'Unknown Artist',
      locationName: (locationName?.isNotEmpty ?? false)
          ? locationName!
          : 'Unknown Location',
      imageUrl: imageUrl,
    );
  }

  final String id;
  final String title;
  final String artistName;
  final String locationName;
  final String imageUrl;
}
