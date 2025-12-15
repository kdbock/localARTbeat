import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:artbeat_core/artbeat_core.dart' as core;
import '../../models/studio_model.dart';
import '../../services/firestore_service.dart';
import '../../theme/community_colors.dart';

class StudioManagementScreen extends StatefulWidget {
  final String studioId;

  const StudioManagementScreen({super.key, required this.studioId});

  @override
  State<StudioManagementScreen> createState() => _StudioManagementScreenState();
}

class _StudioManagementScreenState extends State<StudioManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StudioModel? _studio;
  bool _isLoading = true;
  bool _isCurrentUserOwner = false;

  @override
  void initState() {
    super.initState();
    _loadStudio();
  }

  Future<void> _loadStudio() async {
    try {
      final studio = await _firestoreService.getStudioById(widget.studioId);
      if (studio != null) {
        final currentUser = _auth.currentUser;
        setState(() {
          _studio = studio;
          _isCurrentUserOwner =
              currentUser != null &&
              studio.memberList.isNotEmpty &&
              studio.memberList[0] == currentUser.uid;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading studio: $e')));
    }
  }

  Future<void> _removeMember(String memberId) async {
    if (_studio == null || !_isCurrentUserOwner) return;

    try {
      final updatedMembers = List<String>.from(_studio!.memberList)
        ..remove(memberId);
      final updatedStudio = _studio!.copyWith(memberList: updatedMembers);

      await _firestoreService.updateStudio(updatedStudio);

      setState(() {
        _studio = updatedStudio;
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        // ignore: use_build_context_synchronously
        context,
      ).showSnackBar(SnackBar(content: Text('Error removing member: $e')));
    }
  }

  Future<void> _deleteStudio() async {
    if (_studio == null || !_isCurrentUserOwner) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Studio'),
        content: const Text(
          'Are you sure you want to delete this studio? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firestoreService.deleteStudio(_studio!.id);
        // ignore: use_build_context_synchronously
        Navigator.of(context).pop(); // Return to previous screen
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Studio deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(
          // ignore: use_build_context_synchronously
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting studio: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return core.MainLayout(
        scaffoldKey: GlobalKey<ScaffoldState>(),
        currentIndex: -1,
        appBar: const core.EnhancedUniversalHeader(
          title: 'Studio Management',
          backgroundGradient: CommunityColors.communityGradient,
          titleGradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foregroundColor: Colors.white,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_studio == null) {
      return core.MainLayout(
        scaffoldKey: GlobalKey<ScaffoldState>(),
        currentIndex: -1,
        appBar: const core.EnhancedUniversalHeader(
          title: 'Studio Management',
          backgroundGradient: CommunityColors.communityGradient,
          titleGradient: LinearGradient(
            colors: [Colors.white, Colors.white],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          foregroundColor: Colors.white,
        ),
        child: const Center(child: Text('Studio not found')),
      );
    }

    return core.MainLayout(
      scaffoldKey: GlobalKey<ScaffoldState>(),
      currentIndex: -1,
      appBar: core.EnhancedUniversalHeader(
        title: 'Manage ${_studio!.name}',
        backgroundGradient: CommunityColors.communityGradient,
        titleGradient: const LinearGradient(
          colors: [Colors.white, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        foregroundColor: Colors.white,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Studio info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _studio!.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _studio!.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_studio!.memberList.length} members',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          _studio!.privacyType == 'public'
                              ? Icons.public
                              : Icons.lock,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _studio!.privacyType == 'public'
                              ? 'Public'
                              : 'Private',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Members section
            const Text(
              'Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // Members list
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where(FieldPath.documentId, whereIn: _studio!.memberList)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                final members = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final memberData =
                        members[index].data() as Map<String, dynamic>;
                    final memberId = members[index].id;
                    final isOwner = index == 0; // First member is owner
                    final isCurrentUser = memberId == _auth.currentUser?.uid;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage:
                              core.ImageUrlValidator.safeNetworkImage(
                                memberData['profileImageUrl']?.toString(),
                              ),
                          child:
                              !core.ImageUrlValidator.isValidImageUrl(
                                memberData['profileImageUrl']?.toString(),
                              )
                              ? Text(
                                  ((memberData['displayName'] as String?) ??
                                          'U')[0]
                                      .toUpperCase(),
                                )
                              : null,
                        ),
                        title: Text(
                          (memberData['displayName'] as String?) ??
                              'Unknown User',
                        ),
                        subtitle: Text(isOwner ? 'Owner' : 'Member'),
                        trailing:
                            _isCurrentUserOwner && !isCurrentUser && !isOwner
                            ? IconButton(
                                icon: const Icon(
                                  Icons.remove_circle,
                                  color: Colors.red,
                                ),
                                onPressed: () => _removeMember(memberId),
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 32),

            // Danger zone
            if (_isCurrentUserOwner) ...[
              const Text(
                'Danger Zone',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Delete Studio',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Once you delete this studio, there is no going back. Please be certain.',
                        style: TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _deleteStudio,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Delete Studio'),
                        ),
                      ),
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
}
