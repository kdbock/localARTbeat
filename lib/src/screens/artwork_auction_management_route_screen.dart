import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:flutter/material.dart';

class ArtworkAuctionManagementRouteScreen extends StatefulWidget {
  const ArtworkAuctionManagementRouteScreen({
    super.key,
    required this.artworkId,
  });

  final String artworkId;

  @override
  State<ArtworkAuctionManagementRouteScreen> createState() =>
      _ArtworkAuctionManagementRouteScreenState();
}

class _ArtworkAuctionManagementRouteScreenState
    extends State<ArtworkAuctionManagementRouteScreen> {
  final artwork.ArtworkService _artworkService = artwork.ArtworkService();
  bool _opened = false;

  @override
  Widget build(BuildContext context) => FutureBuilder<artwork.ArtworkModel?>(
    future: _artworkService.getArtworkById(widget.artworkId),
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }

      final artworkModel = snapshot.data;
      if (artworkModel == null) {
        return const Scaffold(body: Center(child: Text('Artwork not found')));
      }

      if (!_opened) {
        _opened = true;
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          final result = await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) =>
                artwork.AuctionManagementModal(artwork: artworkModel),
          );
          if (!context.mounted) return;
          Navigator.of(context).pop(result);
        });
      }

      return const Scaffold(body: SizedBox.shrink());
    },
  );
}
