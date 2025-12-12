import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/migration_service.dart';

/// Screen for managing data migration to standardized moderation status
class MigrationScreen extends StatefulWidget {
  const MigrationScreen({super.key});

  @override
  State<MigrationScreen> createState() => _MigrationScreenState();
}

class _MigrationScreenState extends State<MigrationScreen> {
  final MigrationService _migrationService = MigrationService();

  Map<String, MigrationStatus>? _migrationStatus;
  bool _isLoading = false;
  bool _isMigrating = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _checkMigrationStatus();
  }

  Future<void> _checkMigrationStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final status = await _migrationService.checkMigrationStatus();
      setState(() {
        _migrationStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'admin_migration_error_check_status_failed'.tr(namedArgs: {'error': e.toString()});
        _isLoading = false;
      });
    }
  }

  Future<void> _runMigration() async {
    final confirmed = await _showConfirmationDialog(
      'admin_migration_dialog_run_migration_title'.tr(),
      'admin_migration_dialog_run_migration_message'.tr(),
    );

    if (!confirmed) return;

    setState(() {
      _isMigrating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _migrationService.migrateAllCollections();
      setState(() {
        _successMessage = 'admin_migration_success_completed'.tr();
        _isMigrating = false;
      });

      // Refresh status
      await _checkMigrationStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'admin_migration_error_failed'.tr(namedArgs: {'error': e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<void> _rollbackMigration() async {
    final confirmed = await _showConfirmationDialog(
      'admin_migration_dialog_rollback_title'.tr(),
      'admin_migration_dialog_rollback_message'.tr(),
    );

    if (!confirmed) return;

    setState(() {
      _isMigrating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _migrationService.rollbackMigration();
      setState(() {
        _successMessage = 'admin_migration_success_rollback_completed'.tr();
        _isMigrating = false;
      });

      // Refresh status
      await _checkMigrationStatus();
    } catch (e) {
      setState(() {
        _errorMessage = 'admin_migration_error_rollback_failed'.tr(namedArgs: {'error': e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<void> _migrateGeoFields() async {
    final confirmed = await _showConfirmationDialog(
      'admin_migration_dialog_geo_title'.tr(),
      'admin_migration_dialog_geo_message'.tr(),
    );

    if (!confirmed) return;

    setState(() {
      _isMigrating = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _migrationService.migrateCapturesGeoField();
      setState(() {
        _successMessage = 'admin_migration_success_geo_completed'.tr();
        _isMigrating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'admin_migration_error_geo_failed'.tr(namedArgs: {'error': e.toString()});
        _isMigrating = false;
      });
    }
  }

  Future<bool> _showConfirmationDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('admin_admin_payment_text_cancel'.tr()),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('admin_migration_text_confirm'.tr()),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('admin_migration_text_data_migration'.tr()),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed:
                _isLoading || _isMigrating ? null : _checkMigrationStatus,
            icon: const Icon(Icons.refresh),
            tooltip: 'admin_migration_tooltip_refresh'.tr(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'admin_migration_section_title'.tr(),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This migration adds standardized moderation status fields to all content collections (posts, comments, artwork, captures, ads). '
                      'Existing content will be marked as "approved" by default.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status Messages
            if (_errorMessage != null)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            if (_successMessage != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Migration Status
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _migrationStatus == null
                      ? Center(
                          child: Text('admin_migration_error_failed_to_load'.tr()))
                      : _buildMigrationStatusList(),
            ),

            // Action Buttons
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isMigrating || _isLoading ? null : _runMigration,
                    icon: _isMigrating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.play_arrow),
                    label:
                        Text(_isMigrating ? 'Migrating...' : 'Run Migration'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        _isMigrating || _isLoading ? null : _rollbackMigration,
                    icon: const Icon(Icons.undo),
                    label: Text('admin_migration_text_rollback'.tr()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Geo Field Migration Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    _isMigrating || _isLoading ? null : _migrateGeoFields,
                icon: const Icon(Icons.location_on),
                label: Text('admin_migration_text_migrate_geo_fields'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMigrationStatusList() {
    final collections = _migrationStatus!.entries.toList();

    return ListView.builder(
      itemCount: collections.length,
      itemBuilder: (context, index) {
        final entry = collections[index];
        final status = entry.value;

        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: status.needsMigration
                  ? Colors.orange[100]
                  : Colors.green[100],
              child: Icon(
                status.needsMigration ? Icons.warning : Icons.check_circle,
                color: status.needsMigration
                    ? Colors.orange[700]
                    : Colors.green[700],
              ),
            ),
            title: Text(
              status.collectionName.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${status.migratedDocuments}/${status.totalDocuments} documents migrated',
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: status.migrationProgress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    status.needsMigration ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            trailing: Text(
              '${(status.migrationProgress * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: status.needsMigration
                    ? Colors.orange[700]
                    : Colors.green[700],
              ),
            ),
          ),
        );
      },
    );
  }
}
