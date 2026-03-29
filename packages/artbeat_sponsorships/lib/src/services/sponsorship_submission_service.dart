import 'package:firebase_auth/firebase_auth.dart';

import '../models/sponsorship.dart';
import 'sponsorship_repository.dart';

class SponsorshipBusinessDefaults {
  const SponsorshipBusinessDefaults({
    required this.businessId,
    required this.businessName,
    required this.contactEmail,
  });

  final String? businessId;
  final String businessName;
  final String contactEmail;
}

class SponsorshipSubmissionService {
  SponsorshipSubmissionService({
    FirebaseAuth? auth,
    SponsorshipRepository? sponsorshipRepository,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _sponsorshipRepository =
           sponsorshipRepository ?? SponsorshipRepository();

  final FirebaseAuth _auth;
  final SponsorshipRepository _sponsorshipRepository;

  SponsorshipBusinessDefaults currentBusinessDefaults() {
    final user = _auth.currentUser;
    return SponsorshipBusinessDefaults(
      businessId: user?.uid,
      businessName: user?.displayName?.trim() ?? '',
      contactEmail: user?.email?.trim() ?? '',
    );
  }

  String? get currentBusinessId => _auth.currentUser?.uid;

  String requireCurrentBusinessId() {
    final businessId = currentBusinessId;
    if (businessId == null || businessId.isEmpty) {
      throw Exception('User not authenticated');
    }
    return businessId;
  }

  String nextSponsorshipId() => _sponsorshipRepository.nextId();

  Future<void> submitForReview(Sponsorship sponsorship) =>
      _sponsorshipRepository.createSponsorship(sponsorship);
}
