import 'package:artbeat_community/artbeat_community.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createCommunityProviders() => [
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
];
