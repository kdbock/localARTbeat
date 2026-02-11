import 'package:flutter/material.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_drawer.dart';
import '../services/admin_service.dart';
import 'package:artbeat_artwork/artbeat_artwork.dart' as artwork;
import 'package:artbeat_messaging/artbeat_messaging.dart';

/// Admin Platform Curation Screen
/// Handles Featured content, Artwork of the Day, and Global Announcements
class AdminPlatformCurationScreen extends StatefulWidget {
  const AdminPlatformCurationScreen({super.key});

  @override
  State<AdminPlatformCurationScreen> createState() => _AdminPlatformCurationScreenState();
}

class _AdminPlatformCurationScreenState extends State<AdminPlatformCurationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  final artwork.ArtworkService _artworkService = artwork.ArtworkService();
  final AdminMessagingService _messagingService = AdminMessagingService();
  
  bool _isLoading = false;
  List<core.UserModel> _featuredArtists = [];
  List<artwork.ArtworkModel> _featuredArtworks = [];
  final TextEditingController _announcementController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCurationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _announcementController.dispose();
    super.dispose();
  }

  Future<void> _loadCurationData() async {
    setState(() => _isLoading = true);
    try {
      // Load featured artists
      final allUsers = await _adminService.getAllUsers();
      _featuredArtists = allUsers.where((u) => u.isFeatured).toList();

      // Load featured artworks
      _featuredArtworks = await _artworkService.getFeaturedArtwork(limit: 50);
      
    } catch (e) {
      debugPrint('Error loading curation data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Platform Curation'),
        backgroundColor: const Color(0xFF8C52FF),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Material(
            color: const Color(0xFF8C52FF),
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.white,
              tabs: const [
                Tab(text: 'Featured Content', icon: Icon(Icons.star)),
                Tab(text: 'Announcements', icon: Icon(Icons.campaign)),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildFeaturedTab(),
                      _buildAnnouncementsTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Featured Artists', Icons.people),
          const SizedBox(height: 8),
          if (_featuredArtists.isEmpty)
            const Center(child: Text('No featured artists'))
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _featuredArtists.length,
              itemBuilder: (context, index) {
                final artist = _featuredArtists[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: artist.profileImageUrl.isNotEmpty 
                        ? NetworkImage(artist.profileImageUrl) 
                        : null,
                    child: artist.profileImageUrl.isEmpty ? Text(artist.fullName.isNotEmpty ? artist.fullName[0] : '?') : null,
                  ),
                  title: Text(artist.fullName),
                  subtitle: Text(artist.email),
                  trailing: IconButton(
                    icon: const Icon(Icons.star, color: Colors.amber),
                    onPressed: () => _toggleArtistFeatured(artist),
                  ),
                );
              },
            ),
          const SizedBox(height: 24),
          _buildSectionHeader('Featured Artworks', Icons.brush),
          const SizedBox(height: 8),
          if (_featuredArtworks.isEmpty)
            const Center(child: Text('No featured artworks'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: _featuredArtworks.length,
              itemBuilder: (context, index) {
                final art = _featuredArtworks[index];
                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image.network(art.imageUrl, fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          color: Colors.black54,
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            art.title,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 5,
                        right: 5,
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 15,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.star, color: Colors.amber, size: 20),
                            onPressed: () => _toggleArtworkFeatured(art),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Send Global Announcement', Icons.send),
          const SizedBox(height: 16),
          TextField(
            controller: _announcementController,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Enter announcement message...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _sendAnnouncement,
              icon: const Icon(Icons.campaign),
              label: const Text('Broadcast to All Users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8C52FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Recent Broadcasts', Icons.history),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('broadcasts').orderBy('timestamp', descending: true).limit(10).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return const Center(child: Text('No recent broadcasts'));
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['message'] as String? ?? ''),
                        subtitle: Text('Sent on: ${_formatTimestamp(data['timestamp'] as Timestamp)}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8C52FF)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8C52FF)),
        ),
      ],
    );
  }

  Future<void> _toggleArtistFeatured(core.UserModel artist) async {
    setState(() => _isLoading = true);
    try {
      await _adminService.setUserFeatured(artist.id, false);
      await _loadCurationData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${artist.fullName} removed from featured artists')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleArtworkFeatured(artwork.ArtworkModel art) async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('artwork').doc(art.id).update({
        'isFeatured': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      await _loadCurationData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"${art.title}" removed from featured artworks')),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendAnnouncement() async {
    if (_announcementController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a message')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Broadcast'),
        content: const Text('This will send a notification to ALL active users. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Send')),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _messagingService.sendBroadcastMessage(_announcementController.text.trim());
        _announcementController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Announcement broadcasted successfully')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
