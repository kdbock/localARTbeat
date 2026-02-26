import 'package:flutter/material.dart';
import '../config/legal_config.dart';

/// Privacy Policy Screen
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Privacy Policy'),
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
            'ARTbeat Privacy Policy',
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
            title: '1. Introduction',
            content:
                'Local ARTbeat ("ARTbeat", "we", "our", "us") values your privacy. This Privacy Policy explains how we collect, use, store, and share your personal data when you use the ARTbeat mobile apps, websites, APIs, and related services (the "Platform").\n\nBy using ARTbeat, you agree to the practices described here. If you do not agree, you must not use the Platform.',
          ),

          _TermsSection(
            title: '2. Information We Collect',
            content:
                'a) Information You Provide:\n• Account Information: Name, email, password, ZIP/postal code.\n• Profile Information: Bio, profile photo, customization settings.\n• Artist/Gallery Information: Portfolio, subscription details, payout information.\n• Payment Information: Processed by Stripe; ARTbeat never stores full card details.\n• Content: Artwork, captures, events, ads, comments, messages.\n\nb) Information We Collect Automatically:\n• Device Information: Device type, operating system, app version, crash reports.\n• Usage Data: Logins, navigation, feature usage, interactions (favorites, likes, shares).\n• Location Data: GPS data when you use Art Walks, map features, or location-tagged captures.\n• Analytics Data: Firebase Analytics, engagement tracking, ad performance metrics.\n\nc) Information from Third Parties:\n• App Stores (Apple/Google): For app downloads, in-app purchases, refunds.\n• Social & Sharing Platforms: If you share content via external apps (e.g., Instagram, Facebook).\n• Payment Processors (Stripe): Payment confirmations, refunds, and chargeback details.',
          ),

          _TermsSection(
            title: '3. How We Use Your Information',
            content:
                'We use data to:\n• Provide and improve ARTbeat features (profiles, artwork, events, ads, community).\n• Process payments, subscriptions, and refunds.\n• Enable GPS navigation and location-based discovery.\n• Send notifications (reminders, purchases, account alerts).\n• Moderate content and enforce policies.\n• Provide analytics to artists, galleries, and advertisers.\n• Ensure safety, prevent fraud, and comply with legal requirements.',
          ),

          _TermsSection(
            title: '4. Sharing of Information',
            content:
                'We share your data only as needed:\n• With Service Providers: Stripe (payments), Firebase (storage, authentication, analytics).\n• With Other Users: Profile details, artwork, captures, events, ads, or comments you choose to make public.\n• For Moderation/Legal Compliance: To comply with DMCA, law enforcement, or platform security.\n• In Business Transfers: If ARTbeat undergoes a merger, acquisition, or asset sale.\n\nWe do not sell your personal information.',
          ),

          _TermsSection(
            title: '5. Data Retention',
            content:
                '• Content remains until deleted by you or moderated.\n• Account data is retained while your account is active.\n• You may request deletion of your account and associated data at any time.\n• Account deletion: primary user data is removed within ${LegalConfig.accountDeletionPrimaryDays} days, and backup systems are purged within ${LegalConfig.backupPurgeDays} days.\n• We retain financial/tax/legal records for up to ${LegalConfig.financialRetentionYears} years where required by law.',
          ),

          _TermsSection(
            title: '6. International Data Transfers',
            content:
                '• Data is stored in Firebase\'s global infrastructure (primarily U.S.).\n• For EU/UK residents, transfers rely on Standard Contractual Clauses (SCCs).\n• By using ARTbeat, you consent to cross-border data transfers.',
          ),

          _TermsSection(
            title: '7. Your Rights',
            content:
                'United States (CCPA/State Privacy Laws):\n• Right to know what personal data we collect.\n• Right to request deletion of your personal data.\n• Right to opt out of sale of personal data (we do not sell data).\n\nEU/EEA/UK (GDPR):\n• Right of access, rectification, and erasure.\n• Right to restrict or object to processing.\n• Right to data portability.\n• Right to withdraw consent at any time.\n• Right to lodge a complaint with your local Data Protection Authority.\n\nOther Regions:\n• We honor local legal rights where applicable.',
          ),

          _TermsSection(
            title: '8. Security',
            content:
                '• We use administrative, technical, and organizational safeguards to protect personal data.\n• Authentication, payments, and data transmission use encrypted channels supported by our service providers.\n• Access to sensitive systems is restricted based on role and operational need.\n• Despite these safeguards, no system is 100% secure—users transmit data at their own risk.',
          ),

          _TermsSection(
            title: '9. Children\'s Privacy',
            content:
                '• ARTbeat is not directed to children under 13.\n• If you are under 13, do not register.\n• Parents who believe their child has registered may request deletion via ${LegalConfig.supportEmail}.',
          ),

          _TermsSection(
            title: '10. Changes to This Policy',
            content:
                'We may update this Privacy Policy. Updates will be posted with a new Effective Date, and we will notify users where legally required.',
          ),

          _TermsSection(
            title: '11. Contact Us',
            content:
                'For questions or data requests:\n${LegalConfig.companyName}\n${LegalConfig.mailingAddress}\nEmail: ${LegalConfig.supportEmail}\n\nData rights request SLA:\n• Acknowledgment within ${LegalConfig.dataRequestAckHours} hours\n• Fulfillment target within ${LegalConfig.dataRequestFulfillmentDays} days',
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
