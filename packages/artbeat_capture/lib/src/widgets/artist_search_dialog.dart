import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' show ArtistModel, ArtistService, ImageUrlValidator;

class ArtistSearchDialog extends StatefulWidget {
  final void Function(ArtistModel) onArtistSelected;

  const ArtistSearchDialog({super.key, required this.onArtistSelected});

  @override
  State<ArtistSearchDialog> createState() => _ArtistSearchDialogState();
}

class _ArtistSearchDialogState extends State<ArtistSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  final ArtistService _artistService = ArtistService();
  List<ArtistModel> _artists = [];
  bool _isLoading = false;
  bool _showAddNew = false;

  @override
  void initState() {
    super.initState();
    _searchArtists('');
  }

  Future<void> _searchArtists(String query) async {
    setState(() {
      _isLoading = true;
      _showAddNew = false;
    });

    try {
      final artists = await _artistService.searchArtists(query);
      setState(() {
        _artists = artists;
        _showAddNew = query.isNotEmpty && artists.isEmpty;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_artist_search_error_searching'.tr().replaceAll(
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

  Future<void> _addNewArtist(String name) async {
    setState(() => _isLoading = true);

    try {
      final artist = await _artistService.createArtist(name);
      if (mounted) {
        widget.onArtistSelected(artist);
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'capture_artist_search_error_creating'.tr().replaceAll(
                '{error}',
                e.toString(),
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'capture_artist_search_title'.tr(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search artists...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (value) => _searchArtists(value),
              textInputAction: TextInputAction.search,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_artists.isEmpty && !_showAddNew)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'capture_artist_search_no_results'.tr(),
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ..._artists.map(
                      (artist) => Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: ImageUrlValidator.safeNetworkImage(
                              artist.profileImageUrl,
                            ),
                            child:
                                !ImageUrlValidator.isValidImageUrl(
                                  artist.profileImageUrl,
                                )
                                ? const Icon(Icons.person)
                                : null,
                          ),
                          title: Text(
                            artist.name,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: artist.isVerified
                              ? Row(
                                  children: [
                                    Icon(
                                      Icons.verified,
                                      size: 16,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'capture_artist_search_verified_label'
                                          .tr(),
                                    ),
                                  ],
                                )
                              : null,
                          onTap: () {
                            widget.onArtistSelected(artist);
                            Navigator.of(context).pop();
                          },
                        ),
                      ),
                    ),
                    if (_showAddNew)
                      Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Theme.of(context).primaryColor,
                            child: const Icon(Icons.add, color: Colors.white),
                          ),
                          title: Text(
                            'capture_artist_search_add_new'.tr().replaceAll(
                              '{artistName}',
                              _searchController.text,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text(
                            'capture_artist_search_create_profile'.tr(),
                          ),
                          onTap: () => _addNewArtist(_searchController.text),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
