import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_profile/artbeat_profile.dart' as profile;

// You can replace this with actual Firebase options for development
const mockFirebaseOptions = FirebaseOptions(
  apiKey: 'AIzaSyAWORLK8SxG6IKkaA5CaY2s3J2OIJ_36TA',
  appId: '1:665020451634:android:70aaba9b305fa17b78652b',
  messagingSenderId: '665020451634',
  projectId: 'wordnerd-artbeat',
  storageBucket: 'wordnerd-artbeat.appspot.com',
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    // Check if Firebase is already initialized to avoid duplicate initialization
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: mockFirebaseOptions);
    } else {
      core.AppLogger.firebase(
        'Firebase already initialized, using existing app instance',
      );
    }
    core.AppLogger.firebase('Firebase initialized successfully');
  } catch (e) {
    core.AppLogger.firebase('Failed to initialize Firebase: $e');
    // Continue without Firebase when in development mode
    if (!kDebugMode) rethrow;
  }

  runApp(const ProfileModuleApp());
}

class ProfileModuleApp extends StatelessWidget {
  const ProfileModuleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core providers
        ChangeNotifierProvider<core.UserService>(
          create: (_) => core.UserService(),
        ),
      ],
      child: MaterialApp(
        title: 'ARTbeat Profile Module',
        theme: ThemeData(
          primarySwatch: Colors.indigo,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: const ProfileModuleHome(),
      ),
    );
  }
}

class ProfileModuleHome extends StatelessWidget {
  const ProfileModuleHome({super.key});

  @override
  Widget build(BuildContext context) {
    // Get userService and check if we have a current user for better demo experience
    final userService = Provider.of<core.UserService>(context);
    // Try to get the demo user from the service or use a fallback
    final String demoUserId = userService.currentUserId ?? 'demo_user_id';

    return Scaffold(
      appBar: AppBar(
        title: Text('profile_bin_main_text_artbeat_profile_module'.tr()),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'profile_bin_main_text_profile_module_demo'.tr(),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            // Navigation buttons to the profile screens
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<profile.ProfileViewScreen>(
                  builder: (_) => profile.ProfileViewScreen(
                    userId: demoUserId,
                    isCurrentUser: true,
                  ),
                ),
              ),
              child: Text('profile_bin_main_text_view_profile'.tr()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<profile.EditProfileScreen>(
                  builder: (_) => profile.EditProfileScreen(userId: demoUserId),
                ),
              ),
              child: Text('profile_bin_main_text_edit_profile'.tr()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<profile.FollowersListScreen>(
                  builder: (_) =>
                      profile.FollowersListScreen(userId: demoUserId),
                ),
              ),
              child: Text('profile_bin_main_text_followers'.tr()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<profile.FollowingListScreen>(
                  builder: (_) =>
                      profile.FollowingListScreen(userId: demoUserId),
                ),
              ),
              child: Text('profile_bin_main_text_following'.tr()),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<profile.FavoritesScreen>(
                  builder: (_) => profile.FavoritesScreen(userId: demoUserId),
                ),
              ),
              child: Text('profile_bin_main_text_favorites'.tr()),
            ),
          ],
        ),
      ),
    );
  }
}
