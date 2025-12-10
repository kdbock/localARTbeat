import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/ad_migration_service.dart';

/// Screen for migrating ads from old 'ads' collection to new 'localAds' collection
class AdMigrationScreen extends StatefulWidget {
  const AdMigrationScreen({Key? key}) : super(key: key);

  @override
  State<AdMigrationScreen> createState() => _AdMigrationScreenState();
}

class _AdMigrationScreenState extends State<AdMigrationScreen> {
  final AdMigrationService _migrationService = AdMigrationService();

  MigrationStats? _stats;
  MigrationResult? _lastResult;
  bool _isLoading = false;
  bool _isMigrating = false;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _migrationService.getMigrationStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Failed to load stats: $e');
    }
  }

  Future<void> _runMigration({
    bool dryRun = false,
    bool overwrite = false,
  }) async {
    setState(() => _isMigrating = true);

    try {
      final result = await _migrationService.migrateAllAds(
        dryRun: dryRun,
        overwriteExisting: overwrite,
      );

      setState(() {
        _lastResult = result;
        _isMigrating = false;
      });

      // Refresh stats after migration
      if (!dryRun) {
        await _loadStats();
      }

      _showResult(result, dryRun);
    } catch (e) {
      setState(() => _isMigrating = false);
      _showError('Migration failed: $e');
    }
  }

  void _showResult(MigrationResult result, bool dryRun) {
    final title = dryRun ? 'ads_ad_migration_text_dry_run_results'.tr() : 'ads_ad_migration_text_migration_results'.tr();
    final content =
        '''
${dryRun ? 'Dry run completed' : 'Migration completed'}!

📊 Total ads found: ${result.totalFound}
✅ ${dryRun ? 'Would migrate' : 'Migrated'}: ${result.migrated}
⏭️ Skipped: ${result.skipped}
❌ Failed: ${result.failed}

${result.hasErrors ? '\n⚠️ Errors:\n${result.errors.take(5).join('\n')}${result.errors.length > 5 ? '\n... and ${result.errors.length - 5} more' : ''}' : ''}
    ''';

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('common_ok'.tr()),
          ),
        ],
      ),
    );
  }

  Color _darkenColor(Color color) {
    // Simple color darkening by reducing the lightness
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness * 0.7).clamp(0.0, 1.0)).toColor();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ads_ad_migration_text_ad_migration'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ads_ad_migration_text_migration_statistics'.tr(),
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 16),
                          if (_stats != null) ...[
                            _buildStatRow(
                              'ads_ad_migration_text_old_collection'.tr() + ' (${_stats!.oldCollectionName})',
                              '${_stats!.oldCollectionCount} ads',
                              Colors.orange,
                            ),
                            const SizedBox(height: 8),
                            _buildStatRow(
                              'ads_ad_migration_text_new_collection'.tr() + ' (${_stats!.newCollectionName})',
                              '${_stats!.newCollectionCount} ads',
                              Colors.green,
                            ),
                            const SizedBox(height: 8),
                            _buildStatRow(
                              'ads_ad_migration_text_remaining_to_migrate'.tr(),
                              '${_stats!.oldCollectionCount - _stats!.newCollectionCount} ads',
                              Colors.blue,
                            ),
                          ] else
                            Text('ads_ad_migration_loading_loading_stats'.tr()),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Info Card
                  Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'ads_ad_migration_text_about_migration'.tr(),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(color: Colors.blue.shade700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ads_ad_migration_text_migration_description'.tr(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Text(
                    'ads_ad_migration_text_migration_actions'.tr(),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 16),

                  // Dry Run Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isMigrating
                          ? null
                          : () => _runMigration(dryRun: true),
                      icon: const Icon(Icons.preview),
                      label: Text('ads_ad_migration_text_dry_run_preview'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Migrate Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isMigrating ? null : () => _runMigration(),
                      icon: const Icon(Icons.upload),
                      label: Text('ads_ad_migration_text_migrate_ads_skip'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Overwrite Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isMigrating
                          ? null
                          : () => _showOverwriteDialog(),
                      icon: const Icon(Icons.warning),
                      label: Text('ads_ad_migration_text_migrate_ads_overwrite'.tr()),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                  if (_isMigrating) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(width: 16),
                            Text('ads_ad_migration_text_migration_in_progress'.tr()),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Last Result
                  if (_lastResult != null) ...[
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ads_ad_migration_text_last_migration_result'.tr(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            _buildStatRow(
                              'ads_ad_migration_text_total_found'.tr(),
                              '${_lastResult!.totalFound}',
                              Colors.grey,
                            ),
                            _buildStatRow(
                              'ads_ad_migration_text_migrated'.tr(),
                              '${_lastResult!.migrated}',
                              Colors.green,
                            ),
                            _buildStatRow(
                              'ads_ad_migration_text_skipped'.tr(),
                              '${_lastResult!.skipped}',
                              Colors.orange,
                            ),
                            _buildStatRow(
                              'ads_ad_migration_text_failed'.tr(),
                              '${_lastResult!.failed}',
                              Colors.red,
                            ),
                            if (_lastResult!.hasErrors) ...[
                              const SizedBox(height: 8),
                              Text(
                                'ads_ad_migration_text_errors'.tr() + ' (${_lastResult!.errors.length}):',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              ...(_lastResult!.errors
                                  .take(3)
                                  .map(
                                    (error) => Text(
                                      '• $error',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  )),
                              if (_lastResult!.errors.length > 3)
                                Text(
                                  'ads_ad_migration_text_more_errors'.tr().replaceAll('{count}', '${_lastResult!.errors.length - 3}'),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: _darkenColor(color),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  void _showOverwriteDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('ads_ad_migration_text_overwrite_warning'.tr()),
        content: Text(
          'ads_ad_migration_text_overwrite_warning'.tr(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('admin_admin_payment_text_cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runMigration(overwrite: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'ads_ad_migration_text_overwrite'.tr(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
