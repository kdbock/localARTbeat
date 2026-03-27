import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:easy_localization/easy_localization.dart';
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
      appBar: AppBar(title: Text('legal_center_title'.tr())),
      body: uid == null
          ? Center(child: Text('legal_center_sign_in_required'.tr()))
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
                    Text(
                      'legal_center_company_info_title'.tr(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'legal_center_contact'.tr(
                        namedArgs: {'email': LegalConfig.supportEmail},
                      ),
                    ),
                    Text(
                      'legal_center_dmca'.tr(
                        namedArgs: {'email': LegalConfig.dmcaEmail},
                      ),
                    ),
                    Text(
                      'legal_center_law_enforcement'.tr(
                        namedArgs: {
                          'email': LegalConfig.lawEnforcementEmail,
                        },
                      ),
                    ),
                    Text(
                      'legal_center_address'.tr(
                        namedArgs: {'address': LegalConfig.mailingAddress},
                      ),
                    ),
                    const SizedBox(height: 20),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.gavel_rounded),
                            title: Text('legal_center_terms_title'.tr()),
                            subtitle: Text(
                              'legal_center_version'.tr(
                                namedArgs: {
                                  'version':
                                      '${tos['version'] ?? LegalConfig.tosVersion}',
                                },
                              ),
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
                            title: Text('legal_center_privacy_title'.tr()),
                            subtitle: Text(
                              'legal_center_version'.tr(
                                namedArgs: {
                                  'version':
                                      '${privacy['version'] ?? LegalConfig.privacyVersion}',
                                },
                              ),
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
                      'legal_center_terms_accepted'.tr(
                        namedArgs: {
                          'timestamp': _formatTimestamp(tos['acceptedAt']),
                        },
                      ),
                    ),
                    Text(
                      'legal_center_privacy_accepted'.tr(
                        namedArgs: {
                          'timestamp': _formatTimestamp(privacy['acceptedAt']),
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'legal_center_data_rights_title'.tr(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'legal_center_acknowledgment_sla'.tr(
                        namedArgs: {
                          'hours': '${LegalConfig.dataRequestAckHours}',
                        },
                      ),
                    ),
                    Text(
                      'legal_center_fulfillment_sla'.tr(
                        namedArgs: {
                          'days':
                              '${LegalConfig.dataRequestFulfillmentDays}',
                        },
                      ),
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
    return 'legal_center_not_recorded'.tr();
  }
}
