/// Integration Service Usage Examples
///
/// This file demonstrates how to use the IntegrationService to handle
/// cross-package operations and resolve integration conflicts.

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:artbeat_artist/artbeat_artist.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;

class IntegrationExamples {
  /// Example 1: Check user capabilities across packages
  static Future<void> checkUserCapabilities() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final integration = IntegrationService.instance;
    final capabilities = await integration.getSubscriptionCapabilities(userId);

    core.AppLogger.info('🎯 User Capabilities:');
    debugPrint(
      '  Can access basic features: ${capabilities.canAccessBasicFeatures}',
    );
    debugPrint(
      '  Can access pro features: ${capabilities.canAccessProFeatures}',
    );
    core.AppLogger.info(
      '  Can create artwork: ${capabilities.canCreateArtwork}',
    );
    core.AppLogger.analytics(
      '  Can access analytics: ${capabilities.canAccessAnalytics}',
    );
    debugPrint(
      '  Max artwork uploads: ${capabilities.maxArtworkUploads == -1 ? "Unlimited" : capabilities.maxArtworkUploads}',
    );
    debugPrint(
      '  Preferred subscription source: ${capabilities.preferredSubscriptionSource}',
    );
  }

  /// Example 2: Get unified user data
  static Future<void> getUnifiedUserData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final integration = IntegrationService.instance;
    final unifiedData = await integration.getUnifiedArtistData(userId);

    if (unifiedData != null) {
      core.AppLogger.info('👤 Unified User Data:');
      core.AppLogger.info('  User: ${unifiedData.userModel.fullName}');
      core.AppLogger.info('  Is Artist: ${unifiedData.artistProfile != null}');
      debugPrint(
        '  Core Subscription: ${unifiedData.coreSubscription?.tier.displayName ?? "None"}',
      );
      debugPrint(
        '  Artist Subscription: ${unifiedData.artistSubscription?.tier.displayName ?? "None"}',
      );
    }
  }

  /// Example 3: Enable artist features for a user
  static Future<void> enableArtistFeatures() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final integration = IntegrationService.instance;
    final success = await integration.enableArtistFeatures(userId);

    if (success) {
      core.AppLogger.info('✅ Artist features enabled successfully!');
    } else {
      core.AppLogger.error('❌ Failed to enable artist features');
    }
  }

  /// Example 4: Get subscription recommendations
  static Future<void> getRecommendations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final integration = IntegrationService.instance;
    final recommendation = await integration.getSubscriptionRecommendation(
      userId,
    );

    core.AppLogger.info('💡 Recommendation:');
    core.AppLogger.info('  Type: ${recommendation.type}');
    core.AppLogger.info('  Title: ${recommendation.title}');
    core.AppLogger.info('  Description: ${recommendation.description}');
  }

  /// Example 5: Migration from old ArtistService
  static Future<void> migrateArtistService() async {
    // OLD WAY (DEPRECATED)
    /*
    import 'package:artbeat_artist/artbeat_artist.dart' as artist;
    final oldService = artist.ArtistService();
    final artists = await oldService.getFeaturedArtists(); // DEPRECATED
    */

    // NEW WAY (RECOMMENDED)
    final newService = core.ArtistService(); // From artbeat_core
    final artists = await newService.getFeaturedArtistProfiles(); // Enhanced!

    core.AppLogger.info('🔄 Migration complete:');
    core.AppLogger.info('  Found ${artists.length} featured artists');
    core.AppLogger.info('  Using enhanced search functionality');
  }

  /// Example 6: Widget example showing integration usage
  static Widget buildCapabilityWidget() {
    return FutureBuilder<SubscriptionCapabilities>(
      future: _getUserCapabilities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }

        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        final capabilities = snapshot.data;
        if (capabilities == null) {
          return const Text('Unable to load capabilities');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCapabilityTile(
              'Analytics Access',
              capabilities.canAccessAnalytics,
            ),
            _buildCapabilityTile(
              'Artwork Creation',
              capabilities.canCreateArtwork,
            ),
            _buildCapabilityTile(
              'Event Management',
              capabilities.canCreateEvents,
            ),
            _buildCapabilityTile(
              'Gallery Management',
              capabilities.canManageGallery,
            ),
            if (capabilities.maxArtworkUploads > 0)
              ListTile(
                title: const Text('Upload Limit'),
                subtitle: Text(
                  capabilities.maxArtworkUploads == -1
                      ? 'Unlimited'
                      : '${capabilities.maxArtworkUploads} artworks',
                ),
                leading: const Icon(Icons.cloud_upload),
              ),
          ],
        );
      },
    );
  }

  static Widget _buildCapabilityTile(String title, bool hasAccess) {
    return ListTile(
      title: Text(title),
      leading: Icon(
        hasAccess ? Icons.check_circle : Icons.cancel,
        color: hasAccess ? Colors.green : Colors.red,
      ),
      subtitle: Text(hasAccess ? 'Available' : 'Not available'),
    );
  }

  static Future<SubscriptionCapabilities> _getUserCapabilities() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      return SubscriptionCapabilities.none();
    }

    final integration = IntegrationService.instance;
    return integration.getSubscriptionCapabilities(userId);
  }

  /// Example 7: Advanced usage - Custom recommendation handler
  static Future<void> handleRecommendationAction(BuildContext context) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final integration = IntegrationService.instance;
    final recommendation = await integration.getSubscriptionRecommendation(
      userId,
    );

    switch (recommendation.type) {
      case 'enable-artist':
        final shouldEnable = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (context) => AlertDialog(
            title: Text(recommendation.title),
            content: Text(recommendation.description),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enable'),
              ),
            ],
          ),
        );

        if (shouldEnable == true && recommendation.action != null) {
          final success = await recommendation.action!();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  success
                      ? 'Artist features enabled!'
                      : 'Failed to enable artist features',
                ),
                backgroundColor: success ? Colors.green : Colors.red,
              ),
            );
          }
        }
        break;

      case 'upgrade-pro':
        // Navigate to subscription screen
        // Navigator.push(context, MaterialPageRoute(...));
        break;

      case 'none':
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You have all available features!')),
        );
        break;
    }
  }
}

/// Example 8: Complete integration workflow
class IntegrationWorkflowExample extends StatefulWidget {
  const IntegrationWorkflowExample({super.key});

  @override
  State<IntegrationWorkflowExample> createState() =>
      _IntegrationWorkflowExampleState();
}

class _IntegrationWorkflowExampleState
    extends State<IntegrationWorkflowExample> {
  final integration = IntegrationService.instance;
  UnifiedArtistData? unifiedData;
  SubscriptionCapabilities? capabilities;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final data = await integration.getUnifiedArtistData(userId);
      final caps = await integration.getSubscriptionCapabilities(userId);

      setState(() {
        unifiedData = data;
        capabilities = caps;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Integration Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfoSection(),
            const Divider(height: 32),
            _buildCapabilitiesSection(),
            const Divider(height: 32),
            _buildActionsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoSection() {
    if (unifiedData == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No user data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text('Name: ${unifiedData!.userModel.fullName}'),
            Text('Email: ${unifiedData!.userModel.email}'),
            Text('Is Artist: ${unifiedData!.artistProfile != null}'),
            if (unifiedData!.artistProfile != null)
              Text(
                'Artist Display Name: ${unifiedData!.artistProfile!.displayName}',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesSection() {
    if (capabilities == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No capabilities data available'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capabilities',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            _buildCapabilityRow(
              'Basic Features',
              capabilities!.canAccessBasicFeatures,
            ),
            _buildCapabilityRow(
              'Pro Features',
              capabilities!.canAccessProFeatures,
            ),
            _buildCapabilityRow(
              'Create Artwork',
              capabilities!.canCreateArtwork,
            ),
            _buildCapabilityRow(
              'Analytics Access',
              capabilities!.canAccessAnalytics,
            ),
            _buildCapabilityRow(
              'Gallery Management',
              capabilities!.canManageGallery,
            ),
            Text(
              'Max Uploads: ${capabilities!.maxArtworkUploads == -1 ? "Unlimited" : capabilities!.maxArtworkUploads}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityRow(String label, bool hasCapability) {
    return Row(
      children: [
        Icon(
          hasCapability ? Icons.check_circle : Icons.cancel,
          color: hasCapability ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _enableArtistFeatures,
              child: const Text('Enable Artist Features'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _showRecommendations,
              child: const Text('Get Recommendations'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _refreshData,
              child: const Text('Refresh Data'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _enableArtistFeatures() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final success = await integration.enableArtistFeatures(userId);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Artist features enabled!'
                : 'Failed to enable artist features',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );

      if (success) {
        _refreshData();
      }
    }
  }

  Future<void> _showRecommendations() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final recommendation = await integration.getSubscriptionRecommendation(
      userId,
    );

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(recommendation.title),
          content: Text(recommendation.description),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      isLoading = true;
    });
    await _loadData();
  }
}
