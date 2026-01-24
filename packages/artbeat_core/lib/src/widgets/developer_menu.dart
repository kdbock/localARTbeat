import 'package:flutter/material.dart';
import 'developer_feedback_admin_screen.dart';
import 'feedback_form.dart';
import 'admin_boost_maintenance_screen.dart';

/// Developer menu with admin upload screens only
class DeveloperMenu extends StatelessWidget {
  const DeveloperMenu({super.key});

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.of(
      context,
      rootNavigator: true,
    ).push(MaterialPageRoute<dynamic>(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Developer Menu',
                    style: TextStyle(color: Colors.white, fontSize: 24),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Admin Upload Screens',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Developer Feedback Admin'),
              onTap: () => _navigateToScreen(
                context,
                const DeveloperFeedbackAdminScreen(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.rate_review),
              title: const Text('Submit Feedback'),
              onTap: () {
                Navigator.of(context).pop();
                Future.delayed(const Duration(milliseconds: 250), () {
                  // ignore: use_build_context_synchronously
                  Navigator.of(context, rootNavigator: true).push(
                    MaterialPageRoute<void>(
                      builder: (context) => const FeedbackForm(),
                    ),
                  );
                });
              },
            ),
            _buildAdminSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminSection(BuildContext context) {
    final adminScreens = <String, Widget>{
      'Admin Upload Artist Profiles': const AdminUploadArtistProfilesScreen(),
      'Admin Upload Gallery': const AdminUploadGalleryScreen(),
      'Admin Upload Admin Ads': const AdminUploadAdminAdsScreen(),
      'Admin Upload User Ads': const AdminUploadUserAdsScreen(),
      'Admin Upload Artist Ads': const AdminUploadArtistAdsScreen(),
      'Admin Upload Gallery Ads': const AdminUploadGalleryAdsScreen(),
      'Admin Upload Event': const AdminUploadEventScreen(),
      'Admin Upload User': const AdminUploadUserScreen(),
      'Admin Upload Artworks': const AdminUploadArtworksScreen(),
      'Admin Upload Captures': const AdminUploadCapturesScreen(),
      'Admin Boost Maintenance': const AdminBoostMaintenanceScreen(),
    };
    return ExpansionTile(
      title: const Text('Admin Screens'),
      children: adminScreens.entries.map((entry) {
        return ListTile(
          title: Text(entry.key),
          onTap: () => _navigateToScreen(context, entry.value),
        );
      }).toList(),
    );
  }
}

// Reusable admin upload form widget
class AdminUploadForm extends StatefulWidget {
  final String label;
  final String hint;
  final String uploadType;
  const AdminUploadForm({
    super.key,
    required this.label,
    required this.hint,
    required this.uploadType,
  });

  @override
  State<AdminUploadForm> createState() => _AdminUploadFormState();
}

class _AdminUploadFormState extends State<AdminUploadForm> {
  final TextEditingController _controller = TextEditingController();
  String? _result;
  bool _loading = false;

  void _upload() async {
    setState(() {
      _loading = true;
      _result = null;
    });
    await Future<void>.delayed(const Duration(seconds: 1)); // Simulate upload
    setState(() {
      _loading = false;
      _result = 'Successfully uploaded to \'${widget.uploadType}\'';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(widget.label, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: widget.hint,
            ),
            minLines: 1,
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loading ? null : _upload,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Upload'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 16),
            Text(_result!, style: const TextStyle(color: Colors.green)),
          ],
        ],
      ),
    );
  }
}

// Admin upload screens with UI
class AdminUploadArtistProfilesScreen extends StatelessWidget {
  const AdminUploadArtistProfilesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Artist Profiles')),
    body: const AdminUploadForm(
      label: 'Upload Artist Profiles',
      hint: 'Enter artist profile data (JSON, ID, etc)',
      uploadType: 'artistProfiles',
    ),
  );
}

class AdminUploadGalleryScreen extends StatelessWidget {
  const AdminUploadGalleryScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Gallery')),
    body: const AdminUploadForm(
      label: 'Upload Gallery',
      hint: 'Enter gallery data (JSON, ID, etc)',
      uploadType: 'business',
    ),
  );
}

class AdminUploadAdminAdsScreen extends StatelessWidget {
  const AdminUploadAdminAdsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Admin Ads')),
    body: const AdminUploadForm(
      label: 'Upload Admin Ads',
      hint: 'Enter admin ad data (JSON, ID, etc)',
      uploadType: 'admin_ads',
    ),
  );
}

class AdminUploadUserAdsScreen extends StatelessWidget {
  const AdminUploadUserAdsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload User Ads')),
    body: const AdminUploadForm(
      label: 'Upload User Ads',
      hint: 'Enter user ad data (JSON, ID, etc)',
      uploadType: 'user_ads',
    ),
  );
}

class AdminUploadArtistAdsScreen extends StatelessWidget {
  const AdminUploadArtistAdsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Artist Ads')),
    body: const AdminUploadForm(
      label: 'Upload Artist Ads',
      hint: 'Enter artist ad data (JSON, ID, etc)',
      uploadType: 'artist_ads',
    ),
  );
}

class AdminUploadGalleryAdsScreen extends StatelessWidget {
  const AdminUploadGalleryAdsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Gallery Ads')),
    body: const AdminUploadForm(
      label: 'Upload Gallery Ads',
      hint: 'Enter gallery ad data (JSON, ID, etc)',
      uploadType: 'gallery_ads',
    ),
  );
}

class AdminUploadEventScreen extends StatelessWidget {
  const AdminUploadEventScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Event')),
    body: const AdminUploadForm(
      label: 'Upload Event',
      hint: 'Enter event data (JSON, ID, etc)',
      uploadType: 'event',
    ),
  );
}

class AdminUploadUserScreen extends StatelessWidget {
  const AdminUploadUserScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload User')),
    body: const AdminUploadForm(
      label: 'Upload User',
      hint: 'Enter user data (JSON, ID, etc)',
      uploadType: 'user',
    ),
  );
}

class AdminUploadArtworksScreen extends StatelessWidget {
  const AdminUploadArtworksScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Artworks')),
    body: const AdminUploadForm(
      label: 'Upload Artworks',
      hint: 'Enter artworks data (JSON, ID, etc)',
      uploadType: 'artworks',
    ),
  );
}

class AdminUploadCapturesScreen extends StatelessWidget {
  const AdminUploadCapturesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Admin Upload Captures')),
    body: const AdminUploadForm(
      label: 'Upload Captures',
      hint: 'Enter captures data (JSON, ID, etc)',
      uploadType: 'captures',
    ),
  );
}
