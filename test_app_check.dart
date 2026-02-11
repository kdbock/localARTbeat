import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:artbeat_core/src/firebase/secure_firebase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Test App Check initialization
  try {
    await SecureFirebaseConfig.configureAppCheck(
      teamId: 'H49R32NPY6',
    );
    print('✅ App Check configured successfully');
  } catch (e) {
    print('❌ App Check configuration failed: $e');
  }

  // Test token generation
  try {
    final token = await FirebaseAppCheck.instance.getToken();
    if (token != null && token.isNotEmpty) {
      print('✅ App Check token generated successfully');
      print('Token length: ${token.length}');
    } else {
      print('❌ App Check token is null or empty');
    }
  } catch (e) {
    print('❌ App Check token generation failed: $e');
  }

  runApp(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: Text('App Check Test Complete'),
      ),
    ),
  ));
}