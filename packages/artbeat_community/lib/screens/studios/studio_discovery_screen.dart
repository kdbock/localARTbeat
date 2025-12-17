import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../models/studio_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/community_colors.dart';
import 'studio_chat_screen.dart';

class StudioDiscoveryScreen extends StatefulWidget {
  const StudioDiscoveryScreen({super.key});

  @override
  State<StudioDiscoveryScreen> createState() => _StudioDiscoveryScreenState();
}

class _StudioDiscoveryScreenState extends State<StudioDiscoveryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTag = 'All';
  List<String> _availableTags = ['All'];

  @override
  void initState() {
    super.initState();
    _loadAvailableTags();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableTags() async {
    try {
      final studios = await _firestoreService.getStudios();
      final tags = <String>{};
      for (final studio in studios) {
        tags.addAll(studio.tags);
      }
      setState(() {
        _availableTags = ['All', ...tags.toList()..sort()];
      });
    } catch (e) {
      // Handle error silently
    }
  }

  Stream<QuerySnapshot> _getStudiosStream() {
    return FirebaseFirestore.instance
        .collection('studios')
        .where('privacyType', isEqualTo: 'public')
        .snapshots();
  }

  List<StudioModel> _filterStudios(List<StudioModel> studios) {
    return studios.where((studio) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          studio.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          studio.description.toLowerCase().contains(_searchQuery.toLowerCase());

      final matchesTag =
          _selectedTag == 'All' || studio.tags.contains(_selectedTag);

      return matchesSearch && matchesTag;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return core.MainLayout(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      currentIndex: -1, // Detail screen
      appBar: core.EnhancedUniversalHeader(
        title: 'screen_title_discover_studios'.tr(),
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      child: Column(
        children: [
          // Search and filter section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade50,
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search studios...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Tag filter
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _availableTags.length,
                    itemBuilder: (context, index) {
                      final tag = _availableTags[index];
                      final isSelected = tag == _selectedTag;
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedTag = tag;
                            });
                          },
                          backgroundColor: Colors.white,
                          selectedColor: CommunityColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          checkmarkColor: CommunityColors.primary,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),

          // Studios list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getStudiosStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final studios = snapshot.data!.docs
                    .map((doc) => StudioModel.fromFirestore(doc))
                    .toList();

                final filteredStudios = _filterStudios(studios);

                if (filteredStudios.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty && _selectedTag == 'All'
                              ? 'No studios available yet'
                              : 'No studios match your search',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredStudios.length,
                  itemBuilder: (context, index) {
                    final studio = filteredStudios[index];
                    return StudioCard(
                      studio: studio,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<Widget>(
                            builder: (context) => StudioChatScreen(
                              studioId: studio.id,
                              studio: studio,
                            ),
                          ),
                        );
                      },
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
}

class StudioCard extends StatelessWidget {
  final StudioModel studio;
  final VoidCallback onTap;

  const StudioCard({super.key, required this.studio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Studio name and member count
              Row(
                children: [
                  Expanded(
                    child: Text(
                      studio.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CommunityColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${studio.memberList.length} members',
                      style: const TextStyle(
                        fontSize: 12,
                        color: CommunityColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                studio.description,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),

              // Tags
              if (studio.tags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: studio.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 12),

              // Join button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CommunityColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('Join Studio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
