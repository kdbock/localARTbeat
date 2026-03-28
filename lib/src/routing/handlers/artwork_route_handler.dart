import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:flutter/material.dart';

import '../../screens/artwork_auction_management_route_screen.dart';
import '../route_utils.dart';

class ArtworkRouteHandler {
  const ArtworkRouteHandler();

  Route<dynamic>? handleRoute(RouteSettings settings) {
    switch (settings.name) {
      case core.AppRoutes.artworkUpload:
      case core.AppRoutes.artworkUploadChoice:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.UploadChoiceScreen(),
        );

      case core.AppRoutes.artworkUploadVisual:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.EnhancedArtworkUploadScreen(),
        );

      case core.AppRoutes.artworkUploadWritten:
        return RouteUtils.createMainLayoutRoute(
          child: const artwork.WrittenContentUploadScreen(),
        );

      case core.AppRoutes.artworkBrowse:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      case core.AppRoutes.artworkEdit:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        final artworkModel = RouteUtils.getArgument<artwork.ArtworkModel>(
          settings,
          'artwork',
        );
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkEditScreen(
            artworkId: artworkId,
            artwork: artworkModel,
          ),
        );

      case core.AppRoutes.artworkDetail:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkDetailScreen(artworkId: artworkId),
        );

      case core.AppRoutes.artworkAuctionSetup:
        final modeName = RouteUtils.getArgument<String>(settings, 'mode');
        final mode = modeName == 'editing'
            ? artwork.AuctionSetupMode.editing
            : artwork.AuctionSetupMode.firstTime;
        return RouteUtils.createSimpleRoute(
          child: artwork.AuctionSetupWizardScreen(mode: mode),
        );

      case core.AppRoutes.artworkAuctionManage:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute('Artwork not found');
        }
        return RouteUtils.createSimpleRoute(
          child: ArtworkAuctionManagementRouteScreen(artworkId: artworkId),
        );

      case '/artwork/written-content':
        final writtenContentId = settings.arguments as String?;
        if (writtenContentId == null) {
          return RouteUtils.createErrorRoute('Written content not found');
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.WrittenContentDetailScreen(
            artworkId: writtenContentId,
          ),
        );

      case core.AppRoutes.artworkPurchase:
        final artworkId = RouteUtils.getArgument<String>(settings, 'artworkId');
        if (artworkId == null) {
          return RouteUtils.createErrorRoute(
            'Artwork ID required for purchase',
          );
        }
        return RouteUtils.createSimpleRoute(
          child: artwork.ArtworkPurchaseScreen(artworkId: artworkId),
        );

      case core.AppRoutes.artworkFeatured:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkFeaturedScreen(),
        );

      case core.AppRoutes.artworkRecent:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkRecentScreen(),
        );

      case core.AppRoutes.artworkTrending:
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkTrendingScreen(),
        );

      case core.AppRoutes.artworkSearch:
        final searchQuery = RouteUtils.getArgument<String>(settings, 'query');
        return RouteUtils.createSimpleRoute(
          child: artwork.AdvancedArtworkSearchScreen(initialQuery: searchQuery),
        );

      case '/artwork/local':
      case '/artwork/discovery':
        return RouteUtils.createSimpleRoute(
          child: const artwork.ArtworkBrowseScreen(),
        );

      default:
        return RouteUtils.createNotFoundRoute('Artwork feature');
    }
  }
}
