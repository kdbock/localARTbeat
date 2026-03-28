import 'package:artbeat_community/artbeat_community.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:artbeat_messaging/artbeat_messaging.dart' as messaging;
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createCommunityMessagingProviders() => [
  ChangeNotifierProvider<messaging.ChatService>(
    create: (_) => messaging.ChatService(),
    lazy: true,
  ),
  Provider<core.MessagingStatusService>(
    create: (_) => core.MessagingStatusService(),
    lazy: true,
  ),
  ChangeNotifierProvider<messaging.MessageReactionService>(
    create: (_) => messaging.MessageReactionService(),
    lazy: true,
  ),
  ChangeNotifierProvider<core.MessagingProvider>(
    create: (context) =>
        core.MessagingProvider(context.read<core.MessagingStatusService>()),
    lazy: true,
  ),
  Provider<messaging.PresenceService>(
    create: (_) => messaging.PresenceService(),
    lazy: false,
  ),
  ChangeNotifierProvider<messaging.PresenceProvider>(
    create: (context) =>
        messaging.PresenceProvider(context.read<messaging.PresenceService>()),
    lazy: false,
  ),
  ChangeNotifierProvider<CommunityService>(
    create: (_) => CommunityService(),
    lazy: true,
  ),
  ChangeNotifierProvider<ArtCommunityService>(
    create: (_) => ArtCommunityService(),
    lazy: true,
  ),
  Provider<CommunitySocialActivityService>(
    create: (_) => CommunitySocialActivityService(),
    lazy: true,
  ),
  Provider<DirectCommissionService>(
    create: (_) => DirectCommissionService(),
    lazy: true,
  ),
  Provider<StripeService>(create: (_) => StripeService(), lazy: true),
];
