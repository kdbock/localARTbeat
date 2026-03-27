import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_artist_features_app.dart';

/// Debug menu for accessing development and testing features
class DebugMenu extends StatelessWidget {
  const DebugMenu({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('🛠️ Debug Menu'),
      backgroundColor: Colors.grey[800],
      foregroundColor: Colors.white,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔧 Development Tools',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tools for testing and debugging app features',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Artist Features Test
          Card(
            child: ListTile(
              leading: const Icon(Icons.science, color: Colors.blue, size: 32),
              title: const Text(
                'Artist Features Test',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text(
                'Verify all subscription tier features work properly\n2025 optimization validation',
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) => const ArtistFeatureTestApp(),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Firebase Debug
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud, color: Colors.orange, size: 32),
              title: const Text(
                'Firebase Debug',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Check Firebase connection and data access'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () async {
                await _showFirebaseDebug(context);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Clear Cache
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.cleaning_services,
                color: Colors.red,
                size: 32,
              ),
              title: const Text(
                'Clear Cache',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Reset app cache and preferences'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                _clearCache(context);
              },
            ),
          ),

          const Spacer(),

          // Warning
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Debug tools are for development only',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _showFirebaseDebug(BuildContext context) async {
    // Get Firebase status information
    final firebaseInitialized = Firebase.apps.isNotEmpty;
    final currentUser = FirebaseAuth.instance.currentUser;
    final firestoreConnected = await _checkFirestoreConnection();
    final storageConnected = await _checkStorageConnection();
    final appCheckToken = await _getAppCheckToken();

    unawaited(
      showDialog<void>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🔥 Firebase Debug'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildStatusRow('Firebase Initialized', firebaseInitialized),
                const SizedBox(height: 8),
                _buildStatusRow('Current User', currentUser != null),
                if (currentUser != null) ...[
                  Text('User ID: ${currentUser.uid}'),
                  Text('Email: ${currentUser.email ?? "N/A"}'),
                  Text('Display Name: ${currentUser.displayName ?? "N/A"}'),
                ],
                const SizedBox(height: 8),
                _buildStatusRow('Firestore Connected', firestoreConnected),
                const SizedBox(height: 8),
                _buildStatusRow('Storage Connected', storageConnected),
                const SizedBox(height: 8),
                _buildStatusRow('App Check Active', appCheckToken != null),
                if (appCheckToken != null) ...[
                  const Text('App Check Token:'),
                  Text(
                    appCheckToken,
                    style: const TextStyle(
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('common_close'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) => Row(
    children: [
      Icon(
        status ? Icons.check_circle : Icons.error,
        color: status ? Colors.green : Colors.red,
        size: 16,
      ),
      const SizedBox(width: 8),
      Text(label),
      const Spacer(),
      Text(
        status ? '✅ OK' : '❌ FAIL',
        style: TextStyle(
          color: status ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
        ),
      ),
    ],
  );

  Future<bool> _checkFirestoreConnection() async {
    try {
      await FirebaseFirestore.instance
          .collection('debug_test')
          .doc('connection_check')
          .get();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<bool> _checkStorageConnection() async {
    try {
      await FirebaseStorage.instance.ref('debug_test.txt').getDownloadURL();
      return true;
    } on Exception {
      return false;
    }
  }

  Future<String?> _getAppCheckToken() async {
    try {
      return await FirebaseAppCheck.instance.getToken();
    } on Exception {
      return null;
    }
  }

  Future<void> _clearAllCache(BuildContext context) async {
    try {
      // Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // Clear temporary directory
      final tempDir = await getTemporaryDirectory();
      if (tempDir.existsSync()) {
        await _deleteDirectory(tempDir);
      }

      // Clear application documents directory (cache)
      final appDir = await getApplicationDocumentsDirectory();
      if (appDir.existsSync()) {
        await _deleteDirectory(appDir);
      }

      // Sign out user to force re-authentication
      await FirebaseAuth.instance.signOut();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Cache cleared successfully. Please restart the app.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on Exception catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error clearing cache: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDirectory(Directory dir) async {
    try {
      if (dir.existsSync()) {
        final files = dir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } on Exception {
      // Ignore errors during cleanup
    }
  }

  void _clearCache(BuildContext context) {
    unawaited(
      showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🗑️ Clear Cache'),
          content: const Text(
            'Are you sure you want to clear all cached data? This will:\n\n'
            '• Clear image cache\n'
            '• Reset user preferences\n'
            '• Force re-authentication\n'
            '• Clear temporary files',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('common_cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _clearAllCache(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Clear Cache'),
            ),
          ],
        ),
      ),
    );
  }
}
