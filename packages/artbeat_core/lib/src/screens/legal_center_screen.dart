import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../config/legal_config.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class LegalCenterScreen extends StatelessWidget {
  const LegalCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Legal Center')),
      body: uid == null
          ? const Center(child: Text('Sign in to view consent records.'))
          : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get(),
              builder: (context, snapshot) {
                final data = snapshot.data?.data();
                final legalConsents =
                    (data?['legalConsents'] as Map<String, dynamic>?) ?? {};
                final tos =
                    (legalConsents['termsOfService']
                        as Map<String, dynamic>?) ??
                    {};
                final privacy =
                    (legalConsents['privacyPolicy'] as Map<String, dynamic>?) ??
                    {};

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Local ARTbeat, LLC Legal Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Contact: ${LegalConfig.supportEmail}'),
                    const Text('Address: ${LegalConfig.mailingAddress}'),
                    const SizedBox(height: 20),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.gavel_rounded),
                            title: const Text('Terms of Service'),
                            subtitle: Text(
                              'Version: ${tos['version'] ?? LegalConfig.tosVersion}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const TermsOfServiceScreen(),
                                ),
                              );
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.privacy_tip_outlined),
                            title: const Text('Privacy Policy'),
                            subtitle: Text(
                              'Version: ${privacy['version'] ?? LegalConfig.privacyVersion}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => const PrivacyPolicyScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Terms accepted: ${_formatTimestamp(tos['acceptedAt'])}',
                    ),
                    Text(
                      'Privacy accepted: ${_formatTimestamp(privacy['acceptedAt'])}',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Data Rights SLA',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const Text(
                      'Acknowledgment: within ${LegalConfig.dataRequestAckHours} hours',
                    ),
                    const Text(
                      'Fulfillment target: within ${LegalConfig.dataRequestFulfillmentDays} days',
                    ),
                  ],
                );
              },
            ),
    );
  }

  static String _formatTimestamp(dynamic rawTimestamp) {
    if (rawTimestamp is Timestamp) {
      return rawTimestamp.toDate().toLocal().toString();
    }
    return 'Not recorded';
  }
}
