import 'package:artbeat_sponsorships/artbeat_sponsorships.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> createSponsorshipProviders() => [
  Provider<SponsorshipCheckoutService>(
    create: (_) => SponsorshipCheckoutService(),
    lazy: true,
  ),
  Provider<SponsorshipSubmissionService>(
    create: (_) => SponsorshipSubmissionService(),
    lazy: true,
  ),
];
