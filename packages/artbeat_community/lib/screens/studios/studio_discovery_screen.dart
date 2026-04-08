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
      if (!mounted) return;
      setState(() {
        _availableTags = ['All', ...tags.toList()..sort()];
      });
    } catch (_) {}
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
      currentIndex: -1,
      appBar: core.HudTopBar(
        title: 'screen_title_discover_studios'.tr(),
        subtitle: '',
        showBackButton: true,
        onBackPressed: () => Navigator.of(context).maybePop(),
      ),
      child: core.WorldBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              core.GlassCard(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: const Color(0xFF22D3EE),
                      decoration: core.GlassInputDecoration.search(
                        hintText: 'Search studios...',
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ),
                      ),
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 36,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _availableTags.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final tag = _availableTags[index];
                          final isSelected = tag == _selectedTag;
                          return FilterChip(
                            label: Text(tag),
                            selected: isSelected,
                            onSelected: (_) =>
                                setState(() => _selectedTag = tag),
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.08,
                            ),
                            selectedColor: CommunityColors.primary.withValues(
                              alpha: 0.24,
                            ),
                            checkmarkColor: CommunityColors.primary,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _getStudiosStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      );
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
                        child: core.GlassCard(
                          margin: const EdgeInsets.all(24),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.business,
                                size: 56,
                                color: Colors.white54,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _searchQuery.isEmpty && _selectedTag == 'All'
                                    ? 'No studios available yet'
                                    : 'No studios match your search',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      itemCount: filteredStudios.length,
                      itemBuilder: (context, index) {
                        final studio = filteredStudios[index];
                        return _StudioCard(
                          studio: studio,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
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
        ),
      ),
    );
  }
}

class _StudioCard extends StatelessWidget {
  final StudioModel studio;
  final VoidCallback onTap;

  const _StudioCard({required this.studio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return core.GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  studio.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: CommunityColors.primary.withValues(alpha: 0.24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${studio.memberList.length} members',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            studio.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.white70,
              height: 1.35,
            ),
          ),
          if (studio.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: core.GradientCTAButton(
              text: 'Join Studio',
              icon: Icons.group_add,
              onPressed: onTap,
            ),
          ),
        ],
      ),
    );
  }
}
