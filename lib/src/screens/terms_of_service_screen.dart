import 'package:artbeat_core/artbeat_core.dart' show LegalConfig;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Terms of Service Screen
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('common_terms_of_service'.tr()),
      backgroundColor: Theme.of(context).primaryColor,
      foregroundColor: Colors.white,
    ),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // ignore: unnecessary_const
        children: const [
          Text(
            'ARTbeat Terms of Service',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Effective Date: ${LegalConfig.effectiveDate}',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          Text(
            'Last Updated: ${LegalConfig.lastUpdatedDate}',
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          SizedBox(height: 24),

          _TermsSection(
            title: '1. Acceptance of Terms',
            content:
                'By accessing or using ARTbeat (the "Platform"), you agree to these Terms of Service ("Terms"). If you do not agree, you must not use ARTbeat. These Terms apply worldwide, subject to local laws where expressly required.',
          ),

          _TermsSection(
            title: '2. Eligibility',
            content:
                'You must be at least 13 years old (or the minimum digital consent age in your country).\n\nIf you are under 18, you may use the Platform only with the consent of a parent or guardian.\n\nBecause ARTbeat may contain artistic nudity and mature artistic subject matter, ARTbeat is recommended for users 18 and older.\n\nBy registering, you confirm that the information provided is accurate and up-to-date.',
          ),

          _TermsSection(
            title: '3. Accounts & Registration',
            content:
                'Users must provide a valid name, email, password, and ZIP code during registration.\n\nYou are responsible for maintaining the security of your account, including enabling two-factor authentication where available.\n\nARTbeat may suspend or terminate accounts that violate these Terms.',
          ),

          _TermsSection(
            title: '4. User Types & Roles',
            content:
                'Regular Users: May browse, follow, favorite, and engage with content.\n\nArtists: May upload artwork, manage profiles, sell work, host events, and access subscription tiers.\n\nGalleries: Manage multiple artists, exhibitions, and commissions.\n\nModerators/Admins: Enforce policies, moderate content, and manage the platform.',
          ),

          _TermsSection(
            title: '5. User Content & Intellectual Property',
            content:
                'You retain ownership of artwork, captures, events, and other content you upload.\n\nBy posting, you grant ARTbeat a worldwide, non-exclusive, royalty-free license to store, display, distribute, and promote your content for Platform operation and marketing.\n\nYou may only upload content you own or have the legal right to use.\n\nARTbeat may remove allegedly infringing content, process copyright complaints, request additional information, and terminate repeat infringers.\n\nContent must comply with community standards, including rules against harassment, doxxing, impersonation, scams, unlawful materials, non-consensual imagery, child sexual abuse material, and pornography.',
          ),

          _TermsSection(
            title: '6. Payments & Subscriptions',
            content:
                'Payments are processed via Stripe.\n\nSubscription tiers, ads, events, and in-app purchases are billed in local currency where supported.\n\nAll purchases are final and non-refundable, except where refunds are required by law or platform store policy.\n\nUsers must provide accurate billing information; fraudulent activity may result in termination.',
          ),

          _TermsSection(
            title: '7. Advertising & Sponsorship',
            content:
                'Ads must comply with community and legal standards.\n\nARTbeat reserves the right to reject or remove ads at its discretion.\n\nAd performance analytics are aggregated and anonymized.',
          ),

          _TermsSection(
            title: '8. Events & Ticketing',
            content:
                'Artists and galleries may create public or private events.\n\nTickets (free, paid, VIP) are sold through Stripe.\n\nFor app-level billing or platform processing issues, ARTbeat may investigate and resolve the issue.\n\nFor creator-run auctions, commissions, sales, and event disputes, the creator or host is primarily responsible for fulfillment, policies, and dispute handling unless ARTbeat states otherwise in writing.',
          ),

          _TermsSection(
            title: '9. Messaging & Community Conduct',
            content:
                'Messaging is provided for personal and professional communication.\n\nUsers must not engage in spam, harassment, stalking, doxxing, impersonation, illegal solicitation, off-platform scam solicitation, non-consensual sexual content, or unauthorized data collection.\n\nARTbeat does not read private messages by default, but admins and moderators may review reported threads, attachments, and directly related metadata when investigating abuse, safety, or policy violations.',
          ),

          _TermsSection(
            title: '10. Location-Based Features',
            content:
                'Features such as Art Walks rely on GPS and mapping.\n\nYou consent to ARTbeat\'s use of your location data to provide navigation, recommendations, and achievements.\n\nUsers under 18 may have location sharing and public discovery features limited or disabled.\n\nARTbeat is not responsible for accidents, injuries, or damages during real-world activities, including travel to events, public art locations, or user-organized meetups.',
          ),

          _TermsSection(
            title: '11. Privacy & Data Use',
            content:
                'ARTbeat complies with GDPR (EU), CCPA (California), and other applicable data protection laws.\n\nUsers may request data export or deletion via the Privacy Settings Screen.\n\nData may be transferred internationally; by using ARTbeat, you consent to such transfers.',
          ),

          _TermsSection(
            title: '12. Moderation & Enforcement',
            content:
                'ARTbeat reserves the right to remove content, restrict features, revoke access to abused sections of the Platform, suspend accounts, or permanently ban users at its discretion.\n\nUsers may appeal moderation actions by contacting ${LegalConfig.supportEmail}.\n\nRepeated violations, severe safety violations, copyright abuse, child safety violations, or fraudulent behavior may result in immediate permanent account termination.',
          ),

          _TermsSection(
            title: '13. Prohibited Uses',
            content:
                'You may not:\n\n• Upload unlawful, infringing, defamatory, or harmful content.\n• Harass, stalk, threaten, exploit, or dox other people.\n• Post pornography, child sexual abuse material, or non-consensual sexual imagery.\n• Use ARTbeat for unauthorized advertising, off-platform scams, or pyramid schemes.\n• Circumvent security systems or attempt to reverse-engineer the app.\n• Impersonate others or misrepresent affiliation.',
          ),

          _TermsSection(
            title: '14. International Use',
            content:
                'The Platform is operated from the United States.\n\nUsers outside the US are responsible for compliance with local laws and regulations.\n\nCertain features (payments, ticketing, ads) may not be available in all jurisdictions.',
          ),

          _TermsSection(
            title: '15. Limitation of Liability',
            content:
                'ARTbeat is provided "as is" and "as available".\n\nARTbeat is not liable for:\n• User disputes (artist-patron, buyer-seller).\n• Real-world accidents during events or art walks.\n• Payment processing errors outside ARTbeat\'s control.',
          ),

          _TermsSection(
            title: '16. Indemnification',
            content:
                'You agree to indemnify and hold harmless ARTbeat, its affiliates, employees, and partners from claims, damages, or expenses arising from your use of the Platform.',
          ),

          _TermsSection(
            title: '17. Termination',
            content:
                'You may terminate your account at any time via the Account Settings Screen.\n\nARTbeat may terminate accounts for violations of these Terms.\n\nCertain provisions (IP rights, liability, jurisdiction) survive termination.',
          ),

          _TermsSection(
            title: '18. Governing Law & Dispute Resolution',
            content:
                'For US users: governed by the laws of ${LegalConfig.governingState}, ${LegalConfig.governingCountry}.\n\nFor international users: governed by applicable mandatory local law, otherwise ${LegalConfig.governingState} law applies.\n\nDisputes shall be resolved through binding arbitration in the United States, unless prohibited by law.\n\nTO THE MAXIMUM EXTENT PERMITTED BY LAW, YOU AND ARTbeat AGREE TO BRING CLAIMS ONLY IN AN INDIVIDUAL CAPACITY AND NOT AS A PLAINTIFF OR CLASS MEMBER IN ANY PURPORTED CLASS OR REPRESENTATIVE ACTION.',
          ),

          _TermsSection(
            title: '19. Changes to Terms',
            content:
                'ARTbeat may update these Terms from time to time. Notice will be provided via app notification or email. Continued use of the Platform constitutes acceptance of changes.',
          ),

          _TermsSection(
            title: '20. Contact',
            content:
                'Questions or complaints may be directed to:\n${LegalConfig.companyName}\n${LegalConfig.mailingAddress}\nGeneral support: ${LegalConfig.supportEmail}\nCopyright / DMCA: ${LegalConfig.dmcaEmail}\nLaw enforcement requests: ${LegalConfig.lawEnforcementEmail}',
          ),

          SizedBox(height: 32),
        ],
      ),
    ),
  );
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        Text(content, style: const TextStyle(fontSize: 14, height: 1.5)),
      ],
    ),
  );
}
